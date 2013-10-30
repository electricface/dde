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

connect_signals = ->
    DCore.signal_connect('workarea_changed', (alloc)->
        height = alloc.height
        document.body.style.maxHeight = "#{height}px"
        $('#grid').style.maxHeight = "#{height-60}px"
        # echo 'category column adaptive height'
        launcher?.container.category_column.adaptive_height()
    )


    DCore.signal_connect("lost_focus", (info)=>
        if launcher.dock.LauncherShouldExit_sync(info.xid)
            DCore.Launcher.exit_gui()
    )


    DCore.signal_connect("draw_background", (info)->
#     _b.style.backgroundImage = "url(#{info.path})"
    )


    DCore.signal_connect("update_items", ->
#     echo "update items"

#     return
#     applications = {}
#     hidden_icons = {}
#     category_infos = []
#     _category.innerHTML = ""
#     grid.innerHTML = ""

#     init_all_applications()
#     init_category_list()
#     init_grid()
#     _init_hidden_icons()
    )


    DCore.signal_connect("update_autostart", ->
        if (app = Widget.look_up(info.id))?
            if DCore.Launcher.is_autostart(app.core)
                # echo 'add'
                app.add_to_autostart()
            else
                # echo 'delete'
                app.remove_from_autostart()
    )

    DCore.signal_connect("exit_launcher", ->
        launcher.exit()
    )

###
reset = ->
    s_box.value = ""
    selected_category_id = ALL_APPLICATION_CATEGORY_ID
    # if s_box.value != ""
    #     sort_category_info(sort_methods[sort_method])
    update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
    grid_load_category(selected_category_id)
    save_hidden_apps()
    _show_hidden_icons(false)
    get_first_shown()?.scroll_to_view()
    if Item.hover_item_id
        event = new Event("mouseout")
        Widget.look_up(Item.hover_item_id).element.dispatchEvent(event)

exit_launcher = ->
    DCore.Launcher.exit_gui()

DCore.signal_connect("exit_launcher", ->
    reset()
)
###

