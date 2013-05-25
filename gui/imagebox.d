module gui.imagebox;

import gui.render_box;
import cell.cell;
import shape.shape;
import shape.drawer;
import gui.pageview;
import cell.imagebox;
import cairo.Context;

class RenderImage : BoxRenderer{
private:
    Drawer _drawer;
    Rect _frame;
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
    this(PageView pv){
        super(pv);
    }
    void setBOX(S:Shape)(ImageBOX ib,S s){
        _frame = get_position(ib);
        ib.set_image(_frame,s);

        set_drawer(ib.image);
    }
    void render(Context cr){
        _drawer.fill(cr);
    }
    void stroke(Context cr){
        _drawer.stroke(cr);
    }
}
