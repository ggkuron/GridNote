module gui.gui;

import derelict.sdl2.sdl;
import std.stdio;
import std.string;
import std.array;
import env;
import misc.draw_rect;
import misc.sdl_utils;
import cell.cell;
import manip;
import misc.direct;
import std.algorithm;

SDL_Window* mainWin;
SDL_Renderer* mainRend;
immutable int start_size_w = 960;
immutable int start_size_h = 640;

class Window{
    SDL_Window* window;
    SDL_Renderer* renderer;
    this(){
        window = SDL_CreateWindow(appname.toStringz,
                 SDL_WINDOWPOS_CENTERED,SDL_WINDOWPOS_CENTERED,
                 start_size_w,start_size_h,SDL_WINDOW_SHOWN);
        renderer = SDL_CreateRenderer(window,-1,SDL_RENDERER_ACCELERATED);
        update_window_size();
    }
    void Redraw(){
        SDL_RenderClear(renderer);
        foreach(ref widget; owned_widgets)
        {
            widget.backDesign();
            widget.renderBody();
        }
        SDL_RenderPresent(renderer);
    }

    // Wiget の生成は Slite が行ってる
    Widget[] owned_widgets;
    void attach(Widget w){
        owned_widgets ~= w;
    }
    int width = start_size_w,
        height= start_size_h;
    void update_window_size(){
        SDL_GetWindowSize(mainWin,&width,&height);
    }
}

abstract class Widget{
    // Widgetは描き方を規定するが、
    // 描く必要があるときはWindowを通してWindowごとRedraw
    // 再ドローの必要があるかはWidgetが内包するものによる
    Window attached_window;
    SDL_Renderer* renderer;
    ubyte alpha; // Widget 全体の透過度 Widget自身が管理する
    this(Window win,int x,int y,int w_per_win,int h_per_win)
    out{
        assert( holding_area.w != 0 );
        assert( holding_area.h != 0 );
        if(alpha == 0) writeln("widget alpha is 0 !!");
    }
    body{
        attached_window = win;
        renderer = win.renderer;
        alpha = alpha_master_value;
        assert( attached_window !is null );
        holding_area.x = attached_window.width * x / 100;
        holding_area.y = attached_window.height * y / 100;
        holding_area.w = attached_window.width * w_per_win / 100;
        holding_area.h = attached_window.height * h_per_win / 100;
    }    SDL_Rect holding_area;
    void alpha_inc(){ ++alpha ; }
    void alpha_dec(){ --alpha ; }
    void alpha_set(ubyte val){ alpha = val; }
    void Shring(){}
    void Expand(){}
    void Notify(){}
    abstract void backDesign(){}
    void renderBody(){}
}

class ControlPanel : Widget {
    SDL_Texture* deco;
    this(Window w){
        super(w,0,0,25,100);
        deco = createTexture(w.renderer,control_deco);
    }
    ~this(){
        SDL_DestroyTexture(deco);
    }
    void backDesign(){
        SDL_SetRenderDrawColor(renderer,128,128,128,255);
        SDL_RenderFillRect(renderer,&holding_area);
        drawRect(renderer,deco,holding_area);
    }
}

class PageView : Widget {
    ManipTable manip_table; // userの操作による効果を描画する役目
    CellTable table;    // 描画すべき対象

    ubyte emphasizedLineWidth = 2;
    ubyte selectedLineWidth = 2;
    SDL_Color grid_color = {48,48,48};
    SDL_Color emphasizedLineColor = {255,0,0};
    SDL_Color focused_grid_color = {255,0,0};
    SDL_Color selected_cell_border = {0,255,255};
    SDL_Color white = {255,255,255};
    ubyte grid_alpha = 255;

