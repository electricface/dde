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

class HiddenIconList
    constructor: (@parent)->
        @apps = @parent.apps
        @hidden_icons = {}
        @length = 0

        hidden_icon_ids = DCore.Launcher.load_hidden_apps()
        if hidden_icon_ids?
            hidden_icon_ids.filter((elem, index, array) =>
                if not @apps[elem]
                    array.splice(index, 1)
            )
            DCore.Launcher.save_hidden_apps(hidden_icon_ids)
            for id in hidden_icon_ids
                if @apps[id]
                    @add(@apps[id]).hide_icon()

    length: ->
        @length

    add: (item)->
        @hidden_icons[item.id] = item
        @length += 1
        item

    remove: (item)->
        delete hidden_icons[item.id]
        @length -= 1
        item

    save: ->
        hidden_icons_ids = []
        for own id of hidden_icons
            hidden_icons_ids.push(id)
        DCore.Launcher.save_hidden_apps(hidden_icons_ids)

    show: (items)->
        for own item of @hidden_icons
            if item in items
                @hidden_icons[item].display_icon_temp()

    hide: ->
        for own item of hidden_icons
            hidden_icons[item].hide_icon()
