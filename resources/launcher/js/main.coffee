#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
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

# key: id of app (md5 basenam of path)
# value: Item class
applications = {}

# key: id of app
# value: a list of category id to which key belongs
hidden_icons = {}

# key: id of app
# value: Item class
uninstalling_apps = {}


DCore.signal_connect('workarea_changed', (alloc)->
    height = alloc.height
    _b.style.maxHeight = "#{height}px"
    $('#grid').style.maxHeight = "#{height-60}px"
    category_column_adaptive_height()

    hidden_icon_ids = _get_hidden_icons_ids()
    count = 0
    for i in category_infos[ALL_APPLICATION_CATEGORY_ID]
        if i not in hidden_icon_ids
            count += 1
    _update_scroll_bar(count)
)
DCore.signal_connect("lost_focus", (info)->
    if s_dock.LauncherShouldExit_sync(info.xid)
        exit_launcher()
)
DCore.signal_connect("exit_launcher", ->
    reset()
)
DCore.signal_connect("draw_background", (info)->
    img = new Image()
    img.src = info.path
    img.onload = ->
        _b.style.backgroundImage = "url(#{img.src})"
)
DCore.signal_connect("update_items", (info)->
    # echo "update items:"
    # echo "status: #{info.status}"
    # echo "id: #{info.id}"
    # echo "core: #{info.core}"
    # echo "categories: #{info.categories}"

    if info.status.match(/^deleted$/i)
        if uninstalling_apps[info.id]
            delete uninstalling_apps[info.id]

        if (item = Widget.look_up(info.id))?
            echo 'deleted'
            for category_index in info.categories
                category_infos["#{category_index}"].remove(info.id)
            item.status = SOFTWARE_STATE.UNINSTALLING
            item.hide()
            item.destroy()
            delete applications[info.id]
    else if info.status.match(/^updated$/i)
        if not Widget.look_up(info.id)?
            echo 'added'
            # info.status = "added"
            applications[info.id] = new Item(info.id, info.core)
            for category_index in info.categories
                category_infos["#{category_index}"].push(info.id)
            # TODO: may sort category_info which is changed.
            sort_category_info(sort_methods[sort_method])
            grid.appendChild(applications[info.id].element)
        else
            echo 'updated'
            applications[info.id].update(info.core)

    # FIXME:
    # load what should be shown, not forbidden reloading on searching.
    if s_box.value == ""
        update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
        grid_load_category(selected_category_id)
    else
        search()
)
DCore.signal_connect("uninstall_failed", (info)->
    if (item = uninstalling_apps[info.id])?
        echo "#{info.id} uninstall failed"
        item.status = SOFTWARE_STATE.IDLE
        item.show()
    delete uninstalling_apps[info.id]
)
DCore.signal_connect("autostart_update", (info)->
    if (app = Widget.look_up(info.id))?
        if DCore.Launcher.is_autostart(app.core)
            # echo 'add'
            app.add_to_autostart()
        else
            # echo 'delete'
            app.remove_from_autostart()
)
DCore.Launcher.notify_workarea_size()


get_name_by_id = (id) ->
    if Widget.look_up(id)?
        DCore.DEntry.get_name(Widget.look_up(id).core)
    else
        ""


compare_string = (s1, s2) ->
    return 1 if s1 > s2
    return 0 if s1 == s2
    return -1


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


sort_methods =
    "name": sort_by_name
    "rate": sort_by_rate


reset = ->
    selected_category_id = ALL_APPLICATION_CATEGORY_ID
    clean_search_bar()
    s_box.focus()
    save_hidden_apps()
    _show_hidden_icons(false)
    get_first_shown()?.scroll_to_view()
    if Item.hover_item_id
        event = new Event("mouseout")
        Widget.look_up(Item.hover_item_id).element.dispatchEvent(event)

exit_launcher = ->
    DCore.Launcher.exit_gui()


_get_hidden_icons_ids = ->
    hidden_icons_ids = []
    for own id of hidden_icons
        hidden_icons_ids.push(id)
    return hidden_icons_ids


