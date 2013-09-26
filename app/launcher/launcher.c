/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
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
#include <string.h>
#include <gtk/gtk.h>
#include <gio/gdesktopappinfo.h>
#include "xdg_misc.h"
#include "dwebview.h"
#include "dentry/entry.h"
#include "utils.h"
#include "X_misc.h"
#include "i18n.h"
#include "category.h"
#include "launcher_category.h"
#include "background.h"
#include "file_monitor.h"
#include "DBUS_launcher.h"

#define DOCK_HEIGHT 30
#define APPS_INI "launcher/apps.ini"
#define LAUNCHER_CONF "launcher/config.ini"
#define AUTOSTART_DIR "autostart"
#define GNOME_AUTOSTART_KEY "X-GNOME-Autostart-enabled"


PRIVATE GKeyFile* k_apps = NULL;
PRIVATE GKeyFile* launcher_config = NULL;
PRIVATE GtkWidget* container = NULL;
PRIVATE GtkWidget* webview = NULL;
PRIVATE GSettings* dde_bg_g_settings = NULL;
PRIVATE GPtrArray* config_paths = NULL;
PRIVATE gboolean is_js_already = FALSE;

#ifndef NDEBUG
static gboolean is_daemonize = FALSE;
static gboolean not_exit = FALSE;
#endif


/**
 * @brief - key: the category id
 *          value: a list of applications id (md5 basename of path)
 */
PRIVATE GHashTable* _category_table = NULL;


PRIVATE
void _do_im_commit(GtkIMContext *context, gchar* str)
{
    JSObjectRef json = json_create();
    json_append_string(json, "Content", str);
    js_post_message("im_commit", json);
}


PRIVATE
void _update_size(GdkScreen *screen, GtkWidget* conntainer)
{
    gtk_widget_set_size_request(container, gdk_screen_width(), gdk_screen_height());
}


PRIVATE
void _on_realize(GtkWidget* container)
{
    GdkScreen* screen =  gdk_screen_get_default();
    _update_size(screen, container);
    g_signal_connect(screen, "size-changed", G_CALLBACK(_update_size), container);
    if (is_js_already)
        background_changed(dde_bg_g_settings, CURRENT_PCITURE, NULL);
}


DBUS_EXPORT_API
void launcher_show()
{
    GdkWindow* w = gtk_widget_get_window(container);
    gdk_window_show(w);
}


DBUS_EXPORT_API
void launcher_hide()
{
    GdkWindow* w = gtk_widget_get_window(container);
    gdk_window_hide(w);
}


DBUS_EXPORT_API
void launcher_quit()
{
    monitor_destroy();
    g_key_file_free(k_apps);
    g_key_file_free(launcher_config);
    g_object_unref(dde_bg_g_settings);
    g_hash_table_destroy(_category_table);
    g_ptr_array_unref(config_paths);
    gtk_main_quit();
}


#ifndef NDEBUG
void empty()
{ }
#endif


JS_EXPORT_API
void launcher_exit_gui()
{
#ifndef NDEBUG
    if (is_daemonize || not_exit) {
#endif

        launcher_hide();

#ifndef NDEBUG
    } else {
        launcher_quit();
    }
#endif
}


JS_EXPORT_API
void launcher_notify_workarea_size()
{
    js_post_message_simply("workarea_changed",
            "{\"x\":0, \"y\":0, \"width\":%d, \"height\":%d}",
            gdk_screen_width(), gdk_screen_height());
}


PRIVATE
void _append_to_category(const char* path, GList* cs)
{
    if (_category_table == NULL) {
        _category_table =
            g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL,
                                  (GDestroyNotify)g_ptr_array_unref);
    }

    GPtrArray* l = NULL;

    for (GList* iter = g_list_first(cs); iter != NULL; iter = g_list_next(iter)) {
        gpointer id = iter->data;
        l = g_hash_table_lookup(_category_table, id);
        if (l == NULL) {
            l = g_ptr_array_new_with_free_func(g_free);
            g_hash_table_insert(_category_table, id, l);
        }

        g_ptr_array_add(l, g_strdup(path));
    }
}


