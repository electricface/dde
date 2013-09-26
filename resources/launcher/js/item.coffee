class Item extends Widget
    @theme_icon: null
    @hover_item_id: null
    @display_temp: false

    constructor: (@id, @core)->
        super
        @load_img()

        @name = create_element("div", "item_name", @element)
        @name.innerText = DCore.DEntry.get_name(@core)

        @element.draggable = true
        @hide_element()

        try_set_title(@element, DCore.DEntry.get_name(@core), 80)
        @display_mode = 'display'

        if DCore.Launcher.is_autostart(@core)
            @add_to_autostart()

        @element.addEventListener("contextmenu", Item._contextmenu_callback(@))

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
        if @display_mode == 'display'
            hide_icon_msg = HIDE_ICON
        else
            hide_icon_msg = DISPLAY_ICON

        if @is_autostart
            startup_msg = NOT_STARTUP_ICON
        else
            startup_msg = STARTUP_ICON
        menu = [
            [1, _("_Open")],
            [],
            [2, hide_icon_msg],
            [],
            [3, _("Send to d_esktop"), not DCore.Launcher.has_this_item_on_desktop(@core)],
            [4, _("Send to do_ck"), s_dock!=null],
            [],
            [5, startup_msg]
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
        set_style('cursor', 'wait')
        DCore.DEntry.launch(@core, [])
        Item.hover_item_id = @id
        set_style('cursor', 'auto')
        exit_launcher()

    do_dragstart: (e)=>
        e.dataTransfer.setData("text/uri-list", DCore.DEntry.get_uri(@core))
        e.dataTransfer.setDragImage(@img, 20, 20)
        e.dataTransfer.effectAllowed = "all"

    hide_icon: (e)=>
        @display_mode = 'hidden'
        if HIDE_ICON_CLASS not in @element.classList
            @add_css_class(HIDE_ICON_CLASS, @element)
        if not Item.display_temp and not is_show_hidden_icons
            @element.style.display = 'none'
            Item.display_temp = false
        hidden_icons[@id] = @
        hide_category()
        _update_scroll_bar(category_infos[selected_category_id].length - _get_hidden_icons_ids().length)

    display_icon: (e)=>
        @display_mode = 'display'
        @element.style.display = 'block'
        if HIDE_ICON_CLASS in @element.classList
            @remove_css_class(HIDE_ICON_CLASS, @element)
        delete hidden_icons[@id]
        hidden_icons_num = _get_hidden_icons_ids().length
        show_category()
        if hidden_icons_num == 0
            is_show_hidden_icons = false
            _show_hidden_icons(is_show_hidden_icons)
        _update_scroll_bar(category_infos[selected_category_id].length - hidden_icons_num)

    display_icon_temp: ->
        @element.style.display = 'block'
        Item.display_temp = true
        show_category()

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
            when 4 then s_dock.RequestDock_sync(DCore.DEntry.get_uri(@core).substring(7))
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
        if next_sibling_id
            n = applications[next_sibling_id]
            if n.is_shown() then n else n.next_shown()
        else
            null

    prev_shown: ->
        prev_sibling_id = @element.previousElementSibling?.id
        if prev_sibling_id
            n = applications[prev_sibling_id]
            if n.is_shown() then n else n.prev_shown()
        else
            null

    scroll_to_view: ->
        @element.scrollIntoViewIfNeeded()

    do_mouseover: =>
        @set_style('background', "rgba(0, 183, 238, 0.2)")
        @set_style('border',  "1px rgba(255, 255, 255, 0.2) solid")
        @set_style('borderRadius', "2px")
        Item.hover_item_id = @id

    do_mouseout: =>
        @set_style('background', "")
        @set_style('border', "1px rgba(255, 255, 255, 0.0) solid")
        @set_style('borderRadius', "")
        # Item.hover_item_id = null