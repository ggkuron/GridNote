module gui.guideview;

debug(guid) import std.stdio;
import gui.tableview;
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

import cell.cell;
import cell.contentbox;
import cell.textbox;
import cell.imagebox;
import gui.imagebox;

final class GuideView : DrawingArea,TableView{
private:
    int gridSpace = 32;
    GtkAllocation holding; // この2つの表すのは同じもの
    Rect holding_area;  // 内部処理はこちらを使う

    BoxTable table;    // 描画すべき個々のアイテムに対する
    TextBOX mode_indicator;
    ImageBOX color_box;

    RenderImage render_image;
    RenderTextBOX render_text;

    ubyte renderdLineWidth = 2;
    Color _back_color = Color(darkcyan,96);

    bool onButtonPress(Event event, Widget widget)
    {
        if ( event.type == EventType.BUTTON_PRESS )
        {
            GdkEventButton* buttonEvent = event.button;

            if ( buttonEvent.button == 3)
            {
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
    Rect back;
    RectDrawer backdrw;
    void backDesign(Context cr){
        back = new Rect(0,0,holding_area.w,holding_area.h);
        back.set_color(_back_color);
        backdrw = new RectDrawer(back);
        backdrw.fill(cr);
        auto shadow = new Rect(holding_area.w-7,0,7,holding_area.h);
        shadow.set_color(Color(gray,128));
        backdrw = new RectDrawer(shadow);
        backdrw.fill(cr);
    }
    bool show_contents_border = true;
    void renderTable(Context cr){
        debug(gui) writeln("@@@@ render table start @@@@");
        if(table.empty) return;

        foreach(content; table.get_all_contents())
        {
            if(show_contents_border)
            {
            }

            switch(content[0])
            {
                case "cell.textbox.TextBOX":
                    debug(gui) writeln("render textbox");
                    break;
                default:
                    debug(gui) writeln("something wrong");
                    break;
            }
        }
        debug(gui) writeln("#### render table end ####");
    }
    
    bool draw_callback(Context cr,Widget widget){
        backDesign(cr);
        // renderTable(cr);
        cr.resetClip(); // end of rendering
        return true;
    }

    void FillCell(Context cr,const Cell cell,const Color grid_color){
        // Rect grid_rect = new Rect(get_x(cell),get_y(cell),gridSpace,gridSpace);
        // auto grid_drwer = new RectDrawer(grid_rect);

        // grid_rect.set_color(grid_color);
        // grid_drwer.fill(cr);
    }
    void when_sizeallocate(GdkRectangle* n,Widget w){
        set_holding_area();
    }

public:
    this()
        out{
        }
    body{ 
        setProperty("can-focus",0);

        table = new BoxTable();
        holding_area = new Rect(0,0,200,200);

        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        addOnRealize(&realize);
        addOnUnrealize(&unrealize);

        addOnDraw(&draw_callback);
        addOnButtonPress(&onButtonPress);
        addOnSizeAllocate(&when_sizeallocate);

        showAll();
    }

    Rect select;
    RectDrawer select_drwer;
    double get_x(in Cell c)const{ return c.column * gridSpace ; }
    double get_y(in Cell c)const{ return c.row * gridSpace ; }
    // Cellの順ではなく、x(column方向),y(row方向)順なのに注意
    double[2] get_pos(in Cell c)const{ return [get_x(c),get_y(c)]; }
    // Cellの座標と次のCellの座標、例えば入力Cell(5,5)に対してCell(5,5) とCell(6,6)の中間座標を返す
    // Cellに対する割り算には切り捨て方向に働きCell(5,5)/2 == Cell(2,2)になる。
    double[2] get_center_pos(in Cell c)const{ return [get_x(c) + gridSpace/2, get_y(c) + gridSpace/2]; }


   // アクセサ
    int get_gridSize()const{
        return gridSpace;
    }
}

