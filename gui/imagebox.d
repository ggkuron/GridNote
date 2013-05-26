module gui.imagebox;

import gui.render_box;
import cell.cell;
import shape.shape;
import shape.drawer;
import gui.tableview;
import cell.imagebox;
import cairo.Context;

import util.color;

class RenderImage : BoxRenderer{
private:
    Drawer _drawer;
    Rect _frame;
    ImageBOX _target;
    PointDrawer point_d;
    CircleDrawer circle_d;
    LineDrawer line_d;
    LinesDrawer lines_d;
    RectDrawer rect_d;
    ImageDrawer image_d;
    void set_drawer(Circle c){
        circle_d = new CircleDrawer(c);
        _drawer = circle_d;
    }
    void set_drawer(Rect r){
        rect_d = new RectDrawer(r);
        _drawer = rect_d;
    }
public:
    alias _drawer this;
    this(TableView tv){
        super(tv);
    }
    void setBOX(S:Shape)(ImageBOX ib){
        _target = ib;
        _frame = get_position(ib);
        set_drawer(cast(S)ib.image);
    }
    void render(Context cr){
        // _target.image.set_color(c);
        _drawer.fill(cr);
    }
    void render(Context cr,in Color c){
        _target.image.set_color(c);
        _drawer.fill(cr);
    }

    void stroke(Context cr,in Color c){
        _target.image.set_color(c);
        _drawer.stroke(cr);
    }
}
