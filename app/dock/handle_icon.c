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
#include <gtk/gtk.h>
#include <string.h>
#include "dominant_color.h"
#include "xid2aid.h"
#include "handle_icon.h"
#include "xdg_misc.h"
#include "utils.h"
#include "launcher.h"
#include <gio/gdesktopappinfo.h>

#define BOARD_PATH RESOURCE_DIR"/dock/img/board.png"
#define BOARD_MASK_PATH RESOURCE_DIR"/dock/img/mask.png"

cairo_surface_t* _board = NULL;
cairo_surface_t* _board_mask = NULL;

char* handle_icon(GdkPixbuf* icon, gboolean use_board)
{
    int left_offset = 0;
    int top_offset = 0;

    if (_board== NULL) {
        _board = cairo_image_surface_create_from_png(BOARD_PATH);
        _board_mask = cairo_image_surface_create_from_png(BOARD_MASK_PATH);
    }
    g_assert(_board_mask != NULL);

    cairo_surface_t* surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                          BOARD_WIDTH,
                                                          BOARD_HEIGHT);
    cairo_t* cr  = cairo_create(surface);

    if (use_board) {
        double r, g, b;
        calc_dominant_color_by_pixbuf(icon, &r, &g, &b);
        cairo_set_source_rgb(cr, r, g, b);
        cairo_mask_surface(cr, _board_mask, 0, BOARD_OFFSET);
        /*cairo_paint(cr);*/

        left_offset = (IMG_WIDTH - gdk_pixbuf_get_width(icon)) / 2;
        top_offset = (IMG_HEIGHT - gdk_pixbuf_get_height(icon)) / 2;

        gdk_cairo_set_source_pixbuf(cr, icon, MARGIN_LEFT + left_offset,
                                    MARGIN_TOP-1 + top_offset);
    } else {
        gdk_cairo_set_source_pixbuf(cr, icon, left_offset, top_offset);
    }

    cairo_paint(cr);

    if (use_board) {
        cairo_set_source_surface(cr, _board, 0, BOARD_OFFSET);
        cairo_paint(cr);
    }

    char* data = get_data_uri_by_surface(surface);

    cairo_surface_destroy(surface);
    cairo_destroy(cr);
    return data;
}


guchar* __data_base64 = NULL;
size_t __data_size = 0;
cairo_status_t write_func(void* store, unsigned char* data, unsigned int length)
{
    __data_size = length + __data_size;
    __data_base64 = g_renew(guchar, __data_base64, __data_size);
    memmove((void*)(__data_base64 + __data_size - length), (void*)data, (size_t)length);
    return CAIRO_STATUS_SUCCESS;
}


char* get_data_uri_by_surface(cairo_surface_t* surface)
{
    __data_base64 = NULL;
    __data_size = 0;
    cairo_surface_write_to_png_stream(surface, (cairo_write_func_t)write_func, NULL);
    gchar* base64 = g_base64_encode(__data_base64, __data_size);
    g_free(__data_base64);

    char* ret = g_strconcat("data:image/png;base64,", base64, NULL);
    g_free(base64);

    return ret;
}


void try_get_deepin_icon(const char* _app_id, char** icon, int* operator_code)
{
    char* app_id = g_strdup(_app_id);
    to_lower_inplace(app_id);
    if (is_deepin_app_id(app_id)) {
        g_debug("[try_get_deepin_icon] \"%s\" is deepin app id", app_id);
        *operator_code = get_deepin_app_id_operator(app_id);
        const char* operator_names[] = {
            "USE_ICONNAME",
            "USE_RUNTIME_WITH_BOARD",
            "USE_RUNTIME_WITHOUT_BOARD",
            "USE_PATH",
            "USE_DOMINANTCOLOR"
        };
        g_debug("[try_get_deepin_icon] operator code is %s", operator_names[*operator_code]);
        switch (*operator_code) {
            case ICON_OPERATOR_USE_ICONNAME:
                {
                    char* icon_name =  get_deepin_app_id_value(app_id);
                    char* icon_path = icon_name_to_path(icon_name, 48);
                    g_free(icon_name);
                    g_free(app_id);
                    *icon = icon_path;
                    break;
                }
            case ICON_OPERATOR_USE_RUNTIME_WITH_BOARD:
                g_free(app_id);
                *icon = NULL;
                break;
            case ICON_OPERATOR_USE_RUNTIME_WITHOUT_BOARD:
                g_free(app_id);
                *icon = NULL;
                break;
            case ICON_OPERATOR_USE_PATH:
                g_free(app_id);
                g_warning("[try_get_deepin_icon] Hasn't support set path Icon Handler\n");
                break;
            case ICON_OPERATOR_SET_DOMINANTCOLOR:
                g_free(app_id);
                g_warning("[try_get_deepin_icon] Hasn't support set dominantcolor Icon Handler\n");
                break;
            default:
                g_warning("[try_get_deepin_icon] Hasn't support unknow Icon Handler\n");

        }
    } else {
        g_debug("[try_get_deepin_icon] \"%s\" is not deepin app id", app_id);
        g_free(app_id);
    }
}

