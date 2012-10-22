#include "xdg_misc.h"
#include <gtk/gtk.h>
#include "dwebview.h"
#include "utils.h"
#include "X_misc.h"

GtkWidget* container = NULL;
int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);
    set_default_theme("Deepin");
    set_desktop_env_name("GNOME");

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);

    char* path = get_html_path("dock");
    GtkWidget *webview = d_webview_new_with_uri(path);
    g_free(path);

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));
    gtk_window_set_skip_pager_hint(GTK_WINDOW(container), TRUE);
    gtk_window_move(GTK_WINDOW(container), 0, 900-50);

    gtk_window_set_keep_above(GTK_WINDOW(container), TRUE);

    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    gtk_window_resize(GTK_WINDOW(container), 1440, 50);
    gtk_widget_show_all(container);
    gtk_main();
    return 0;
}

void set_notify_area_allocation()
{
}