module gui.gui;

import derelict.sdl2.sdl;
import deimos.cairo.cairo;
import std.stdio;
import std.string;
import std.array;
import env;
import misc.draw_rect;
import misc.sdl_utils;
import cell.cell;
import cell.textbox;
import text.text;
import manip;
import misc.direct;
import std.algorithm;
import gui.textbox;
import shape.shape;
import shape.drawer;

SDL_Window* mainWin;
SDL_Renderer* mainRend;
immutable int start_size_w = 960;
immutable int start_size_h = 640;

class Window{
    SDL_Window* window;
    SDL_Surface* win_srf;
    cairo_t* cr;
    int width = start_size_w;
    int height = start_size_h;

    this(){
        window = SDL_CreateWindow(appname.toStringz,
                 SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,
                 width,height,SDL_WINDOW_SHOWN);
        win_srf = SDL_GetWindowSurface(window);
        update_window_size();
        set_context();
    }
    void Redraw(){
        foreach(ref widget; owned_widgets)
        {
             widget.backDesign();
             widget.renderBody();
        }
        SDL_UpdateWindowSurface(window);
        cairo_set_source_rgb(cr,0.22,0.22,0.2);
        cairo_paint(cr);
    }
    // Wiget の生成は Slite が行ってる
    Widget[] owned_widgets;
    void attach(Widget w){
        owned_widgets ~= w;
    }
    void update_window_size(){
        SDL_GetWindowSize(mainWin,&width,&height);
    }
    private void set_context(){
        auto surface = cairo_image_surface_create_for_data
            (cast(char*)win_srf.pixels,CairoFormat.ARGB32,width,height,win_srf.pitch);
         cr = cairo_create(surface);
    }
}

abstract class Widget{
    // Widgetは描き方を規定するが、
    // 描く必要があるときはWindowを通してWindowごとRedraw
    // 再ドローの必要があるかはWidgetが内包するものによる
    Window attached_window;
    cairo_t* cr;
    ubyte alpha; // Widget 全体の透過度 Widget自身が管理する
    this(Window win,int x,int y,int w_per_win,int h_per_win)
        out{
        assert( holding_area.w != 0 );
        assert( holding_area.h != 0 );
        assert( cr);
        if(alpha == 0) writeln("widget alpha is 0 !!");
        assert( attached_window !is null );
        }
    body{
        attached_window = win;
        cr = win.cr;

        alpha = alpha_master_value;
        holding_area = new Rect(
                attached_window.width * x / 100,
                attached_window.height * y / 100,
                attached_window.width * w_per_win / 100,
                attached_window.height * h_per_win / 100);
    }   
    Rect holding_area;
    void alpha_inc(){ ++alpha ; }
    void alpha_dec(){ --alpha ; }
    void alpha_set(ubyte val){ alpha = val; }
    void Shring(){}
    void Expand(){}
    void Notify(){}
    void backDesign(){}
    void renderBody(){}
}

class ControlPanel : Widget {
    Image deco;
    ImageDrawer idrawer;
    this(Window w){
        super(w,0,0,25,100);
        deco = new Image(control_deco,holding_area);
        idrawer = new ImageDrawer(cr,deco);
    }
    ~this(){
    }
    override void backDesign()
    {
        assert(idrawer);
        assert(deco);
        idrawer.clip();
    }
    void renderBody(){
        cairo_reset_clip(cr);
    }
}

class PageView : Widget {
    ManipTable manip_table; // tableに対する操作: 操作に伴う状態を読み取り描画する必要がある
    ContentBOX table;    // 描画すべき対象: 
    ReferBOX in_view;    // table にattachされた 表示領域

    RenderTextBOX render_text ;

    ubyte emphasizedLineWidth = 2;
    ubyte selectedLineWidth = 2;
    Color grid_color = Color(48,48,48,96);
    Color focused_grid_color = Color(255,0,0,64);
    Color selected_cell_border_color = Color(0,228,228,128);
    Color normal_focus_color = Color(0,255,255,128);
    Color selected_focus_color = Color(0,255,255,168);

