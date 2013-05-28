module cell.imagebox;

import cell.cell;
import cell.contentbox;
import cell.table;
import gui.tableview;
import shape.shape;
import shape.drawer;
import cairo.Context;

import gui.pageview;
debug(cell) import std.stdio;

// DrawerをContentが持つのはイレギュラーだけど、
// 版画精神に基づき形づくるのはDrawerの仕事となっており
// ImageBOXのContentはその形そのものであるので許容する
// ..(shapeとdrawerの対応をばらすとめんどくさいし
// package はguiでもいいかもしれない
// ..(guiってpackage名も実態にそぐってないな.rendererとか?

// 描画図形のパタンを増やすならDrawerで実装する
// ここはTableへのインターフェースにすぎず
class ImageBOX : ContentBOX{
private:
    TableView _view;
    Shape _image;
    Rect _frame;
    string _filename;
    Drawer _drawer;
    ImageBOX _target;
    PointDrawer point_d;
    CircleDrawer circle_d;
    LineDrawer line_d;
    LinesDrawer lines_d;
    RectDrawer rect_d;
    ImageDrawer image_d;
public:
    this(BoxTable table,TableView tv)
        out{
        assert(_view);
        }
    body{
        super(table);
        _view = tv;
    }
    override bool require_create_in(in Cell c)
    {
        return table.try_create_in(this,c);
    }

    @property Shape image(){
        return _image;
    }
    override bool is_to_spoil(){
        return false || super.is_to_spoil();
        // tobe implement
    }
    final void fill(Context cr){
        _drawer.fill(cr);
    }
    final void stroke(Context cr){
        _drawer.stroke(cr);
    }
    final void fill(Context cr,in Color c){
        _image.set_color(c);
        _drawer.fill(cr);
    }
    final void stroke(Context cr,in Color c){
        _image.set_color(c);
        _drawer.stroke(cr);
    }
    // drawerで指定した色を優先するので指定しなくてもいい
    // 版画の版みたいなShapeの使い方を想定して
    void set_color(in Color c){
        _image.set_color(c);
    }
    void set_circle(){
        debug(cell) writeln("sc tl: ",top_left);
        debug(cell) writeln("br: ",bottom_right);
        debug(cell) writeln("cc: ",(top_left+bottom_right)/2);

        auto center = _view.get_center_pos((top_left+bottom_right)/2);
        auto radius = numof_col * (_view.get_gridSize()*4/5);
        _image = new Circle(center,radius/2);
        circle_d = new CircleDrawer(cast(Circle)_image);
        _drawer = circle_d;
    }
    void set_rect(){
        immutable gridSize = _view.get_gridSize();
        auto tl = _view.get_pos(top_left);
        auto w = numof_col * gridSize;
        auto h = numof_row * gridSize;
        _image = new Rect(tl[0],tl[1],w,h);
        // _image.set_color(c);
        rect_d = new RectDrawer(cast(Rect)_image);
        _drawer = rect_d;
    }
}
