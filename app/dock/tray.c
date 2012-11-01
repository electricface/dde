#include "notification_area/na-tray-manager.h"
#include "X_misc.h"
#include "dwebview.h"

#define DEFAULT_WIDTH 24
#define DEFAULT_INTERVAL 30
GHashTable* icons = NULL;

static void
tray_icon_to_info(GdkWindow* icon, gint xy, GString* string);

static GdkFilterReturn
monitor_remove(GdkXEvent* xevent, GdkEvent* event, gpointer data)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        g_hash_table_remove(icons, (GdkWindow*)data);
        char* msg = g_strdup_printf("{\"id\":%d}", GPOINTER_TO_INT(data));
        js_post_message("tray_icon_removed", msg);
        g_free(msg);
    }
    return GDK_FILTER_CONTINUE;
}

void tray_icon_added (NaTrayManager *manager, Window child, GtkWidget* container)
{
    GdkWindow* icon = gdk_x11_window_foreign_new_for_display(gdk_display_get_default(), child);

    gint x = g_hash_table_size(icons) * DEFAULT_INTERVAL;
    gint y = 0;

    gint xy = y + (x  << 16);
    g_hash_table_insert(icons, icon, GINT_TO_POINTER(xy)); 

    gdk_window_reparent(icon, gtk_widget_get_window(container), x, y);
    gdk_window_set_events(icon, GDK_VISIBILITY_NOTIFY_MASK); //add this mask so, gdk can handle GDK_SELECTION_CLEAR event to destroy this gdkwindow.
    gdk_window_add_filter(icon, monitor_remove, icon);
    gdk_window_set_composited(icon, TRUE);
    gdk_window_move_resize(icon, -100, -100, DEFAULT_WIDTH, DEFAULT_WIDTH);

    GString* string = g_string_new("");
    tray_icon_to_info(icon, xy, string);
    string->str[string->len-1] = '\0';
    js_post_message("tray_icon_added", string->str);
    puts(string->str);
    g_string_free(string, TRUE);
}
void tray_init(GtkWidget* container)
{
    GdkScreen* screen = gdk_screen_get_default();
    NaTrayManager* tray_manager = NULL;
    tray_manager = na_tray_manager_new();
    na_tray_manager_manage_screen(tray_manager, screen);

    icons = g_hash_table_new(g_direct_hash, g_direct_equal);

    g_signal_connect(tray_manager, "tray_icon_added", G_CALLBACK(tray_icon_added), container);
}


//JS_EXPORT
void set_tray_icon_position(double _icon, double _x, double _y)
{
    GdkWindow* icon = (GdkWindow*)GINT_TO_POINTER((gint)_icon);
    if (g_hash_table_contains(icons, icon)) {
        int x = (int) _x;
        int y = (int) _y;
        int xy = y + (x  << 16);
        g_hash_table_insert(icons, icon, GINT_TO_POINTER(xy));
        gdk_window_move(icon, x, y);
        gdk_window_show(icon);

        GdkWindow* container = gdk_window_get_parent(icon);
        GdkRectangle rect;
        gdk_window_get_geometry(container, &(rect.x), &(rect.y), &(rect.width), &(rect.height));
        gdk_window_invalidate_rect(container, &rect, TRUE);
    } else {
        g_warning("Don't use invalid tray_icon ID\n");
    }
}


static void
tray_icon_to_info(GdkWindow* icon, gint xy, GString* string)
{
    char* res_class = NULL;
    char* res_name = NULL;
    get_wmclass(icon, &res_class, &res_name);
    g_string_append_printf(string, "{\"id\":%d, \"clss\":\"%s\",\"name\":\"%s\"},", GPOINTER_TO_INT(icon), res_class, res_name);
    g_free(res_class);
    g_free(res_name);
}
//JS_EXPORT
char* get_tray_icon_list()
{
    GString* string = g_string_new("[");
    g_hash_table_foreach(icons, (GHFunc)tray_icon_to_info, string);
    if (string->len > 2) {
        g_string_overwrite(string, string->len-1, "]");
        return g_string_free(string, FALSE);
    } else {
        g_string_free(string, TRUE);
        return g_strdup("[]");
    }
}


static void 
draw_tray_icon(GdkWindow* icon, gint xy, cairo_t* cr)
{
    if (gdk_window_is_destroyed(icon)) {
        g_assert_not_reached();
    } else {
        gint x = xy >> 16;
        gint y = xy & 0xffff;
        gdk_cairo_set_source_window(cr, icon, x, y);
        cairo_paint(cr);
    }
}

gboolean draw_tray_icons(GtkWidget* w, cairo_t *cr, gpointer data)
{
    g_hash_table_foreach(icons, (GHFunc)draw_tray_icon, cr);
    return TRUE;
}