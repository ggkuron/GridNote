module gui.gui;

debug(gui) import std.stdio;
debug(cmd) import std.stdio;
import std.string;
import std.array;
import env;
import cell.cell;
import cell.textbox;
import text.text;
import manip;
import misc.direct;
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
import gtk.IMMulticontext;

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
        setDefaultSize(-1,-1);

        // auto box = new Box(GtkOrientation.HORIZONTAL,1);
        setEvents(EventMask.ALL_EVENTS_MASK);
        auto page_view = new PageView();
        // box.add(page_view);
        // box.setChildPacking(page_view,1,1,1,GtkPackType.START);

        // add(box);
        add(page_view);

        page_view.show();
        // box.showAll();
        showAll();
    }
}

// 主要なGrid領域
final class PageView : DrawingArea{
private:
    Rect holding_area;
    ManipTable manip_table; // tableに対する操作: 操作に伴う状態を読み取り描画する必要がある
    BoxTable table;    // 描画すべき対象: 
    ReferTable in_view;    // table にattachされた 表示領域
    Menu menu;

    InputInterpreter interpreter;
    RenderTextBOX render_text ;
    IMMulticontext imm;

    ubyte renderdLineWidth = 2;
    ubyte selectedLineWidth = 2;
    ubyte manipLineWidth = 2;
    Color grid_color = Color(48,48,48,96);
    Color selected_cell_border_color = Color("#00e4e4",128);
    Color normal_focus_color = Color(cyan,128);
    Color selected_focus_color = Color(cyan,168);
    Color manip_box_color = Color(darkorenge,128);

    bool grid_show_flg = true;
    Lines grid;
    LinesDrawer drw_grid;
    int gridSpace =32; // □の1辺長
    ubyte grid_width = 1;

    bool on_key_press(Event ev,Widget w){
        return interpreter.key_to_cmd(ev,w);
    }
    bool on_key_release(Event ev,Widget w){

        return cast(bool)imm.filterKeypress(ev.key());
    }
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
    void commit(string str,IMContext imc){
        if(interpreter.input_state == InputState.edit)
        {
            manip_table.im_commit_to_box(str);
            queueDraw();
        }
    }
    void preedit_changed(IMContext imc){
        if(interpreter.input_state == InputState.edit)
        {
            auto inputted_box = manip_table.get_target();
            render_text.prepare_preedit(imm,inputted_box);
            // レイアウトのことは投げる
            // IMContextごと
            queueDraw();
        }
    }
    // ascii mode に切り替わったことを期待してみる
    // どうもIMContextの実装依存ぽい
    void preedit_end(IMContext imc){
        if(interpreter.input_state == InputState.edit)
        {
            // imc.reset();
        }
    }
    void preedit_start(IMContext imc){
    }

    bool retrieve_surrounding(IMContext imc){
        auto surround = render_text.get_surrounding();
        imc.setSurrounding(surround[0],surround[1]);
        return true;
    }
    bool focus_in(Event ev,Widget w){
        grabFocus();
        return interpreter.focus_in(ev,w);
    }
    bool focus_out(Event ev,Widget w){
        return interpreter.focus_out(ev,w);
    }
    void realize(Widget w){
        imm.setClientWindow(getParentWindow());
    }
    void unrealize(Widget w){
        imm.setClientWindow(null);
    }
    void set_holding_area()
        in{
        assert(holding_area);
        }
        out{
        assert(holding_area.w >=0);
        assert(holding_area.h >=0);
        }
    body{
        holding_area.w = getWidth();
        holding_area.h = getHeight();
    }
    void set_in_view(){
        in_view.set_table_size(in_view.offset,
                cast(int)(holding_area.w/gridSpace),
                cast(int)(holding_area.h/gridSpace));
        in_view.data_sync();
    }
    void move_view(Direct dir){
        in_view.offset.move(dir);
    }
    Rect back;
    RectDrawer backdrw;
    void backDesign(Context cr){
        backdrw.clip(cr);
    }
    void renderTable(Context cr){
        debug(gui) writeln("render table start");
        set_in_view();
        if(in_view.get_box().empty) return;

        foreach(content_in_view; in_view.get_contents())
        {
            switch(content_in_view[0])
            {
                case "cell.textbox.TextBOX":
                    debug(gui) writeln("render textbox");
                    render(cr,cast(TextBOX)content_in_view[1]);
                    break;
                default:
                    debug(gui) writeln("something wrong");
                    break;
            }
        }
        // render_text 全くふさわしくないけど、これ以外今ない、またまったく問題もない
        render_text.render_grid(cr,manip_table.get_target(),manip_box_color,manipLineWidth);

        debug(gui) writeln("end");
    }
    void render(Context cr,TextBOX b){
        render_text.render(cr,b);
    }
    
