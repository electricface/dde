/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *              Liqiang Lee <liliqiang@linuxdeepin.com>
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

#include "main.h"
#include "na-tray-manager.h"
#include "X_misc.h"
#include "tray.h"
#include "tray_hide.h"
#include "tray_guard_window.h"
#include "region.h"
#include "utils.h"
#include "i18n.h"

#define CLAMP_WIDTH(w) (((w) < 16) ? 16 : (w))
#define DEFAULT_INTERVAL 4
#define PADDING ((PANEL_HEIGHT - DEFAULT_HEIGHT) / 2)
#define NA_BASE_Y PADDING


static GHashTable* _icons = NULL;
static gint _na_width = 0;
static gboolean _TRY_ICON_INIT = FALSE;

#define FCITX_TRAY_ICON "fcitx"
#ifdef SPECIAL_FCITX
static GdkWindow* _fcitx_tray = NULL;
static gint _fcitx_tray_width = 0;


void _update_fcitx_try_position();
#endif
void _update_notify_area_width();
gboolean draw_tray_icons(GtkWidget* w, cairo_t *cr);


int tray_width()
{
    return _na_width;
}


GdkWindow* get_icon_window(GdkWindow* wrapper)
{
    return g_object_get_data(G_OBJECT(wrapper), "wrapper_child") ? : wrapper;
}


GdkWindow* get_wrapper_window(GdkWindow* icon)
{
    return g_object_get_data(G_OBJECT(icon), "wrapper_parent") ? : icon;
}


GdkWindow* create_wrapper(GdkWindow* parent, Window tray_icon)
{
    gdk_flush();
    GdkWindow* icon = gdk_x11_window_foreign_new_for_display(gdk_display_get_default(), tray_icon);
    if (icon == NULL)
        return NULL;
    GdkVisual* visual = gdk_window_get_visual(icon);
    GdkWindow* wrapper = NULL;
    if (gdk_visual_get_depth(visual) == 24) {
        GdkWindowAttr attributes;
        attributes.width = DEFAULT_HEIGHT;
        attributes.height = DEFAULT_HEIGHT;
        attributes.window_type = GDK_WINDOW_CHILD;
        attributes.wclass = GDK_INPUT_OUTPUT;
        attributes.event_mask = GDK_ALL_EVENTS_MASK;
        attributes.visual = visual;
        wrapper = gdk_window_new(parent, &attributes, GDK_WA_VISUAL);
        //TODO: there should set color correspond by dock background color
        /*GdkColor color = {1, 0, 0, 1};*/
        /*gdk_window_set_background_rgba(wrapper, &color);*/

        XReparentWindow(gdk_x11_get_default_xdisplay(),
                tray_icon,
                GDK_WINDOW_XID(wrapper),
                0, 0);
        gdk_window_show(icon);
        g_object_set_data(G_OBJECT(wrapper), "wrapper_child", icon);
        g_object_set_data(G_OBJECT(icon), "wrapper_parent", wrapper);
    } else {
        wrapper = icon;
    }
    return wrapper;
}


void tray_icon_do_screen_size_change()
{
    if (_TRY_ICON_INIT) {
#ifdef SPECIAL_FCITX
        _update_fcitx_try_position();
#endif
        _update_notify_area_width();
    }
}


void safe_window_move_resize(GdkWindow* wrapper, int x, int y, int w, int h)
{
    XSelectInput(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(wrapper), ExposureMask | VisibilityChangeMask | EnterWindowMask | LeaveWindowMask);
    gdk_window_move_resize(wrapper, x, y, w, h);
    GdkWindow* icon = g_object_get_data(G_OBJECT(wrapper), "wrapper_child");
    if (icon) {
        gdk_window_resize(icon, w, h);
    }
    gdk_window_set_events(wrapper, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_VISIBILITY_NOTIFY_MASK);
}


