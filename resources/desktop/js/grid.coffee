#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#             Cole <phcourage@gmail.com>
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

# workarea size
s_width = 0
s_height = 0

# workarea offset
s_offset_x = 0
s_offset_y = 0

#grid block size for items
grid_item_width = 0
grid_item_height = 0

# gird size
cols = 0
rows = 0

# grid html element
div_grid = null
# grid occupy table
o_table = null

# all file items on desktop
all_item = new Array
# special items on desktop
speical_item = new Array
# all widget items on grid
widget_item = new Array
# all selected items on desktop
selected_item = new Array
# the last widget which been operated last time
last_widget = ""

# store the buffer canvas
drag_canvas = null
# store the context of the buffer canvas
drag_context = null
# store the left top point of drag image start point
drag_start = {x : 0, y: 0}

# store the area selection box for grid
sel = null

# we need to ignore keyup event when rename files
ingore_keyup_counts = 0

# store the pos the user pop the context menu
rightclick_pos = {clientX : 0, clientY : 0}

#templates
TEMPATES_LENGTH = 0
TEMPLATES_FILE_ID_FIRST = 20

#draw icon and title to canvas surface
draw_icon_on_canvas = (canvas_cantext, start_x, start_y, icon, title)->
    # draw icon
    #echo "draw_icon_on_canvas"
    if icon.src.length
        canvas_cantext.shadowColor = "rgba(0, 0, 0, 0)"
        canvas_cantext.drawImage(
            icon,
            start_x + (_ITEM_WIDTH_ - icon.width) / 2,
            start_y,
            icon.width,
            icon.height)
    # draw text
    canvas_cantext.shadowOffsetX = 1
    canvas_cantext.shadowOffsetY = 1
    canvas_cantext.shadowColor = "rgba(0, 0, 0, 1.0)"
    canvas_cantext.shadowBlur = 1.5
    canvas_cantext.font = "small san-serif"
    canvas_cantext.fillStyle = "rgba(255, 255, 255, 1.0)"
    canvas_cantext.textAlign = "center"
    rest_text = title
    line_number = 0
    while rest_text.length > 0
        if rest_text.length < 10 then n = rest_text.length
        else n = 10
        m = canvas_cantext.measureText(rest_text.substr(0, n)).width
        if m == 90
        else if m > 90
            --n
            while n > 0 and canvas_cantext.measureText(rest_text.substr(0, n)).width > 90
                --n
        else
            ++n
            while n <= rest_text.length and canvas_cantext.measureText(rest_text.substr(0, n)).width < 90
                ++n

        line_text = rest_text.substr(0, n)
        rest_text = rest_text.substr(n)

        canvas_cantext.fillText(line_text, start_x + 46, start_y + 64 + line_number * 14, 90)
        ++line_number


# calc the best row and col number for desktop
calc_row_and_cols = (wa_width, wa_height) ->
    #echo "calc_row_and_cols"
    # #echo "_ITEM_WIDTH_:" + _ITEM_WIDTH_ + ",_ITEM_HEIGHT_:" + _ITEM_HEIGHT_
    # only 4  9 16 25  but 16 is the best 
    _GRID_WIDTH_INIT_ = _ITEM_WIDTH_
    _GRID_HEIGHT_INIT_ = _ITEM_HEIGHT_
    # #echo "wa_width:" + wa_width + ",wa_height:" + wa_height
    # #echo "_GRID_WIDTH_INIT_:" + _GRID_WIDTH_INIT_ + ",_GRID_HEIGHT_INIT_:" + _GRID_HEIGHT_INIT_
    n_cols = Math.floor(wa_width / _GRID_WIDTH_INIT_)
    n_rows = Math.floor(wa_height / _GRID_HEIGHT_INIT_)
    xx = wa_width % _GRID_WIDTH_INIT_
    yy = wa_height % _GRID_HEIGHT_INIT_
    # #echo "xx:" + xx + ",yy:" + yy
    g_ITEM_WIDTH_ = _GRID_WIDTH_INIT_ + Math.floor(xx / n_cols)
    g_ITEM_HEIGHT_ = _GRID_HEIGHT_INIT_ + Math.floor(yy / n_rows)
    # #echo "n_cols:" + n_cols +  ",n_rows:" + n_rows + ",g_ITEM_WIDTH_:" + g_ITEM_WIDTH_ + ",g_ITEM_HEIGHT_:" + g_ITEM_HEIGHT_

    return [n_cols, n_rows, g_ITEM_WIDTH_, g_ITEM_HEIGHT_]
    # return [n_cols, n_rows, _GRID_WIDTH_INIT_, _GRID_HEIGHT_INIT_]  


# update the coordinate of the gird_div to fit the size of the workarea
update_gird_position = (wa_x, wa_y, wa_width, wa_height) ->
    #echo "update_gird_position"
    s_offset_x = wa_x
    s_offset_y = wa_y
    s_width = wa_width
    s_height = wa_height

    div_grid.style.left = s_offset_x
    div_grid.style.top = s_offset_y
    div_grid.style.width = s_width
    div_grid.style.height = s_height

    [cols, rows, grid_item_width, grid_item_height] = calc_row_and_cols(s_width, s_height)
    return


load_position = (id) ->
    #echo "load_position"
    if typeof(id) != "string" then #echo "error load_position #{id}"

    pos = localStorage.getObject("id:" + id)

    if pos == null then return null

    if cols > 0 and pos.x + pos.width - 1 >= cols then pos.x = cols - pos.width
    if rows > 0 and pos.y + pos.height - 1 >= rows then pos.y = rows - pos.height
    pos


