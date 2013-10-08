#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 liliqiang
#
#Author:      liliqiang <liliqiang@linuxdeepin.com>
#Maintainer:  liliqiang <liliqiang@liunxdeepin.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

class Launcher
    constructor: ->
        echo 'init launcher'
        try
            @s_dock = DCore.DBus.session("com.deepin.dde.dock")
        catch error
            @s_dock = null

        @search_bar = new SearchBar(@)
        @container = new Container(@)

    exit: ->
        @search_bar.clean()
        @container.reset()
        DCore.Launcher.exit_gui()

    bind_events: ->
        @

    connect_signal: ->
        @
