module gui.render_box;

import gui.gui;
import cell.cell;
import misc.direct;
import shape.shape;
import cairo.Context;
debug(gui) import std.stdio;

class RenderBOX{
    protected:
    PageView page_view;
    ReferTable in_view;
    // SDL_Rect[] contents_positions;
    public:
    this(PageView pv)
        out{
        assert(page_view);
        assert(in_view);
        }
    body{
        page_view = pv;
        in_view = pv.in_view;
    }
    final protected Rect get_position(CellBOX b){
        assert(b.get_box() !is null);
//         TODO 不安なここなおす

        auto cp = in_view.get_view_position(b);
        debug(gui) writefln("cp : %s",cp);
        auto x = page_view.get_x(cp);
        auto y = page_view.get_y(cp);

        // auto depth = box.recursive_depth();
        // auto grid = page_view.grid_length(depth) ;
        auto grid = page_view.gridSpace;
        import std.stdio;
        writeln("ul:",cp);

        int w = grid * b.get_x_width();
        int h = grid * b.get_y_width();

        auto result =  new Rect(x,y,w,h);
        writefln("result is %f %f %f %f",result.x,result.y,result.w,result.h);
        return result;
    }
}
