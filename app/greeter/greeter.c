/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2013 Long Wei
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

#include <gtk/gtk.h>
#include <cairo-xlib.h>
#include <gdk/gdkx.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <lightdm.h>
#include <unistd.h>
#include <glib.h>
#include <stdlib.h>
#include <glib/gstdio.h>
#include <glib/gprintf.h>
#include <sys/types.h>
#include <signal.h>
#include <X11/XKBlib.h>
#include "user.h"
#include "session.h"
#include "greeter_util.h"
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
#include "camera.h"
#include "mutils.h"
#include "settings.h"
#include "DBUS_greeter.h"

#define GREETER_HTML_PATH "file://"RESOURCE_DIR"/greeter/index.html"

static GtkWidget* container = NULL;
static GtkWidget* webview = NULL;
LightDMGreeter *greeter;
GKeyFile *greeter_keyfile;
gchar* greeter_file;

struct AuthHandler {
    gchar *username;
    gchar *password;
    gchar *session;
};

struct AuthHandler *handler;

static void
free_auth_handler (struct AuthHandler *handler)
{
    if (handler == NULL) {
        return ;
    }

    if (handler->username != NULL) {
        g_free (handler->username);
    }

    if (handler->password != NULL) {
        g_free (handler->password);
    }

    if (handler->session != NULL) {
        g_free (handler->session);
    }

    if (handler != NULL) {
        g_free (handler);
    }
}

static void
start_authentication (struct AuthHandler *handler)
{
    gchar *username = g_strdup (handler->username);
    //g_warning ("start authentication:%s\n", username);

    if (g_strcmp0 (username, "guest") == 0) {
        lightdm_greeter_authenticate_as_guest (greeter);
        g_warning ("start authentication for guest\n");

    } else {
        lightdm_greeter_authenticate (greeter, username);
    }

    g_free (username);
}

static void
respond_authentication (LightDMGreeter *greeter, const gchar *text, LightDMPromptType type)
{
    gchar *respond = NULL;

    if (type == LIGHTDM_PROMPT_TYPE_QUESTION) {
        respond = g_strdup (handler->username);

    }  else if (type == LIGHTDM_PROMPT_TYPE_SECRET) {
        respond = g_strdup (handler->password);

    } else {
        g_warning ("respond authentication failed:invalid prompt type\n");
        return ;
    }
    //g_warning ("respond authentication:%s\n", respond);

    lightdm_greeter_respond (greeter, respond);

    g_free (respond);
}

static void
set_last_user (const gchar* username)
{
    gchar *data;
    gsize length;

    g_key_file_set_value (greeter_keyfile, "deepin-greeter", "last-user", g_strdup (username));
    data = g_key_file_to_data (greeter_keyfile, &length, NULL);
    g_file_set_contents (greeter_file, data, length, NULL);

    g_free (data);
}

static void
start_session (LightDMGreeter *greeter)
{
    gchar *session = g_strdup (handler->session);
    //g_warning ("start session:%s\n", session);

    if (!lightdm_greeter_get_is_authenticated (greeter)) {
        g_warning ("start session:not authenticated\n");
        js_post_message_simply("auth-failed", "{\"error\":\"%s\"}", _("Invalid Password"));

        g_free (session);
        return ;
    }

    set_last_user (handler->username);
    keep_user_background (handler->username);
    kill_user_lock (handler->username, handler->password);

    if (!lightdm_greeter_start_session_sync (greeter, session, NULL)) {
        g_warning ("start session %s failed\n", session);

        g_free (session);
        free_auth_handler (handler);

    } else {
        g_debug ("start session %s succeed\n", session);

        g_key_file_free (greeter_keyfile);
        g_free (greeter_file);
        g_free (session);
        free_auth_handler (handler);
    }
}

