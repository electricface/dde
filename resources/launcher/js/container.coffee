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

compare_string = (s1, s2) ->
    return 1 if s1 > s2
    return 0 if s1 == s2
    return -1


get_name_by_id = (id) ->
    if Widget.look_up(id)?
        DCore.DEntry.get_name(Widget.look_up(id).core)
    else
        ""


sort_by_name = (items)->
    items.sort((lhs, rhs)->
        lhs_name = get_name_by_id(lhs)
        rhs_name = get_name_by_id(rhs)
        compare_string(lhs_name, rhs_name)
    )


sort_by_rate = do ->
    rates = null
    items_name_map = {}

    (items, update)->
        if update
            rates = DCore.Launcher.get_app_rate()

            items_name_map = {}
            for id in category_infos[ALL_APPLICATION_CATEGORY_ID]
                if not items_name_map[id]?
                    items_name_map[id] =
                        DCore.DEntry.get_appid(Widget.look_up(id).core)

        items.sort((lhs, rhs)->
            lhs_appid = items_name_map[lhs]
            lhs_rate = rates[lhs_appid] if lhs_appid?

            rhs_appid = items_name_map[rhs]
            rhs_rate = rates[rhs_appid] if rhs_appid?

            if lhs_rate? and rhs_rate?
                rates_delta = rhs_rate - lhs_rate
                if rates_delta == 0
                    return compare_string(get_name_by_id(lhs), get_name_by_id(rhs))
                else
                    return rates_delta
            else if lhs_rate? and not rhs_rate?
                return -1
            else if not lhs_rate? and rhs_rates?
                return 1
            else
                return compare_string(get_name_by_id(lhs), get_name_by_id(rhs))
        )


class Config
    constructor: ->
        @read()
        @methods =
            "name": sort_by_name
            "rate": sort_by_rate

    sort_method: ->
        @methods[@sort_method_name]

    read: ->
        @sort_method_name = "name"
        if (method_name = DCore.Launcher.sort_method())?
            @sort_method_name = method_name
        else
            save()

    save: ->
        DCore.Launcher.save_config('sort_method', @sort_method_name)


class Container
    constructor: (@parent)->
        # echo 'init container'
        @search_bar = @parent.search_bar

        @config = new Config(@)
        @dock = @parent.dock
        @body = @parent.body

        all_items = DCore.Launcher.get_items_by_category(ALL_APPLICATION_CATEGORY_ID)

        # key: id of app (md5 basenam of path)
        # value: Item class
        @apps = []
        @grid = new Grid(@)
        @category_column = new CategoryColumn(@)

        for core in all_items
            id = DCore.DEntry.get_id(core)
            @apps[id] = new Item(id, core, @)

        @category_column.load()

        @grid.render(@category_column.category_infos[ALL_APPLICATION_CATEGORY_ID])
        @grid.load_category(ALL_APPLICATION_CATEGORY_ID)
        @grid.hidden_icons.load()
        @grid.hidden_icons.hide()

        @body.addEventListener("contextmenu", Container.contextmenu_callback(@))
        @body.addEventListener("itemselected", (e)=>
            switch e.id
                when 1
                    if @config.sort_method_name == "name"
                        @config.sort_method_name = "rate"
                    else
                        @config.sort_method_name = "name"
                    @config.save()

                when 2
                    @grid.load_category(@category_column.selected_category_id)
                    @grid.toggle_hidden_icons()

            @body.addEventListener("contextmenu", Container.contextmenu_callback(@))
        )

    reset: ->
        @grid.reset()
        @category_column.reset()

    _menu: ->
        menu = [
            [1, SORT_MESSAGE[@config.sort_method_name]],
            [2, HIDDEN_ICON_MESSAGE[@grid.show_hidden_icons]]
        ]

    @contextmenu_callback: do ->
        func_handle = null
        (item)->
            item.body.removeEventListener('contextmenu', func_handle)
            func_handle = (e) ->
                item.body.contextMenu = build_menu(item._menu())

