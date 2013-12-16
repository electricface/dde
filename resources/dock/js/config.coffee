MAX_SCALE = 1
ITEM_HEIGHT = 60.0
ITEM_WIDTH = 54.0

ICON_WIDTH = 48.0
ICON_HEIGHT = 48.0

DOCK_HEIGHT = 68.0
BOARD_HEIGHT = 40

BOARD_IMG_PATH = "img/board.png"

BOARD_IMG_MARGIN_BOTTOM = 6.0

INDICATER_WIDTH = ITEM_WIDTH

THREE_MARGIN_STEP = 3.0
TWO_MARGIN_STEP = 2.0


PREVIEW_BORDER_LENGTH = 5.0
PREVIEW_CANVAS_WIDTH = 190.0
PREVIEW_CANVAS_HEIGHT = 110.0
PREVIEW_WINDOW_WIDTH = 230.0
PREVIEW_WINDOW_HEIGHT = 160.0

#below should not modify
INDICATER_IMG_MARGIN_LEFT = "#{(ITEM_WIDTH - INDICATER_WIDTH) / ITEM_WIDTH * 100}%"
BOARD_IMG_MARGIN_LEFT = "#{((ITEM_WIDTH - ICON_WIDTH) / 2) / ITEM_WIDTH  * 100}%"

IN_INIT = true

NOT_FOUND_ICON = DCore.get_theme_icon("invalid-dock_app", 48)

ICON_SCALE = MAX_SCALE  #this will be modify on runtime

EMPTY_TRASH_ICON = "user-trash"
FULL_TRASH_ICON = "user-trash-full"

SHORT_INDICATOR = "img/indicator-short.svg"
LONG_INDICATOR = "img/indicator-long.svg"

PANEL_IMG = 'img/panel.svg'

ITEM_TYPE_NULL = ''
ITEM_TYPE_APP = "App"
ITEM_TYPE_APPLET = "Applet"
ITEM_TYPE_RICH_DIR = "RichDir"

WEEKDAY = ["SUN", "MON", "TUE", "WEN", "THU", "FRI", "STA"]

DIGIT_CLOCK =
    'bg':'img/digit-clock.svg'
    'id':'dde_digit_clock'
    'type': "digit"

ANALOG_CLOCK =
    'bg':'img/analog-clock.svg'
    'id':'dde_analog_clock'
    'type': "analog"
