/** * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Long Wei
 *
 * Author:      Long Wei <yilang2007lw@gmail.com>
 * Maintainer:  Long Wei <yilang2007lw@gamil.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/

#include <sys/types.h>
#include <signal.h>
#include <stdlib.h>
#include <string.h>
#include <glib.h>
#include <gio/gio.h>
#include <stdio.h>
#include <string.h>
#include <shadow.h>
#include <unistd.h>
#include <errno.h>
#include <crypt.h>

#define LOCK_DBUS_NAME     "com.deepin.dde.lock"
#define LOCK_DBUS_OBJ       "/com/deepin/dde/lock"
#define LOCK_DBUS_IFACE     "com.deepin.dde.lock"


struct LoginInfo {
    char* username;
    gboolean is_already_no_pwd_login;
};

static struct LoginInfo login_info = {NULL, FALSE};

const char* _lock_dbus_iface_xml =
"<?xml version=\"1.0\"?>\n"
"<node>\n"
"	<interface name=\""LOCK_DBUS_IFACE"\">\n"
"		<method name=\"UnlockCheck\">\n"
"			<arg name=\"username\" type=\"s\" direction=\"in\">\n"
"			</arg>\n"
"			<arg name=\"password\" type=\"s\" direction=\"in\">\n"
"			</arg>\n"
"			<arg name=\"succeed\" type=\"b\" direction=\"out\">\n"
"			</arg>\n"
"		</method>\n"
"		<method name=\"ExitLock\">\n"
"			<arg name=\"username\" type=\"s\" direction=\"in\">\n"
"			</arg>\n"
"			<arg name=\"password\" type=\"s\" direction=\"in\">\n"
"			</arg>\n"
"		</method>\n"
"		<method name=\"NeedPwd\">\n"
"			<arg name=\"username\" type=\"s\" direction=\"in\">\n"
"			</arg>\n"
"			<arg name=\"needed\" type=\"b\" direction=\"out\">\n"
"			</arg>\n"
"		</method>\n"
"		<method name=\"IsLiveCD\">\n"
"			<arg name=\"username\" type=\"s\" direction=\"in\">\n"
"			</arg>\n"
"			<arg name=\"livecd\" type=\"b\" direction=\"out\">\n"
"			</arg>\n"
"		</method>\n"
"		<method name=\"AddNoPwdLogin\">\n"
"			<arg name=\"username\" type=\"s\" direction=\"in\">\n"
"			</arg>\n"
"			<arg name=\"result\" type=\"b\" direction=\"out\">\n"
"			</arg>\n"
"		</method>\n"
"		<method name=\"RemoveNoPwdLogin\">\n"
"			<arg name=\"username\" type=\"s\" direction=\"in\">\n"
"			</arg>\n"
"			<arg name=\"result\" type=\"b\" direction=\"out\">\n"
"			</arg>\n"
"		</method>\n"
"	</interface>\n"
"</node>\n"
;

static GMainLoop *loop = NULL;
static guint lock_service_owner_id;
static guint lock_service_reg_id;        //used for unregister an object path
static guint retry_reg_timeout_id;   //timer used for retrying dbus name registration.
static GDBusConnection* lock_connection;

//internal functions
static gboolean _retry_registration (gpointer user_data);

static void _on_bus_acquired (GDBusConnection * connection, const gchar * name, gpointer user_data);

static void _on_name_acquired (GDBusConnection * connection, const gchar * name, gpointer user_data);

static void _on_name_lost (GDBusConnection * connection, const gchar * name, gpointer user_data);

static void _bus_method_call (GDBusConnection * connection, const gchar * sender, const gchar * object_path, const gchar * interface,
                              const gchar * method, GVariant * params, GDBusMethodInvocation * invocation, gpointer user_data);

static void _bus_handle_exit_lock (const gchar *username, const gchar *password);

static gboolean _bus_handle_need_pwd (const gchar *username);

static gboolean _bus_handle_is_livecd (const gchar *username);

static gboolean _bus_handle_unlock_check (const gchar *username, const gchar *password);

static gboolean _bus_handle_add_nopwdlogin (const gchar* username);

static gboolean _bus_handle_remove_nopwdlogin (const gchar* username);

static gboolean do_exit (gpointer user_data);

static GDBusNodeInfo *      node_info = NULL;
static GDBusInterfaceInfo * interface_info = NULL;
static GDBusInterfaceVTable interface_table = {
                               method_call:   _bus_method_call,
                               get_property:   NULL, /* No properties */
                               set_property:   NULL  /* No properties */
                            };