save_position = (id, pos) ->
    #echo "save_position"
    assert("string" == typeof(id), "[save_position]id not string")
    assert(pos != null, "[save_position]pos null")
    localStorage.setObject("id:" + id, pos)
    return


discard_position = (id) ->
    #echo "discard_position"
    assert("string" == typeof(id), "[discard_position]id not string")
    localStorage.removeItem("id:" + id)
    return


clear_all_positions = ->
    #echo "clear_all_positions"
    for i in all_item
        localStorage.removeItem("id:#{i}")
    for i in speical_item
        localStorage.removeItem("id:#{i}")
    return


compare_pos_top_left = (base, pos) ->
    #echo "compare_pos_top_left"
    if pos.y < base.y
        -1
    else if pos.y >= base.y and pos.y <= base.y + base.height - 1
        if pos.x < base.x
            -1
        else if pos.x >= base.x and pos.x <= base.x + base.width - 1
            0
        else
            1
    else
        1


compare_pos_rect = (base1, base2, pos) ->
    top_left = Math.min(base1.x, base2.x)
    top_right = Math.max(base1.x, base2.x)
    bottom_left = Math.min(base1.y, base2.y)
    bottom_right = Math.max(base1.y, base2.y)
    if top_left <= pos.x <= top_right and bottom_left <= pos.y <= bottom_right
        true
    else
        false


calc_pos_to_pos_distance = (base, pos) ->
    #echo "calc_pos_to_pos_distance"
    Math.sqrt(Math.pow(Math.abs(base.x - pos.x), 2) + Math.pow(Math.abs(base.y - pos.y), 2))


find_item_by_coord_delta = (start_item, x_delta, y_delta) ->
    #echo "find_item_by_coord_delta"
    items = speical_item.concat(all_item)
    pos = start_item.get_pos()
    while true
        if x_delta != 0
            pos.x += x_delta
            if x_delta > 0 and pos.x > cols then break
            else if x_delta < 0 and pos.x < 0 then break
        if y_delta != 0
            pos.y += y_delta
            if y_delta > 0 and pos.y > rows then break
            else if y_delta < 0 and pos.y < 0 then break

        if detect_occupy(pos) == false then continue

        #optimization by looking up o_table to get ID
        for i in items
            w = Widget.look_up(i)
            if not w? then continue
            find_pos = w.get_pos()
            if (find_pos.x <= pos.x <= find_pos.x + find_pos.width - 1) and (find_pos.y <= pos.y <= find_pos.y + find_pos.height - 1)
                return w
    null


init_occupy_table = ->
    #echo "init_occupy_table"
    o_table = new Array()
    for i in [0..cols]
        o_table[i] = new Array(rows)
    return


clear_occupy = (id, info) ->
    #echo "clear_occupy"
    if info.x == -1 or info.y == -1 then return true
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            if o_table[info.x+i][info.y+j] == id
                o_table[info.x+i][info.y+j] = null
            else
                return false
    return true


set_occupy = (id, info) ->
    #echo "set_occupy"
    assert(info != null, "[set_occupy] get null info")
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            o_table[info.x+i][info.y+j] = id
    return


detect_occupy = (info, id = null) ->
    #echo "detect_occupy"
    assert(info != null, "[detect_occupy]get null info")
    if (info.x + info.width) > cols  or (info.y + info.height) > rows
        return true
    for i in [0..info.width - 1] by 1
        for j in [0..info.height - 1] by 1
            if o_table[info.x+i][info.y+j] and o_table[info.x+i][info.y+j] != id
                return true
    return false


clear_occupy_table = ->
    #echo "clear_occupy_table"
    item_list = all_item.concat(speical_item)
    for i in item_list
        if (w = Widget.look_up(i))?
            pos = w.get_pos()
            clear_occupy(w.get_id(), pos)
            pos.x = -1
            pos.y = -1
            w.set_pos(pos)
    return


find_free_position = (w, h) ->
    #echo "find_free_position"
    info = {x:0, y:0, width:w, height:h}
    for i in [0..cols - 1]
        for j in [0..rows - 1]
            if not o_table[i][j]?
                info.x = i
                info.y = j
                return info
    return null


pixel_to_pos = (x, y, w, h) ->
    index_x = Math.min(Math.floor(x / grid_item_width), (cols - 1))
    index_y = Math.min(Math.floor(y / grid_item_height), (rows - 1))

    # index_x = Math.min(Math.floor(x / _ITEM_WIDTH_), (cols - 1))
    # index_y = Math.min(Math.floor(y / _ITEM_HEIGHT_), (rows - 1))
    coord_to_pos(index_x, index_y, w, h)


coord_to_pos = (pos_x, pos_y, w, h) ->
    {x : pos_x, y : pos_y, width : w, height : h}


move_to_position = (widget, info) ->
    # #echo "move_to_position"
    old_info = widget.get_pos()

    widget.move(info.x * grid_item_width, info.y * grid_item_height)
    widget.move(info.x * _ITEM_WIDTH_, info.y * _ITEM_HEIGHT_)

    if (old_info.x > -1) and (old_info.y > -1) then clear_occupy(widget.get_id(), old_info)
    set_occupy(widget.get_id(), info)

    widget.set_pos(info)
    save_position(widget.get_id(), info)
    return


