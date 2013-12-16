#Copyright (c) 2012 ~ 2013 Deepin, Inc.
#              2012 ~ 2013 snyh
#
#Author:      snyh <snyh@snyh.org>
#             Cole <phcourage@gmail.com>
#             bluth <yuanchenglu001@gmail.com>
#
#Maintainer:  Cole <phcourage@gmail.com>
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


class ComputerVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_computer_entry()
        super(entry, false, false)

    set_id : =>
        @id = _ITEM_ID_COMPUTER_


    get_name : =>
        _("Computer")


    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon(_ICON_ID_COMPUTER_, D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    # get_path : =>
    #     ""


    do_buildmenu : ->
        [
            [1, _("_Open")],
            [],
            [2, _("_Properties")]
        ]


    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 2
                DCore.Desktop.run_deepin_settings("system_information")
            else
                echo "computer unkown command id:#{evt.id} title:#{evt.title}"
        return


    item_rename : =>
        return


class HomeVDir extends DesktopEntry
    constructor : ->
        entry = DCore.Desktop.get_home_entry()
        super(entry, false, false)


    set_id : =>
        @id = _ITEM_ID_USER_HOME_


    get_name : =>
        _("Home")


    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon(_ICON_ID_USER_HOME_, D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    get_path : =>
        ""


    do_drop : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @_entry, true)
        return


    do_dragenter : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.preventDefault()
            evt.dataTransfer.dropEffect = "move"
        return


    do_buildmenu : ->
        [
            [1, _("_Open")],
            [],
            [2, _("_Properties")]
        ]


    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 2
                show_entries_properties([@_entry])
            else
                echo "computer unkown command id:#{evt.id} title:#{evt.title}"
        return


    item_rename : =>
        return


class TrashVDir extends DesktopEntry
    constructor : ->
        entry = DCore.DEntry.get_trash_entry()
        super(entry, false, false)

    # XXX: try to avoid that get empty state when system startup
    setTimeout(@item_update, 400) if DCore.DEntry.get_trash_count() == 0


    set_id : =>
        @id = _ITEM_ID_TRASH_BIN_


    get_name : =>
        _("Trash")


    set_icon : (src = null) =>
        if src == null
            if DCore.DEntry.get_trash_count() > 0
                icon = DCore.get_theme_icon(_ICON_ID_TRASH_BIN_FULL_, D_ICON_SIZE_NORMAL)
            else
                icon = DCore.get_theme_icon(_ICON_ID_TRASH_BIN_, D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    get_path : =>
        ""


    do_drop : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)

            if tmp_list.length > 0 then DCore.DEntry.trash(tmp_list)
        return


    do_dragenter : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.preventDefault()
            evt.dataTransfer.dropEffect = "move"
        return


    do_buildmenu : ->
        menus = []
        menus.push([1, _("_Open")])
        menus.push([])
        count = DCore.DEntry.get_trash_count()
        if count > 1
            menus.push([3, _("_Clean up %1 items").args(count)])
        else if count == 1
            menus.push([3, _("_Clean up 1 item")])
        else
            menus.push([3, _("_Clean up"), false])
        menus

    do_itemselected : (evt) ->
        switch evt.id
            when 1
                @item_exec()
            when 3
                DCore.DEntry.confirm_trash()
            else
                echo "computer unkown command id:#{evt.id} title:#{evt.title}"
        return


    item_rename : =>
        return


class DeepinSoftwareCenter extends DesktopEntry
    constructor : ->
        super(null, false, false)


    set_id : =>
        @id = _ITEM_ID_DSC_


    get_name : =>
        _("Software Center")


    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon(_ICON_ID_DSC_, D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    get_path : =>
        ""


    do_buildmenu : ->
        menus = [[1, _("_Open")]]


    item_rename : =>
        return


    item_exec : =>
        DCore.Desktop.run_deepin_software_center()
