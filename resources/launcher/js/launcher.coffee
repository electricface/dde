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


body = document.body
try
    dock = DCore.DBus.session("com.deepin.dde.dock")
catch error
    dock = null


config = new Config()
search_bar = new SearchBar()
grid = new Grid()
category_column = new CategoryColumn()
container = new Container()


exit = ->
    search_bar.clean()
    container.reset()


bind_events = ->
    body.addEventListener("click", (e)=>
        e.stopPropagation()
        if e.target != $("#category")
            DCore.Launcher.exit_gui()
    )

    body.addEventListener('keypress', (e) =>
        if e.which != ESC_KEY and not e.ctrlKey and e.which != BACKSPACE_KEY
            search_bar.append_value(String.fromCharCode(e.which))
            search()
    )

    # this does not work on keypress
    body.addEventListener("keydown", (e) =>
        if e.which == TAB_KEY
            e.preventDefault()
            if e.shiftKey and e.ctrlKey
                grid.selected_up()
            else if e.shiftKey
                grid.selected_prev()
            else if e.ctrlKey
                grid.selected_down()
            else
                grid.selected_next()
        else if e.shiftKey or e.altKey
            return
        else if e.ctrlKey
            e.preventDefault()
            switch e.which
                when P_KEY
                    grid.selected_up()
                when F_KEY
                    grid.selected_next()
                when B_KEY
                    grid.selected_prev()
                when N_KEY
                    grid.selected_down()
        else if not e.shiftKey and not e.altKey
            switch e.which
                when ESC_KEY
                    e.stopPropagation()
                    if search_bar.empty()
                        DCore.Launcher.exit_gui()
                    else
                        search_bar.clean()
                        # update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
                        grid.load_category(category_column.selected_category_id)
                when BACKSPACE_KEY
                    e.stopPropagation()
                    e.preventDefault()
                    _last_value = search_bar.value()
                    search_bar.set_value(_last_value.substr(0, _last_value.length - 1))
                    if search_bar.empty()
                        container.reset()
                        return  # to avoid to invoke search function
                    search()
                when ENTER_KEY
                    if grid.item_selected
                        grid.item_selected.do_click(e)
                    else
                        grid.get_first_shown()?.do_click(e)
                when UP_ARROW
                    grid.selected_up()
                when DOWN_ARROW
                    grid.selected_down()
                when LEFT_ARROW
                    grid.selected_prev()
                when RIGHT_ARROW
                    grid.selected_next()
    )
