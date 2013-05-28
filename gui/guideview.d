module gui.guideview;

debug(gui) import std.stdio;
import gui.tableview;
import std.string;
import std.array;
import env;
import cell.cell;
import cell.table;
import cell.refer;
import cell.textbox;
import text.text;
import util.direct;
import std.algorithm;
import gui.textbox;
import shape.shape;
import shape.drawer;

import command.command;

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

import manip;

final class GuideView : DrawingArea,TableView{
private:
    int gridSpace = 24;
    GtkAllocation holding; // この2つの表すのは同じもの
    Rect holding_area;  // 内部処理はこちらを使う

    BoxTable table;    // 描画すべき個々のアイテムに対する
    TextBOX mode_indicator;

    // RenderImage render_image;
    RenderTextBOX render_text;

    ubyte renderdLineWidth = 2;
    Color _back_color = Color(moccasin,96);

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
        debug(gui) writeln("@@@@ render Guide table start @@@@");
        if(table.empty) return;

        debug(gui) writeln("#### render table end ####");
    }
    void renderColorBox(Context cr){
        int cnt_col;
        if(_selected_color)
        {
            // _selected_color.require_create_in(Cell(max_row()-2,2));
            _selected_color.set_rect();
            _selected_color.fill(cr);
        }
        foreach(cb; color_box)
        {
            // cb.require_create_in(Cell(max_row,cnt_col++));
            cb.fill(cr);
        }
    }
    bool draw_callback(Context cr,Widget widget){
        backDesign(cr);
        // renderTable(cr);
        renderColorBox(cr);
        cr.resetClip(); // end of rendering
        return true;
    }
    // 非常に怪しい。というか機能してない
    // 中の要素決まってから書き直す
    void when_sizeallocated(GdkRectangle* n,Widget w){
        immutable Min= Cell(15,8);
        immutable Max= Cell(35,10);
        const min_pos = get_pos(Min);
        const max_pos = get_pos(Max);

        set_holding_area();
        set_color_box();
        if(holding_area.w < min_pos[0])
            setSizeRequest(cast(int)min_pos[0],cast(int)min_pos[1]);
        else if(holding_area.h > max_pos[0])
            setSizeRequest(cast(int)max_pos[0],cast(int)max_pos[1]);
        debug(gui) writeln("holding w:",holding_area.w, "h:",holding_area.h);
    }
    ImageBOX[Color] color_box;
    ImageBOX _selected_color;
    RectDrawer color_back;
    immutable color_box_row = 9;
    ImageBOX color_back_color;
    void add_color(in Color c,bool clear=false){
        static int col;
        if(clear) col = 0;
        auto ib = new ImageBOX(table,this);
        ib.require_create_in(Cell(max_row(),col++));
        ib.set_circle();
        ib.set_color(c);
        color_box[c] = ib;
    }
    void set_color_box(){
        void clear(){
            foreach(c; color_box)
                c.remove_from_table();
            color_box.clear();
        }
        clear();
        color_back_color = new ImageBOX(table,this);
        color_back_color.hold_tl(Cell(max_row()-3,1),2,2);
        color_back_color.set_rect();
        color_back_color.set_color(oldlace);

        add_color(black,true);
        add_color(red);
        add_color(green);
        add_color(blue);
    }
    void select_color(in Color c){
        if(c !in color_box)
            add_color(c);
        _selected_color = color_box[c];
    }
    int max_row()const{
        return cast(int)(holding_area.h / gridSpace -1);
    }
    int max_col()const{
        return cast(int)(holding_area.w / gridSpace -1);
    }
public:
    this(){ 
        setProperty("can-focus",0);

        table = new BoxTable();
        holding_area = new Rect(0,0,200,200);
        render_text = new RenderTextBOX(this);
        // render_image = new RenderImage(this);

        set_color_box();

        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        addOnRealize(&realize);
        addOnUnrealize(&unrealize);

        addOnSizeAllocate(&when_sizeallocated);
        addOnDraw(&draw_callback);
        addOnButtonPress(&onButtonPress);

        showAll();
    }

    Rect select;
    RectDrawer select_drwer;
    double get_x(in Cell c)const{ return c.column * gridSpace ; }
    double get_y(in Cell c)const{ return c.row * gridSpace ; }

   // アクセサ
    int get_gridSize()const{
        return gridSpace;
    }
    const(Rect) get_holdingArea()const{
        return holding_area;
    }
}