    this(Window w,CellTable ct,ManipTable uv){
        super(w,25,0,75,100);
        manip_table = uv;
        table = ct;
        grid_alpha = alpha;
    }
    void backDesign(){
        SDL_SetRenderDrawColor(renderer,96,96,96,255);
        SDL_RenderFillRect(renderer,&holding_area);
    }
    void showGrid(){
        SetRenderColor(renderer,grid_color,grid_alpha);
        SDL_Rect drw_rect = holding_area;
        drw_rect.h = 1;
        for(;drw_rect.y < holding_area.h; drw_rect.y += gridSpace)
        {
            SDL_RenderFillRect(renderer,&drw_rect);
        }
        drw_rect = holding_area;
        drw_rect.w = 1;
        for(;drw_rect.x < holding_area.w + holding_area.x; drw_rect.x += gridSpace)
        {
            SDL_RenderFillRect(renderer,&drw_rect);
        }
    }
    void renderBody(){
        showGrid();
        if(manip_table.mode != focus_mode.select)
            renderFocus();
        else renderSelect();
    }
    void renderFocus(){
        emphasizeGrid(manip_table.focus,emphasizedLineColor,emphasizedLineWidth);
    }
    void renderSelect(){
        emphasizeGrids(manip_table.select.cells,selected_cell_border,selectedLineWidth);
    }
    private:
    void emphasizeGrid(const Cell cell,const SDL_Color grid_color,const ubyte grid_width){
        SDL_Rect grid_rect = {get_x(cell),get_y(cell),gridSpace, gridSpace};
        for(int i; i<grid_width ; ++i)
        {
            SDL_RenderDrawRect(renderer,&grid_rect);
            grid_rect = SDL_Rect(grid_rect.x+1, grid_rect.y+1,
                         grid_rect.w-2, grid_rect.h-2);
        }
    }
    void emphasizeGrids(const Cell[] cells,const SDL_Color color,const ubyte grid_width){
        if(cells.empty) return;

        foreach(a; cells)
        {
            const auto ad_info = adjacent_info(cells,a);
            foreach(dir; Direct.min .. Direct.max+1 )
            {
                if(!ad_info[cast(Direct)dir]){ // 隣接してない方向の境界を書く
                    drawCellLine(a,cast(Direct)dir,white,grid_width); // 先にホワイトで既に存在する色を消す
                    drawCellLine(a,cast(Direct)dir,selected_cell_border,grid_width);
                }
            }
        }
    }
    private int get_x(Cell c){ return c.column * gridSpace + holding_area.x; }
    private int get_y(Cell c){ return c.row * gridSpace + holding_area.y; }
    void drawCellLine(const Cell cell,const Direct dir,SDL_Color color,ubyte width){
        auto startx = get_x(cell);
        auto starty = get_y(cell);
        int endx,endy;
        final switch(dir)
        {   // 
            case Direct.right:
                startx += gridSpace;
                endx = startx;
                endy = starty + gridSpace;
                for(ubyte w; w<width; ++w)
                {
                    SetRenderColor(renderer,color,alpha);
                    SDL_RenderDrawLine(renderer,startx,starty,endx,endy);
                    --startx;
                    --endx;
                }
                break;
            case Direct.left:
                endx = startx;
                endy = starty + gridSpace;
                for(ubyte w; w<width; ++w)
                {
                    SetRenderColor(renderer,color,alpha);
                    SDL_RenderDrawLine(renderer,startx,starty,endx,endy);
                    ++startx;
                    ++endx;
                }
                break;
            case Direct.up:
                endx = startx + gridSpace;
                endy = starty;
                for(ubyte w; w<width; ++w)
                {
                    SetRenderColor(renderer,color,alpha);
                    SDL_RenderDrawLine(renderer,startx,starty,endx,endy);
                    ++starty;
                    ++endy;
                }
                break;
            case Direct.down:
                starty += gridSpace;
                endx = startx + gridSpace;
                endy = starty;
                for(ubyte w; w<width; ++w)
                {
                    SetRenderColor(renderer,color,alpha);
                    SDL_RenderDrawLine(renderer,startx,starty,endx,endy);
                    --starty;
                    --endy;
                }
                break;
        }
    }
    void table_check(){
        if(table.changed_flg){
            attached_window.Redraw();
            table.changed_flg = false;
        }
    }
}