void
lock_setup_dbus_service ()
{
    GError* error = NULL;

    node_info = g_dbus_node_info_new_for_xml (_lock_dbus_iface_xml, &error);
    if (error != NULL) {
        g_critical ("Unable to parse interface xml: %s", error->message);
        g_error_free (error);
    }

    interface_info = g_dbus_node_info_lookup_interface (node_info, LOCK_DBUS_IFACE);
    if (interface_info == NULL) {
        g_critical ("Unable to find interface '"LOCK_DBUS_IFACE"'");
    }

    lock_service_owner_id = 0;
    lock_service_reg_id = 0;
    retry_reg_timeout_id = 0;

    _retry_registration (NULL);
}

static gboolean
_retry_registration (gpointer user_data)
{
    lock_service_owner_id = g_bus_own_name (G_BUS_TYPE_SYSTEM,
                                            LOCK_DBUS_NAME,
                                            G_BUS_NAME_OWNER_FLAGS_NONE,
                                            lock_service_reg_id ? NULL : _on_bus_acquired,
                                            _on_name_acquired,
                                            _on_name_lost,
                                            NULL,
                                            NULL);
    return TRUE;
}

static void
_on_bus_acquired (GDBusConnection * connection, const gchar * name, gpointer user_data)
{
    GError* error = NULL;

    g_debug ("on_bus_acquired");
    lock_connection = connection;

    //register object.
    lock_service_reg_id = g_dbus_connection_register_object (connection,
                                                             LOCK_DBUS_OBJ,
                                                             interface_info,
                                                             &interface_table,
                                                             user_data,
                                                             NULL,
                                                             &error);
    if (error != NULL) {
        g_critical ("Unable to register the object to DBus: %s", error->message);

        g_error_free (error);

        g_bus_unown_name (lock_service_owner_id);

        lock_service_owner_id = 0;
        retry_reg_timeout_id = g_timeout_add_seconds (1, _retry_registration, NULL);

        return;
    }
    return;
}

static void
_on_name_acquired (GDBusConnection * connection, const gchar * name, gpointer user_data)
{
    g_debug ("Dbus name acquired");
}

static void
_on_name_lost (GDBusConnection * connection, const gchar * name, gpointer user_data)
{
    if (connection == NULL) {
        g_critical("Unable to get a connection to DBus");

    } else {
        g_critical("Unable to claim the name %s", LOCK_DBUS_NAME);
    }

    lock_service_owner_id = 0;
}

/*
 * 	this function implements all the methods in the Registrar interface.
 */
static void
_bus_method_call (GDBusConnection * connection, const gchar * sender, const gchar * object_path, const gchar * interface,
                 const gchar * method, GVariant * params, GDBusMethodInvocation * invocation, gpointer user_data)
{
    g_debug ("bus_method_call");
    GVariant * retval = NULL;
    GError * error = NULL;

    if (g_strcmp0 (method, "ExitLock") == 0) {

        const gchar *username = NULL;
        const gchar *password = NULL;
        g_variant_get (params, "(ss)", &username, &password);

        _bus_handle_exit_lock (username, password);

    } else if (g_strcmp0 (method, "UnlockCheck") == 0) {

        const gchar *username = NULL;
        const gchar *password = NULL;
        g_variant_get (params, "(ss)", &username, &password);

        retval = g_variant_new("(b)", _bus_handle_unlock_check(username, password));

    } else if (g_strcmp0 (method, "NeedPwd") == 0) {

        const gchar *username = NULL;
        g_variant_get (params, "(s)", &username);

        retval = g_variant_new("(b)", _bus_handle_need_pwd (username));

    } else if (g_strcmp0 (method, "IsLiveCD") == 0) {

        const gchar *username = NULL;
        g_variant_get (params, "(s)", &username);

        retval = g_variant_new ("(b)", _bus_handle_is_livecd (username));

    } else if (0 == g_strcmp0(method, "AddNoPwdLogin")) {
        const gchar* username = NULL;
        g_variant_get(params, "(s)", &username);

        retval = g_variant_new ("(b)", _bus_handle_add_nopwdlogin (username));

    } else if (0 == g_strcmp0(method, "RemoveNoPwdLogin")) {
        const gchar* username = NULL;
        g_variant_get(params, "(s)", &username);

        retval = g_variant_new ("(b)", _bus_handle_remove_nopwdlogin (username));

    } else {

        g_warning ("Calling method '%s' on lock and it's unknown", method);
    }

    if (error != NULL) {

        g_dbus_method_invocation_return_dbus_error (invocation, "com.deepin.dde.lock.Error", error->message);
        g_error_free (error);

    } else {
        g_dbus_method_invocation_return_value (invocation, retval);
    }
}

