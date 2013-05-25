module gui.render_box;

import gui.tableview;
import gui.pageview;
import cell.cell;
import cell.collection;
import cell.contentflex;
import cell.contentbox;
import cell.table;
import cell.refer;
import util.direct;
import std.typecons;
import shape.shape;
import shape.drawer;
import cairo.Context;
debug(gui) import std.stdio;

class BoxRenderer{
    TableView table_view;
    ReferTable in_view;
    protected:
    int get_gridSize()const{
        return table_view.get_gridSize();
    }
    public:
    this(PageView pv)
        out{
        assert(table_view);
        assert(in_view);
        }
    body{
        table_view = pv;
        in_view = pv.get_view();
    }
    final protected Rect get_position(const CellContent b){
        assert(b !is null);

        auto cp = b.top_left;
        debug(gui) writefln("cp : %s",cp);
        auto x = table_view.get_x(cp);
        auto y = table_view.get_y(cp);

        auto grid = table_view.get_gridSize;

        int w = grid * b.numof_col();
        int h = grid * b.numof_row();

        auto result =  new Rect(x,y,w,h);
        debug(gui) writefln("result is %f %f %f %f",result.x,result.y,result.w,result.h);
        return result;
    }
public:
final:
    void render_grid(Context cr,const CellContent b,const Color color,const ubyte width){
        table_view.strokeGrids(cr,b.get_cells(),color,width);
    }
    void render_fill(Context cr,const ContentFlex b,const Color color){
        table_view.FillGrids(cr,b.get_cells(),color);
    }
    void render_fill(Context cr,const ContentBOX b,const Color color){
        table_view.FillBox(cr,b,color);
    }
    double[2] get_center(in ContentBOX b)const{
        const center_cell = (b.top_left + b.bottom_right)/2;
        return table_view.get_center_pos(center_cell);
    }

    // final public void render_fill(Context cr,const CellContent b,const Color color){
    //     Rect grid_rect = get_position(b);
    //     auto grid_drwer = new RectDrawer(grid_rect);

    //     grid_rect.set_color(color);
    //     grid_drwer.fill(cr);

    // }
}