# need optimization
move_to_anywhere = (widget) ->
    # #echo "move_to_anywhere"
    pos = load_position(widget.get_id())
    if pos? and not detect_occupy(pos, widget.get_id())
        move_to_position(widget, pos)
    else
        old_size = widget.get_pos()
        new_pos = find_free_position(old_size.width, old_size.height)
        move_to_position(widget, new_pos)
    return


move_to_somewhere = (widget, pos) ->
    # #echo "move_to_somewhere"
    if not detect_occupy(pos, widget.get_id())
        move_to_position(widget, pos)
    else
        pos = find_free_position(pos.width, pos.height)
        move_to_position(widget, pos)
    return


place_desktop_items = ->
    # #echo "place_desktop_items"
    clear_occupy_table()

    total_item = speical_item.concat(all_item)
    not_founds = []
    for i in total_item
        if not (w = Widget.look_up(i))?
            echo "uncleaned item #{i}"
            continue

        pos = w.get_pos()
        if (pos.x > -1) and (pos.y > -1) # we have a place
            if not detect_occupy(pos, w.get_id())
                move_to_somewhere(w, pos)
        else if (old_pos = load_position(i)) != null # we get position remembered in localStorage
            move_to_somewhere(w, old_pos)
        else
            not_founds.push(i)

    for i in not_founds
        w = Widget.look_up(i)
        if w? then move_to_anywhere(w)
    return


sort_list_by_name_from_id = (id1, id2) ->
    # #echo "sort_list_by_name_from_id"
    w1 = Widget.look_up(id1)
    w2 = Widget.look_up(id2)
    if not w1? or not w2?
        echo "we get error here[sort_list_by_name_from_id]"
        return id1.localeCompare(id2)
    else
        return w1.get_name().localeCompare(w2.get_name())


sort_list_by_mtime_from_id = (id1, id2) ->
    # #echo "sort_list_by_mtime_from_id"
    w1 = Widget.look_up(id1)
    w2 = Widget.look_up(id2)
    if not w1? or not w2?
        echo "we get error here[sort_list_by_mtime_from_id]"
        return w1.localeCompare(w2)
    else
        return w1.get_mtime() - w2.get_mtime()


sort_desktop_item_by_func = (func) ->
    # #echo "sort_desktop_item_by_func"
    clear_all_positions()

    item_ordered_list = all_item.concat()
    item_ordered_list.sort(func)

    clear_occupy_table()

    for i in speical_item
        if (w = Widget.look_up(i))?
            old_pos = w.get_pos()
            old_pos.x = -1
            old_pos.y = -1
            w.set_pos(old_pos)
            move_to_anywhere(w)

    for i in item_ordered_list
        if (w = Widget.look_up(i))?
            old_pos = w.get_pos()
            old_pos.x = -1
            old_pos.y = -1
            w.set_pos(old_pos)
            move_to_anywhere(w)
    return


menu_sort_desktop_item_by_name = ->
    sort_desktop_item_by_func(sort_list_by_name_from_id)
    return


menu_sort_desktop_item_by_mtime = ->
    sort_desktop_item_by_func(sort_list_by_mtime_from_id)
    return


create_entry_to_new_item = (entry) ->
    # #echo "create_entry_to_new_item"
    w = Widget.look_up(DCore.DEntry.get_id(entry))
    if not w? then w = create_item(entry)

    cancel_all_selected_stats()
    pos = pixel_to_pos(rightclick_pos.clientX, rightclick_pos.clientY, 1, 1)
    move_to_somewhere(w, pos)
    all_item.push(w.get_id())
    set_item_selected(w)
    update_selected_item_drag_image()
    w.item_rename()


menu_create_new_folder = (name_add_before) ->
    entry = DCore.Desktop.new_directory(name_add_before)
    create_entry_to_new_item(entry)


menu_create_new_file = (name_add_before) ->
    entry = DCore.Desktop.new_file(name_add_before)
    create_entry_to_new_item(entry)

menu_create_templates = (id) ->
    templates = DCore.DEntry.get_templates_files()
    name_add_before = _("Untitled") + " "
    switch id
        when TEMPLATES_FILE_ID_FIRST then menu_create_new_folder(name_add_before)
        when TEMPLATES_FILE_ID_FIRST + 1 then menu_create_new_file(name_add_before)
        else
            id_num = id - TEMPLATES_FILE_ID_FIRST - 2
            for i in [0...templates.length] by 1
                if i == id_num
                    if (DCore.DEntry.create_templates(templates[i],name_add_before))
                        echo "create_templates finish!"
    return