static void
_bus_handle_exit_lock (const gchar *username, const gchar *password)
{
    gchar *lockpid_file = g_strdup_printf ("%s%s%s", "/home/", username, "/.dlockpid");

    if (!g_file_test (lockpid_file, G_FILE_TEST_EXISTS)) {
        g_debug("user hadn't locked");

    } else {
        gchar *contents = NULL;
        gsize length;

        if (g_file_get_contents (lockpid_file, &contents, &length, NULL)) {

            gboolean succeed = _bus_handle_unlock_check (username, password);
            g_debug ("kill user lock by pid");

            if (succeed) {
                // header doesn't work, add this to avoid warning
                extern int kill(pid_t, int);

                if (kill ((pid_t)strtol (contents, NULL, 10), SIGTERM) == 0){
                    g_debug ("kill user lock succeed");

                } else {
                    g_debug ("kill user lock failed");
                }

            } else {
                g_debug ("username and password not match");
            }

        } else {
            g_warning("get lockpid contents failed");
        }

        g_free(contents);
    }

    g_free(lockpid_file);
}

static gboolean
_bus_handle_unlock_check (const gchar *username, const gchar *password)
{
    if (!(_bus_handle_need_pwd (username))) {
        return TRUE;
    }

    struct spwd *user_data;
    errno = 0;

    user_data = getspnam (username);

    if (user_data == NULL) {
        g_warning ("No such user %s, or error %s\n", username, strerror (errno));
        return TRUE;
    }

    if (user_data->sp_pwdp == NULL || strlen (user_data->sp_pwdp) == 0) {
        g_warning ("user sp_pwdp is null\n");
        return TRUE;
    }

    if ((strcmp (crypt (password, user_data->sp_pwdp), user_data->sp_pwdp)) == 0) {
        return TRUE;
    }

    return FALSE;
}

static
GPtrArray *get_nopasswdlogin_users ()
{
    GPtrArray *nopasswdlogin = g_ptr_array_new ();
    GError *error = NULL;

    GFile *file = g_file_new_for_path ("/etc/group");
    g_assert (file);

    GFileInputStream *input = g_file_read (file, NULL, &error);
    if (error != NULL) {
        g_warning ("read /etc/group failed\n");
        g_clear_error (&error);
    }
    g_assert (input);

    GDataInputStream *data_input = g_data_input_stream_new ((GInputStream *) input);
    g_assert (data_input);

    char *data = (char *) 1;
    while (data) {
        gsize length = 0;
        data = g_data_input_stream_read_line (data_input, &length, NULL, &error);
        if (error != NULL) {
            g_warning ("read line error\n");
            g_clear_error (&error);
        }

        if (data != NULL) {
            if (g_str_has_prefix (data, "nopasswdlogin")){
                gchar **nopwd_line = g_strsplit (data, ":", 4);
                g_debug ("data:%s", data);
                g_debug ("nopwd_line[3]:%s", nopwd_line[3]);

                if (nopwd_line[3] != NULL) {
                    gchar **user_strv = g_strsplit (nopwd_line[3], ",", 1024);

                    for (guint i = 0; i < g_strv_length (user_strv); i++) {
                        g_debug ("user_strv[i]:%s", user_strv[i]);
                        g_ptr_array_add (nopasswdlogin, g_strdup (user_strv[i]));
                    }
                    g_strfreev (user_strv);
                }
                g_strfreev (nopwd_line);
            }
        } else {
            break;
        }
    }

    g_object_unref (data_input);
    g_object_unref (input);
    g_object_unref (file);

    return nopasswdlogin;
}

