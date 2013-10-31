com_dir = ../../common/js
com_coffee = ${com_dir}/module.coffee ${com_dir}/utils.coffee ${com_dir}/selector.coffee ${com_dir}/widget.coffee ${com_dir}/animation.coffee

all: ${com_coffee} config.coffee signal.coffee search_bar.coffee item.coffee \
    hidden_icon_list.coffee grid.coffee category_column.coffee \
    container.coffee launcher.coffee main.coffee
	coffee -cj launcher.js $^
