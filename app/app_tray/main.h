#ifndef __TRAY_H__
#define __TRAY_H__


#include <gtk/gtk.h>

#define PANEL_HEIGHT 24
#define SHADOW_WIDTH 5
#define TRAY_HEIGHT (PANEL_HEIGHT + SHADOW_WIDTH)

GdkWindow* TRAY_GDK_WINDOW();

#endif /* end of include guard: __TRAY_H__ */