void safe_window_move(GdkWindow* wrapper, int x, int y)
{
    XSelectInput(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(wrapper), ExposureMask | VisibilityChangeMask | EnterWindowMask | LeaveWindowMask);
    gdk_window_move(wrapper, x, y);
    gdk_window_set_events(wrapper, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_VISIBILITY_NOTIFY_MASK);
}


static int offset = 0;
void accumulate_na_width(GdkWindow* wrapper, gpointer width)
{
#ifdef SPECIAL_FCITX
    g_assert(wrapper != _fcitx_tray);
#endif
    int icon_width = gdk_window_get_width(wrapper);
    gdk_window_flush(wrapper);
    gint _na_base_x = gdk_screen_width()/2 - _na_width/2 + offset;
    if (icon_width != GPOINTER_TO_INT(width))
        safe_window_move_resize(wrapper, _na_base_x, NA_BASE_Y, GPOINTER_TO_INT(width), DEFAULT_HEIGHT);
    else {
        safe_window_move(wrapper, _na_base_x, NA_BASE_Y);
    }
    offset += icon_width + PADDING;
}


void _update_notify_area_width()
{
    _na_width = g_hash_table_size(_icons) * (PADDING + DEFAULT_WIDTH) + PADDING;
    offset = PADDING;
    g_hash_table_foreach(_icons, (GHFunc)accumulate_na_width, NULL);
    update_tray_guard_window_position(_na_width);
    update_tray_region(_na_width);
    gdk_window_invalidate_rect(TRAY_GDK_WINDOW(), NULL, FALSE);
}


#ifdef SPECIAL_FCITX
void _update_fcitx_try_position()
{
    if (_fcitx_tray) {
        safe_window_move_resize(_fcitx_tray,
                gdk_screen_width() - _fcitx_tray_width - 2 * DEFAULT_INTERVAL,
                NA_BASE_Y,
                _fcitx_tray_width, DEFAULT_HEIGHT);
        _update_notify_area_width();
    }
}
#endif


GdkFilterReturn
monitor_icon_event(GdkXEvent* xevent, GdkEvent* event, GdkWindow* wrapper);
void destroy_wrapper(GdkWindow* wrapper)
{
    GdkWindow* icon = get_icon_window(wrapper);
    gdk_window_remove_filter(icon, (GdkFilterFunc)monitor_icon_event, wrapper);
    if (icon != wrapper) {
        gdk_window_destroy(wrapper); //this will decrements wrapper's reference count, don't repeat call g_object_unref
        g_object_unref(icon);
    } else {
        g_object_unref(icon);
    }
}


GdkFilterReturn
monitor_icon_event(GdkXEvent* xevent, GdkEvent* event, GdkWindow* wrapper)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
#ifdef SPECIAL_FCITX
        if (_fcitx_tray == wrapper) {
            destroy_wrapper(_fcitx_tray);
            _fcitx_tray = NULL;
            _fcitx_tray_width = 0;
        } else {
#endif
            g_hash_table_remove(_icons, wrapper);
            destroy_wrapper(wrapper);
#ifdef SPECIAL_FCITX
        }
#endif

        _update_notify_area_width();
        return GDK_FILTER_CONTINUE;
    } else if (xev->type == ConfigureNotify) {
        XConfigureEvent* xev = (XConfigureEvent*)xevent;
        int new_width = ((XConfigureEvent*)xev)->width;
#ifdef SPECIAL_FCITX
        if (wrapper == _fcitx_tray) {
            _fcitx_tray_width = CLAMP_WIDTH(new_width);
            _update_fcitx_try_position();
        } else if (wrapper != _fcitx_tray) {
#endif
            int new_height = ((XConfigureEvent*)xev)->height;
            g_hash_table_insert(_icons, wrapper, GINT_TO_POINTER(CLAMP_WIDTH((new_width * 1.0 / new_height * DEFAULT_HEIGHT))));
            _update_notify_area_width();
#ifdef SPECIAL_FCITX
        }
#endif

        return GDK_FILTER_REMOVE;
    } else if (xev->type == PropertyNotify) {
        tray_delay_hide(2000/*ms*/);
    }

    return GDK_FILTER_CONTINUE;
}


