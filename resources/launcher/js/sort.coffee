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


compare = (s1, s2) ->
    # echo "compare #{s1}, #{s2}"
    return 1 if s1 > s2
    return 0 if s1 == s2
    return -1


get_name_by_id = (id) ->
    if (w = Widget.look_up(id))?
        # echo w.display_name
        w.display_name
    else
        ""


sort_by_name = (items)->
    items.sort((lhs, rhs)->
        lhs_name = get_name_by_id(lhs)
        rhs_name = get_name_by_id(rhs)
        compare(lhs_name, rhs_name)
    )


sort_by_rate = do ->
    # key: Item id
    # value: appid
    id_map = {}
    (items, rates)->
        items.sort((lhs, rhs)->
            id_map[lhs] ?= DCore.DEntry.get_appid(Widget.look_up(lhs).core)
            id_map[rhs] ?= DCore.DEntry.get_appid(Widget.look_up(rhs).core)

            lhs_appid = id_map[lhs]
            lhs_rate = if lhs_appid? then rates[lhs_appid] else null

            rhs_appid = id_map[rhs]
            rhs_rate = if rhs_appid? then rates[rhs_appid] else null

            # echo "### comepare \"#{lhs_appid}\" and \"#{rhs_appid}\""
            # echo "## #{lhs_rate}, #{rhs_rate}"
            if lhs_rate and rhs_rate
                # echo "# compare rate"
                rates_delta = rhs_rate - lhs_rate
                if rates_delta == 0
                    return compare(get_name_by_id(lhs), get_name_by_id(rhs))
                else
                    return rates_delta
            else if lhs_rate and not rhs_rate
                # echo "# just left has rate"
                return -1
            else if not lhs_rate and rhs_rate
                # echo "# just right has rate"
                return 1
            else
                # echo "# no rate, compare name"
                return compare(get_name_by_id(lhs), get_name_by_id(rhs))
        )
