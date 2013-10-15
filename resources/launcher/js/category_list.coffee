_category = $("#category")

_select_category_timeout_id = 0
selected_category_id = ALL_APPLICATION_CATEGORY_ID
_create_category = (info) ->
    el = document.createElement('div')

    el.setAttribute('class', 'category_name')
    el.setAttribute('cat_id', info.ID)
    el.setAttribute('id', info.ID)
    el.innerText = info.Name

    el.addEventListener('click', (e) ->
        e.stopPropagation()
    )
    el.addEventListener('mouseover', (e)->
        e.stopPropagation()
        if info.ID != selected_category_id
            s_box.value = "" if s_box.value != ""
            _select_category_timeout_id = setTimeout(
                ->
                    grid_load_category(info.ID)
                    selected_category_id = info.ID
                , 25)
    )
    el.addEventListener('mouseout', (e)->
        if _select_category_timeout_id != 0
            clearTimeout(_select_category_timeout_id)
    )
    return el


category_column_adaptive_height = ->
    warp = _category.parentNode
    # add 20px for margin
    categories_height = _category.children.length * (_category.lastElementChild.clientHeight + 20)
    warp_height = window.screen.height - 100
    if categories_height > warp_height
        warp.style.overflowY = "scroll"
        warp.style.marginBottom = "#{GRID_MARGIN_BOTTOM}px"

# key: category id
# value: a list of Item's id which is in category
category_infos = []
_load_category_infos = (cat_id, sort_func)->
    if cat_id == ALL_APPLICATION_CATEGORY_ID
        frag = document.createDocumentFragment()
        category_infos[cat_id] = []
        for own key, value of applications
            frag.appendChild(value.element)
            category_infos[cat_id].push(key)
        grid.appendChild(frag)
    else
        info = DCore.Launcher.get_items_by_category(cat_id)
        category_infos[cat_id] = info

    sort_func(category_infos[cat_id])

hide_category = ->
    for own i of category_infos
        all_is_hidden = category_infos["#{i}"].every((el, idx, arr) ->
            applications[el].display_mode == "hidden"
        )
        if all_is_hidden and not Item.display_temp
            $("##{i}").style.display = "none"
            # i is a string, selected_category_id is a number
            # "==" in coffee is "===" in js
            if "" + selected_category_id == i
                selected_category_id = ALL_APPLICATION_CATEGORY_ID
            grid_load_category(selected_category_id)


show_category = ->
    for own i of category_infos
        not_all_is_hidden = category_infos["#{i}"].some((el, idx, arr) ->
            applications[el].display_mode != "hidden"
        )
        if not_all_is_hidden or Item.display_temp
            $("##{i}").style.display = "block"

sort_category_info = (sort_func)->
    sort_func(category_infos[ALL_APPLICATION_CATEGORY_ID], true)
    for own i of category_infos
        if i != "" + ALL_APPLICATION_CATEGORY_ID
            sort_func(category_infos[i])
    return

sort_method = "name"
init_category_list = ->
    if (_sort_method = DCore.Launcher.sort_method())?
        sort_method = _sort_method
    else
        DCore.Launcher.save_config('sort_method', sort_method)

    frag = document.createDocumentFragment()
    for info in DCore.Launcher.get_categories()
        c = _create_category(info)
        frag.appendChild(c)
        _load_category_infos(info.ID, sort_methods[sort_method])

    _category.appendChild(frag)

    category_column_adaptive_height()
