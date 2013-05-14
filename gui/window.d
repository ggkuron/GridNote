module gui.window;

debug(gui) import std.stdio;
debug(cmd) import std.stdio;
import gui.pageview;
import std.string;
import std.array;
import env;
import cell.cell;
import cell.textbox;
import std.algorithm;
import shape.shape;
import shape.drawer;

import gtk.Box;

import gtkc.gdktypes;
import gtk.MainWindow;
import gtk.Widget;

import gtk.EventBox;
import gtk.ImageMenuItem;
import gtk.AccelGroup;

import gdk.Event;

import gtk.DrawingArea;
import gtk.Menu;
import cairo.Surface;
import cairo.Context;

immutable int start_size_w = 960;
immutable int start_size_h = 640;

class Window : MainWindow{
    int width = start_size_w;
    int height = start_size_h;

    this(){
        super(appname);
        setDefaultSize(width,height);

        auto box = new Box(GtkOrientation.HORIZONTAL,1);
        setEvents(EventMask.ALL_EVENTS_MASK);
        auto page_view = new PageView();
        box.packStart(page_view,1,1,0);

        add(box);
        // add(page_view);

        page_view.show();
        box.showAll();
        showAll();
    }
}


