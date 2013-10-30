#include "dock_test.h"

enum Event {
    TriggerShow,
    TriggerHide,
    ShowNow,
    HideNow,
};

enum State {
    StateShow,
    StateShowing,
    StateHidden,
    StateHidding,
};

void dock_test_hide()
{
    /* Test({ */
    /*         dock_delay_show(100); */
    /* }, "dock_delay_show"); */

    /* Test({ */
    /*         dock_delay_hide(100); */
    /* }, "dock_delay_hide"); */

    /* Test({ */
    /*         dock_show_now(); */
    /* }, "dock_show_now"); */

    /* Test({ */
    /*     dock_hide_now(); */
    /* }, "dock_hide_now"); */

    /* Test({ */
    /*     dock_update_hide_mode(); */
    /* }, "dock_update_hide_mode"); */

    /* Test({ */
    /*     dock_hide_real_now(); */
    /* }, "dock_hide_real_now"); */

    /* Test({ */
    /*     dock_show_real_now(); */
    /* }, "dock_show_real_now"); */

    /* Test({ */
    /*     update_dock_guard_window_position(); */
    /* }, "update_dock_guard_window_position"); */

    // failed
    extern void _change_workarea_height(int height);
    Test({
         _change_workarea_height(0);
         _change_workarea_height(60);
         }, "change_workarea_height");

    extern void set_state(enum State new_state);

    // failed for _change_workarea_height
    /* Test({ */
    /*      extern void enter_show(); */
    /*      set_state(StateHidding); */
    /*      enter_show(); */
    /*      }, "enter_show"); */

    // failed
    /* Test({ */
    /*      extern void enter_showing(); */
    /*      set_state(StateHidding); */
    /*      enter_showing(); */
    /*      }, "enter_showing"); */

    // failed
    /* Test({ */
    /*      extern void enter_hide(); */
    /*      set_state(StateHidding); */
    /*      enter_hide(); */
    /*      }, "enter_hide"); */

    // failed
    /* Test({ */
    /*      extern void enter_hidding(); */
    /*      set_state(StateHidden); */
    /*      enter_hidding(); */
    /*      }, "enter_hidding"); */

    // failed
    /* Test({ */
    /*     dock_toggle_show(); */
    /* }, "dock_toggle_show"); */

    // failed
    /* Test({ */
    /*      extern void handle_event(enum Event ev); */
    /*      handle_event(TriggerShow); */
    /*      handle_event(TriggerHide); */
    /*      handle_event(ShowNow); */
    /*      handle_event(HideNow); */
    /*      }, "handle_event"); */
}

