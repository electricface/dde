#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2013 ~ 2013 Liqiang Lee
#
#Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
#Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
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

class Item extends Widget
    @theme_icon: null
    @display_temp: false

    constructor: (@id, @core, @parent)->
        super
        @load_img()
        @grid = @parent.grid
        @apps = @parent.apps
        @hidden_icons = @grid.hidden_icons
        @category_column = @parent.category_column
        @launcher = @parent.parent

        @name = create_element("div", "item_name", @element)
        @name.innerText = DCore.DEntry.get_name(@core)

        @element.draggable = true
        @hide_element()

        @try_set_title(DCore.DEntry.get_name(@core), 80)
        @display_mode = 'display'

        if DCore.Launcher.is_autostart(@core)
            @add_to_autostart()
        else
            @is_autostart = false

        @element.addEventListener("contextmenu", Item._contextmenu_callback(@))

    try_set_title: (text, width)->
        setTimeout(=>
            height = calc_text_size(text, width)
            if height > 38
                @element.setAttribute('title', text)
        , 200)

    load_img: ->
        im = DCore.DEntry.get_icon(@core)
        if im == null
            im = DCore.get_theme_icon('invalid-dock_app', ITEM_IMG_SIZE)

        @img = create_img("", im, @element)

        @img.onload = (e) =>
            if @img.width == @img.height
                @img.className = 'square_img'
            else if @img.width > @img.height
                @img.className = 'hbar_img'
                new_height = ITEM_IMG_SIZE * @img.height / @img.width
                grap = (ITEM_IMG_SIZE - Math.floor(new_height)) / 2
                @img.style.padding = "#{grap}px 0px"
            else
                @img.className = 'vbar_img'

        @img.onerror = (e) =>
            src = DCore.get_theme_icon('invalid-dock_app', ITEM_IMG_SIZE)
            if src != @img.src
                @img.src = src

    add_to_autostart: ->
        @is_autostart = true
        DCore.Launcher.add_to_autostart(@core)
        Item.theme_icon ?= DCore.get_theme_icon(AUTOSTART_ICON_NAME,
            AUTOSTART_ICON_SIZE)
        last = @element.lastChild
        if last.tagName != 'IMG'
            create_img("autostart_flag", Item.theme_icon, @element)

    remove_from_autostart: ->
        if DCore.Launcher.remove_from_autostart(@core)
            @is_autostart = false
            last = @element.lastChild
            @element.removeChild(last) if last.tagName == 'IMG'

    toggle_autostart: ->
        if @is_autostart
            @remove_from_autostart()
        else
            @add_to_autostart()

    _menu: ->
        # echo AUTOSTARTUP_MESSAGE[@is_autostart]
        menu = [
            [1, _("_Open")],
            [],
            [2, ITEM_HIDDEN_ICON_MESSAGE[@display_mode]],
            [],
            [3, _("Send to d_esktop"), not DCore.Launcher.is_on_desktop(@core)],
            [4, _("Send to do_ck"), @parent.dock!=null],
            [],
            [5, AUTOSTARTUP_MESSAGE[@is_autostart]]
        ]

        if DCore.DEntry.internal()
            menu.push([])
            menu.push([100, "report this bad icon"])

        menu

    @_contextmenu_callback: do ->
        _callback_func = null
        (item)->
            item.element.removeEventListener('contextmenu', _callback_func)
            _callback_func = (e) ->
                item.element.contextMenu = build_menu(item._menu())

    do_click: (e)=>
        e.stopPropagation()
        @element.style.cursor = 'wait'
        DCore.DEntry.launch(@core, [])
        @grid.hover_item_id = @id
        @element.style.cursor = 'auto'
        @launcher.exit()

    do_dragstart: (e)=>
        e.dataTransfer.setData("text/uri-list", DCore.DEntry.get_uri(@core))
        e.dataTransfer.setDragImage(@img, 20, 20)
        e.dataTransfer.effectAllowed = "all"

    hide_icon: (e)=>
        @display_mode = 'hidden'

        if HIDE_ICON_CLASS not in @element.classList
            @add_css_class(HIDE_ICON_CLASS, @element)

        if not Item.display_temp and not @grid.show_hidden_icons
            @element.style.display = 'none'
            @grid.update_scroll_bar(@category_column.selected_category_infos().length )#- hidden_icons_num)
            @category_column.hide_empty_category()

        @hidden_icons.add(@)

    display_icon: (e)=>
        @display_mode = 'display'
        @element.style.display = 'block'

        if HIDE_ICON_CLASS in @element.classList
            @remove_css_class(HIDE_ICON_CLASS, @element)

        @hidden_icons.remove(@)
        if @hidden_icons.length == 0
            Item.display_temp = false

    display_icon_temp: ->
        @element.style.display = 'block'
        @grid.update_scroll_bar(@category_column.selected_category_infos().length)

    toggle_icon: ->
        if @display_mode == 'display'
            @hide_icon()
        else
            @display_icon()

        @element.addEventListener('contextmenu', Item._contextmenu_callback(@))

    do_itemselected: (e)=>
        switch e.id
            when 1 then DCore.DEntry.launch(@core, [])
            when 2 then @toggle_icon()
            when 3 then DCore.DEntry.copy_dereference_symlink([@core], DCore.Launcher.get_desktop_entry())
            when 4 then @parent.dock?.RequestDock_sync(DCore.DEntry.get_uri(@core).substring(7))
            when 5 then @toggle_autostart()
            when 100 then DCore.DEntry.report_bad_icon(@core)  # internal

    hide: ->
        @hide_element()

    # use '->', Item.display_temp and @display_mode will be undifined when this
    # function is pass to some other functions like setTimeout
    show: =>
        @show_element() if Item.display_temp or @display_mode == 'display'

    select: ->
        @element.setAttribute("class", "item item_selected")

    unselect: ->
        @element.setAttribute("class", "item")

    next_shown: ->
        next_sibling_id = @element.nextElementSibling?.id
        if next_sibling_id and (n = @apps[next_sibling_id])?
            if n.is_shown() then n else n.next_shown()
        else
            null

    prev_shown: ->
        prev_sibling_id = @element.previousElementSibling?.id
        if prev_sibling_id and (n = @apps[prev_sibling_id])?
            if n.is_shown() then n else n.prev_shown()
        else
            null

    scroll_to_view: ->
        @element.scrollIntoViewIfNeeded()

    do_mouseover: =>
        @element.style.background = "rgba(0, 183, 238, 0.2)"
        @element.style.border = "1px rgba(255, 255, 255, 0.2) solid"
        @element.style.borderRadius = "2px"
        @grid.hover_item_id = @id

    do_mouseout: =>
        @element.style.background = ''
        @element.style.border = "1px rgba(255, 255, 255, 0.0) solid"
        @element.style.borderRadius = ""


compare_string = (s1, s2) ->
    return 1 if s1 > s2
    return 0 if s1 == s2
    return -1


get_name_by_id = (id) ->
    if Widget.look_up(id)?
        DCore.DEntry.get_name(Widget.look_up(id).core)
    else
        ""


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


