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


class CategoryEntry
    constructor: (info, sort_func)->
        @items = []
        @id = info.ID
        @selected = false

        @el = create_element('div', 'category_name')
        @el.setAttribute('cat_id', info.ID)
        @el.setAttribute('id', info.ID)
        @el.innerText = info.Name

        if @id == ALL_APPLICATION_CATEGORY_ID
            frag = document.createDocumentFragment()
            for own key, value of all_apps
                frag.appendChild(value.element)
                @items.push(key)
            grid.grid.appendChild(frag)
        else
            @items = DCore.Launcher.get_items_by_category(@id)

        sort_func(@items)

    select: ->
        if not @selected
            @selected = true
            @el.classList.add('category_selected')

    unselect: ->
        if @selected
            @selected = false
            @el.classList.remove('category_selected')

    hide: ->
        @el.style.display = 'none'

    show: ->
        @el.style.display = 'block'

    some: (pred_func)->
        @items.some(pred_func)

    every: (pred_func)->
        @items.every(pred_func)

    sort: (sort_func)->
        sort_func(@items)


class CategoryList
    constructor: ->
        # key: category id
        # value: a list of Item's id which is in category
        @categories = {}

    add: (category)->
        @categories[category.id] = category

    category_entry: (id)->
        @categories[id]

    foreach: (func, other_data)->
        for own id of @categories
            func(@, @categories[id], other_data)
        return


class CategoryColumn
    constructor: (@parent)->
        # echo 'init category'
        @timeout_id = null
        @selected_category_id = ALL_APPLICATION_CATEGORY_ID

        @category_list = new CategoryList()

        @el = $("#category")
        @el.addEventListener('contextmenu', (e)->
            e.preventDefault()
            e.stopPropagation()
        )
        @el.addEventListener('click', (e)->
            e.preventDefault()
            e.stopPropagation()
        )
        @el.addEventListener('mouseover', (e)=>
            if 'category_name' in e.target.classList
                item = @category_list.category_entry(e.target.id)
                if not item.selected
                    search_bar.clean if search_bar.empty()
                    @timeout_id = setTimeout(
                        =>
                            grid.load_category(item.id)
                            @selected_category_id = item.id
                            @show_selected_category()
                        , 25)
        )
        @el.addEventListener('mouseout', (e)=>
            if 'category_name' in e.target.classList
                item = @category_list.category_entry(e.target.id)
                if @timeout_id != 0
                    clearTimeout(@timeout_id)
        )

    load: ->
        frag = document.createDocumentFragment()
        for info in DCore.Launcher.get_categories()
            c = new CategoryEntry(info, config.sort_method())
            frag.appendChild(c.el)
            @category_list.add(c)
        @el.appendChild(frag)

        @adaptive_height()
        @show_selected_category()

    adaptive_height: ->
        warp = @el.parentNode
        # add 20px for margin
        categories_height = @el.children.length * (@el.lastElementChild.clientHeight + 20)
        warp_height = window.screen.height - 100
        if categories_height > warp_height
            warp.style.overflowY = "scroll"
            warp.style.marginBottom = "#{GRID_MARGIN_BOTTOM}px"

    show_selected_category: ->
        @category_list.foreach((list, item, c)=>
            if item.id == c.selected_category_id
                item.select()
            else
                item.unselect()
        , @)

    category_items: (id)->
        @category_list.category_entry(id).items

    selected_category_items: ->
        @category_items(@selected_category_id)

    hide_empty_category: ->
        @category_list.foreach((list, item, c)=>
            all_is_hidden = item.every((el, idx, arr)->
                all_apps[el].display_mode == "hidden"
            )

            if all_is_hidden and Item.display_temp
                item.hidden()
                if item.id == c.selected_category_id
                    c.selected_category_id = ALL_APPLICATION_CATEGORY_ID
                    c.show_selected_category()
                grid.load_category(c.selected_category_id)
        , @)

    show_nonempty_category: ->
        @category_list.foreach((list, item)->
            not_all_is_hidden = item.some((el, idx, arr) ->
                all_apps[el].display_mode != "hidden"
            )

            if not_all_is_hidden or Item.display_temp
                item.show()
        )

    reset: ->
        if @timeout_id
            clearTimeout(@timeout_id)
            @timeout_id = null
        @selected_category_id = ALL_APPLICATION_CATEGORY_ID
        @show_selected_category()

        sort_func = config.sort_method()
        sort_func(@selected_category_items())
        @sort_items(sort_func)

    sort_items: (sort_func)->
        @category_list.foreach((list, item)->
            item.sort(sort_func)
        )

