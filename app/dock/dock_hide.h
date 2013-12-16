/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
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
#ifndef __DOCK_HIDE_H__
#define __DOCK_HIDE_H__

#include <glib.h>
void dock_delay_show(int delay);
void dock_delay_hide(int delay);
void dock_show_now();
void dock_hide_now();
void dock_hide_real_now();
void dock_show_real_now();

void dock_toggle_show();
void dock_update_hide_mode();

void update_dock_guard_window_position(double width);

void init_dock_guard_window();
gboolean is_mouse_in_dock();
#endif