PRIVATE
void _record_category_info(const char* id, GDesktopAppInfo* info)
{
    GList* categories = get_deepin_categories(info);
    _append_to_category(id, categories);
    g_list_free(categories);
}


PRIVATE
JSObjectRef _init_category_table()
{
    JSObjectRef items = json_array_create();
    GList* app_infos = g_app_info_get_all();

    GList* iter = app_infos;
    for (gsize i=0, skip=0; iter != NULL; i++, iter = g_list_next(iter)) {

        GAppInfo* info = iter->data;
        if (!g_app_info_should_show(info)) {
            skip++;
            continue;
        }

        char* id = dentry_get_id(info);
        _record_category_info(id, G_DESKTOP_APP_INFO(info));
        g_free(id);

        json_array_insert_nobject(items, i - skip,
                info, g_object_ref, g_object_unref);

        g_object_unref(info);
    }

    g_list_free(app_infos); //the element of GAppInfo should free by JSRunTime not here!

    return items;
}


JS_EXPORT_API
JSObjectRef launcher_get_items_by_category(double _id)
{
    int id = _id;
    if (id == ALL_CATEGORY_ID)
        return _init_category_table();

    JSObjectRef items = json_array_create();

    GPtrArray* l = g_hash_table_lookup(_category_table, GINT_TO_POINTER(id));
    if (l == NULL) {
        return items;
    }

    JSContextRef cxt = get_global_context();
    for (int i = 0; i < l->len; ++i) {
        const char* path = g_ptr_array_index(l, i);
        json_array_insert(items, i, jsvalue_from_cstr(cxt, path));
    }

    return items;
}


PRIVATE
gboolean _pred(const gchar* lhs, const gchar* rhs)
{
    return g_strrstr(lhs, rhs) != NULL;
}


typedef gboolean (*Prediction)(const gchar*, const gchar*);


PRIVATE
double _get_weight(const char* src, const char* key, Prediction pred, double weight)
{
    if (src == NULL) {
        return 0.0;
    }

    char* k = g_utf8_casefold(src, -1);
    double ret = pred(k, key) ? weight : 0.0;
    g_free(k);
    return ret;
}

#define FILENAME_WEIGHT 0.3
#define GENERIC_NAME_WEIGHT 0.01
#define KEYWORD_WEIGHT 0.1
#define CATEGORY_WEIGHT 0.01
#define NAME_WEIGHT 0.01
#define DISPLAY_NAME_WEIGHT 0.1
#define DESCRIPTION_WEIGHT 0.01
#define EXECUTABLE_WEIGHT 0.05

JS_EXPORT_API
double launcher_is_contain_key(GDesktopAppInfo* info, const char* key)
{
    double weight = 0.0;

    /* desktop file information */
    const char* path = g_desktop_app_info_get_filename(info);
    char* basename = g_path_get_basename(path);
    *strchr(basename, '.') = '\0';
    weight += _get_weight(basename, key, _pred, FILENAME_WEIGHT);
    g_free(basename);

    const char* gname = g_desktop_app_info_get_generic_name(info);
    weight += _get_weight(gname, key, _pred, GENERIC_NAME_WEIGHT);

    const char* const* keys = g_desktop_app_info_get_keywords(info);
    if (keys != NULL) {
        size_t n = g_strv_length((char**)keys);
        for (size_t i=0; i<n; i++) {
            weight += _get_weight(keys[i], key, _pred, KEYWORD_WEIGHT);
        }
    }

    const char* categories = g_desktop_app_info_get_categories(info);
    if (categories) {
        gchar** category_names = g_strsplit(categories, ";", -1);
        gsize len = g_strv_length(category_names) - 1;
        for (gsize i = 0; i < len; ++i) {
            weight += _get_weight(category_names[i], key, _pred, CATEGORY_WEIGHT);
        }
        g_strfreev(category_names);
    }

    /* application information */
    const char* name = g_app_info_get_name((GAppInfo*)info);
    weight += _get_weight(name, key, _pred, NAME_WEIGHT);

    const char* dname = g_app_info_get_display_name((GAppInfo*)info);
    weight += _get_weight(dname, key, _pred, DISPLAY_NAME_WEIGHT);

    const char* desc = g_app_info_get_description((GAppInfo*)info);
    weight += _get_weight(desc, key, _pred, DESCRIPTION_WEIGHT);

    const char* exec = g_app_info_get_executable((GAppInfo*)info);
    weight += _get_weight(exec, key, _pred, EXECUTABLE_WEIGHT);

    return weight;
}


