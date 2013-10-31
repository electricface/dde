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

ITEM_WIDTH = 122
ITEM_HEIGHT = 132

SCROLL_STEP_LEN = ITEM_HEIGHT

ALL_APPLICATION_CATEGORY_ID = -1

NUM_SHOWN_ONCE = 10

ITEM_IMG_SIZE = 48

GRID_MARGIN_BOTTOM = 30

ESC_KEY = 27
BACKSPACE_KEY = 8
ENTER_KEY = 13
TAB_KEY = 9

P_KEY = 80
N_KEY = 78
B_KEY = 66
F_KEY = 70

UP_ARROW = 38
DOWN_ARROW = 40
LEFT_ARROW = 37
RIGHT_ARROW = 39

HIDDEN_ICON_MESSAGE =
    true: _("_Hide hidden icons")
    false: _("_Display hidden icons")

ITEM_HIDDEN_ICON_MESSAGE =
    'display': _("_Hide this icon")
    'hidden': _("_Display this icon")

HIDE_ICON_CLASS = 'hide_icon'
INVALID_ICON = 'invalid-dock_app'

AUTOSTARTUP_MESSAGE =
    false: _("_Add to autostart")
    true: _("_Remove from autostart")

AUTOSTART_ICON_NAME = "emblem-autostart"
AUTOSTART_ICON_SIZE = 16

SORT_MESSAGE =
    "name": _("Sort By _Frequency")
    "rate": _("Sort By _Name")


compare_string = (s1, s2) ->
    # echo "compare #{s1}, #{s2}"
    return 1 if s1 > s2
    return 0 if s1 == s2
    return -1


get_name_by_id = (id) ->
    if Widget.look_up(id)?
        DCore.DEntry.get_name(Widget.look_up(id).core)
    else
        ""


sort_by_name = (items)->
    # echo 'name'
    items.sort((lhs, rhs)->
        lhs_name = get_name_by_id(lhs)
        rhs_name = get_name_by_id(rhs)
        compare_string(lhs_name, rhs_name)
    )


sort_by_rate = do ->
    rates = null
    items_name_map = {}

    (items, update)->
        # echo 'rate'
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


class Config
    constructor: ->
        @read()
        @methods =
            "name": sort_by_name
            "rate": sort_by_rate

    sort_method: ->
        @methods[@sort_method_name]

    read: ->
        @sort_method_name = "name"
        if (method_name = DCore.Launcher.sort_method())?
            @sort_method_name = method_name
        else
            save()

    save: ->
        DCore.Launcher.save_config('sort_method', @sort_method_name)