# all DND event handlers
init_grid_drop = ->
    div_grid.addEventListener("drop", (evt) =>
        evt.preventDefault()
        evt.stopPropagation()

        file_uri = []
        tmp_copy = []
        #tmp_move = []

        if evt.dataTransfer.files.length == 0 # if the drop_target is internet files 
            xdg_target = evt.dataTransfer.getData("Text")
            enter_indexof = []
            enter_indexof[0] = 0
            k = 1
            for i in [0 ... xdg_target.length] by 1
                if xdg_target[i] == "\n"
                    enter_indexof[k++] = i
            for i in [0 ... enter_indexof.length - 1] by 1
                file_uri[i] = xdg_target.substring(enter_indexof[i],enter_indexof[i+1]-1)#  -1 means delete enter char 

            pos = pixel_to_pos(evt.clientX, evt.clientY, 1, 1)
            w = Math.sqrt(file_uri.length) + 1
            for i in [0 ... file_uri.length] by 1
                file = file_uri[i]
                if (f_e = DCore.DEntry.create_by_path(file))?
                    tmp_copy.push(f_e)
                    # only copy , not move
                    # if DCore.DEntry.should_move(f_e)
                    #     #echo "move"
                    #     tmp_move.push(f_e)
                    # else
                    #     #echo "copy"
                    #     tmp_copy.push(f_e)
                    # make items as much nearer as possible to the pos that user drag on
                    p = {x : 0, y : 0, width : 1, height : 1}
                    p.x = pos.x + (i % w)
                    p.y = pos.y + Math.floor(i / w)
                    if p.x >= cols or p.y >= rows then continue
                    save_position(DCore.DEntry.get_id(f_e), p) if not detect_occupy(p)
            # only copy , not move
            # if tmp_move.length
            #     DCore.DEntry.move(tmp_move, g_desktop_entry, true)
            if tmp_copy.length
                DCore.DEntry.copy(tmp_copy, g_desktop_entry)

            evt.dataTransfer.setData("Text",desktop_uri)

        else if not _IS_DND_INTERLNAL_(evt) and evt.dataTransfer.files.length > 0
            pos = pixel_to_pos(evt.clientX, evt.clientY, 1, 1)
            w = Math.sqrt(evt.dataTransfer.files.length) + 1
            for i in [0 ... evt.dataTransfer.files.length] by 1
                file = evt.dataTransfer.files[i]
                if (f_e = DCore.DEntry.create_by_path(file.path))?
                    tmp_copy.push(f_e)
                    # only copy , not move
#                    if DCore.DEntry.should_move(f_e)
                        #tmp_move.push(f_e)
                    #else
                        #tmp_copy.push(f_e)

                    # make items as much nearer as possible to the pos that user drag on
                    p = {x : 0, y : 0, width : 1, height : 1}
                    p.x = pos.x + (i % w)
                    p.y = pos.y + Math.floor(i / w)
                    if p.x >= cols or p.y >= rows then continue
                    save_position(DCore.DEntry.get_id(f_e), p) if not detect_occupy(p)
            # only copy , not move
            #if tmp_move.length
                #DCore.DEntry.move(tmp_move, g_desktop_entry, true)
            if tmp_copy.length
                DCore.DEntry.copy(tmp_copy, g_desktop_entry)
        return
    )
    div_grid.addEventListener("dragover", (evt) =>
        evt.preventDefault()
        evt.stopPropagation()
        if evt.dataTransfer.getXDSPath().length > 0 # compatible with XDS protocol
            evt.dataTransfer.dropEffect = "copy"
        else if not _IS_DND_INTERLNAL_(evt)
            evt.dataTransfer.dropEffect = "move"
        else
            evt.dataTransfer.dropEffect = "link"
        return
    )
    div_grid.addEventListener("dragenter", (evt) =>
        if evt.dataTransfer.getXDSPath().length > 0 # compatible with XDS protocol
            evt.dataTransfer.dropEffect = "copy"

        else if not _IS_DND_INTERLNAL_(evt)
            evt.dataTransfer.dropEffect = "move"
        else
            evt.dataTransfer.dropEffect = "link"
        return
    )
    div_grid.addEventListener("dragleave", (evt) =>
        evt.stopPropagation()
        return
    )


selected_copy_to_clipboard = ->
    tmp_list = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.modifiable == true
            tmp_list.push(w.get_entry())
    DCore.DEntry.clipboard_copy(tmp_list)


selected_cut_to_clipboard = ->
    # #echo "selected_cut_to_clipboard"
    tmp_list = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.modifiable == true
            tmp_list.push(w.get_entry())
            w.display_cut()
    DCore.DEntry.clipboard_cut(tmp_list)


paste_from_clipboard = ->
    # #echo "paste_from_clipboard"
    DCore.DEntry.clipboard_paste(g_desktop_entry)


item_dragstart_handler = (widget, evt) ->
    # #echo "item_dragstart_handler"
    all_selected_items = ""
    if selected_item.length > 0
        for i in [0 ... selected_item.length] by 1
            w = Widget.look_up(selected_item[i])
            if not w? or w.modifiable == false then continue
            path = w.get_path()
            if path.length > 0 
                all_selected_items += path + "\r\n"
        if all_selected_items.length > 2
            all_selected_items = all_selected_items.substring(0,all_selected_items.length-2)
        else 
            echo "warning:items path is null"
        evt.dataTransfer.setData("text/uri-list", all_selected_items)
        _SET_DND_INTERNAL_FLAG_(evt)
        evt.dataTransfer.effectAllowed = "all"

        pos = widget.get_pos()
        x = (pos.x - drag_start.x) * grid_item_width + (_ITEM_WIDTH_ / 2)
        y = (pos.y - drag_start.y) * grid_item_height + 26
        evt.dataTransfer.setDragCanvas(drag_canvas, x, y)

    else
        evt.dataTransfer.effectAllowed = "none"

    return


