module gui.guideview;

debug(guid) import std.stdio;
import std.string;
import std.array;
import env;
import cell.cell;
import cell.table;
import cell.refer;
import cell.textbox;
import text.text;
import manip;
import util.direct;
import std.algorithm;
import gui.textbox;
import shape.shape;
import shape.drawer;

import command.command;
import gtk.Box;

import gtkc.gdktypes;
import gtk.MainWindow;
import gtk.Widget;
import gtk.IMContext;

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

final class GuideView : DrawingArea{
private:
    GtkAllocation holding; // この2つの表すのは同じもの
    Rect holding_area;  // 内部処理はこちらを使う

    BoxTable table;    // 描画すべき対象: 
    ReferTable in_view;    // table にattachされた 表示領域
    Menu menu;

    InputInterpreter interpreter;
    RenderTextBOX render_text ;

    ubyte renderdLineWidth = 2;
    Color grid_color = Color(48,48,48,96);
    Color selected_cell_border_color = Color("#00e4e4",128);
    Color normal_focus_color = Color(cyan,128);
    Color selected_focus_color = Color(cyan,168);
    Color manip_box_color = Color(darkorenge,128);

    bool onButtonPress(Event event, Widget widget)
    {
        if ( event.type == EventType.BUTTON_PRESS )
        {
            GdkEventButton* buttonEvent = event.button;

            if ( buttonEvent.button == 3)
            {
                menu.showAll();
                menu.popup(buttonEvent.button, buttonEvent.time);
                return true;
            }
        }
        return false;
    }
    bool focus_in(Event ev,Widget w){
        return true;
    }
    bool focus_out(Event ev,Widget w){
        return true;
    }
    void realize(Widget w){
    }
    void unrealize(Widget w){
    }
    void set_holding_area()
        in{
        assert(holding_area);
        }
        out{
        assert(holding_area.w > 0);
        assert(holding_area.h > 0);
        }
    body{
        getAllocation(holding);
        holding_area.set_by(holding);
    }
    void set_view_size(){
    }
    Rect back;
    RectDrawer backdrw;
    void backDesign(Context cr){
        backdrw.clip(cr);
    }
    bool show_contents_border = true;
    void renderTable(Context cr){
    //    debug(gui) writeln("@@@@ render table start @@@@");
    //    if(in_view.empty) return;

    //    foreach(content_in_view; in_view.get_contents())
    //    {
    //        if(show_contents_border)
    //        {
    //            render_text.render_fill(cr,content_in_view[1],Color(linen,96));
    //            render_text.render_grid(cr,content_in_view[1],Color(gold,128),1);
    //        }

    //        switch(content_in_view[0])
    //        {
    //            case "cell.textbox.TextBOX":
    //                debug(gui) writeln("render textbox");
    //                render(cr,cast(TextBOX)content_in_view[1]);
    //                break;
    //            default:
    //                debug(gui) writeln("something wrong");
    //                break;
    //        }
    //    }
    //    render_text.render_grid(cr,manip_table.get_target(),manip_box_color,manipLineWidth);

    //    debug(gui) writeln("#### render table end ####");
    }
    void render(Context cr,TextBOX b){
        render_text.render(cr,b);
    }
    
    bool draw_callback(Context cr,Widget widget){
        backDesign(cr);
        renderTable(cr);
        cr.resetClip(); // end of rendering
        return true;
    }

    void renderFillCell(Context cr,const Cell cell,const Color grid_color){
        // Rect grid_rect = new Rect(get_x(cell),get_y(cell),gridSpace,gridSpace);
        // auto grid_drwer = new RectDrawer(grid_rect);

        // grid_rect.set_color(grid_color);
        // grid_drwer.fill(cr);
    }
    void when_sizeallocate(GdkRectangle* n,Widget w){
        set_holding_area();
        set_view_size();
    }

public:
    this(Cell start_offset = Cell(0,0))
        out{
        assert(back);
        assert(backdrw);
        }
    body{ 
        void init_drwer(){
            back = new Rect(holding_area);
            back.set_color(orenge);
            backdrw = new RectDrawer(back);
            debug(gui) writefln("x:%f y:%f w:%f h:%f ",holding_area.x,holding_area.y,holding_area.w,holding_area.h);
        }
        setProperty("can-focus",0);

        menu = new Menu();
        table = new BoxTable();
        holding_area = new Rect(0,0,start_size_w,start_size_h);

        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        addOnRealize(&realize);
        addOnUnrealize(&unrealize);

        init_drwer();
        addOnDraw(&draw_callback);
        addOnButtonPress(&onButtonPress);
        addOnSizeAllocate(&when_sizeallocate);

        menu.append( new ImageMenuItem(StockID.CUT, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.COPY, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.PASTE, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.DELETE, cast(AccelGroup)null) );

        menu.attachToWidget(this, null);

        showAll();
    }

    Rect select;
    RectDrawer select_drwer;
    void renderFillGrids(Context cr,const Cell[] cells,const Color color){
        foreach(c; cells)
        {
            renderFillCell(cr,c,color);
        }
    }
   // アクセサ
public:
}

