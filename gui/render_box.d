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
    this(PageView pv)
        out{
        assert(page_view);
        assert(in_view);
        assert(cr != null);
        }
    body{
        cr = pv.cr;
        page_view = pv;
        in_view = pv.in_view;
    }
    final Rect get_position(CellBOX box){
        assert(box.managed_area !is null);
//         ここなおす
//             概念が不定形
        auto ul = in_view.upper_left(box.managed_area.keys);
        auto x = page_view.get_x(ul);
        auto y = page_view.get_y(ul);

        auto depth = box.recursive_depth();
        auto grid = page_view.grid_length(depth) ;
        import std.stdio;
        writeln("ul:",ul);
        writef("depth:%d grid:%d \n",depth,grid);
        int w = grid * (box.count_linedcells(ul,Direct.right) + 1);
        int h = grid * (box.count_linedcells(ul,Direct.down) + 1);

        auto result =  new Rect(x,y,w,h);
        writefln("result is %f %f %f %f",result.x,result.y,result.w,result.h);
        writefln("lu is %d %d ",ul.row,ul.column);
        return result;
    }
}