item_dragend_handler = (w, evt) ->
    # #echo "item_dragend_handler"
    if evt.dataTransfer.dropEffect == "link"
        old_pos = w.get_pos()
        new_pos = pixel_to_pos(evt.clientX, evt.clientY, 1, 1)
        coord_x_shift = new_pos.x - old_pos.x
        coord_y_shift = new_pos.y - old_pos.y

        if coord_x_shift == 0 and coord_y_shift == 0 then return

        far_pos = {x : 0, y : 0, width : 1, height : 1}

        if coord_x_shift == 0
            far_pos.x = new_pos.x
        else if coord_y_shift == 0
            far_pos.y = new_pos.y
        else
            k = (new_pos.y - old_pos.y) / (new_pos.x - old_pos.x)
            b = (old_pos.y * new_pos.x - old_pos.x * new_pos.y) / (new_pos.x - old_pos.x)
            if k < 0
                far_pos.x = (0 - b) / k
            else
                far_pos.y = b

        # sort selected items by distance from the base point
        ordered_list = new Array()
        distance_list = new Array()
        for i in selected_item
            if not (w = Widget.look_up(i))? then continue
            dis = calc_pos_to_pos_distance(far_pos, w.get_pos())
            for j in [0 ... distance_list.length]
                if dis < distance_list[j]
                    break
            ordered_list.splice(j, 0, i)
            distance_list.splice(j, 0, dis)

        if (coord_x_shift <= 0 and coord_y_shift > 0) or (coord_x_shift > 0 and coord_y_shift >= 0)
            ordered_list.reverse()

        for i in ordered_list
            if not (w = Widget.look_up(i))? then continue

            old_pos = w.get_pos()
            new_pos = coord_to_pos(old_pos.x + coord_x_shift, old_pos.y + coord_y_shift, 1, 1)

            if new_pos.x < 0 or new_pos.y < 0 or new_pos.x >= cols or new_pos.y >= rows then continue

            move_to_somewhere(w, new_pos) if not detect_occupy(new_pos, w.get_id())

        update_selected_item_drag_image()
    return


set_item_selected = (w, change_focus = true, add_top = false) ->
    #echo "set_item_selected"
    if w.selected == false
        w.item_selected()
        if add_top == true
            selected_item.unshift(w.get_id())
        else
            selected_item.push(w.get_id())

        if change_focus
            if last_widget != w.get_id()
                if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
                last_widget = w.get_id()
            if not w.has_focus then w.item_focus()
    return


set_all_item_selected = ->
    #echo "set_all_item_selected"
    for i in speical_item.concat(all_item)
        if selected_item.indexOf(i) >= 0 then continue
        w = Widget.look_up(i)
        if w? then set_item_selected(w, false)


cancel_item_selected = (w, change_focus = true) ->
    #echo "cancel_item_selected"
    i = selected_item.indexOf(w.get_id())
    if i < 0 then return false
    selected_item.splice(i, 1)
    w.item_normal()

    if change_focus and last_widget != w.get_id()
        if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
        last_widget = w.get_id()
        w.item_focus()
    return true


cancel_all_selected_stats = () ->
    #echo "cancel_all_selected_stats"
    Widget.look_up(i)?.item_normal() for i in selected_item
    selected_item.splice(0)
    return


update_selected_stats = (w, evt) ->
    #echo "update_selected_stats"
    if evt.ctrlKey
        if w.selected == true then cancel_item_selected(w)
        else set_item_selected(w)

    else if evt.shiftKey
        if selected_item.length > 1
            last_one_id = selected_item[selected_item.length - 1]
            selected_item.splice(selected_item.length - 1, 1)
            cancel_all_selected_stats()
            selected_item.push(last_one_id)

        if selected_item.length == 1
            end_pos = pixel_to_pos(evt.clientX, evt.clientY, 1, 1)
            start_pos = Widget.look_up(selected_item[0]).get_pos()

            ret = compare_pos_top_left(start_pos, end_pos)
            if ret < 0
                for w_id in speical_item.concat(all_item)
                    if not (val = Widget.look_up(w_id))? then continue
                    i_pos = Widget.look_up(w_id).get_pos()
                    if compare_pos_top_left(end_pos, i_pos) >= 0 and compare_pos_top_left(start_pos, i_pos) < 0
                        set_item_selected(val, true, true)
            else if ret == 0
                cancel_item_selected(selected_item[0])
            else
                for w_id in speical_item.concat(all_item)
                    if not (val = Widget.look_up(w_id))? then continue
                    i_pos = Widget.look_up(w_id).get_pos()
                    if compare_pos_top_left(start_pos, i_pos) > 0 and compare_pos_top_left(end_pos, i_pos) <= 0
                        set_item_selected(val, true, true)

        else
            set_item_selected(w)

    else
        n = selected_item.indexOf(w.get_id())
        if n < 0
            cancel_all_selected_stats()
            set_item_selected(w)

        if n >= 0
            selected_item.splice(n, 1)
            cancel_all_selected_stats()
            selected_item.push(w.get_id())
            if last_widget != w.get_id()
                if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
                last_widget = w.get_id()

    update_selected_item_drag_image()
    return


