module gui.pageview;

debug(gui) import std.stdio;
debug(cmd) import std.stdio;
import std.string;
import std.array;
import env;
import cell.cell;
import cell.table;
import cell.contentbox;
import cell.refer;
import cell.textbox;
// import cell.rangebox;
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

// 主要なGrid領域
// view と guiに纏わる操作を分離したい
final class PageView : DrawingArea{
private:
    GtkAllocation holding; // この2つの表すのは同じもの
    Rect holding_area;  // 内部処理はこちらを使う

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
        if(interpreter.state == InputState.edit)
        {
            manip_table.im_commit_to_box(str);
            queueDraw();
        }
    }
    void preedit_changed(IMContext imc){
        if(interpreter.state == InputState.edit)
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
        if(interpreter.state == InputState.edit)
        {
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
        imm.focusIn();
        return true;
    }
    bool focus_out(Event ev,Widget w){
        imm.focusOut();
        return true;
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
        assert(holding_area.w > 0);
        assert(holding_area.h > 0);
        }
    body{
        getAllocation(holding);
        holding_area.set_by(holding);
    }
    void set_view_size(){
        in_view.set_range(in_view.offset,
                cast(int)(holding_area.w/gridSpace),
                cast(int)(holding_area.h/gridSpace));
    }
    Rect back;
    RectDrawer backdrw;
    void backDesign(Context cr){
        back = new Rect(0,0,holding_area.w,holding_area.h);
        back.set_color(orenge);
        backdrw = new RectDrawer(back);

        backdrw.clip(cr);
    }
    bool show_contents_border = true;
    void renderTable(Context cr){
        debug(gui) writeln("@@@@ render table start @@@@");
        if(in_view.empty) return;

        foreach(content_in_view; in_view.get_contents())
        {
            if(content_in_view[1].empty()) continue;
            switch(content_in_view[0])
            {
                case "cell.textbox.TextBOX":
                    debug(gui) writeln("render textbox");
                        if(show_contents_border)
                        {
                            render_text.render_fill(cr,cast(TextBOX)content_in_view[1],Color(linen,96));
                            render_text.render_grid(cr,content_in_view[1],Color(gold,128),1);
                        }
                        render(cr,cast(TextBOX)content_in_view[1]);
                    break;
                default:
                    debug(gui) writeln("something wrong");
                    break;
            }
        }

        // render_text 全くふさわしくないけど、これ以外今ない、問題もない
        render_text.render_grid(cr,manip_table.get_target(),manip_box_color,manipLineWidth);

        debug(gui) writeln("#### render table end ####");
    }
    void render(Context cr,TextBOX b){
        render_text.render(cr,b);
    }
    
    // ascii mode に切り替わったことを期待してみる
    // どうもIMContextの実装依存のよう
    bool draw_callback(Context cr,Widget widget){
        debug(gui) writeln("draw callback");
        backDesign(cr);
        if(grid_show_flg) renderGrid(cr);
        renderTable(cr);
        renderSelection(cr);
        renderFocus(cr);
        cr.resetClip(); // end of rendering
        debug(gui) writeln("end");
        return true;
    }
    void setGrid(){
        grid = new Lines();
        grid.set_color(grid_color);
        grid.set_width(grid_width);
        for(double y = 0; y < holding_area.h ; y += gridSpace)
        {
            auto start = new Point(0,y);
            auto end = new Point(holding_area.w,y);
            grid.add_line(new Line(start,end,grid_width));
        }
        for(double x = 0 ; x < holding_area.w ; x += gridSpace)
        {
            auto start = new Point(x,0);
            auto end = new Point(x, holding_area.h);
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
    void renderSelection(Context cr){
        renderGrids(cr,manip_table.select.get_cells(),
                selected_cell_border_color,selectedLineWidth);
    }
    void renderFillCell(Context cr,in Cell cell,in Color grid_color){
        Rect grid_rect = new Rect(get_x(cell),get_y(cell),gridSpace,gridSpace);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(grid_color);
        grid_drwer.fill(cr);
    }
    void when_sizeallocate(GdkRectangle* n,Widget w){
        set_holding_area();
        set_view_size();
        setGrid();
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
                break;
            case Direct.left:
                endp.x = startp.x;
                endp.y = startp.y + gridSpace;
                break;
            case Direct.up:
                endp.x = startp.x + gridSpace;
                endp.y = startp.y;
                break;
            case Direct.down:
                startp.y += gridSpace;
                endp.x = startp.x + gridSpace;
                endp.y = startp.y;
                break;
        }
        result = new Line(startp,endp);
        result.set_width(w);
        result.set_color(color);

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
        }
    body{ 
        void init_selecter(){
            select = new Rect(0,0,gridSpace,gridSpace);
            select_drwer = new RectDrawer(select);
        }
        void set_view_offset(){
            // TODO: set start_offset 
        }

        setProperty("can-focus",1);

        imm = new IMMulticontext();
        menu = new Menu();
        table = new BoxTable();
        manip_table = new ManipTable(table,this);
        interpreter = new InputInterpreter(manip_table,this,imm);
        holding_area = new Rect(0,0,200,200);

        in_view = new ReferTable(table,start_offset,1,1);

        addOnKeyPress(&interpreter.key_to_cmd);
        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        addOnRealize(&realize);
        addOnUnrealize(&unrealize);

        init_selecter();
        setGrid();
        render_text = new RenderTextBOX(this);

        addOnDraw(&draw_callback);
        addOnButtonPress(&onButtonPress);
        addOnSizeAllocate(&when_sizeallocate);
        imm.addOnCommit(&commit);
        imm.addOnPreeditChanged(&preedit_changed);
        imm.addOnPreeditStart(&preedit_start);
        imm.addOnPreeditEnd(&preedit_end);
        imm.addOnRetrieveSurrounding(&retrieve_surrounding);

        menu.append( new ImageMenuItem(StockID.CUT, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.COPY, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.PASTE, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.DELETE, cast(AccelGroup)null) );
        imm.appendMenuitems(menu);

        menu.attachToWidget(this, null);

        showAll();
    }
    void move_view(in Direct dir){
        in_view.move_area(dir);
    }
    void zoom_in(){
        ++gridSpace;
    }
    void zoom_out(){
        if(gridSpace)  --gridSpace;
    }
    void toggle_grid_show(){
        grid_show_flg = !grid_show_flg;
    }
    void toggle_boxborder_show(){
        show_contents_border = !show_contents_border;
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
    double get_x(in Cell c)const{ return (c.column - in_view.offset.column) * gridSpace ; }
    double get_y(in Cell c)const{ return (c.row - in_view.offset.row)* gridSpace ; }
    Point get_pos(Cell c){ return new Point(get_x(c),get_y(c)); }

    void renderFillBox(Context cr,in ContentBOX rb,const Color grid_color){
        immutable top_left = rb.top_left();
        Rect grid_rect = new Rect(get_x(top_left),get_y(top_left),gridSpace*rb.numof_col,gridSpace*rb.numof_row);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(grid_color);
        grid_drwer.fill(cr);
    }
    void renderStrokeBox(Context cr,const ContentBOX rb,const Color grid_color){
        immutable top_left = rb.top_left();
        Rect grid_rect = new Rect(get_x(top_left),get_y(top_left),gridSpace*rb.numof_col,gridSpace*rb.numof_row);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(grid_color);
        grid_drwer.stroke(cr);
    }
   // アクセサ
public:
    ReferTable get_view(){
        return in_view;
    }
    int get_gridSize()const{
        return gridSpace;
    }
    Cell get_view_max()const{
        return in_view.max_cell();
    }
}

