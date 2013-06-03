module cell.imagebox;

import cell.cell;
import cell.contentbox;
import cell.table;
import gui.tableview;
import shape.shape;
import shape.drawer;
import cairo.Context;
import util.direct;

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

// Cell位置に合わせて相対的に表示を動かす、
// cairoのtranslateとかscaleだけで行けそう
// 内部のPointとか置き換える必要あるのかいな
//     付随してるデータを更新しないのはさっすがにまずいか
// translateとかscaleはcairoで図形を定義するときだけに限定するとかいうこと 
class ImageBOX : ContentBOX{
private:
    TableView _view;
    Shape _image;
    Rect _frame;
    string _filename;
    Drawer _drawer;
    void delegate() set_shape;
protected:
    bool _set_shaped;
public:
    this(BoxTable table,TableView tv)
        out{
        assert(_view);
        }
    body{
        super(table);
        _view = tv;
   }
    void reshape(){
        set_shape();
    }
    override bool require_create_in(in Cell c)
    {
        return table.try_create_in(this,c);
    }
    @property Shape image(){
        return _image;
    }
    final void fill(Context cr){
        if(_set_shaped)
        {
            set_shape();
            _drawer.fill(cr);
        }
    }
    final void stroke(Context cr){
        if(_set_shaped)
        {
            set_shape();
            _drawer.stroke(cr);
        }
    }
    final void fill(Context cr,in Color c){
        if(_set_shaped)
        {
            set_shape();
            _image.set_color(c);
            _drawer.fill(cr);
        }
    }
    final void stroke(Context cr,in Color c){
        if(_set_shaped)
        {
            set_shape();
            _image.set_color(c);
            _drawer.stroke(cr);
        }
    }
    // drawerで指定した色を優先するので指定しなくてもいい
    // 版画の版みたいなShapeの使い方を想定して
    override void set_color(in Color c){
        _image.set_color(c);
    }
    void set_width(in ubyte w)
        in{
        assert(_image);
        }
    body{
        _drawer.set_width(w);
    }
    // override bool require_move(in Cell c){
    //     if(super.require_move(c))
    //     {
    //         set_shape();
    //         return true;
    //     }
    //     else return false;
    // }
    // override bool require_move(in Direct to,in int width=1){
    //     if(super.require_move(to,width))
    //     {
    //         set_shape();
    //         return true;
    //     }
    //     else return false;
    // }
    // override bool require_expand(in Direct to,in int width=1){
    //     if(super.require_expand(to,width))
    //     {
    //         set_shape();
    //         return true;
    //     }
    //     else return false;
    // }
}

class RectBOX : ImageBOX{
    RectDrawer _rect_d;
    this(BoxTable table,TableView tv){
        super(table,tv);
    }
    void set_drawer()
        out{
        assert(_rect_d);
        assert(_drawer);
        assert(_image);
        }
    body{
        immutable gridSize = _view.get_gridSize();
        const tl = _view.get_pos(top_left);
        immutable w = numof_col * gridSize;
        immutable h = numof_row * gridSize;
        _image = new Rect(tl[0],tl[1],w,h);
        _rect_d = new RectDrawer(cast(Rect)_image);
        _drawer = _rect_d;
        _set_shaped = true;
        set_shape = &reflesh_rect;
    }
    void reflesh_rect(){
        immutable gridSize = _view.get_gridSize();
        const tl = _view.get_pos(top_left);
        immutable w = numof_col * gridSize;
        immutable h = numof_row * gridSize;
        (cast(Rect)_image).replace(tl[0],tl[1],w,h);
    }
}
class PointBOX : ImageBOX{
    PointDrawer _point_d;
    this(BoxTable table,TableView tv){
        super(table,tv);
    }
    void set_drawer(){
        immutable gridSize = _view.get_gridSize();
        const tl = _view.get_pos(top_left);
        _image = new Point(tl);
        _point_d = new PointDrawer(cast(Point)_image);
        _drawer = _point_d;
        _set_shaped = true;
        set_shape = &reflesh_point;
    }
    void reflesh_point(){
        immutable gridSize = _view.get_gridSize();
        const tl = _view.get_pos(top_left);
        (cast(Point)_image).replace(tl);
    }
}
class CircleBOX : ImageBOX{
    CircleDrawer _circle_d;
    this(BoxTable table,TableView tv){
        super(table,tv);
    }
    void set_drawer(){
        debug(cell) writeln("sc tl: ",top_left);
        debug(cell) writeln("br: ",bottom_right);
        debug(cell) writeln("cc: ",(top_left+bottom_right)/2);

        auto center = _view.get_center_pos((top_left+bottom_right)/2);
        auto radius = numof_col * (_view.get_gridSize()*4/5);
        _image = new Circle(center,radius/2);
        _circle_d = new CircleDrawer(cast(Circle)_image);
        _drawer = _circle_d;
        _set_shaped = true;
        set_shape = &reflesh_circle;
    }
    void reflesh_circle(){
        auto center = _view.get_center_pos((top_left+bottom_right)/2);
        auto radius = numof_col * (_view.get_gridSize()*4/5);
        (cast(Circle)_image).replace(center,radius/2);
    }
}

// ContentBOX実装というよりCellStructure版のような実装しかしてない
// PageViewのGridsのための手抜きしてるんで気力あるときに書き換えよう
// というかそんな多様性ほしくないかも
class LinesBOX : ImageBOX{
    LinesDrawer _lines_d;
    LinesDrawerEach _linesE_d;
    this(BoxTable table,TableView tv){
        super(table,tv);
    }
    void set_drawer(Line[] ls,in double w)
    {
        auto lines = new Lines();
        lines.set_width(w);
        lines.add_line(ls);
        _lines_d = new LinesDrawer(lines);
        _image = lines;
        _drawer = _lines_d;
        _set_shaped = true;
        set_shape = delegate(){};
    }
    void set_drawer(Line[] ls)
    {
        auto lines = new Lines(ls);
        _linesE_d = new LinesDrawerEach(lines);
        _image = lines;
        _drawer = _linesE_d;
        _set_shaped = true;
        set_shape = delegate(){};
    }
}

// class ArrowBOX : ImageBOX{
//     ArrowDrawer _arrow_d;
//     C
//     void set_drawer(){
//         auto center = _view.get_center_pos((top_left+bottom_right)/2);
//         auto radius = numof_col * _view.get_gridSize() *4/5;
//         _image = new Circle(center,radius/2);
//         _circle_d = new CircleDrawer(cast(Circle)_image);
//         _drawer = _circle_d;
//         set_shape = &reflesh_circle;
//     }
//     void reflesh_circle(){
//         auto center = _view.get_center_pos((top_left+bottom_right)/2);
//         auto radius = numof_col * (_view.get_gridSize()*4/5);
//         (cast(Circle)_image).replace(center,radius/2);
//     }
// }