JS_EXPORT_API
gboolean greeter_start_session (const gchar *username, const gchar *password, const gchar *session)
{
    gboolean use_face_login = greeter_use_face_recognition_login(username);
    if (use_face_login)
        dbus_add_nopwdlogin((char*)username);

    gboolean ret = FALSE;

    if (handler != NULL) {
        free_auth_handler (handler);
    }

    handler = g_new0 (struct AuthHandler, 1);
    handler->username = g_strdup (username);
    handler->password = g_strdup (password);
    handler->session = g_strdup (session);

    if (lightdm_greeter_get_is_authenticated (greeter)) {

        g_warning ("greeter start session:already authenticated\n");
        //start_session (handler);
        ret = TRUE;

    } else if (lightdm_greeter_get_in_authentication (greeter)) {

        if (g_strcmp0 (username, lightdm_greeter_get_authentication_user (greeter)) == 0) {

            g_warning ("greeter start session:current user in authentication\n");
         //   respond_authentication (handler);

        } else {

            g_warning ("greeter start session:other user in authentication\n");
          //  lightdm_greeter_cancel_authentication (greeter);
        }

    } else {

        // g_warning ("greeter start session:start authenticated\n");
        start_authentication (handler);

        ret = TRUE;
    }

    if (use_face_login)
        dbus_remove_nopwdlogin((char*)username);

    return ret;
}

int main (int argc, char **argv)
{
    /* if (argc == 2 && g_str_equal(argv[1], "-d")) */
    g_setenv("G_MESSAGES_DEBUG", "all", FALSE);

    GdkScreen *screen;
    GdkRectangle geometry;

    init_i18n ();
    gtk_init (&argc, &argv);

    greeter = lightdm_greeter_new ();
    g_assert (greeter);

    g_signal_connect (greeter, "show-prompt", G_CALLBACK (respond_authentication), NULL);
    //g_signal_connect(greeter, "show-message", G_CALLBACK(show_message_cb), NULL);
    g_signal_connect (greeter, "authentication-complete", G_CALLBACK (start_session), NULL);
    //g_signal_connect(greeter, "autologin-timer-expired", G_CALLBACK(autologin_timer_expired_cb), NULL);

    if(!lightdm_greeter_connect_sync (greeter, NULL)){
        g_warning ("connect greeter failed\n");
        exit (EXIT_FAILURE);
    }

    gchar *greeter_dir = g_build_filename (g_get_user_cache_dir (), "lightdm", NULL);

    if (g_mkdir_with_parents (greeter_dir, 0755) < 0){
        greeter_dir = "/var/cache/lightdm";
    }

    greeter_file = g_build_filename (greeter_dir, "deepin-greeter", NULL);
    g_free (greeter_dir);

    greeter_keyfile = g_key_file_new ();
    g_key_file_load_from_file (greeter_keyfile, greeter_file, G_KEY_FILE_NONE, NULL);

    gdk_window_set_cursor (gdk_get_default_root_window (), gdk_cursor_new (GDK_LEFT_PTR));

    container = create_web_container (FALSE, TRUE);
    gtk_window_set_decorated (GTK_WINDOW (container), FALSE);

    screen = gtk_window_get_screen (GTK_WINDOW (container));
    gdk_screen_get_monitor_geometry (screen, gdk_screen_get_primary_monitor (screen), &geometry);
    gtk_window_set_default_size (GTK_WINDOW (container), geometry.width, geometry.height);
    gtk_window_move (GTK_WINDOW (container), geometry.x, geometry.y);

    webview = d_webview_new_with_uri (GREETER_HTML_PATH);
    g_signal_connect (webview, "draw", G_CALLBACK (erase_background), NULL);
    gtk_container_add (GTK_CONTAINER(container), GTK_WIDGET (webview));
    gtk_widget_realize (container);

    GdkWindow* gdkwindow = gtk_widget_get_window (container);
    GdkRGBA rgba = { 0, 0, 0, 0.0 };
    gdk_window_set_background_rgba (gdkwindow, &rgba);

    gtk_widget_show_all (container);

 //   monitor_resource_file("greeter", webview);
    init_camera(argc, argv);
    turn_numlock_on ();
    gtk_main ();
    destroy_camera();

    return 0;
}

