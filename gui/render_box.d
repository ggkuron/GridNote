module gui.render_box;

import gui.gui;
import cell.cell;
import misc.direct;
import shape.shape;
import cairo.Context;
debug(gui) import std.stdio;

class BoxRenderer{
    protected:
    PageView page_view;
    ReferTable in_view;

    public:
    this(PageView pv)
        out{
        assert(page_view);
        assert(in_view);
        }
    body{
        page_view = pv;
        in_view = pv.get_view();
    }
    final protected Rect get_position(CellBOX b){
        assert(b.get_box() !is null);
//         TODO 不安なここなおす

        auto cp = in_view.get_view_position(b);
        debug(gui) writefln("cp : %s",cp);
        auto x = page_view.get_x(cp);
        auto y = page_view.get_y(cp);

        auto grid = page_view.get_gridSize;
        import std.stdio;
        writeln("ul:",cp);

        int w = grid * b.get_numof_hcell();
        int h = grid * b.get_numof_vcell();

        auto result =  new Rect(x,y,w,h);
        writefln("result is %f %f %f %f",result.x,result.y,result.w,result.h);
        return result;
    }
    final public void render_grid(Context cr,CellBOX b,const Color color,const ubyte width){
        page_view.renderGrids(cr,b.get_box(),color,width);
    }
    final public void render_fill(Context cr,CellBOX b,const Color color){
        page_view.renderFillGrids(cr,b.get_box(),color);
    }

}