    // ascii mode に切り替わったことを期待してみる
    // どうもIMContextの実装依存ぽい
    bool draw_callback(Context cr,Widget widget){
        debug(gui) writeln("draw callback");
        backDesign(cr);
        if(grid_show_flg) renderGrid(cr);
        renderTable(cr);
        renderSelect(cr);
        renderFocus(cr);
        cr.resetClip(); // end of rendering
        debug(gui) writeln("end");
        return true;
    }
    void setGrid(){
        grid = new Lines();
        grid.set_color(grid_color);
        grid.set_width(grid_width);
        for(double y = holding_area.y; y < holding_area.h + holding_area.h; y += gridSpace)
        {
            auto start = new Point(holding_area.x,y);
            auto end = new Point(holding_area.x+holding_area.w,y);
            grid.add_line(new Line(start,end,grid_width));
        }
        for(double x = holding_area.x ; x < holding_area.w + holding_area.x; x += gridSpace)
        {
            auto start = new Point(x,holding_area.y);
            auto end = new Point(x, holding_area.y + holding_area.h);
            grid.add_line(new Line(start,end,grid_width));
        }
        drw_grid = new LinesDrawer(grid);
    }

    void renderGrid(Context cr){
        drw_grid.stroke(cr);
    }
    void renderFocus(Context cr){
        // 現在は境界色を変えてるだけだけど
        // 考えられる他の可能性のために
        // e.g. cell内部色を変えるとか（透過させるとか
        final switch(manip_table.mode)
        {
            case focus_mode.normal:
                renderFillCell(cr,manip_table.select.focus,normal_focus_color); 
                break;
            case focus_mode.select:
                renderFillCell(cr,manip_table.select.focus,selected_focus_color); 
                break;
            case focus_mode.edit:
                // renderFillCell(cr,manip_table.select.focus,selected_focus_color); 
                // Text編集中,IMに任せるため
                break;
        }
    }
    void renderSelect(Context cr){
        renderGrids(cr,manip_table.select.get_box(),
                selected_cell_border_color,selectedLineWidth);
    }
    void renderFillCell(Context cr,const Cell cell,const Color grid_color){
        Rect grid_rect = new Rect(get_x(cell),get_y(cell),gridSpace,gridSpace);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(grid_color);
        grid_drwer.fill(cr);
    }

