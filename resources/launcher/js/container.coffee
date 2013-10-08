#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 liliqiang
#
#Author:      liliqiang <liliqiang@linuxdeepin.com>
#Maintainer:  liliqiang <liliqiang@liunxdeepin.com>
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

class Config
    constructor: ->
        @sort_method_name
        @methods =
            "name": sort_by_name
            "rate": sort_by_rate

    sort_method: ->
        @methods[@sort_method_name]

    read: ->

    save: ->
        DCore.Launcher.save_config('sort_method', @sort_method_name)


class Container
    contructor: (@parent)->
        @search_bar = @parent.search_bar
        @config = new Config(@)
        @s_dock = @parent.s_dock

        all_items = DCore.Launcher.get_items_by_category(ALL_APPLICATION_CATEGORY_ID)
        @apps = []
        for core in all_items
            id = DCore.DEntry.get_id(core)
            @apps[id] = new Item(id, core, @)

        @category_column = new CategoryColumn(@)
        @grid = new Grid(@)

    reset: ->
        @grid.reset()
        @category_column.reset()
