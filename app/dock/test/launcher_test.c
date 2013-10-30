#include "dock_test.h"
#include "jsextension.h"
#include <gio/gdesktopappinfo.h>

typedef struct _Workspace Workspace;
struct _Workspace {
    int x, y;
};
typedef struct {
    char* title; /* _NET_WM_NAME */
    char* instance_name;  /*WMClass first field */
    char* clss; /* WMClass second field*/
    char* app_id; /*current is executabe file's name*/
    char* exec; /* /proc/pid/cmdline or /proc/pid/exe */
    int state;
    gboolean is_overlay_dock;
    gboolean is_hidden;
    gboolean is_maximize;
    gboolean use_board;
    gulong cross_workspace_num;
    Workspace workspace[4];

    Window window;
    GdkWindow* gdkwindow;

    char* icon;
    gboolean need_update_icon;
} Client;

extern void _update_window_title(Client *c);
extern void _update_window_class(Client *c);
extern void _update_window_appid(Client *c);
extern void _update_window_icon(Client *c);

void dock_test_launcher()
{
    /* Test({ */
    /*      update_dock_apps(); */
    /*      }, "update_dock_apps"); */

    /* Test({ */
    /*      extern void _save_apps_position(); */
    /*      _save_apps_position(); */
    /*      }, "_save_apps_position"); */

    /* char* app_id = NULL; */
    /* GDesktopAppInfo* info1 = g_desktop_app_info_new_from_filename("/usr/share/applications/devhelp.desktop"); */
    /* GDesktopAppInfo* info2 = g_desktop_app_info_new_from_filename("/usr/share/applications/fcitx.desktop"); */
    /* GDesktopAppInfo* info3 = g_desktop_app_info_new_from_filename("/usr/share/applications/deepin-desktop.desktop"); */
    /* GDesktopAppInfo* info4 = g_desktop_app_info_new_from_filename("/usr/share/applications/deepin-dock.desktop"); */
    /* extern char* get_app_id(GDesktopAppInfo* info); */
    /* Test({ */
    /*      g_assert(info1 != NULL); */
    /*      app_id = get_app_id(info1); */
    /*      g_assert(0 == g_strcmp0(app_id, "devhelp")); */
    /*      g_clear_pointer(&app_id, g_free); */

    /*      g_assert(info2 != NULL); */
    /*      app_id = get_app_id(info2); */
    /*      g_assert(0 == g_strcmp0(app_id, "fcitx")); */
    /*      g_clear_pointer(&app_id, g_free); */

    /*      g_assert(info3 != NULL); */
    /*      app_id = get_app_id(info3); */
    /*      g_assert(0 == g_strcmp0(app_id, "desktop")); */
    /*      g_clear_pointer(&app_id, g_free); */

    /*      g_assert(info4 != NULL); */
    /*      app_id = get_app_id(info4); */
    /*      g_assert(0 == g_strcmp0(app_id, "dock")); */
    /*      g_clear_pointer(&app_id, g_free); */
    /*      }, "get_app_id"); */

    /* Test({ */
    /*      extern int get_need_terminal(GDesktopAppInfo*); */
    /*      g_assert(get_need_terminal(info1) == 0); */
    /*      g_assert(get_need_terminal(info2) == 0); */
    /*      g_assert(get_need_terminal(info3) == 0); */
    /*      g_assert(get_need_terminal(info4) == 0); */
    /*      }, "get_need_terminal"); */

    /* GDesktopAppInfo* info5 = g_desktop_app_info_new_from_filename("/usr/share/applications/firefox.desktop"); */
    // those two seem have some problems
    /* extern void dock_swap_apps_position(const char* id1, const char* id2); */
    /* Test({ */
    /*      dock_swap_apps_position(get_app_id(info1), get_app_id(info2)); */
    /*      dock_swap_apps_position(get_app_id(info2), get_app_id(info1)); */
    /*      dock_swap_apps_position(get_app_id(info2), get_app_id(info3)); */
    /*      dock_swap_apps_position(get_app_id(info1), get_app_id(info5)); */
    /*      }, "dock_swap_apps_position"); */

    /* extern void dock_insert_apps_position(const char* id, const char* anchor_id); */
    /* Test({ */
    /*      dock_insert_apps_position(get_app_id(info1), get_app_id(info2)); */
    /*      dock_insert_apps_position(get_app_id(info2), get_app_id(info1)); */
    /*      dock_insert_apps_position(get_app_id(info2), get_app_id(info3)); */
    /*      dock_insert_apps_position(get_app_id(info1), get_app_id(info5)); */
    /*      }, "dock_insert_apps_position"); */

    /* extern void write_app_info(GDesktopAppInfo* info); */
    /* Test({ */
    /*      write_app_info(info1); */
    /*      write_app_info(info2); */
    /*      write_app_info(info3); */
    /*      write_app_info(info4); */
    /*      write_app_info(info5); */
    /*      }, "write_app_info"); */


    /* int xid = 0x2000035;  // ATTENTION!! change it yourself when you need to test. */
    /* Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default()); */
    /* GdkWindow* root = gdk_get_default_root_window(); */
    /* Client* c = g_slice_new(Client); */
    /* c->window = xid; */
    /* c->title = NULL; */
    /* c->clss = NULL; */
    /* c->instance_name = NULL; */
    /* c->app_id = NULL; */
    /* c->exec = NULL; */
    /* c->icon = NULL; */
    /* _update_window_title(c); */
    /* _update_window_class(c); */
    /* _update_window_appid(c); */
    /* ArrayContainer fs = {NULL, 0}; */

    // ATTENTION!!! test after commenting g_app_info_launch function;
    /* extern gboolean dock_launch_by_app_id(const char* app_id, const char* exec, ArrayContainer fs); */
    /* Test({ */
    /*      dock_launch_by_app_id(c->app_id, c->exec, fs); */
    /*      }, "dock_launch_by_app_id"); */

    // TODO:
    // TBT, build_app_info lead to failed
    /* extern gboolean request_by_info(const char* name, const char* cmdline, const char* icon); */
    /* Test({ */
    /*      request_by_info(c->app_id, c->exec, c->icon); */
    /*      }, "request_by_info"); */

    /* g_free(c->title); */
    /* g_free(c->clss); */
    /* g_free(c->instance_name); */
    /* g_free(c->app_id); */
    /* g_free(c->exec); */
    /* g_free(c->icon); */
    /* g_slice_free(Client, c); */

    /* extern void dock_request_dock(const char* app_id); */
    /* extern void dock_request_undock(const char* app_id); */
    /* Test({ */
    /*      dock_request_dock("/usr/share/applications/firefox.desktop"); */
    /*      dock_request_undock("firefox"); */
    /*      }, "dock_request_dock and dock_request_undock"); */

    /* g_object_unref(info1); */
    /* g_object_unref(info2); */
    /* g_object_unref(info3); */
    /* g_object_unref(info4); */
    /* g_object_unref(info5); */

    // TOD failed
    /* Test({ */
    /*      extern JSValueRef build_app_info(const char* app_id); */
    /*      #<{(| build_app_info("firefox"); |)}># */
    /*      JSValueRef app_info = build_app_info("google-chrome"); */
    /*      if (app_info) */
    /*          js_post_message("launcher_added", app_info); */
    /*      }, "build_app_info"); */
}

