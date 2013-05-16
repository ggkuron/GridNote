module gui.render_box;

import gui.pageview;
import cell.cell;
import cell.collection;
import cell.table;
import cell.refer;
import util.direct;
import shape.shape;
import shape.drawer;
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
    final protected Rect get_position(const CellContent b){
        assert(b !is null);

        auto cp = in_view.get_position(b);
        debug(gui) writefln("cp : %s",cp);
        auto x = page_view.get_x(cp);
        auto y = page_view.get_y(cp);

        auto grid = page_view.get_gridSize;

        int w = grid * b.numof_col();
        int h = grid * b.numof_row();

        auto result =  new Rect(x,y,w,h);
        debug(gui) writefln("result is %f %f %f %f",result.x,result.y,result.w,result.h);
        return result;
    }
    final public void render_grid(Context cr,const CellContent b,const Color color,const ubyte width){
        page_view.renderGrids(cr,b.get_cells(),color,width);
    }
    final public void render_fill(Context cr,const CellCollection b,const Color color){
        page_view.renderFillGrids(cr,b.get_cells(),color);
    }
    final public void render_fill(Context cr,const CellContent b,const Color color){
        Rect grid_rect = get_position(b);
        auto grid_drwer = new RectDrawer(grid_rect);

        grid_rect.set_color(color);
        grid_drwer.fill(cr);

    }
}
