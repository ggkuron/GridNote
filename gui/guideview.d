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
    int _gridSpace = 24;
    GtkAllocation _holding; // この2つの表すのは同じもの
    Rect _holding_area;  // 内部処理はこちらを使う

    BoxTable _table;    // 描画すべき個々のアイテムに対する
    TextBOX _mode_indicator;

    RenderTextBOX _render_text;


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
        assert(_holding_area);
        }
        out{
        assert(_holding_area.w > 0);
        assert(_holding_area.h > 0);
        }
    body{
        getAllocation(_holding);
        _holding_area.set_by(_holding);
    }
    ImageBOX _back_color;
    Color _back_color_color = Color(moccasin,96);
    void backDesign(Context cr){
        _back_color.set_color(_back_color_color);
        _back_color.fill(cr);

        // shadow
        cr.setLineWidth(2);
        cr.moveTo(_holding_area.w-2,0);
        cr.lineTo(_holding_area.w-2,_holding_area.h);
        cr.set_color(Color(gray,128));
        cr.stroke();

        color_box_back.fill(cr);
    }
    bool show_contents_border = true;
    void renderTable(Context cr){
        debug(gui) writeln("@@@@ render Guide _table start @@@@");
        if(_table.empty) return;

        debug(gui) writeln("#### render _table end ####");
    }
    void renderColorBox(Context cr){
        int cnt_col;
        if(_selected_color_box)
        {
            _selected_color_box.fill(cr);
        }
        foreach(cb; color_box)
        {
            cb.fill(cr);
        }
    }
    bool draw_callback(Context cr,Widget widget){
        backDesign(cr);
        renderColorBox(cr);
        cr.resetClip(); // end of rendering
        return true;
    }
    // 非常に怪しい。というか機能してない?
    // 中の要素決まってから書き直す
    void when_sizeallocated(GdkRectangle* n,Widget w){
        immutable Min= Cell(15,8);
        immutable Max= Cell(35,10);
        const min_pos = get_pos(Min);
        const max_pos = get_pos(Max);

        set_holding_area();
        set_color_box();
        // _selected_color_box.require_create_in(Cell(max_row()-2,1));
        _selected_color_box.hold_tl(Cell(max_row()-3,1),2,2);
        _selected_color_box.set_rect();
        _selected_color_box.set_color(_selected_color);

        _back_color.hold_tl(Cell(0,0),max_col()+1,max_row()+1);
        _back_color.set_rect();

        if(_holding_area.w < min_pos[0])
            setSizeRequest(cast(int)min_pos[0],cast(int)min_pos[1]);
        else if(_holding_area.h > max_pos[0])
            setSizeRequest(cast(int)max_pos[0],cast(int)max_pos[1]);
        debug(gui) writeln("_holding w:",_holding_area.w, "h:",_holding_area.h);
    }
    ImageBOX[Color] color_box;
    ImageBOX _selected_color_box;
    RectDrawer color_back;
    immutable color_box_row = 9;
    ImageBOX color_box_back;
    // Color color_box_back;
    void add_color(in Color c,bool clear=false){
        static int col;
        if(clear) col = 0;
        auto ib = new ImageBOX(_table,this);
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
        color_box_back = new ImageBOX(_table,this);
        color_box_back.hold_tl(Cell(max_row()-3,0),max_col()+1,5);
        color_box_back.set_rect();
        color_box_back.set_color(Color(blue,50));

        add_color(black,true);
        add_color(red);
        add_color(green);
        add_color(blue);
        add_color(yellow);
    }
    Color _selected_color;
    void select_color(in Color c){
        if(c !in color_box)
            add_color(c);
        // _selected_color_box = color_box[c];
        _selected_color = c;
    }
    int max_row()const{
        return cast(int)(_holding_area.h / _gridSpace -1);
    }
    int max_col()const{
        return cast(int)(_holding_area.w / _gridSpace -1);
    }
public:
    this(){ 
        setProperty("can-focus",0);

        _table = new BoxTable();
        _holding_area = new Rect(0,0,200,200);
        _render_text = new RenderTextBOX(this);
        _selected_color_box = new ImageBOX(_table,this);
        _back_color = new ImageBOX(_table,this);

        set_color_box();

        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        addOnRealize(&realize);
        addOnUnrealize(&unrealize);

        addOnSizeAllocate(&when_sizeallocated);
        addOnDraw(&draw_callback);
        addOnButtonPress(&onButtonPress);

        showAll();

        select_color(blue);
    }

    double get_x(in Cell c)const{ return c.column * _gridSpace ; }
    double get_y(in Cell c)const{ return c.row * _gridSpace ; }

   // アクセサ
    int get_gridSize()const{
        return _gridSpace;
    }
    const(Rect) get_holdingArea()const{
        return _holding_area;
    }
}