# draw selected item icons DND image on special html canvas
update_selected_item_drag_image = ->
    #echo "update_selected_item_drag_image"
    drag_draw_delay_timer = -1

    if selected_item.length == 0 then return

    pos = Widget.look_up(selected_item[0]).get_pos()
    top_left = {x : (cols - 1), y : (rows - 1)}
    bottom_right = {x : 0, y : 0}

    for i in selected_item
        if not (w = Widget.look_up(i))? then continue
        pos = w.get_pos()

        if top_left.x > pos.x then top_left.x = pos.x
        if bottom_right.x < pos.x then bottom_right.x = pos.x

        if top_left.y > pos.y then top_left.y = pos.y
        if bottom_right.y < pos.y then bottom_right.y = pos.y

    if top_left.x > bottom_right.x then top_left.x = bottom_right.x
    if top_left.y > bottom_right.y then top_left.y = bottom_right.y

    drag_canvas.width = (bottom_right.x - top_left.x + 1) * _ITEM_WIDTH_
    drag_canvas.height = (bottom_right.y - top_left.y + 1) * _ITEM_HEIGHT_

    for i in selected_item
        w = Widget.look_up(i)
        if not w? then continue

        pos = w.get_pos()
        pos.x -= top_left.x
        pos.y -= top_left.y

        start_x = pos.x * _ITEM_WIDTH_
        start_y = pos.y * _ITEM_HEIGHT_

        draw_icon_on_canvas(drag_context, start_x, start_y, w.item_icon, w.item_name.innerText)

    [drag_start.x, drag_start.y] = [top_left.x , top_left.y]
    return


is_selected_multiple_items = ->
    selected_item.length > 1


open_selected_items = ->
    #echo "open_selected_items"
    Widget.look_up(i)?.item_exec() for i in selected_item
    return


delete_selected_items = (real_delete) ->
    #echo "delete_selected_items"
    tmp = []
    for i in selected_item
        w = Widget.look_up(i)
        if w? and w.deletable == true then tmp.push(w.get_entry())

    return if tmp.length == 0
    if real_delete then DCore.DEntry.delete_files(tmp, true)
    else DCore.DEntry.trash(tmp)
    return


show_entries_properties = (entries) ->
    #echo "show_entries_properties"
    try
        if (entry =  DCore.DEntry.create_by_path("/usr/bin/deepin-nautilus-properties"))?
            DCore.DEntry.launch(entry, entries)
    catch e
    return


show_selected_items_properties = ->
    #echo "show_selected_items_properties"
    tmp = []
    for i in selected_item
        if (w = Widget.look_up(i))? then tmp.push(w.get_entry())
    show_entries_properties(tmp)
    return


compress_selected_items = ->
    #echo "compress_selected_items"
    tmp = []
    for i in selected_item
        if (w = Widget.look_up(i))? then tmp.push(w.get_entry())
    try
        DCore.DEntry.compress_files(tmp)
    catch e
    return


decompress_selected_items = ->
    #echo "decompress_selected_items"
    tmp = []
    for i in selected_item
        if (w = Widget.look_up(i))? then tmp.push(w.get_entry())
    try
        DCore.DEntry.decompress_files(tmp)
    catch e
    return


decompress_selected_items_here = ->
    #echo "decompress_selected_items_here"
    if selected_item?
        tmp = []
        for i in selected_item
            if (w = Widget.look_up(i))? then tmp.push(w.get_entry())
        try
            DCore.DEntry.decompress_files_here(tmp)
        catch e
        return
    else
        return

get_items_compressibility = ->
    # echo "get_items_compressibility"
    if selected_item?
        tmp = []
        for i in selected_item
            if (w = Widget.look_up(i))
                if(false == w.modifiable)
                    return 0
                else
                    tmp.push(w.get_entry())
        return DCore.DEntry.files_compressibility(tmp)
    else
        return 0



gird_left_mousedown = (evt) ->
    #echo "grid_left_mounsedown"
    evt.stopPropagation()
    if evt.button == 0 and evt.ctrlKey == false and evt.shiftKey == false
        cancel_all_selected_stats()
        if last_widget.length > 0 then Widget.look_up(last_widget)?.item_blur()
    return


grid_right_click = (evt) ->
    #echo "grid_right_click"
    evt.stopPropagation()
    rightclick_pos.clientX = evt.clientX
    rightclick_pos.clientY = evt.clientY
    if evt.ctrlKey == false and evt.shiftKey == false
        cancel_all_selected_stats()

    templates = []
    templates_menu = []
    templates = DCore.DEntry.get_templates_files()
    templates_menu.push([TEMPLATES_FILE_ID_FIRST, _("_Folder")])
    templates_menu.push([TEMPLATES_FILE_ID_FIRST + 1, _("_Text document")])
    TEMPATES_LENGTH = 2 + templates.length
    for i in [0...templates.length] by 1
        templates_name = DCore.DEntry.get_name(templates[i])
        templates_id = i + 22
        templates_menu.push([templates_id,templates_name])

    menus = []
    menus.push([_("_Sort by"), [
                [11, _("_Name")],
                [12, _("Last modified _time")]
            ]
        ])
    menus.push([_("_New"), templates_menu])
    # warning: the templates id can > 30 ,so ,the menu 3 couldnot has child menu id 31\32\33
    menus.push([3, _("Open in _terminal")])
    menus.push([4, _("_Paste"), DCore.DEntry.can_paste()])
    menus.push([])
    menus.push([5, _("_Display settings")])
    menus.push([6, _("D_esktop settings")])
    menus.push([7, _("Pe_rsonalize")])

    div_grid.parentElement.contextMenu = build_menu(menus)
    return


grid_do_itemselected = (evt) ->
    switch evt.id
        when 11 then menu_sort_desktop_item_by_name()
        when 12 then menu_sort_desktop_item_by_mtime()
        when 3 then DCore.Desktop.run_terminal()
        when 4 then paste_from_clipboard()
        when 5 then DCore.Desktop.run_deepin_settings("display")
        when 6 then DCore.Desktop.run_deepin_settings("desktop")
        when 7 then DCore.Desktop.run_deepin_settings("individuation")
        else 
            # warning: the TEMPATES_LENGTH + TEMPLATES_FILE_ID_FIRST must < 30 . 
            # if it > 30 ,and when menu 3 has child menu id 31\31\33,and this will be the same id with the templates id
            if evt.id > TEMPLATES_FILE_ID_FIRST - 1 && evt.id < TEMPATES_LENGTH + TEMPLATES_FILE_ID_FIRST
                menu_create_templates(evt.id)
            else
                echo "not implemented function #{evt.id},#{evt.title}"
    return


