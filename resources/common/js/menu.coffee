DEEPIN_MENU_NAME = "com.deepin.menu"
DEEPIN_MENU_PATH = "/com/deepin/menu"
DEEPIN_MENU_INTERFACE = "com.deepin.menu.Menu"
DEEPIN_MENU_MANAGER_INTERFACE = "com.deepin.menu.Manager"


DEEPIN_MENU_TYPE =
    NORMAL: 0
    CHECKBOX: 1
    RADIOBOX: 2


DEEPIN_MENU_CORNER_DIRECTION =
    UP: "up"
    DOWN: "down"
    LEFT: "left"
    RIGHT: "right"


class NormalMenu
    constructor: (items...)->
        @x = 0
        @y = 0
        @isDockMenu = false
        @cornerDirection = DEEPIN_MENU_CORNER_DIRECTION.DOWN
        if items.length == 1 and Array.isArray(items[0])
            @menuJsonContent = new MenuContent(items[0])
        else
            @menuJsonContent = new MenuContent(items)

    apply: (fn, items)->
        MenuContent.prototype[fn].apply(@menuJsonContent, items)

    append: (items...)->
        @apply("append", items)

    addSeparator: ->
        @menuJsonContent.addSeparator()

    toString: ->
        "{\"x\": #{@x}, \"y\": #{@y}, \"isDockMenu\": #{@isDockMenu}, \"cornerDirection\": \"#{@cornerDirection}\", \"menuJsonContent\": \"#{@menuJsonContent.toString().addSlashes()}\"}"


class MenuContent
    constructor: (item...)->
        @x = 0
        @y = 0
        @isDockMenu = false
        @cornerDirection = DEEPIN_MENU_CORNER_DIRECTION.down
        if item.length == 1
            @menuJsonContent = new MenuContent(item[0])
        else
            @menuJsonContent = new MenuContent(item)

    append: (item...)->
        MenuContent::append.apply(@menuJsonContent, item)

    addSeparator: ->
        @menuJsonContent.addSeparator()

    toString: ->
        "{\"x\": #{@x}, \"y\": #{@y}, \"isDockMenu\": #{@isDockMenu}, \"cornerDirection\": \"#{@cornerDirection}\", \"menuJsonContent\": \"#{@menuJsonContent.toString().addSlashes()}\"}"


class MenuContent
    constructor: (item...)->
        @checkableMenu = false
        @singleCheck = false
        @items = []
        if item.length == 1 and Array.isArray(item[0])
            MenuContent::append.apply(@, item[0])
        else
            MenuContent::append.apply(@, item)

    append: (items...)->
        items.forEach((el) =>
            @items.push(el)
        )
        @

    addSeparator: ->
        @append(new MenuSeparator())

    toString:->
        JSON.stringify(@)


class CheckBoxMenu extends NormalMenu
    constructor:->
        super
        @checkableMenu = true


class RadioBoxMenu extends CheckBoxMenu
    constructor:->
        super
        @singleCheck = true


class MenuItem
    constructor: (itemId, @itemText, subMenu=null)->
        @itemId = "#{itemId}"
        @isCheckable = false
        @checked = false
        @itemIcon = ''
        @itemIconHover = ''
        @isActive = true
        @itemIconInactive = ""
        @showCheckmark = true
        if subMenu == null
            @itemSubMenu = new MenuContent
        else
            @itemSubMenu = subMenu.menu.menuJsonContent

    setIcon: (icon)->
        @itemIcon = icon
        @

    setHoverIcon: (icon)->
        @itemIconHover = icon
        @

    setInactiveIcon: (icon)->
        @itemIconInactive = icon
        @

    setSubMenu: (subMenu)->
        @itemSubMenu = subMenu.menu.menuJsonContent
        @

    setActive: (isActive)->
        @isActive = isActive
        @

    setShowCheckmark: (showCheckmark)->
        @showCheckmark = showCheckmark
        @

    toString: ->
        JSON.stringify(@)


class CheckBoxMenuItem extends MenuItem
    constructor: (itemId, itemText, checked=false, isActive=true)->
        super(itemId, itemText)
        @isCheckable = true

    setChecked: (checked)->
        @checked = checked
        @


class RadioBoxMenuItem extends CheckBoxMenuItem


class MenuSeparator extends MenuItem
    constructor: ->
        super('', '')


get_dbus = (type, dbus_name, dbus_path, dbus_interface)->
    # echo "#{dbus_name}, #{dbus_path}, #{dbus_interface}"
    for dump in [0...10]
        try
            dbus = DCore.DBus["#{type.toLowerCase()}_object"](
                dbus_name, dbus_path, dbus_interface
            )
            return dbus

    throw "Get DBus \"#{dbus_name} #{dbus_path} #{dbus_interface}\" failed"


class Menu
    constructor: (@type, items...)->
        switch @type
            when DEEPIN_MENU_TYPE.NORMAL
                @menu = new NormalMenu(items)
            when DEEPIN_MENU_TYPE.CHECKBOX
                @menu = new CheckBoxMenu(items)
            when DEEPIN_MENU_TYPE.RADIOBOX
                @menu = new RadioBoxMenu(items)
            else
                throw "Invalid DEEPIN_MENU_TYPE: #{@type}"
        @_init_dbus()

    apply: (fn, items)->
        switch @menu.constructor.name
            when "NormalMenu"
                NormalMenu.prototype[fn].apply(@menu, items)
            when "CheckBoxMenu"
                CheckBoxMenu.prototype[fn].apply(@menu, items)
            when "RadioBoxMenu"
                RadioBoxMenu.prototype[fn].apply(@menu, items)
        @

    append: (items...)->
        @apply("append", items)

    addSeparator: ->
        @menu.addSeparator()
        @

    setDockMenuCornerDirection: (cornerDirection)->
        @menu.cornerDirection = cornerDirection
        @

    addListener: (@callback)->
        try
            @dbus.connect("ItemInvoked", @callback)
            @
        catch e
            echo "listenItemSelected: #{e}"

    _init_dbus: ->
        manager = get_dbus(
            "session",
            DEEPIN_MENU_NAME,
            DEEPIN_MENU_PATH,
            DEEPIN_MENU_MANAGER_INTERFACE
        )

        menu_dbus_path = manager.RegisterMenu_sync()
        # echo "menu path is: #{menu_dbus_path}"
        @dbus = get_dbus(
            "session",
            DEEPIN_MENU_NAME,
            menu_dbus_path,
            DEEPIN_MENU_INTERFACE)

    showMenu: (x, y, ori=null)->
        @menu.x = x
        @menu.y = y
        if ori != null
            @menu.isDockMenu = true
            @menu.cornerDirection = ori
        # echo @menu
        @dbus.ShowMenu("#{@menu}")

    toString: ->
        "#{@menu}"

    destroy: ->
        try
            @dbus.dis_connect("ItemInvoked", @callback)
