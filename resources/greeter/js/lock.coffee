#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
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

class Lock extends Widget

    constructor:->
        super
        echo "Lock"

    webview_ok:(_current_user)->
        DCore.Lock.webview_ok(_current_user.id)


    start_login_connect:(userinfo)->
        DCore.signal_connect("start-login", ->
            echo "receive start login"
            # TODO: maybe some animation or some reflection.
            userinfo.is_recognizing = false
            DCore.Lock.try_unlock("")
        )


document.body.style.height = window.innerHeight
document.body.style.width = window.innerWidth

lock = new Lock()

user = new User()
$("#div_users").appendChild(user.element)
user.new_userinfo_for_lock()
#user.roundabout_animation()
#user.jCarousel_animation()

userinfo = user.get_current_userinfo()
_current_user = user.get_current_userinfo()

lock.start_login_connect(userinfo)
lock.webview_ok(_current_user)

timedate = new TimeDate()
$("#div_time").appendChild(timedate.element)
timedate.show()



$("#div_power").title = _("ShutDown")
powermenu = new PowerMenu($("#div_power"))
powermenu.new_power_menu()


if audio_play_status
    mediacontrol = new MediaControl()
    $("#div_media_control").appendChild(mediacontrol.element)
    mediacontrol.keydown_listener()


if not is_livecd
    s = new SwitchUser()
    s.button_switch()
    $("#div_switchuser").appendChild(s.element)
