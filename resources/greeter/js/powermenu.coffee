#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
#Maintainer:  LongWei <yilang2007lw@gmail.com>
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

class PowerMenu extends Widget
    upower_obj = null
    consolekit_obj = null
    power_dict = {}
    power_menu = null
    parent = null
    img_before = null
    
    constructor: (parent_el) ->
        super
        parent = parent_el
        img_before = "images/powermenu/"

    suspend_cb : ->
        power_force("suspend")

    restart_cb : ->
        power_force("restart")

    shutdown_cb : ->
        power_force("shutdown")

    signal_connect:->
        #DCore.signal_connect("power", (msg) ->
        #    status_div = create_element("div", " ", $("#Debug"))
        #    status_div.innerText = "status:" + msg.status
        #)

    get_power_dict : ->
        power_dict["suspend"] = @suspend_cb
        power_dict["restart"] = @restart_cb
        power_dict["shutdown"] = @shutdown_cb
        return power_dict

    new_power_menu:->
        power_dict = @get_power_dict()
        power_menu_cb = (id, title)->
            power_dict[id]()

        power_menu = new ComboBox("power", power_menu_cb)

        for key, value of power_dict
            # power_menu.insert(key, key, "images/control-power.png")
            title = null
            if key == "suspend"
                title = _("suspend")
                img = img_before + "#{key}.png"
                power_menu.insert(key, title, img)
            else if key == "restart"
                title = _("restart")
                img = img_before + "#{key}.png"
                power_menu.insert(key, title, img)
            else if key == "shutdown"
                title = _("shutdown")
            else
                echo "invalid power option"

        power_menu.current_img.src = img_before + "shutdown_normal.png"
        parent.appendChild(power_menu.element) if parent
        power_menu.current_img.addEventListener("mouseover",=>
            power_menu.current_img.src = img_before + "shutdown.png"
        )
        power_menu.current_img.addEventListener("mouseout",=>
            power_menu.current_img.src = img_before + "shutdown_normal.png"
        )
        power_menu.current_img.addEventListener("click", (e) =>
            power_dict["shutdown"]()
        )
        power_menu.menu.element.addEventListener("mouseover",=>
            power_menu.current_img.src = img_before + "shutdown.png"
        )
