#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2012 snyh
#              2013 ~ 2013 Liqiang Lee
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
#             Liqiang Lee <liliqiang@linuxdeepin.com>
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


_b = document.body
is_show_hidden_icons = false

# inited = false
# DCore.signal_connect("draw_background", (info)->
#     _b.style.backgroundImage = "url(#{info.path})"
#     if inited
#         DCore.Launcher.clear()
#     inited = true
# )
# DCore.signal_connect("update_items", ->
#     echo "update items"
#
#     return
#     applications = {}
#     hidden_icons = {}
#     category_infos = []
#     _category.innerHTML = ""
#     grid.innerHTML = ""
#
#     init_all_applications()
#     init_category_list()
#     init_grid()
#     _init_hidden_icons()
# )


DCore.Launcher.notify_workarea_size()


_get_hidden_icons_ids = ->
    hidden_icons_ids = []
    for own id of hidden_icons
        hidden_icons_ids.push(id)
    return hidden_icons_ids


_contextmenu_callback = do ->
    _callback_func = null
    (icon_msg, sort_msg) ->
        f = (e) ->
            # remove the useless callback function to get better performance
            _b.removeEventListener('contextmenu', _callback_func)
            menu = [[1, sort_msg]]

            hidden_icons_ids = _get_hidden_icons_ids()
            if hidden_icons_ids.length
                menu.push([2, icon_msg])

            _b.contextMenu = build_menu(menu)
            _callback_func = f


_show_hidden_icons = (is_shown) ->
    if is_shown == is_show_hidden_icons
        return
    is_show_hidden_icons = is_shown

    Item.display_temp = false
    if is_shown
        for own item of hidden_icons
            if item in category_infos[selected_category_id]
                hidden_icons[item].display_icon_temp()
        msg = HIDE_HIDDEN_ICONS
    else
        for own item of hidden_icons
            hidden_icons[item].hide_icon()
        msg = DISPLAY_HIDDEN_ICONS

    _b.addEventListener("contextmenu", _contextmenu_callback(msg,
        SORT_MESSAGE[sort_method]))


init_all_applications = ->
    # get all applications and sort them by name
    _all_items = DCore.Launcher.get_items_by_category(ALL_APPLICATION_CATEGORY_ID)

    for core in _all_items
        id = DCore.DEntry.get_id(core)
        applications[id] = new Item(id, core)


_init_hidden_icons = do ->
    f = null
    ->
        hidden_icon_ids = DCore.Launcher.load_hidden_apps()
        if hidden_icon_ids?
            hidden_icon_ids.filter((elem, index, array) ->
                if not applications[elem]
                    array.splice(index, 1)
            )
            DCore.Launcher.save_hidden_apps(hidden_icon_ids)
            for id in hidden_icon_ids
                if applications[id]
                    hidden_icons[id] = applications[id]
                    hidden_icons[id].hide_icon()

        _b.removeEventListener("itemselected", f)
        _b.addEventListener("itemselected", (e) ->
            switch e.id
                when 1
                    if sort_method == "rate"
                        sort_method = "name"
                    else if sort_method == "name"
                        sort_method = "rate"

                    sort_category_info(sort_methods[sort_method])
                    # update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                    grid_load_category(selected_category_id)

                    DCore.Launcher.save_config('sort_method', sort_method)
                    _b.addEventListener("contextmenu",
                                        _contextmenu_callback(
                                            DISPLAY_HIDDEN_ICONS,
                                            SORT_MESSAGE[sort_method]))
                when 2
                    grid_load_category(selected_category_id)
                    _show_hidden_icons(not is_show_hidden_icons)
            f = this
        )

        _b.addEventListener("contextmenu",
                            _contextmenu_callback(DISPLAY_HIDDEN_ICONS,
                                                  SORT_MESSAGE[sort_method]))

        return


# init_search_box()
# init_all_applications()
# init_category_list()
# init_grid()
# _init_hidden_icons()
new Launcher().bind_events().connect_signals()
DCore.Launcher.webview_ok()