void tray_icon_added (NaTrayManager *manager, Window child, GtkWidget* container)
{
    GdkWindow* wrapper = create_wrapper(gtk_widget_get_window(container), child);
    if (wrapper == NULL)
        return;
    GdkWindow* icon = get_icon_window(wrapper);
    g_assert(icon != NULL);

    gdk_window_reparent(wrapper, gtk_widget_get_window(container), _na_width, 0);
    //add this mask so, gdk can handle GDK_SELECTION_CLEAR event to destroy this gdkwindow.
    gdk_window_set_events(icon, GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_VISIBILITY_NOTIFY_MASK);
    gdk_window_add_filter(icon, (GdkFilterFunc)monitor_icon_event, wrapper);
    gdk_window_set_composited(wrapper, TRUE);

    gdk_window_show(wrapper);

    char *re_class = NULL;
    get_wmclass(icon, &re_class, NULL);
#ifdef SPECIAL_FCITX
    if (g_strcmp0(re_class, FCITX_TRAY_ICON) == 0) {
        _fcitx_tray = wrapper;
        _fcitx_tray_width = CLAMP_WIDTH(gdk_window_get_width(icon));
        _update_fcitx_try_position();
    } else {
#endif
        int width = gdk_window_get_width(icon) * 1.0 / gdk_window_get_height(icon) * DEFAULT_HEIGHT;
        gdk_window_resize(icon, width, DEFAULT_HEIGHT);
        g_hash_table_insert(_icons, wrapper, GINT_TO_POINTER(CLAMP_WIDTH(width)));
#ifdef SPECIAL_FCITX
    }
#endif
    g_free(re_class);
    _update_notify_area_width();
}


void tray_init(GtkWidget* container)
{
    _icons = g_hash_table_new(g_direct_hash, g_direct_equal);
    GdkScreen* screen = gdk_screen_get_default();
    NaTrayManager* tray_manager = NULL;
    if (na_tray_manager_check_running(screen)) {
        g_warning(_("another systray is already running..."));
        exit(1);
    }
    tray_manager = na_tray_manager_new();
    /* g_spawn_command_line_async("xev -name dapptray", NULL); */
    //TODO: update _na_base_y
    na_tray_manager_manage_screen(tray_manager, screen);

    g_signal_connect(tray_manager, "tray_icon_added", G_CALLBACK(tray_icon_added), container);
    g_signal_connect_after(container, "draw", G_CALLBACK(draw_tray_icons), NULL);
    _TRY_ICON_INIT = TRUE;

    init_region(TRAY_GDK_WINDOW(), 0, 0, 0, PANEL_HEIGHT);
    init_tray_guard_window();
    update_tray_guard_window_position(0);
}


void
draw_tray_icon(GdkWindow* wrapper, gpointer no_use, cairo_t* cr)
{
    GdkWindow* icon = get_icon_window(wrapper);
    g_assert(GDK_IS_WINDOW(wrapper));
    if (!gdk_window_is_destroyed(icon)) {
        int x = 0;
        int y = 0;
        gdk_window_get_geometry(wrapper, &x, &y, NULL, NULL); //gdk_window_get_position will get error value when dock is hidden!
        cairo_save(cr);
        gdk_cairo_set_source_window(cr, icon, x, y);
        cairo_paint(cr);
        cairo_restore(cr);
    }
}


