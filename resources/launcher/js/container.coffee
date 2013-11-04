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


# key: id of app (md5 basenam of path)
# value: Item class
all_apps = {}

class Container
    constructor: (@parent)->
        # echo 'init container'
        all_items = DCore.Launcher.get_items_by_category(ALL_APPLICATION_CATEGORY_ID)
        for core in all_items
            id = DCore.DEntry.get_id(core)
            all_apps[id] = new Item(id, core, @)

        category_column.load()

        grid.hidden_icons.load()
        grid.init_grid()
        grid.hidden_icons.hide()

        body.addEventListener("contextmenu", Container.contextmenu_callback(@))
        body.addEventListener("itemselected", (e)=>
            switch e.id
                when 1
                    if config.sort_method_name == "name"
                        config.sort_method_name = "rate"
                    else
                        config.sort_method_name = "name"
                    config.save()
                    category_column.sort_items(config.sort_method())
                    grid.render_dom(category_column.category_items(ALL_APPLICATION_CATEGORY_ID))
                    grid.load_category(category_column.selected_category_id)
                when 2
                    grid.load_category(category_column.selected_category_id)
                    grid.toggle_hidden_icons()

            body.addEventListener("contextmenu", Container.contextmenu_callback(@))
        )

    reset: ->
        category_column.reset()
        grid.reset()

    _menu: ->
        menu = [[1, SORT_MESSAGE[config.sort_method_name]]]

        if grid.hidden_icons.length() > 0
            menu.push([2, HIDDEN_ICON_MESSAGE[grid.show_hidden_icons]])

        menu

    @contextmenu_callback: do ->
        func_handle = null
        (item)->
            body.removeEventListener('contextmenu', func_handle)
            func_handle = (e) ->
                body.contextMenu = build_menu(item._menu())

