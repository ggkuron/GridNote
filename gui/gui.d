module gui.gui;

import derelict.sdl2.sdl;
import std.stdio;
import std.string;
import env;
import misc.draw_rect;

SDL_Window* mainWin;
SDL_Renderer* mainRend;
immutable int start_size_w = 960;
immutable int start_size_h = 640;

static class GUIManager{
    Window mainWindow;
    this(){
        mainWindow = new Window();
        mainWindow.attach(new ControlPanel(mainWindow));
        mainWindow.attach(new PageView(mainWindow));
    }
    void draw(){
        mainWindow.Redraw();
    }
}

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
    void Redraw()
    {
        SDL_SetRenderDrawColor(renderer,255,255,255,255); // 最背面の色
        SDL_RenderClear(renderer);
        foreach(ref widget; owned_widgets)
        {
            widget.backDesign();
            widget.renderBody();
        }
        SDL_RenderPresent(renderer);
    }
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
    Window attached_window;
    this(Window win,int x,int y,int w_per_win,int h_per_win)out{
        assert( holding_area.w != 0 );
        assert( holding_area.h != 0 );
    }
    body{
        attached_window = win;
        assert( attached_window !is null );
        holding_area.x = attached_window.width * x / 100;
        holding_area.y = attached_window.height * y / 100;
        holding_area.w = attached_window.width * w_per_win / 100;
        holding_area.h = attached_window.height * h_per_win / 100;
    }    SDL_Rect holding_area;
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
        deco = createTexture(attached_window.renderer,"./deco.bmp");
    }
    ~this(){
        SDL_DestroyTexture(deco);
    }
    void backDesign(){
        auto renderer = attached_window.renderer;
        SDL_SetRenderDrawColor(renderer,128,128,128,255);
        SDL_RenderFillRect(renderer,&holding_area);
        drawRect(renderer,deco,holding_area);
    }
}
class PageView : Widget {
    this(Window w){
        super(w,25,0,75,100);
    }
    void backDesign(){
        auto renderer = attached_window.renderer;
        SDL_SetRenderDrawColor(renderer,96,96,96,255);
        SDL_RenderFillRect(renderer,&holding_area);
    }
    void showGrid(){
        auto renderer = attached_window.renderer;

        SDL_SetRenderDrawColor(renderer,grid_color.r,grid_color.g,grid_color.b,grid_alpha);
        SDL_Rect drw_rect = holding_area;
        drw_rect.h = 1;
        for(;drw_rect.y < holding_area.h; drw_rect.y += gridBandWidth)
        {
            SDL_RenderFillRect(renderer,&drw_rect);
        }
        drw_rect = holding_area;
        drw_rect.w = 1;
        for(;drw_rect.x < holding_area.w + holding_area.x; drw_rect.x += gridBandWidth)
        {
            SDL_RenderFillRect(renderer,&drw_rect);
        }
    }
    void renderBody(){
        showGrid();
    }
}