PRIVATE
void _insert_category(JSObjectRef categories, int array_index, int id, const char* name)
{
    JSObjectRef item = json_create();
    json_append_number(item, "ID", id);
    json_append_string(item, "Name", name);
    json_array_insert(categories, array_index, item);
}


PRIVATE
void _record_categories(JSObjectRef categories, const char* names[], int num)
{
    int index = 1;
    for (int i = 0; i < num; ++i) {
        if (g_hash_table_lookup(_category_table, GINT_TO_POINTER(i)))
            _insert_category(categories, index++, i, names[i]);
    }

    if (g_hash_table_lookup(_category_table, GINT_TO_POINTER(OTHER_CATEGORY_ID))) {
        int other_category_id = num - 1;
        _insert_category(categories, index, OTHER_CATEGORY_ID, names[other_category_id]);
    }
}


JS_EXPORT_API
JSObjectRef launcher_get_categories()
{
    JSObjectRef categories = json_array_create();

    _insert_category(categories, 0, ALL_CATEGORY_ID, ALL);

    const char* names[] = {
        INTERNET, MULTIMEDIA, GAMES, GRAPHICS, PRODUCTIVITY,
        INDUSTRY, EDUCATION, DEVELOPMENT, SYSTEM, UTILITIES,
        OTHER
    };

    int category_num = 0;
    const GPtrArray* infos = get_all_categories_array();

    if (infos == NULL) {
        category_num = G_N_ELEMENTS(names);
    } else {
        category_num = infos->len;
        for (int i = 0; i < category_num; ++i) {
            char* name = g_ptr_array_index(infos, i);

            extern int find_category_id(const char* category_name);
            int id = find_category_id(name);
            int index = id == OTHER_CATEGORY_ID ? category_num - 1 : id;

            names[index] = name;
        }
    }

    _record_categories(categories, names, category_num);
    return categories;
}


JS_EXPORT_API
GFile* launcher_get_desktop_entry()
{
    return g_file_new_for_path(DESKTOP_DIR());
}


JS_EXPORT_API
JSValueRef launcher_load_hidden_apps()
{
    if (k_apps == NULL) {
        k_apps = load_app_config(APPS_INI);
    }

    g_assert(k_apps != NULL);
    GError* error = NULL;
    gsize length = 0;
    gchar** raw_hidden_app_ids = g_key_file_get_string_list(k_apps,
                                                            "__Config__",
                                                            "app_ids",
                                                            &length,
                                                            &error);
    if (raw_hidden_app_ids == NULL) {
        g_warning("read config file %s/%s failed: %s", g_get_user_config_dir(),
                  APPS_INI, error->message);
        g_error_free(error);
        return jsvalue_null();
    }

    JSObjectRef hidden_app_ids = json_array_create();
    JSContextRef cxt = get_global_context();
    for (gsize i = 0; i < length; ++i) {
        g_debug("%s\n", raw_hidden_app_ids[i]);
        json_array_insert(hidden_app_ids, i, jsvalue_from_cstr(cxt, raw_hidden_app_ids[i]));
    }

    g_strfreev(raw_hidden_app_ids);
    return hidden_app_ids;
}


JS_EXPORT_API
void launcher_save_hidden_apps(ArrayContainer hidden_app_ids)
{
    if (hidden_app_ids.data != NULL) {
        g_key_file_set_string_list(k_apps, "__Config__", "app_ids",
            (const gchar* const*)hidden_app_ids.data, hidden_app_ids.num);
        save_app_config(k_apps, APPS_INI);
    }
}


