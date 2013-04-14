module gui.render_box;

import derelict.sdl2.sdl;
import gui.gui;
import cell.cell;
import misc.direct;
import deimos.cairo.cairo;
import shape.shape;

class RenderBOX{
    cairo_t* cr;
    PageView page_view;
    CellBOX in_view;
    // SDL_Rect[] contents_positions;
    this(cairo_t* r,PageView pv){
        cr = r;
        page_view = pv;
        in_view = pv.in_view;
    }
    Rect get_position(CellBOX box){
        auto ul = box.upper_left;

        auto depth = box.recursive_depth();
        auto grid = page_view.grid_length(depth) ;
        import std.stdio;
        writef("depth:%d grid:%d \n",depth,grid);
        int w = grid * (box.count_linedcells(ul,Direct.right) + 1);
        int h = grid * (box.count_linedcells(ul,Direct.down) + 1);

        auto result =  new Rect(page_view.get_x(ul),page_view.get_y(ul), w, h);
        writefln("result is %f %f %f %f",result.x,result.y,result.w,result.h);
        writefln("lu is %d %d ",ul.row,ul.column);
        return result;
    }
}
