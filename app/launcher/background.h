/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
 * Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
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

#ifndef BACKGROUND_H
#define BACKGROUND_H

#include <gdk/gdk.h>
#include <gio/gio.h>

#define SCHEMA_ID "com.deepin.dde.background"
#define CURRENT_PCITURE "current-picture"

GSettings* get_background_gsettings();
void set_background(GdkWindow* win, GSettings* settings, double width, double height);
void background_changed(GSettings* settings, char* key, gpointer user_data);

#endif /* end of include guard: BACKGROUND_H */

