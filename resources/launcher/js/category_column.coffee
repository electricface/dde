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

class CategoryColumn
    constructor: (@parent)->
        # echo 'init category'
        @category = $("#category")
        @select_category_timeout_id = null
        @selected_category_id = ALL_APPLICATION_CATEGORY_ID
        @s_box = @parent.parent.search_bar
        @grid = @parent.grid
        @config = @parent.config
        @apps = @parent.apps

        # key: category id
        # value: a list of Item's id which is in category
        @category_infos = []

    load: ->
        frag = document.createDocumentFragment()
        for info in DCore.Launcher.get_categories()
            c = @create_category(info)
            frag.appendChild(c)
            @load_category_infos(info.ID, @config.sort_method())

        @category.appendChild(frag)

        @set_adaptive_height()
        @show_selected_category()

    create_category: (info) ->
        el = document.createElement('div')

        el.setAttribute('class', 'category_name')
        el.setAttribute('cat_id', info.ID)
        el.setAttribute('id', info.ID)
        el.innerText = info.Name

        el.addEventListener('contextmenu', (e)->
            e.preventDefault()
            e.stopPropagation()
        )
        el.addEventListener('click', (e) ->
            e.stopPropagation()
        )
        el.addEventListener('mouseover', (e)=>
            e.stopPropagation()
            if info.ID != @selected_category_id
                @s_box.clean() if !@s_box.empty()
                @select_category_timeout_id = setTimeout(
                    =>
                        @grid.load_category(info.ID)
                        @selected_category_id = info.ID
                        @show_selected_category()
                    , 25)
        )
        el.addEventListener('mouseout', (e)=>
            if @select_category_timeout_id != 0
                clearTimeout(@select_category_timeout_id)
        )
        return el

    load_category_infos: (cat_id, sort_func)->
        if cat_id == ALL_APPLICATION_CATEGORY_ID
            frag = document.createDocumentFragment()
            @category_infos[cat_id] = []
            for own key, value of @apps
                frag.appendChild(value.element)
                @category_infos[cat_id].push(key)
            @grid.grid.appendChild(frag)
        else
            info = DCore.Launcher.get_items_by_category(cat_id)
            @category_infos[cat_id] = info

        sort_func(@category_infos[cat_id])

    set_adaptive_height: ->
        warp = @category.parentNode
        # add 20px for margin
        categories_height = @category.children.length * (@category.lastElementChild.clientHeight + 20)
        if categories_height > warp.clientHeight
            warp.style.overflowY = "scroll"
            warp.style.marginBottom = "#{GRID_MARGIN_BOTTOM}px"

    show_selected_category: ->
        cns = $s(".category_name")
        for c in cns
            if `this.selected_category_id == c.getAttribute("cat_id")`
                c.classList.add('category_selected')
            else
                c.classList.remove('category_selected')
        return

    hide_empty_category: ->
        for own i of @category_infos
            all_is_hidden = @category_infos["#{i}"].every((el, idx, arr) =>
                @apps[el].display_mode == "hidden"
            )
            if all_is_hidden and not Item.display_temp
                $("##{i}").style.display = "none"
                # i is a string, selected_category_id is a number
                # "==" in coffee is "===" in js
                if "" + @selected_category_id == i
                    @selected_category_id = ALL_APPLICATION_CATEGORY_ID
                    @show_selected_category()
                @grid.load_category(@selected_category_id)

    show_nonempty_category: ->
        for own i of @category_infos
            not_all_is_hidden = @category_infos["#{i}"].some((el, idx, arr) =>
                @apps[el].display_mode != "hidden"
            )
            if not_all_is_hidden or Item.display_temp
                $("##{i}").style.display = "block"

    reset: ->
        @selected_category_id = ALL_APPLICATION_CATEGORY_ID
        if @select_category_timeout_id
            clearTimeout(@select_category_timeout_id)
            @select_category_timeout_id = null
        @show_selected_category()

    selected_category_infos: ->
        @category_infos[@selected_category_id]
