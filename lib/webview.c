/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/
#include "dwebview.h"
#include "jsextension.h"
#include "utils.h"

GtkWidget* create_web_container(bool normal, bool above)
{
    GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(gtk_main_quit), NULL);
    if (!normal)
        gtk_window_set_decorated(GTK_WINDOW(window), false);

    GdkScreen *screen = gdk_screen_get_default();
    GdkVisual *visual = gdk_screen_get_rgba_visual(screen);

    if (!visual)
        visual = gdk_screen_get_system_visual(screen);
    gtk_widget_set_visual(window, visual);

    /*if (normal) {*/
        /*gtk_widget_set_size_request(window, 800, 600);*/
        /*return window;*/
    /*}*/

    /*gtk_window_maximize(GTK_WINDOW(window));*/
    /*if (above)*/
        /*gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);*/
    /*else*/
        /*gtk_window_set_keep_below(GTK_WINDOW(window), FALSE);*/

    return window;
}

gboolean erase_background(GtkWidget* widget, 
        cairo_t *cr, gpointer data)
{ 
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    return FALSE;
}

static void add_ddesktop_class(WebKitWebView *web_view,
        WebKitWebFrame *frame, 
        gpointer context, 
        gpointer arg3, 
        gpointer user_data)
{
    JSGlobalContextRef jsContext = webkit_web_frame_get_global_context(frame);

    init_js_extension(jsContext, (void*)web_view);
}



WebKitWebView* inspector_create(WebKitWebInspector *inspector,
        WebKitWebView *web_view, gpointer user_data)
{
    GtkWidget* win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_widget_set_size_request(win, 800, 500);
    GtkWidget* web = webkit_web_view_new();
    gtk_container_add(GTK_CONTAINER(win), web);
    gtk_widget_show_all(win);
    return WEBKIT_WEB_VIEW(web);
}

static bool webview_key_release_cb(GtkWidget* webview, 
        GdkEvent* event, gpointer data)
{
    GdkEventKey *ev = (GdkEventKey*)event;
    switch (ev->keyval) {
        case GDK_KEY_F5: 
            webkit_web_view_reload(WEBKIT_WEB_VIEW(webview));
            break;
        case GDK_KEY_F12:
            {
                WebKitWebInspector *inspector = webkit_web_view_get_inspector(
                        WEBKIT_WEB_VIEW(webview));
                g_assert(inspector != NULL);
                WebKitDOMNode *node = 
                    (WebKitDOMNode*)webkit_web_view_get_dom_document(
                            (WebKitWebView*)webview);
                webkit_web_inspector_inspect_node(inspector, node);
                break;
            }
    }

    return FALSE;
}


static void
d_webview_init(DWebView *dwebview)
{
    WebKitWebView* webview = (WebKitWebView*)dwebview;
    webkit_web_view_set_transparent(webview, TRUE);

    /*g_signal_connect(G_OBJECT(webview), "draw",*/
           /*G_CALLBACK(_erase_background), NULL);*/


    g_signal_connect(G_OBJECT(webview), "window-object-cleared",
            G_CALLBACK(add_ddesktop_class), webview);

    g_signal_connect(webview, "key-release-event", 
            G_CALLBACK(webview_key_release_cb), NULL);

    WebKitWebInspector *inspector = webkit_web_view_get_inspector(
            WEBKIT_WEB_VIEW(webview));
    g_assert(inspector != NULL);
    g_signal_connect_after(inspector, "inspect-web-view", 
            G_CALLBACK(inspector_create), NULL);


}

GType d_webview_get_type(void)
{
    static GType type = 0;
    if (!type) {
        static const GTypeInfo info = {
            sizeof(DWebViewClass),
            NULL,
            NULL,
            NULL,//(GClassInitFunc)d_webview_class_init,
            NULL,
            NULL,
            sizeof(DWebView),
            0,
            (GInstanceInitFunc)d_webview_init,
        };

        type = g_type_register_static(WEBKIT_TYPE_WEB_VIEW,  "DWebView", &info, 0);
    }
    return type;
}



GtkWidget* d_webview_new()
{
    GtkWidget* webview = g_object_new(D_WEBVIEW_TYPE, NULL);
    WebKitWebSettings *setting = webkit_web_view_get_settings(WEBKIT_WEB_VIEW(webview));

    char* cfg_path = g_build_filename(g_get_user_config_dir(), 
            "deepin-desktop", NULL);
    g_object_set(G_OBJECT(setting), 
            /*"enable-default-context-menu", FALSE,*/
            "enable-developer-extras", TRUE, 
            /*"html5-local-storage-database-path", cfg_path,*/
            "enable-plugins", FALSE,
            "javascript-can-access-clipboard",

            NULL);
    webkit_set_web_database_directory_path(cfg_path);
    g_free(cfg_path);

    return webview;
}

GtkWidget* d_webview_new_with_uri(const char* uri)
{
    /*return g_object_new(D_WEBVIEW_TYPE, "uri", uri, NULL);*/
    GtkWidget* webview = d_webview_new();
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), uri);
    return webview;
}