# handle up/down/left/right arrow keys to navigate between items
grid_do_keydown_to_shortcut = (evt) ->
    #echo "grid_do_keydown_to_shortcut"
    if rename_div_process_events then return
    if evt.keyCode >= 37 and evt.keyCode <= 40
        evt.stopPropagation()
        evt.preventDefault()

        if last_widget.length == 0 or not (w = Widget.look_up(last_widget))?
            w = Widget.look_up(_ITEM_ID_COMPUTER_)

        w_f = null
        if evt.keyCode == 37         # left arrow
            w_f = find_item_by_coord_delta(w, -1, 0)
        else if evt.keyCode == 38    # up arrow
            w_f = find_item_by_coord_delta(w, 0, -1)
        else if evt.keyCode == 39    # right arrow
            w_f = find_item_by_coord_delta(w, 1, 0)
        else if evt.keyCode == 40    # down arrow
            w_f = find_item_by_coord_delta(w, 0, 1)
        if not w_f? then return

        if evt.ctrlKey == true
            w.item_blur()
            w_f.item_focus()
            last_widget = w_f.get_id()

        else if evt.shiftKey == true
            if selected_item.length > 1
                start_item = selected_item[0]
                selected_item.splice(0, 1)
                cancel_all_selected_stats()
                selected_item.push(start_item)

            if selected_item.length == 1
                start_pos = Widget.look_up(selected_item[0]).get_pos()
                end_pos = w_f.get_pos()
                if compare_pos_top_left(start_pos, end_pos) < 0
                    pos_a = start_pos
                    pos_b = end_pos
                else
                    pos_b = start_pos
                    pos_a = end_pos
                for i in speical_item.concat(all_item)
                    if not (w_i = Widget.look_up(i))? then continue
                    item_pos = w_i.get_pos()
                    if compare_pos_rect(pos_a, pos_b, item_pos) == true
                        set_item_selected(w_i) if not w_i.selected

                if last_widget != w_f.get_id()
                    w.item_blur() if last_widget.length > 0 and (w = Widget.look_up(last_widget))?
                    last_widget = w_f.get_id()
            else
                w_f.item_selected()
        else
            cancel_all_selected_stats()
            set_item_selected(w_f)
    return


# handle shortcuts keys
grid_do_keyup_to_shrotcut = (evt) ->
    #echo "grid_do_keyup_to_shrotcut"
    if rename_div_process_events then return
    msg_disposed = false
    if ingore_keyup_counts > 0
        --ingore_keyup_counts
        msg_disposed = true

    else if evt.keyCode == 65    # CTRL+A
        if evt.ctrlKey == true and evt.shiftKey == false and evt.altKey == false
            set_all_item_selected()
            msg_disposed = true

    else if evt.keyCode == 88    # CTRL+X
        if evt.ctrlKey == true and evt.shiftKey == false and evt.altKey == false
            selected_cut_to_clipboard()
            msg_disposed = true

    else if evt.keyCode == 67    # CTRL+C
        if evt.ctrlKey == true and evt.shiftKey == false and evt.altKey == false
            selected_copy_to_clipboard()
            msg_disposed = true

    else if evt.keyCode == 86    # CTRL+V
        if evt.ctrlKey == true and evt.shiftKey == false and evt.altKey == false
            paste_from_clipboard()
            msg_disposed = true

    else if evt.keyCode == 46    # Delete
        if evt.ctrlKey == false and evt.altKey == false
            delete_selected_items(evt.shiftKey == true)
            msg_disposed = true

    else if evt.keyCode == 113   # F2
        if evt.ctrlKey == false and evt.shiftKey == false and evt.altKey == false
            if selected_item.length == 1
                w = Widget.look_up(selected_item[0])
                if w? then w.item_rename()
            msg_disposed = true

    else if evt.keyCode == 32    # space
        if evt.ctrlKey == true
            if last_widget.length > 0 and (w = Widget.look_up(last_widget))?
                if w.selected == false
                    set_item_selected(w)
                    w.item_focus() if not w.has_focus
                else
                    cancel_item_selected(w)
            msg_disposed = true

    if msg_disposed == true
        evt.stopPropagation()
        evt.preventDefault()
    return


grid_do_keypress_to_shrotcut = (evt) ->
    #echo "grid_do_keypress_to_shrotcut"
    if rename_div_process_events then return
    evt.stopPropagation()
    evt.preventDefault()
    if evt.keyCode == 13    # Enter
        if evt.ctrlKey == false and evt.shiftKey == false and evt.altKey == false
            if selected_item.length > 0
                Widget.look_up(last_widget)?.item_exec()
    return