    // Cell[] start_offset = [Cell(0,0)];
    this(Window w,ContentBOX ct,ManipTable uv, Cell start_offset = Cell(0,0))
        out{
            assert(cr);
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
            select_drwer = new RectDrawer(cr,select);
        }
        void init_drwer(){
            back = new Rect(holding_area);
            back.set_color(red);
            backdrw = new RectDrawer(cr,back);
            writefln("x:%f y:%f w:%f h:%f ",holding_area.x,holding_area.y,holding_area.w,holding_area.h);
        }
        void init_start_view(){
            // start_offset init TODO
        }

        super(w,25,0,75,100);
        manip_table = uv;
        table = ct;

        init_selecter();
        init_drwer();
        setGrid();
        in_view = new ReferBOX(table,start_offset,cast(int)(holding_area.w/gridSpace),cast(int)(holding_area.h/gridSpace));
        render_text =  new RenderTextBOX(this);
        update();
    }
    void set_in_view(){
        in_view.capture_to(in_view.offset,cast(int)(holding_area.w/gridSpace),cast(int)(holding_area.h/gridSpace));
    }
    Rect back;
    RectDrawer backdrw;
    void backDesign(){
        backdrw.clip();
    }
    void renderTable(){
        import std.stdio;
        set_in_view();
        if(!in_view.cells.keys.empty)
        foreach(box_in_view; in_view.cells)
        {
            if(auto tb = cast(TextBOX)box_in_view) 
                render_text.render(tb);
        }
    }
    int grid_length(int depth){ // 階層化に対応してる？？
        auto result = gridSpace;
        auto view_depth = in_view.recursive_depth();
        foreach(i;view_depth+1 .. depth)
            result /= 2;
        return result;
    }
    Lines grid;
    LinesDrawer drw_grid;
    int gridSpace =40; // □の1辺長
    ubyte grid_width = 1;

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
        drw_grid = new LinesDrawer(cr,grid);
    }
    private void renderGrid(){
        drw_grid.stroke();
    }
    void renderBody(){
        backDesign();
        renderGrid();
        renderTable();
        renderSelect();
        renderFocus();
        cairo_reset_clip(cr); // end of rendering
    }
    void renderFocus(){
        // 現在は境界色を変えてるだけだけど
        // 考えられる他の可能性ものために
        // cellの色を変えるとか（透過させるとか
        final switch(manip_table.mode)
        {
            case focus_mode.normal:
                emphasizeGrid(manip_table.focus,normal_focus_color,emphasizedLineWidth); break;
            case focus_mode.select:
                emphasizeGrid(manip_table.focus,selected_focus_color,emphasizedLineWidth); break;
            case focus_mode.edit:
                break;
        }
    }
    Rect select;
    RectDrawer select_drwer;
    void renderSelect(){
        emphasizeGrids(manip_table.select.cells.keys,
                selected_cell_border_color,selectedLineWidth);
    }
    private void emphasizeGrid(const Cell cell,const Color grid_color,const ubyte grid_width){
        Rect grid_rect = new Rect(get_x(cell),get_y(cell),gridSpace,gridSpace);
        auto grid_drwer = new RectDrawer(cr,grid_rect);

        grid_rect.set_color(grid_color);
        grid_drwer.fill();
    }
    private void emphasizeGrids(const Cell[] cells,const Color color,const ubyte grid_width){
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
        LinesDrawer drwer = new LinesDrawer(cr,perimeters);
        drwer.stroke();
    }
    double get_x(Cell c){ return c.column * gridSpace + holding_area.x; }
    double get_y(Cell c){ return c.row * gridSpace + holding_area.y; }
    // Point get_pos(Cell c){ return new Point(get_x(c),get_y(c)); }
    private Line CellLine(const Cell cell,const Direct dir,Color color,double w){
        auto startp = new Point();
        auto endp = new Point();
        startp.x = get_x(cell);
        startp.y = get_y(cell);
        Line result;
        final switch(dir)
        {   // 
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
    void update(){
        in_view.clear();
        in_view.capture_to(in_view.offset,cast(int)(holding_area.w/gridSpace), cast(int)(holding_area.h/gridSpace));
        set_in_view();
    }
    void table_check(){
        if(table.changed_flg){
            attached_window.Redraw();
            table.changed_flg = false;
        }
    }
}