JS_EXPORT_API
gboolean launcher_has_this_item_on_desktop(Entry* _item)
{
    GDesktopAppInfo* item = (GDesktopAppInfo*)_item;
    const char* item_path = g_desktop_app_info_get_filename(item);
    char* basename = g_path_get_basename(item_path);
    char* desktop_item_path = g_build_filename(DESKTOP_DIR(), basename, NULL);

    GFile* desktop_item = g_file_new_for_path(desktop_item_path);
    g_free(basename);

    gboolean is_exist = g_file_query_exists(desktop_item, NULL);
    g_object_unref(desktop_item);
    g_debug("%s exist? %d", desktop_item_path, is_exist);
    g_free(desktop_item_path);

    return is_exist;
}

void _init_config_path()
{
    config_paths = g_ptr_array_new_with_free_func(g_free);

    char* autostart_dir = g_build_filename(g_get_user_config_dir(),
                                           AUTOSTART_DIR, NULL);

    if (g_file_test(autostart_dir, G_FILE_TEST_EXISTS))
        g_ptr_array_add(config_paths, autostart_dir);
    else
        g_free(autostart_dir);

    char const* const* sys_paths = g_get_system_config_dirs();
    for (int i = 0 ; sys_paths[i] != NULL; ++i) {
        autostart_dir = g_build_filename(sys_paths[i], AUTOSTART_DIR, NULL);

        if (g_file_test(autostart_dir, G_FILE_TEST_EXISTS))
            g_ptr_array_add(config_paths, autostart_dir);
        else
            g_free(autostart_dir);
    }

    g_ptr_array_add(config_paths, NULL);
}

gboolean _read_gnome_autostart_enable(const char* path, const char* name, gboolean* is_autostart)
{
    gboolean is_success = FALSE;

    char* full_path = g_build_filename(path, name, NULL);
    GKeyFile* candidate_app = g_key_file_new();
    GError* err = NULL;
    g_key_file_load_from_file(candidate_app, full_path, G_KEY_FILE_NONE, &err);

    if (err != NULL) {
        g_warning("[_read_gnome_autostart_enable] load desktop file(%s) failed: %s", full_path, err->message);
        goto out;
    }

    gboolean has_autostart_key = g_key_file_has_key(candidate_app,
                                                    G_KEY_FILE_DESKTOP_GROUP,
                                                    GNOME_AUTOSTART_KEY,
                                                    &err);
    if (err != NULL) {
        g_warning("[_read_gnome_autostart_enable] function g_key_has_key error: %s", err->message);
        goto out;
    }

    if (has_autostart_key) {
        gboolean gnome_autostart = g_key_file_get_boolean(candidate_app,
                                                          G_KEY_FILE_DESKTOP_GROUP,
                                                          GNOME_AUTOSTART_KEY,
                                                          &err);
        if (err != NULL) {
            g_warning("[_read_gnome_autostart_enable] get value failed: %s", err->message);
        } else {
            *is_autostart = gnome_autostart;
        }

        is_success = TRUE;
    }

out:
    g_free(full_path);
    if (err != NULL)
        g_error_free(err);
    g_key_file_unref(candidate_app);
    return is_success;
}

PRIVATE
gboolean _check_exist(const char* path, const char* name)
{
    GError* err = NULL;
    GDir* dir = g_dir_open(path, 0, &err);

    if (dir == NULL) {
        g_warning("[_check_exist] open dir(%s) failed: %s", path, err->message);
        g_error_free(err);
        return FALSE;
    }

    gboolean is_existing = FALSE;

    const char* filename = NULL;
    while ((filename = g_dir_read_name(dir)) != NULL) {
        char* lowercase_name = g_utf8_strdown(filename, -1);

        if (0 == g_strcmp0(name, lowercase_name)) {
            g_free(lowercase_name);
            is_existing = TRUE;
            break;
        }

        g_free(lowercase_name);
    }

    g_dir_close(dir);

    return is_existing;
}


