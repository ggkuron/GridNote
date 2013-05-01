module gui.gui;

debug(gui) import std.stdio;
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
import gtk.VBox;
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
        // page_view.show();
        add(page_view);
        // box.show();
        showAll();
    }
}

class PageView : DrawingArea{
    Rect holding_area;
    ManipTable manip_table; // tableに対する操作: 操作に伴う状態を読み取り描画する必要がある
    BoxTable table;    // 描画すべき対象: 
    ReferTable in_view;    // table にattachされた 表示領域
    Menu menu;

    InputInterpreter interpreter;
    RenderTextBOX render_text ;

    ubyte emphasizedLineWidth = 2;
    ubyte selectedLineWidth = 2;
    Color grid_color = Color(48,48,48,96);
    Color focused_grid_color = Color(255,0,0,64);
    Color selected_cell_border_color = Color(0,228,228,128);
    Color normal_focus_color = Color(0,255,255,128);
    Color selected_focus_color = Color(0,255,255,168);

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
            back.set_color(red);
            backdrw = new RectDrawer(back);
            debug(gui) writefln("x:%f y:%f w:%f h:%f ",holding_area.x,holding_area.y,holding_area.w,holding_area.h);
        }
        void set_view_offset(){
            // TODO: set start_offset 
        }

        menu = new Menu();
        table = new BoxTable();
        setProperty("can-focus",1);
        holding_area = new Rect(0,0,2000,2000);
        // resetStyle();
        // set_holding_area();

        manip_table = new ManipTable(table);
        interpreter = new InputInterpreter(manip_table,this);

        int num_of_gird_x = cast(int)(holding_area.w/gridSpace);
        int num_of_grid_y = cast(int)(holding_area.h/gridSpace);
        in_view = new ReferTable(table,start_offset,num_of_gird_x,num_of_grid_y);

        addOnKeyPress(&interpreter.key_to_cmd);
        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        debug(gui) writefln("holding %f %f",holding_area.w,holding_area.h);

        init_selecter();
        init_drwer();
        setGrid();
        render_text =  new RenderTextBOX(this);

        addOnDraw(&draw_callback);
    }
    bool focus_in(Event ev,Widget w){
        grabFocus();
        return interpreter.focus_in(ev,w);
    }
    bool focus_out(Event ev,Widget w){
        return interpreter.focus_out(ev,w);
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
        in_view.set_table(in_view.offset,
                cast(int)(holding_area.w/gridSpace),
                cast(int)(holding_area.h/gridSpace));
    }
    Rect back;
    RectDrawer backdrw;
    void backDesign(Context cr){
        backdrw.clip(cr);
    }
    void renderTable(Context cr){
        set_in_view();
        if(!in_view.get_box().empty)
        foreach(content_in_view; in_view.get_contents())
        {
            switch(content_in_view[0])
            {
                case "TextBOX":
                    render(cr,cast(TextBOX)content_in_view[1]);
                default:
                    break;
            }
        }
    }
    void render(Context cr,TextBOX b){
        render_text.render(cr,b);
    }
    // 階層化構造 has gone
    // Cell.Cellの構造が歪まない方法思いつくまで封印
    // int grid_length(int depth){ // 階層化に対応してる？？
    //     auto result = gridSpace;
    //     auto view_depth = in_view.recursive_depth();
    //     foreach(i;view_depth+1 .. depth)
    //         result /= 2;
    //     return result;
    // }
    Lines grid;
    LinesDrawer drw_grid;
    int gridSpace =40; // □の1辺長
    ubyte grid_width = 1;
    public int get_gridSize()const{
        return gridSpace;
    }
    void zoom_in(){
        ++gridSpace;
    }
    void zoom_out(){
        if(!gridSpace) return;
        --gridSpace;
    }

    private void setGrid(){
        grid = new Lines();
        grid.set_color(grid_color);
        grid.set_width(grid_width);
        for(double y = holding_area.y; y < holding_area.h+ holding_area.h; y += gridSpace)
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
    private void renderGrid(Context cr){
        drw_grid.stroke(cr);
    }
    public bool draw_callback(Context cr,Widget widget){
        debug(gui) writeln("draw callback");
        backDesign(cr);
        renderGrid(cr);
        renderTable(cr);
        renderSelect(cr);
        renderFocus(cr);
        cr.resetClip(); // end of rendering
        return true;
    }
    void renderFocus(Context cr){
        // 現在は境界色を変えてるだけだけど
        // 考えられる他の可能性のために
        // e.g. cellの色を変えるとか（透過させるとか
        final switch(manip_table.mode)
        {
            case focus_mode.normal:
                emphasizeGrid(cr,manip_table.select.focus,normal_focus_color,emphasizedLineWidth); 
                break;
            case focus_mode.select:
                emphasizeGrid(cr,manip_table.select.focus,selected_focus_color,emphasizedLineWidth); 
                break;
            case focus_mode.edit:
                emphasizeGrid(cr,manip_table.select.focus,selected_focus_color,emphasizedLineWidth); 
                break;
        }
    }
    Rect select;
    RectDrawer select_drwer;
    void renderSelect(Context cr){
        emphasizeGrids(cr,manip_table.select.get_box(),
                selected_cell_border_color,selectedLineWidth);
    }
    private void emphasizeGrid(Context cr,const Cell cell,const Color grid_color,const ubyte grid_width){
        Rect grid_rect = new Rect(get_x(cell),get_y(cell),gridSpace,gridSpace);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(grid_color);
        grid_drwer.fill(cr);
    }
    private void emphasizeGrids(Context cr,const Cell[] cells,const Color color,const ubyte grid_width){
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
            foreach(dir; Direct.min .. Direct.max+1 )
            {
                if(!ad_info[cast(Direct)dir]){ // 隣接してない方向の境界を書く
                    perimeters.add_line(CellLine(c,cast(Direct)dir,selected_cell_border_color,grid_width));
                }
            }
        }
        LinesDrawer drwer = new LinesDrawer(perimeters);
        drwer.stroke(cr);
    }
    double get_x(const Cell c)const{ return c.column * gridSpace + holding_area.x; }
    double get_y(const Cell c)const{ return c.row * gridSpace + holding_area.y; }
    Point get_pos(Cell c){ return new Point(get_x(c),get_y(c)); }

    private Line CellLine(const Cell cell,const Direct dir,Color color,double w){
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
    private void update(){
        set_in_view();
    }
}

