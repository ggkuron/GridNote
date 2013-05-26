module cell.imagebox;

import cell.cell;
import cell.contentbox;
import cell.table;
import gui.tableview;
import shape.shape;
import shape.drawer;
import cairo.Context;

import gui.pageview;

class ImageBOX : ContentBOX{
private:
    TableView _view;
    Shape _image;
    Rect _frame;
    string _filename;
public:
    this(BoxTable table,TableView tv)
        out{
        assert(_view);
        }
    body{
        super(table);
        _view = tv;
    }
    @property Shape image(){
        return _image;
    }
    override bool is_to_spoil(){
        return false;
        // tobe implement
    }
    // drawerで指定した色を優先するので指定しなくてもいい
    // 版画の版みたいなShapeの使い方を想定して
    void set_circle(in Color c=red){
        auto center = _view.get_center_pos((top_left+bottom_right)/2);
        auto radius = numof_col * (_view.get_gridSize()*4/5);
        _image = new Circle(center,radius/2);
        _image.set_color(c);
    }
    void set_rect(in Color c=red){
        immutable gridSize = _view.get_gridSize();
        auto tl = _view.get_pos(top_left);
        auto w = numof_col * gridSize;
        auto h = numof_row * gridSize;
        _image = new Rect(tl[0],tl[1],w,h);
        _image.set_color(c);
    }
}