    void update(){
        set_in_view();
    }
    Line CellLine(const Cell cell,const Direct dir,Color color,double w){
        auto startp = new Point();
        auto endp = new Point();
        startp.x = get_x(cell);
        startp.y = get_y(cell);
        Line result;
        final switch(dir)
        {   
            case Direct.right:
                startp.x += gridSpace;
                endp.x = startp.x;
                endp.y = startp.y + gridSpace;
                result = new Line(startp,endp);
                result.set_width(w);
                result.set_color(color);
                break;
            case Direct.left:
                endp.x = startp.x;
                endp.y = startp.y + gridSpace;
                result = new Line(startp,endp);
                result.set_color(color);
                result.set_width(w);
                break;
            case Direct.up:
                endp.x = startp.x + gridSpace;
                endp.y = startp.y;
                result = new Line(startp,endp);
                result.set_color(color);
                result.set_width(w);
                break;
            case Direct.down:
                startp.y += gridSpace;
                endp.x = startp.x + gridSpace;
                endp.y = startp.y;
                result = new Line(startp,endp);
                result.set_color(color);
                result.set_width(w);
                break;
        }
        return result;
    }

public:
    this(Cell start_offset = Cell(0,0))
        out{
        assert(table);
        assert(in_view);
        assert(render_text);
        assert(select);
        assert(select_drwer);
        assert(back);
        assert(backdrw);
        }
    body{ 
        void init_selecter(){
            select = new Rect(0,0,gridSpace,gridSpace);
            select_drwer = new RectDrawer(select);
        }
        void init_drwer(){
            back = new Rect(holding_area);
            back.set_color(orenge);
            backdrw = new RectDrawer(back);
            debug(gui) writefln("x:%f y:%f w:%f h:%f ",holding_area.x,holding_area.y,holding_area.w,holding_area.h);
        }
        void set_view_offset(){
            // TODO: set start_offset 
        }

        imm = new IMMulticontext();
        menu = new Menu();
        table = new BoxTable();
        setProperty("can-focus",1);
        holding_area = new Rect(0,0,2000,2000);
        auto setting = getSettings();
        // set_holding_area();

        manip_table = new ManipTable(table);
        interpreter = new InputInterpreter(manip_table,this,imm);

        int num_of_gird_x = cast(int)(holding_area.w/gridSpace);
        int num_of_grid_y = cast(int)(holding_area.h/gridSpace);
        in_view = new ReferTable(table,start_offset,num_of_gird_x,num_of_grid_y);

        addOnKeyPress(&interpreter.key_to_cmd);
        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        addOnRealize(&realize);
        addOnUnrealize(&unrealize);
        debug(gui) writefln("holding %f %f",holding_area.w,holding_area.h);

        init_selecter();
        init_drwer();
        setGrid();
        render_text =  new RenderTextBOX(this);

        addOnDraw(&draw_callback);
        addOnButtonPress(&onButtonPress);
        imm.addOnCommit(&commit);
        imm.addOnPreeditChanged(&preedit_changed);
        imm.addOnPreeditStart(&preedit_start);
        imm.addOnPreeditEnd(&preedit_end);
        imm.addOnRetrieveSurrounding(&retrieve_surrounding);

        menu = new Menu();
        menu.append( new ImageMenuItem(StockID.CUT, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.COPY, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.PASTE, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.DELETE, cast(AccelGroup)null) );
        imm.appendMenuitems(menu);

        menu.attachToWidget(this, null);

        showAll();
    }

    void zoom_in(){
        ++gridSpace;
    }
    void zoom_out(){
        if(gridSpace)  --gridSpace;
    }
    void switch_grid_show(){
        grid_show_flg = !grid_show_flg;
    }
    Rect select;
    RectDrawer select_drwer;
    void renderFillGrids(Context cr,const Cell[] cells,const Color color){
        foreach(c; cells)
        {
            renderFillCell(cr,c,color);
        }
    }
    void renderGrids(Context cr,const Cell[] cells,const Color color,const ubyte grid_width){
        bool[Direct] adjacent_info(const Cell[] cells,const Cell searching){
            if(cells.empty) assert(0);
            bool[Direct] result;
            foreach(dir; Direct.min .. Direct.max+1){ result[cast(Direct)dir] = false; }

            foreach(a; cells)
            {
                if(a.column == searching.column)
                {   // adjacent to up or down
                    if(a.row == searching.row-1)  result[Direct.up] = true; else
                    if(a.row == searching.row+1)  result[Direct.down] = true;
                } 
                if(a.row == searching.row)
                {
                    if(a.column == searching.column-1) result[Direct.left] = true; else
                    if(a.column == searching.column+1) result[Direct.right] = true;
                }
            }
            return result;
        }
        if(cells.empty) return;

        Lines perimeters = new Lines;
        perimeters.set_color(color);
        perimeters.set_width(selectedLineWidth);

        foreach(c; cells)
        {
            const auto ad_info = adjacent_info(cells,c);
            foreach(n; Direct.min .. Direct.max+1 )
            {
                auto dir = cast(Direct)n;
                if(!ad_info[dir]){ // 隣接してない方向の境界を書く
                    perimeters.add_line(CellLine(c,dir,selected_cell_border_color,grid_width));
                }
            }
        }
        LinesDrawer drwer = new LinesDrawer(perimeters);
        drwer.stroke(cr);
    }
    double get_x(const Cell c)const{ return c.column * gridSpace + holding_area.x; }
    double get_y(const Cell c)const{ return c.row * gridSpace + holding_area.y; }
    Point get_pos(Cell c){ return new Point(get_x(c),get_y(c)); }

   // アクセサ
public:
    ReferTable get_view(){
        return in_view;
    }
    int get_gridSize()const{
        return gridSpace;
    }
}