static
gboolean is_user_nopasswdlogin (const gchar *username)
{
    gboolean ret = FALSE;
    GPtrArray *nopwdlogin = get_nopasswdlogin_users ();

    for (guint i = 0; i < nopwdlogin->len; i++) {
        g_debug ("array i:%s", (gchar*) g_ptr_array_index (nopwdlogin, i));

        if(g_strcmp0 (username, g_ptr_array_index (nopwdlogin, i)) == 0){
            g_debug ("nopwd login true");
            ret = TRUE;
        }
    }

    g_ptr_array_free (nopwdlogin, TRUE);

    return ret;
}

static gboolean
_bus_handle_need_pwd (const gchar *username)
{
    struct spwd *user_data;

    user_data = getspnam (username);

    if (user_data != NULL && strlen (user_data->sp_pwdp) == 0) {
        g_debug ("user had blank password\n");
        return FALSE;
    }

    if (is_user_nopasswdlogin (username)) {
        g_debug ("user in nopasswdlogin group\n");
        return FALSE;
    }

    if ((strcmp (crypt ("", user_data->sp_pwdp), user_data->sp_pwdp)) == 0) {
        g_debug ("live account don't need password\n");
        return FALSE;
    }

    return TRUE;
}

static gboolean
_bus_handle_is_livecd (const gchar *username)
{
    if (g_strcmp0 ("deepin", username) != 0) {
        return FALSE;
    }

    struct spwd *user_data;

    user_data = getspnam (username);

    if (user_data == NULL || strlen (user_data->sp_pwdp) == 0) {
        return FALSE;
    }

    if ((strcmp (crypt ("", user_data->sp_pwdp), user_data->sp_pwdp)) != 0) {
        return FALSE;
    }

    return TRUE;
}

static gboolean
_bus_handle_add_nopwdlogin (const gchar* username)
{
    gboolean ret = FALSE;

    GError *error = NULL;

    if (is_user_nopasswdlogin (username)) {

        login_info.username = g_strdup (username);
        login_info.is_already_no_pwd_login = TRUE;
        ret = TRUE;

    } else {
        gchar *add_cmd = g_strdup_printf ("gpasswd -a %s nopasswdlogin", username);

        g_spawn_command_line_sync (add_cmd, NULL, NULL, NULL, &error);
        if (error != NULL) {
            g_warning ("_bus_handle_add_nopwdlogin:%s\n", error->message);
            g_error_free (error);

        } else {
            ret = TRUE;
        }
        error = NULL;

        g_free (add_cmd);
    }

    return ret;
}

static gboolean
_bus_handle_remove_nopwdlogin (const gchar* username)
{
    gboolean ret = FALSE;

    if (login_info.is_already_no_pwd_login)
        return TRUE;

    GError *error = NULL;

    if (!is_user_nopasswdlogin (username)) {

        ret = TRUE;

    } else {
        gchar *remove_cmd = g_strdup_printf ("gpasswd -d %s nopasswdlogin", username);

        g_spawn_command_line_sync (remove_cmd, NULL, NULL, NULL, &error);
        if (error != NULL) {
            g_warning ("_bus_handle_remove_nopwdlogin:%s\n", error->message);
            g_error_free (error);

        } else {
            ret = TRUE;
        }
        error = NULL;

        g_free (remove_cmd);
    }

    return ret;
}

static gboolean
do_exit (gpointer user_data)
{
    g_main_loop_quit (loop);

    return FALSE;
}

int main (int argc, char **argv)
{
    loop = g_main_loop_new (NULL, FALSE);

    lock_setup_dbus_service ();

    g_timeout_add_seconds (60, do_exit, NULL);

    g_main_loop_run (loop);

    return 0;
}

