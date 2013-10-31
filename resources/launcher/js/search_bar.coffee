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

class SearchBar
    constructor: (@parent)->
        # echo 'init search bar'
        @s_box = $("#s_box")
        @s_box.setAttribute("placeholder", _("Type to search..."))

        $("#search").addEventListener('click', (e)=>
            if e.target == @s_box
                e.stopPropagation()
        )

        # @s_box.addEventListener('input', @s_box.blur())

        DCore.signal_connect("im_commit", (info)=>
            @s_box.value += info.Content
            search()
        )

        # cursor = create_element("span", "cursor", document.body)
        # cursor.innerText = "|"

    clean: ->
        @s_box.value = ""

    set_value: (value) ->
        @s_box.value = value

    append_value: (s) ->
        @set_value(@s_box.value + s)

    empty: ->
        @s_box.value == ""

    length: ->
        @s_box.length

    value: ->
        @s_box.value

    equal: (value)->
        @s_box.value == value


do_search = ->
    ret = []
    key = search_bar.value().toLowerCase().trim()

    for k,v of all_apps
        if key == ""
            ret.push(
                "value": k
                "weight": 0
            )
        else if (weight = DCore.Launcher.weight(v.core, key))
            ret.push(
                "value": k
                "weight": weight
            )

    ret.sort((lhs, rhs) -> rhs.weight - lhs.weight)
    ret = (item.value for item in ret)

    return grid.render_dom(ret)

search = do ->
    _search_id = null
    ->
        clearTimeout(_search_id)
        _search_id = setTimeout(->
            grid.show_items(grid.render_dom(do_search()))
        , 20)