JS_EXPORT_API
gboolean launcher_is_autostart(Entry* _item)
{
    if (config_paths == NULL) {
        _init_config_path();
    }


    gboolean is_autostart = FALSE;
    gboolean is_existing = FALSE;
    GDesktopAppInfo* item = (GDesktopAppInfo*)_item;
    char* name = get_desktop_file_basename(item);
    char* lowcase_name = g_utf8_strdown(name, -1);
    g_free(name);

    char* path = NULL;
    for (int i = 0; (path = (char*)g_ptr_array_index(config_paths, i)) != NULL; ++i) {
        if ((is_existing = _check_exist(path, lowcase_name))) {
            gboolean gnome_autostart = FALSE;


            if (i == 0 && _read_gnome_autostart_enable(path, lowcase_name, &gnome_autostart)) {
                // user config
                is_autostart = gnome_autostart;
            } else {
                is_autostart = is_existing;
            }

            break;
        }
    }

    g_free(lowcase_name);

    return is_autostart;
}


JS_EXPORT_API
void launcher_add_to_autostart(Entry* _item)
{
    if (launcher_is_autostart(_item))
        return;

    const char* item_path = g_desktop_app_info_get_filename(G_DESKTOP_APP_INFO(_item));
    GFile* item = g_file_new_for_path(item_path);

    char* app_name = g_path_get_basename(item_path);
    const char* config_dir = g_get_user_config_dir();
    char* dest_path = g_build_filename(config_dir, AUTOSTART_DIR, app_name, NULL);
    g_free(app_name);

    GFile* dest = g_file_new_for_path(dest_path);
    g_free(dest_path);

    do_dereference_symlink_copy(item, dest, G_FILE_COPY_NONE);
    g_object_unref(dest);
    g_object_unref(item);
}


JS_EXPORT_API
gboolean launcher_remove_from_autostart(Entry* _item)
{
    GDesktopAppInfo* item = (GDesktopAppInfo*)_item;

    if (config_paths == NULL) {
        _init_config_path();
    }

    int i = 0;
    char* path = NULL;
    while ((path = (char*)g_ptr_array_index(config_paths, i++)) != NULL) {
        GDir* dir = g_dir_open(path, 0, NULL);
        if (dir == NULL)
            return FALSE;

        char* name = get_desktop_file_basename(item);

        const char* filename = NULL;
        while ((filename = g_dir_read_name(dir)) != NULL) {
            char* lowercase_name = g_utf8_strdown(filename, -1);

            if (0 == g_strcmp0(name, lowercase_name)) {
                g_free(lowercase_name);
                char* file_path = g_build_filename(path, filename, NULL);
                GFile* file = g_file_new_for_path(file_path);
                g_free(file_path);
                GError* error = NULL;
                gboolean success = g_file_delete(file, NULL, &error);
                if (!success) {
                    g_warning("delete file failed: %s", error->message);
                    g_error_free(error);
                }
                g_object_unref(file);
                return success;
            }

            g_free(lowercase_name);
        }

        g_dir_close(dir);
        g_free(name);
    }

    return FALSE;
}


JS_EXPORT_API
JSValueRef launcher_sort_method()
{
    if (launcher_config == NULL) {
        launcher_config = load_app_config(LAUNCHER_CONF);
    }

    GError* error = NULL;
    char* sort_method = g_key_file_get_string(launcher_config, "main", "sort_method", &error);
    if (error != NULL) {
        g_warning("get sort method error: %s", error->message);
        g_error_free(error);
        return jsvalue_null();
    }


    JSContextRef ctx = get_global_context();
    JSValueRef method = jsvalue_from_cstr(ctx, sort_method);

    g_free(sort_method);

    return method;
}


JS_EXPORT_API
void launcher_save_config(char const* key, char const* value)
{
    if (launcher_config == NULL)
        launcher_config = load_app_config(LAUNCHER_CONF);

    g_key_file_set_string(launcher_config, "main", "sort_method", value);

    save_app_config(launcher_config, LAUNCHER_CONF);
}


