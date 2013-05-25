module cell.imagebox;

import cell.cell;
import cell.contentbox;
import cell.table;
import shape.shape;
import shape.drawer;
import cairo.Context;

import gui.pageview;

class ImageBOX : ContentBOX{
private:
    PageView _pv;
    Shape _image;
    Rect _frame;
    string _filename;
public:
    this(BoxTable table,string filepath)
        out{
        assert(_pv);
        }
    body{
        super(table);
        _filename = filepath;
    }
    @property Shape image(){
        return _image;
    }
    void set_image(Shape s)
        in{
        assert(_filename);
        }
        out{
        assert(_image);
        }
    body{
        _image = s;
    }
    override bool is_to_spoil(){
        return false;
        // tobe implement
    }
    void set_circle(){
        auto center = _pv.get_center_pos((top_left+bottom_right)/2);
        auto radius = numof_col * (_pv.get_gridSize()/3);
        _image = new Circle(center,radius);
    }
}