void cairo_image_surface_blur(cairo_surface_t* surface, double radius)
{
    // Steve Hanov, 2009
    // Released into the public domain.

    // get width, height
    int width = cairo_image_surface_get_width(surface);
    int height = cairo_image_surface_get_height(surface);
    unsigned char* dst = (unsigned char*)malloc(width*height*4);
    unsigned* precalc =
        (unsigned*)malloc(width*height*sizeof(unsigned));
    unsigned char* src = cairo_image_surface_get_data(surface);
    double mul = 1.f / ((radius*2)*(radius*2));

    // The number of times to perform the averaging. According to wikipedia,
    // three iterations is good enough to pass for a gaussian.
    const int MAX_ITERATIONS = 3;

    memcpy(dst, src, width*height*4);

    int iteration;
    int channel;
    for (iteration = 0; iteration < MAX_ITERATIONS; iteration++) {
        for(channel = 0; channel < 4; channel++) {
            int x,y;

            // precomputation step.
            unsigned char* pix = src;
            unsigned* pre = precalc;

            pix += channel;
            for (y = 0; y < height; y++) {
                for (x = 0; x < width; x++) {
                    int tot = pix[0];
                    if (x>0) tot += pre[-1];
                    if (y>0) tot += pre[-width];
                    if (x>0 && y>0) tot -= pre[-width-1];
                    *pre++ = tot;
                    pix += 4;
                }
            }

            // blur step.
            pix = dst + (int)radius * width * 4 + (int)radius * 4 + channel;
            for (y = radius; y < height - radius; y++) {
                for (x = radius; x < width - radius; x++) {
                    int l = x < radius ? 0 : x - radius;
                    int t = y < radius ? 0 : y - radius;
                    int r = x + radius >= width ? width - 1 : x + radius;
                    int b = y + radius >= height ? height - 1 : y + radius;
                    int tot = precalc[r+b*width] + precalc[l+t*width] -
                        precalc[l+b*width] - precalc[r+t*width];
                    *pix = (unsigned char)(tot*mul);
                    pix += 4;
                }
                pix += (int)radius * 2 * 4;
            }
        }
        memcpy(src, dst, width*height*4);
    }

    free(dst);
    free(precalc);
}


void _draw_background(cairo_t* cr)
{
    // draw shadow
    int shadow_width = _na_width + SHADOW_WIDTH * 2;
    cairo_surface_t* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32, gdk_screen_width(), TRAY_HEIGHT);
    cairo_t* ctx = cairo_create(surface);
    cairo_translate(ctx, (gdk_screen_width() - shadow_width) / 2, 0);

    // outter
    draw_tray_panel(ctx, shadow_width, TRAY_HEIGHT);
    cairo_set_source_rgba(ctx, 1, 1, 1, 0);
    cairo_fill(ctx);

    // inner
    cairo_translate(ctx, SHADOW_WIDTH, 0);
    draw_tray_panel(ctx, _na_width, PANEL_HEIGHT + 3);
    cairo_set_source_rgba(ctx, 0, 0, 0, .5);
    cairo_fill(ctx);

    /* cairo_surface_write_to_png(surface, "/tmp/bg.png"); */
    cairo_image_surface_blur(surface, 2.);
    /* cairo_surface_write_to_png(surface, "/tmp/blur_bg.png"); */
    cairo_destroy(ctx);

    cairo_save(cr);
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
    cairo_set_source_surface(cr, surface, 2, -1);
    cairo_surface_destroy(surface);
    cairo_paint(cr);

    // draw main panel
    cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
    cairo_translate(cr, (gdk_screen_width() - _na_width)/2, 0);
    cairo_set_source_rgba(cr, 0, 0, 0, 0.5);
    draw_tray_panel(cr, _na_width, PANEL_HEIGHT);
    cairo_fill(cr);

    /* cairo_paint(cr); */
    cairo_restore(cr);
}


gboolean draw_tray_icons(GtkWidget* w, cairo_t *cr)
{
    if (_na_width < DEFAULT_WIDTH) {
        cairo_save(cr);
        cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
        cairo_paint(cr);
        cairo_set_operator(cr, CAIRO_OPERATOR_OVER);
        cairo_restore(cr);
        return FALSE;
    }

    _draw_background(cr);

    if (_icons != NULL) {
        g_hash_table_foreach(_icons, (GHFunc)draw_tray_icon, cr);
#ifdef SPECIAL_FCITX
        if (_fcitx_tray)
            draw_tray_icon(_fcitx_tray, NULL, cr);
#endif
    }
    return TRUE;
}

