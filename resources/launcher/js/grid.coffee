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

class Grid
    constructor: (@parent)->
        # echo 'init grid'
        @apps = @parent.apps
        @grid = $('#grid')
        @item_selected = null
        @hover_item_id = null
        @hidden_icons = new HiddenIconList(@)

        @show_hidden_icons = false

    reset: ->
        @get_first_shown()?.scroll_to_view()
        @hidden_icons.save()
        @hidden_icons.hide()
        @load_category(ALL_APPLICATION_CATEGORY_ID)
        if @hover_item_id
            event = new Event("mouseout")
            Widget.look_up(@hover_item_id).element.dispatchEvent(event)

    render: (items) ->
        for id in items
            item_to_be_shown = @grid.removeChild($("#"+id))
            @grid.appendChild(item_to_be_shown)
        return items

    update_scroll_bar: (len) ->
        # echo "items length: #{len}"
        ratio_row_number = ITEM_WIDTH * len / @grid.clientWidth
        row_number = Math.floor(ratio_row_number)
        if ratio_row_number != row_number
            row_number += 1

        if row_number * ITEM_HEIGHT >= @grid.clientHeight
            @grid.style.overflowY = "scroll"
        else
            @grid.style.overflowY = "hidden"

    show_items: (items) ->
        @update_selected(null)

        count = 0
        for i in @hidden_icons
            if i in items
                count += 1
        @update_scroll_bar(items.length - count)

        for own key, value of @apps
            if key not in items
                value.hide()

        count = 0
        for id in items
            group_num = parseInt(count++ / NUM_SHOWN_ONCE)
            setTimeout(@apps[id].show, 4 + group_num)

        return  # some return like here will keep js converted by coffeescript returning stupid things

    load_category: (cat_id) ->
        @show_items(@parent.category_column.category_infos[cat_id])
        @update_selected(null)

    init_grid: ->
        sort_category_info(sort_methods[sort_method])
        @render(@parent.category_column.category_infos[ALL_APPLICATION_CATEGORY_ID])
        @load_category(ALL_APPLICATION_CATEGORY_ID)

    show_grid_dom_child: ->
        c = @grid.children
        i = 0
        while i < c.length
            echo "#{get_name_by_id(c[i].id)}"
            i = i + 1

    get_item_row_count: ->
        parseInt(@grid.clientWidth / ITEM_WIDTH)

    update_selected: (el)->
        @item_selected?.unselect()
        @item_selected = el
        @item_selected?.select()

    get_first_shown: ->
        first_item = @apps[$(".item").id]
        if first_item?.is_shown()
            first_item
        else
            first_item?.next_shown()

    show_item_shown: (item)->
        if item
            item.scroll_to_view()
            @update_selected(item)

    show_first_shown: ->
        first_shown = @get_first_shown()
        @show_item_shown(first_shown)

    selected_next: ->
        if not @item_selected
            @show_first_shown()
            return

        @show_item_shown(@item_selected.next_shown())

    selected_prev: ->
        if not @item_selected
            @show_first_shown()
            return

        @show_item_shown(@item_selected.prev_shown())

    selected_down: ->
        if not @item_selected
            @show_first_shown()
            return

        n = @item_selected
        for i in [0..@get_item_row_count()-1]
            if n
                n = n.next_shown()
            else
                break
        if n
            @grid.scrollTop += SCROLL_STEP_LEN
            @show_item_shown(n)

    selected_up: ->
        if not @item_selected
            @show_first_shown()
            return

        n = @item_selected
        for i in [0..@get_item_row_count()-1]
            if n
                n = n.prev_shown()
            else
                break
        if n
            @grid.scrollTop -= SCROLL_STEP_LEN
            @show_item_shown(n)

    toggle_hidden_icons: =>
        @show_hidden_icons = !@show_hidden_icons

        if @show_hidden_icons
            Item.display_temp = true
            @hidden_icons.show(@parent.category_column.selected_category_infos())
        else
            Item.display_temp = false
            @hidden_icons.hide()
