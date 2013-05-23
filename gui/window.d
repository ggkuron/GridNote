module gui.window;

debug(gui) import std.stdio;
debug(cmd) import std.stdio;
import gui.pageview;
import gui.guideview;
import env;

import gtk.Box;

import gtk.MainWindow;
import gtk.Widget;

import gtk.EventBox;
import gtk.ImageMenuItem;
import gtk.AccelGroup;

import gtk.DrawingArea;
import gtk.Menu;

immutable int start_size_w = 480;
immutable int start_size_h = 480;

class Window : MainWindow{
    int width = start_size_w;
    int height = start_size_h;

    this(){
        super(appname);
        setDefaultSize(width,height);

        auto box = new Box(GtkOrientation.HORIZONTAL,1);
        setEvents(EventMask.ALL_EVENTS_MASK);
        auto page_view = new PageView();
        auto guide_view = new GuideView();
        guide_view.setSizeRequest(180,-1);
        page_view.setSizeRequest(900,-1);
        box.packStart(guide_view,1,1,0);
        box.packStart(page_view,1,1,0);

        add(box);
        // add(page_view);

        // page_view.show();
        // guide_view.show();
        box.showAll();
        showAll();
    }
}

