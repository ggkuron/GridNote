module gui.render_box;

import gui.tableview;
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

/+
package methods:
    final:
    Rect window_position(in CellContent);
    void render_grid(Context,in CellContent,in Color,int width);
    void render_fill(Context,in ContentBOX,in Color)
    void render_fill(Context,in ContentFlex,in Color)
    double[2] get_center(in ContentBOX)const;
    int get_gridSize()const;
+/

class BoxRenderer{
private:
    TableView _table_view;
protected:
public:
    this(TableView tv)
        out{
        assert(_table_view);
        }
    body{
        _table_view = tv;
    }
package:
    final Rect window_position(in CellContent b)
        in{
        assert(b !is null);
        }
    body{
        const cp = b.top_left;
        debug(gui) writefln("cp : %s",cp);
        const xy = _table_view.get_window_pos(cp);

        auto grid = _table_view.get_gridSize;

        const w = grid * b.numof_col();
        const h = grid * b.numof_row();

        auto result =  new Rect(xy[0],xy[1],w,h);
        debug(gui) writefln("window_position : %f %f %f %f",result.x,result.y,result.w,result.h);
        return result;
    }
    final Rect context_position(in CellContent b)
        in{
        assert(b !is null);
        }
    body{
        const cp = b.top_left;
        debug(gui) writefln("cp : %s",cp);
        const xy = _table_view.get_pos(cp);

        auto grid = _table_view.get_gridSize;

        int w = grid * b.numof_col();
        int h = grid * b.numof_row();

        auto result =  new Rect(xy[0],xy[1],w,h);
        debug(gui) writefln("window_position : %f %f %f %f",result.x,result.y,result.w,result.h);
        return result;
    }

    int get_gridSize()const{
        return _table_view.get_gridSize();
    }
    final void stroke(Context cr,in CellContent b,in Color color,in ubyte width)
        in{
        assert(b);
        }
    body{
        _table_view.StrokeGrids(cr,b.get_cells(),color,width);
    }
    final void fill(Context cr,in ContentFlex b,in Color color){
        _table_view.FillGrids(cr,b.get_cells(),color);
    }
    final void fill(Context cr,in ContentBOX b,in Color color){
        _table_view.FillBox(cr,b,color);
    }
    final double[2] get_center(in ContentBOX b)const{
        const center_cell = (b.top_left + b.bottom_right)/2;
        return _table_view.get_center_pos(center_cell);
    }
    final void fill(Context cr,in Cell ce,in Color c){
        _table_view.FillCell(cr,ce,c);
    }
    final void fill(Context cr,Rect rect){
        _table_view.Fill(cr,rect);
    }
    final void stroke(Context cr,in Cell ce,in Color c){
        _table_view.StrokeCell(cr,ce,c);
    }
}
