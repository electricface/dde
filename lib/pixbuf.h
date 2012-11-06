#ifndef _PIXBUF_H__
#define _PIXBUF_H__
char* generate_directory_icon(const char* p1, const char* p2, const char* p3, const char* p4);
char* get_data_uri_by_path(const char* path);

#include <gdk-pixbuf/gdk-pixbuf.h>
char* get_data_uri_by_pixbuf(GdkPixbuf* pixbuf);
char* pixbuf_to_canvas_data(GdkPixbuf* pixbuf);
#endif
