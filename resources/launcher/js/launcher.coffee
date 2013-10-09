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

class Launcher
    constructor: ->
        echo 'init launcher'
        @body = document.body
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
        @body.addEventListener("click", (e)=>
            e.stopPropagation()
            if e.target != $("#category")
                @exit()
        )

        @body.addEventListener('keypress', (e) =>
            if e.which != ESC_KEY and not e.ctrlKey
                @search_bar.append_value(String.fromCharCode(e.which))
                # @search_bar.search()
        )

        # this does not work on keypress
        @body.addEventListener("keydown", do =>
            _last_value = ''
            (e) =>
                if e.which == TAB_KEY
                    e.preventDefault()
                    if e.shiftKey and e.ctrlKey
                        @container.grid.selected_up()
                    else if e.shiftKey
                        @container.grid.selected_prev()
                    else if e.ctrlKey
                        @container.grid.selected_down()
                    else
                        @container.grid.selected_next()
                else if e.shiftKey or e.altKey
                    return
                else if e.ctrlKey
                    e.preventDefault()
                    switch e.which
                        when P_KEY
                            @container.grid.selected_up()
                        when F_KEY
                            @container.grid.selected_next()
                        when B_KEY
                            @container.grid.selected_prev()
                        when N_KEY
                            @container.grid.selected_down()
                else if not e.shiftKey and not e.altKey
                    switch e.which
                        when ESC_KEY
                            e.stopPropagation()
                            if @search_bar.empty()
                                @exit()
                            else
                                @search_bar.clean()
                                # update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                                @container.grid.load_category(@container.category_column.selected_category_id)
                        when UP_ARROW
                            @container.grid.selected_up()
                        when DOWN_ARROW
                            @container.grid.selected_down()
                        when LEFT_ARROW
                            @container.grid.selected_prev()
                        when RIGHT_ARROW
                            @container.grid.selected_next()
                        when BACKSPACE_KEY
                            _last_value = @search_bar.value()
                            @search_bar.set_value(_last_value.substr(0, _last_value.length - 1))
                            if @search_bar.empty()
                                if not @search_bar.equal(_last_value)
                                    1
                                    # init_grid()
                                return  # to avoid to invoke search function
                            # search()
                        when ENTER_KEY
                            if @container.grid.item_selected
                                @container.grid.item_selected.do_click(e)
                            else
                                @container.grid.get_first_shown()?.do_click(e)
        )
        @

    connect_signals: ->
        DCore.signal_connect('workarea_changed', (alloc)=>
            height = alloc.height
            @body.style.maxHeight = "#{height}px"
            $('#grid').style.maxHeight = "#{height-60}px"
        )
        DCore.signal_connect("lost_focus", (info)=>
            if @s_dock.LauncherShouldExit_sync(info.xid)
                @exit()
        )
        DCore.signal_connect("draw_background", (info)->
        #     _b.style.backgroundImage = "url(#{info.path})"
        #     if inited
        #         DCore.Launcher.clear()
        #     inited = true
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
        )
        @
