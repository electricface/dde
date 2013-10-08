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

class CategoryColumn
    constructor: (@parent)->
        @category = $("#category")
        @select_category_timeout_id = 0
        @selected_category_id = ALL_APPLICATION_CATEGORY_ID
        @s_box = @parent.parent.search_bar

        frag = document.createDocumentFragment()
        for info in DCore.Launcher.get_categories()
            c = @create_category(info)
            frag.appendChild(c)
            @load_category_infos(info.ID, sort_methods[sort_method])

        @category.appendChild(frag)

        @set_adaptive_height()

    @create_category = (info) ->
        el = document.createElement('div')

        el.setAttribute('class', 'category_name')
        el.setAttribute('cat_id', info.ID)
        el.setAttribute('id', info.ID)
        el.innerText = info.Name

        el.addEventListener('click', (e) ->
            e.stopPropagation()
        )
        el.addEventListener('mouseover', (e)=>
            e.stopPropagation()
            if info.ID != @selected_category_id
                s_box.value = "" if s_box.value != ""
                _select_category_timeout_id = setTimeout(
                    =>
                        grid_load_category(info.ID)
                        @selected_category_id = info.ID
                    , 25)
        )
        el.addEventListener('mouseout', (e)->
            if _select_category_timeout_id != 0
                clearTimeout(_select_category_timeout_id)
        )
        return el

    set_adaptive_height: ->
        warp = @category.parentNode
        # add 20px for margin
        categories_height = @category.children.length * (@category.lastElementChild.clientHeight + 20)
        if categories_height > warp.clientHeight
            warp.style.overflowY = "scroll"
            warp.style.marginBottom = "#{GRID_MARGIN_BOTTOM}px"

    hide_empty_category: ->
        for own i of @category_infos
            all_is_hidden = @category_infos["#{i}"].every((el, idx, arr) ->
                applications[el].display_mode == "hidden"
            )
            if all_is_hidden and not Item.display_temp
                $("##{i}").style.display = "none"
                # i is a string, selected_category_id is a number
                # "==" in coffee is "===" in js
                if "" + @selected_category_id == i
                    @selected_category_id = ALL_APPLICATION_CATEGORY_ID
                grid_load_category(@selected_category_id)

    show_nonempty_category: ->

    reset: ->
