#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2013 ~ 2013 Liqiang Lee
#
#Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
#Maintainer:  Liqiang Lee <liliqiang@liunxdeepin.com>
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
        # echo 'init hidden icon list'
        @grid = @parent

        # key: the id of each instance of Item class
        # value: Item class instance
        @hidden_icons = {}
        @length = 0

    load: ->
        hidden_icon_ids = DCore.Launcher.load_hidden_apps()
        if not hidden_icon_ids?
            return

        hidden_icon_ids.filter((elem, index, array) =>
            if not all_apps[elem]
                array.splice(index, 1)
        )
        DCore.Launcher.save_hidden_apps(hidden_icon_ids)
        for id in hidden_icon_ids
            if all_apps[id]
                @add(all_apps[id])

    add: (item)->
        if item
            @hidden_icons[item.id] = item
            @length += 1
            @save()
        item

    remove: (item)->
        if item and delete @hidden_icons[item.id]
            @length -= 1
            @save()
        item

    save: ->
        hidden_icons_ids = Object.keys(@hidden_icons)
        # echo "#{hidden_icons_ids}"
        DCore.Launcher.save_hidden_apps(hidden_icons_ids)

    show: (items)->
        for own item of @hidden_icons
            if item in items
                @hidden_icons[item].display_icon_temp()

        category_column.show_nonempty_category()
        len = category_column.selected_category_items().length
        grid.update_scroll_bar(len)
        return

    hide: ->
        for own item of @hidden_icons
            @hidden_icons[item].hide_icon()

        category_column.hide_empty_category()
        len = category_column.selected_category_items().length
        grid.update_scroll_bar(len)
        return

    hidden_icons_of_category: (cat_id)->
        ids = category_column.category_items(cat_id)
        Object.keys(@hidden_icons).filter((id) ->
            id in ids
        )
