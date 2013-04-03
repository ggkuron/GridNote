module gui.render_box;

import derelict.sdl2.sdl;
import gui.gui;
import cell.cell;
import misc.direct;

class RenderBOX{
    SDL_Renderer* renderer;
    PageView page_view;
    CellBOX in_view;
    // SDL_Rect[] contents_positions;
    this(SDL_Renderer* r,PageView pv){
        renderer = r;
        page_view = pv;
        in_view = pv.in_view;
    }
    SDL_Rect get_position(CellBOX box){
        auto ul_c = box.upper_left;

        auto depth = box.recursive_depth();
        auto grid = page_view.grid_length(depth) ;
        import std.stdio;
        // writef("depth:%d grid:%d cw%d ch%d \n",depth,grid);
        int w = grid * (box.count_linedcells(ul_c,Direct.right) + 1);
        int h = grid * (box.count_linedcells(ul_c,Direct.down) + 1);

        return SDL_Rect(page_view.get_x(ul_c),page_view.get_y(ul_c), w, h);
    }
}
