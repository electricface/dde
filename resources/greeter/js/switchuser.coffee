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


class SwitchUser extends Widget
    constructor: ()->
        super
        clearInterval(draw_camera_id)
        draw_camera_id = null
    
    button_switch:->
        echo "button_switch"
        @switch = create_img("switch", "images/userswitch/acount_switch_normal.png", @element)
        @switch.style.cursor = "pointer"
        @switch.style.width = "60px"
        @switch.style.height = "60px"
        @switch.addEventListener("mouseover", =>
            @switch.src = "images/userswitch/acount_switch_hover.png"
        )
        @switch.addEventListener("mouseout", =>
            @switch.src = "images/userswitch/acount_switch_normal.png"
        )
        @switch.addEventListener("click", =>
            #document.body.style.opacity = "0.0"
            #document.body.style.display = "none"
            #DCore.Lock.quit()
            DCore.Lock.switch_user()
            #@SwitchToGreeter()
        )

    SwitchToGreeter:->
        try
            switch_dbus = DCore.DBus.sys_object("org.freedesktop.DisplayManager","/org/freedesktop/DisplayManager/Seat0","org.freedesktop.DisplayManager.Seat")
            switch_dbus.SwitchToGreeter()
        catch error
            echo "can not find the switch dbus,perhaps you only have one userAccount!"
            return false

    SwitchToUser:(username,session_name)->
        try
            switch_dbus = DCore.DBus.sys_object("org.freedesktop.DisplayManager","/org/freedesktop/DisplayManager/Seat0","org.freedesktop.DisplayManager.Seat")
            switch_dbus.SwitchToUser_sync(username,session_name)
            echo switch_dbus
        catch error
            echo "can not find the switch dbus,perhaps you only have one userAccount!"
            return false

