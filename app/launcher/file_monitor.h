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

#ifndef FILE_MONITOR_H
#define FILE_MONITOR_H

#include <glib.h>
#include <gio/gdesktopappinfo.h>

void add_monitors();
void destroy_monitors();

enum DesktopStatus {
    UNKNOWN,
    DELETED,
    UPDATED
};


struct DesktopInfo {
    char* id;
    char* path;
    enum DesktopStatus status;
    GList* categories;
    GDesktopAppInfo* core;
};

#endif /* end of include guard: FILE_MONITOR_H */