save_hidden_apps = ->
    DCore.Launcher.save_hidden_apps(_get_hidden_icons_ids())


is_show_hidden_icons = false
_show_hidden_icons = (is_shown) ->
    if is_shown == is_show_hidden_icons
        return
    is_show_hidden_icons = is_shown

    Item.display_temp = false
    if is_shown
        for own item of hidden_icons
            if item in category_infos[selected_category_id]
                hidden_icons[item].display_icon_temp()
    else
        for own item of hidden_icons
            hidden_icons[item].hide_icon()


bind_events = ->
    _b.addEventListener("contextmenu", (e)->
        e.preventDefault()
        menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, SORT_MESSAGE[sort_method])
        )
        hidden_icons_ids = _get_hidden_icons_ids()
        if hidden_icons_ids.length
            menu.append(new MenuItem(2, HIDDEN_ICONS_MESSAGE[is_show_hidden_icons]))

        DCore.Launcher.force_show(true)
        menu.dbus.connect("MenuUnregistered", -> DCore.Launcher.force_show(false))
        menu.addListener((id) ->
            id = parseInt(id)
            switch id
                when 1
                    if sort_method == "rate"
                        sort_method = "name"
                    else if sort_method == "name"
                        sort_method = "rate"

                    sort_category_info(sort_methods[sort_method])
                    update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                    grid_load_category(selected_category_id)

                    DCore.Launcher.save_config('sort_method', sort_method)
                when 2
                    grid_load_category(selected_category_id)
                    _show_hidden_icons(not is_show_hidden_icons)
            DCore.Launcher.force_show(false)
        ).showMenu(e.clientX, e.clientY)
    )

    _b.addEventListener("click", (e)->
        e.stopPropagation()
        if e.target != $("#category")
            exit_launcher()
    )


    _b.addEventListener('keypress', (e) ->
        e.preventDefault()
        e.stopPropagation()
        if e.which != ESC_KEY and e.which != BACKSPACE_KEY and e.which != ENTER_KEY and e.whicn != SPACE_KEY
            s_box.value += String.fromCharCode(e.which)
    )


# this does not work on keypress
    _b.addEventListener("keydown", (e) ->
        e.stopPropagation()
        if e.ctrlKey and e.shiftKey and e.which == TAB_KEY
            e.preventDefault()
            selected_up()
        else if e.ctrlKey
            e.preventDefault()
            switch e.which
                when P_KEY
                    selected_up()
                when F_KEY
                    selected_next()
                when B_KEY
                    selected_prev()
                when N_KEY, TAB_KEY
                    selected_down()
                when ENTER_KEY, SPACE_KEY
                    s_box.focus()
        else if String.fromCharCode(e.which).match(/\w/) or e.which == BACKSPACE_KEY
            s_box.focus()
        else
            switch e.which
                when ESC_KEY
                    e.preventDefault()
                    e.stopPropagation()
                    if s_box.value == ""
                        exit_launcher()
                    else
                        s_box.focus()
                        clean_search_bar()
                when ENTER_KEY
                    e.preventDefault()
                    if item_selected
                        item_selected.do_click()
                    else
                        get_first_shown()?.do_click()
                when UP_ARROW
                    e.preventDefault()
                    selected_up()
                when DOWN_ARROW
                    e.preventDefault()
                    selected_down()
                when LEFT_ARROW
                    e.preventDefault()
                    selected_prev()
                when RIGHT_ARROW
                    e.preventDefault()
                    selected_next()
                when TAB_KEY
                    e.preventDefault()
                    if e.shiftKey
                        selected_prev()
                    else
                        selected_next()
    )


init_all_applications = ->
    # get all applications and sort them by name
    _all_items = DCore.Launcher.get_items_by_category(ALL_APPLICATION_CATEGORY_ID)

    for core in _all_items
        id = DCore.DEntry.get_id(core)
        applications[id] = new Item(id, core)


_init_hidden_icons = ->
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


init_search_box()
init_all_applications()
init_category_list()
init_grid()
_init_hidden_icons()
bind_events()
DCore.Launcher.webview_ok()
DCore.Launcher.test()