create_item_grid = ->
    #echo "create_item_grid"
    div_grid = document.createElement("div")
    div_grid.setAttribute("id", "item_grid")
    document.body.appendChild(div_grid)
    update_gird_position(s_offset_x, s_offset_y, s_width, s_height)
    init_grid_drop()
    div_grid.parentElement.addEventListener("mousedown", gird_left_mousedown)
    div_grid.parentElement.addEventListener("contextmenu", grid_right_click)
    div_grid.parentElement.addEventListener("itemselected", grid_do_itemselected)
    div_grid.parentElement.addEventListener("keydown", grid_do_keydown_to_shortcut)
    div_grid.parentElement.addEventListener("keyup", grid_do_keyup_to_shrotcut)
    div_grid.parentElement.addEventListener("keypress", grid_do_keypress_to_shrotcut)
    sel = new Mouse_Select_Area_box(div_grid.parentElement)

    drag_canvas = document.createElement("canvas")
    drag_context = drag_canvas.getContext('2d')
    return


class Mouse_Select_Area_box
    constructor : (parentElement) ->
        @parent_element = parentElement
        @element = document.createElement("div")
        @element.setAttribute("id", "mouse_select_area_box")
        @element.style.display = "none"
        @parent_element.appendChild(@element)
        @parent_element.addEventListener("mousedown", @mousedown_event)

    destory : =>
        @parent_element.removeChild(@element)

    mousedown_event : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        if evt.button == 0
            @parent_element.addEventListener("mousemove", @mousemove_event)
            @parent_element.addEventListener("mouseup", @mouseup_event)
            @parent_element.addEventListener("contextmenu", @contextmenu_event, true)
            @start_point = evt
            @start_pos = pixel_to_pos(evt.clientX - s_offset_x, evt.clientY - s_offset_y, 1, 1)
            @last_pos = @start_pos
            @total_item = speical_item.concat(all_item)
            
        return

    contextmenu_event : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        return


    mousemove_event : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        sl = Math.min(Math.max(Math.min(@start_point.clientX, evt.clientX), s_offset_x), s_offset_x + s_width)
        st = Math.min(Math.max(Math.min(@start_point.clientY, evt.clientY), s_offset_y), s_offset_y + s_height)
        sw = Math.min(Math.abs(evt.clientX - @start_point.clientX), s_width - sl)
        sh = Math.min(Math.abs(evt.clientY - @start_point.clientY), s_height - st)
        @element.style.left = "#{sl}px"
        @element.style.top = "#{st}px"
        @element.style.width = "#{sw}px"
        @element.style.height = "#{sh}px"
        @element.style.display = "block"

        new_pos = pixel_to_pos(evt.clientX - s_offset_x, evt.clientY - s_offset_y, 1, 1)
        
        for i in @total_item
            if not (w = Widget.look_up(i))? then continue
            item_pos = w.get_pos()
            if compare_pos_rect(new_pos, @start_pos, item_pos) == true
                if w.selected == false then set_item_selected(w) 
            else
                if w.selected == true then cancel_item_selected(w)
            
        return


    mouseup_event : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        @parent_element.removeEventListener("mousemove", @mousemove_event)
        @parent_element.removeEventListener("mouseup", @mouseup_event)
        @parent_element.removeEventListener("contextmenu", @contextmenu_event, true)
        @element.style.display = "none"

        if selected_item.length > 0 then update_selected_item_drag_image()
        return

# fullscreen div for item renaming
rename_div_process_events = false
item_rename_div = document.createElement("div")
item_rename_div.setAttribute("class", "pop_rename")
item_rename_div.style.display = "none"
document.body.appendChild(item_rename_div)
item_rename_div.addEventListener("mousedown", (evt) ->
        evt.stopPropagation()
        return
)
item_rename_div.addEventListener("mouseup", (evt) ->
        evt.stopPropagation()
        return
)
item_rename_div.addEventListener("click", (evt) ->
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.item_complete_rename(true)
        return
)
item_rename_div.addEventListener("contextmenu", (evt) ->
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.item_complete_rename(true)
        return
)

item_rename_div.parentElement.addEventListener("keydown", (evt) ->
        if not rename_div_process_events then return
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.on_item_rename_keydown(evt)
        return
)
item_rename_div.parentElement.addEventListener("keypress", (evt) ->
        if  not rename_div_process_events then return
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.on_item_rename_keypress(evt)
        return
)
item_rename_div.parentElement.addEventListener("keyup", (evt) ->
        if  not rename_div_process_events then return
        evt.stopPropagation()
        if @id.length?
            if (w = Widget.look_up(@id))?
                w.on_item_rename_keyup(evt)
        return
)


move_widget_to_rename_div = (w) ->
    #echo "move_widget_to_rename_div"
    if rename_div_process_events == true then return
    w.element.style.left = "#{w.element.offsetLeft + s_offset_x - 1}px"
    w.element.style.top = "#{w.element.offsetTop + s_offset_y - 1}px"
    div_grid.removeChild(w.element)
    item_rename_div.appendChild(w.element)
    item_rename_div.setAttribute("id", w.get_id())
    item_rename_div.style.zIndex = 50
    item_rename_div.focus()
    item_rename_div.style.display = "block"
    rename_div_process_events = true
    return


move_widget_to_grid_after_rename = (w) ->
    #echo "move_widget_to_grid_after_rename"
    if rename_div_process_events == false then return
    w.element.style.left = "#{w.element.offsetLeft - s_offset_x - 1}px"
    w.element.style.top = "#{w.element.offsetTop - s_offset_y - 1}px"
    item_rename_div.removeChild(w.element)
    div_grid.appendChild(w.element)
    item_rename_div.style.zIndex = 0
    item_rename_div.blur()
    item_rename_div.style.display = "none"
    rename_div_process_events = false
    return
