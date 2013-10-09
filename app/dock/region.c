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
#include "region.h"
#include "dwebview.h"

cairo_region_t* _region = NULL;
GdkWindow* _win = NULL;
cairo_rectangle_int_t _base_rect;


void init_region(GdkWindow* win, double x, double y, double width, double height)
{
    if (_win == NULL) {
        _win = win;
        _region = cairo_region_create();
        _base_rect.x = x;
        _base_rect.y = y;
        _base_rect.width = width;
        _base_rect.height = height;
        dock_require_region(0, 0, width, height);
    } else {
        _win = NULL;
        cairo_region_destroy(_region);
        init_region(win, x, y, width, height);
    }
}


PRIVATE
gboolean _help_do_window_region(cairo_region_t* region)
{
    gdk_window_input_shape_combine_region(_win, region, 0, 0);
    return FALSE;
}


PRIVATE
void do_window_shape_combine_region(cairo_region_t* region)
{
    static int _id = -1;
    if (_id != -1)
        g_source_remove(_id);
    _id = g_timeout_add(100, (GSourceFunc)_help_do_window_region, region);
}


JS_EXPORT_API
void dock_require_all_region()
{
    do_window_shape_combine_region(NULL);
}


void dock_force_set_region(double x, double y, double width, double height)
{
    cairo_region_destroy(_region);
    cairo_rectangle_int_t tmp = {(int)x + _base_rect.x, (int)y + _base_rect.y, (int)width, (int)height};

    cairo_rectangle_int_t dock_board_rect = _base_rect;
    dock_board_rect.x = 0;
    dock_board_rect.y = gdk_screen_height() - 30;
    dock_board_rect.height = 30;
    dock_board_rect.width = gdk_screen_width();
    _region = cairo_region_create_rectangle(&dock_board_rect);

    cairo_region_union_rectangle(_region, &tmp);
    do_window_shape_combine_region(_region);
}


void dock_require_region(double x, double y, double width, double height)
{
    cairo_rectangle_int_t tmp = {(int)x + _base_rect.x, (int)y + _base_rect.y, (int)width, (int)height};
    cairo_region_union_rectangle(_region, &tmp);
    do_window_shape_combine_region(_region);
}


void dock_release_region(double x, double y, double width, double height)
{
    cairo_rectangle_int_t tmp = {(int)x + _base_rect.x, (int)y + _base_rect.y, (int)width, (int)height};
    cairo_region_subtract_rectangle(_region, &tmp);
    do_window_shape_combine_region(_region);
}


void dock_set_region_origin(double x, double y)
{
    _base_rect.x = x;
    _base_rect.y = y;
}


gboolean dock_region_overlay(const cairo_rectangle_int_t* tmp)
{
    cairo_region_t* region = cairo_region_copy(_region);
    cairo_region_intersect_rectangle(region, &_base_rect);
    gboolean r = (cairo_region_contains_rectangle(region, tmp) != CAIRO_REGION_OVERLAP_OUT);
    cairo_region_destroy(region);
    return r;
}


void region_rectangles()
{
    int num = cairo_region_num_rectangles(_region);

    for (int i = 0; i < num; ++i) {
        cairo_rectangle_int_t tmp;
        cairo_region_get_rectangle(_region, i, &tmp);
        g_debug("coordiantes: %dx%d, width: %d, height: %d", tmp.x, tmp.y, tmp.width, tmp.height);
    }
}

