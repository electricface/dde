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
        @grid = $('#grid')
        @item_selected = null
        @hover_item_id = null
        @hidden_icons = new HiddenIconList(@)

        @show_hidden_icons = false

    reset: ->
        @get_first_shown()?.scroll_to_view()
        @init_grid()
        @hidden_icons.save()
        @hidden_icons.hide()
        if @hover_item_id
            event = new Event("mouseout")
            Widget.look_up(@hover_item_id).element.dispatchEvent(event)

    render_dom: (items) ->
        for id in items
            item_to_be_shown = @grid.removeChild($("#"+id))
            @grid.appendChild(item_to_be_shown)
        return items

    update_scroll_bar: (len) ->
        # echo "items length: #{len}"
        lang = document.body.getAttribute('lang')
        if lang == 'en'
            category_width = 220
        else
            category_width = 180

        grid_width = window.screen.width - 20 - category_width
        row_number = Math.ceil(ITEM_WIDTH * len / grid_width)
        grid_height = window.screen.height - 100
        if row_number * ITEM_HEIGHT >= grid_height
            @grid.style.overflowY = "scroll"
        else
            @grid.style.overflowY = "hidden"

    update_selected: (el)->
        @item_selected?.unselect()
        @item_selected = el
        @item_selected?.select()

    show_items: (items) ->
        # echo 'show_items'
        @update_selected(null)

        count = 0
        for i in items
            if @hidden_icons.is_hidden_icon(i)
                count += 1
        @update_scroll_bar(items.length - count)

        for own key, value of all_apps
            if key not in items
                value.hide()

        count = 0
        for id in items
            group_num = parseInt(count++ / NUM_SHOWN_ONCE)
            setTimeout(all_apps[id].show, 4 + group_num)

        return  # some return like here will stop js returning stupid things

    load_category: (cat_id) ->
        @show_items(category_column.category_items(cat_id))
        @update_selected(null)

    init_grid: ->
        @render_dom(category_column.selected_category_items())
        @load_category(category_column.selected_category_id)

    get_item_row_count: ->
        parseInt(@grid.clientWidth / ITEM_WIDTH)

    get_first_shown: ->
        first_item = all_apps[$(".item").id]
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
            @hidden_icons.show(category_column.selected_category_items())
        else
            Item.display_temp = false
            @hidden_icons.hide()

        @update_scroll_bar(category_column.selected_category_items().length)