JS_EXPORT_API
JSValueRef launcher_get_app_rate()
{
    GKeyFile* record_file = load_app_config("dock/record.ini");

    gsize size = 0;
    char** groups = g_key_file_get_groups(record_file, &size);

    JSObjectRef json = json_create();

    for (int i = 0; i < size; ++i) {
        GError* error = NULL;
        gint64 num = g_key_file_get_int64(record_file, groups[i], "StartNum", &error);

        if (error != NULL) {
            g_warning("get record file value failed: %s", error->message);
            continue;
        }

        json_append_number(json, groups[i], num);
    }

    g_strfreev(groups);
    g_key_file_free(record_file);

    return json;
}


JS_EXPORT_API
void launcher_webview_ok()
{
    background_changed(dde_bg_g_settings, CURRENT_PCITURE, NULL);
    is_js_already = TRUE;
}


PRIVATE
void daemonize()
{
    g_warning("daemonize");
    pid_t pid = 0;
    if ((pid = fork()) == -1) {
        g_warning("fork error");
        exit(0);
    } else if (pid != 0){
        exit(0);
    }

    setsid();

    if ((pid = fork()) == -1) {
        g_warning("fork error");
        exit(0);
    } else if (pid != 0){
        exit(0);
    }
}


JS_EXPORT_API
void launcher_clear()
{
    webkit_web_view_reload_bypass_cache((WebKitWebView*)webview);
}


int main(int argc, char* argv[])
{
    if (argc == 2 && g_str_equal("-d", argv[1]))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);

#ifndef NDEBUG
    if (argc == 2 && g_str_equal("-D", argv[1]))
        is_daemonize = TRUE;

    if (argc == 2 && 0 == g_strcmp0("-f", argv[1])) {
        not_exit = TRUE;
    }
#endif

    if (is_application_running("launcher.app.deepin")) {
        g_warning("another instance of application launcher is running...\n");
        dbus_launcher_show();
        return 0;
    }

    signal(SIGKILL, launcher_quit);
    signal(SIGTERM, launcher_quit);

#ifndef NDEBUG
    if (is_daemonize)
#endif
        daemonize();

    init_i18n();
    gtk_init(&argc, &argv);
    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_wmclass(GTK_WINDOW(container), "dde-launcher", "DDELauncher");

    set_default_theme("Deepin");
    set_desktop_env_name("Deepin");

    webview = d_webview_new_with_uri(GET_HTML_PATH("launcher"));

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    g_signal_connect(container, "realize", G_CALLBACK(_on_realize), NULL);
    g_signal_connect (container, "destroy", G_CALLBACK(gtk_main_quit), NULL);
#ifndef NDEBUG
    g_signal_connect(container, "delete-event", G_CALLBACK(empty), NULL);
#endif
    dde_bg_g_settings = g_settings_new(SCHEMA_ID);
    g_signal_connect(dde_bg_g_settings, "changed::"CURRENT_PCITURE,
                     G_CALLBACK(background_changed), NULL);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);

    GdkWindow* gdkwindow = gtk_widget_get_window(container);
    GdkRGBA rgba = {0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gdkwindow, &rgba);
    set_launcher_background(gtk_widget_get_window(webview), dde_bg_g_settings,
                            gdk_screen_width(), gdk_screen_height());

    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);
    gdk_window_set_skip_pager_hint(gdkwindow, TRUE);

    GtkIMContext* im_context = gtk_im_multicontext_new();
    gtk_im_context_set_client_window(im_context, gdkwindow);
    GdkRectangle area = {0, 1700, 100, 30};
    gtk_im_context_set_cursor_location(im_context, &area);
    gtk_im_context_focus_in(im_context);
    g_signal_connect(im_context, "commit", G_CALLBACK(_do_im_commit), NULL);

    setup_launcher_dbus_service();

#ifndef NDEBUG
    monitor_resource_file("launcher", webview);
#endif

    monitor_apps();
    gtk_widget_show_all(container);
    gtk_main();
    monitor_destroy();
    return 0;
}

