module shape.shape;

import cell.cell;
import cell.table;
import cell.contentbox;
import std.string;
import std.array;
import cairo.ImageSurface;
import gtkc.gtktypes;

public import util.color;

// 色はDrawerによって表示上は上書きされたりするので
// 規定値として
// 素のまま転がしておくよりはsetter/getter置いて
// Shapeはstructのように振る舞うんだけど、colorはDrawerによって
// 表示上は上書きされたりする脆い存在なので素のまま転がしておくより
// setter/getterを置いてDrawer側のインターフェースと合わせるか
// 素のままおいて、Drawer側のインターフェースと差別化するか
//   Drawer側は@propertyでcolor持ってるのでただややこしいことになるのであわせる

/+  classとしてShapeを持つ意味
    Drawerとセットで切り替えるBridge的な使用ができる
    Struct+Drawer内包+Bridge側をtemplateでもできそう
    書き換えの労力はさほど無さそう
    シリアライズめんどくさそうなら考える
+/
abstract class Shape{
    Color _color;
    final void set_color(in Color c){
        _color = c;
    }
    @property final Color color()const{
        return _color;
    }
    void scale(){}
}

final class Point : Shape{
    double x,y;
    this(in double xx=0, in double yy=0){
        replace(xx,yy);
    }
    this(in int xx=0, in int yy=0){
        replace(xx,yy);
    }
    this(in double[2] p){
        x = p[0];
        y = p[1];
    }
    // 値をコピーする.共有はしない。
    this(in Point r){
        replace(r);
    }
    void replace(in double xx=0, in double yy=0){
        x = xx;
        y = yy;
    }
    void replace(in int xx=0, in int yy=0){
        x = xx;
        y = yy;
    }
    void replace(in double[2] p){
        x = p[0];
        y = p[1];
    }
    void replace(in Point r){
        x = r.x;
        y = r.y;
    }
}
final class Line : Shape{
    Point start,end;
    double width;
    this(){}
    this(Point p1,Point p2){
        start = p1;
        end = p2;
    }
    this(in double[2] p1,in double[2] p2){
        start = new Point(p1[0],p1[1]);
        end = new Point(p2[0],p2[1]);
    }
    this(Point p1,Point p2,in double w){
        this(p1,p2);
        set_width(w);
    }
    void set_width(in double w){
        width = w;
    }
}
final class Lines : Shape{
    Line[] lines;
    double width;
    this(){}
    this(double[2][2][] lines...){
        foreach(l; lines)
        {
            auto ll = new Line(l[0],l[1]);
            add_line(ll);
        }
    }
    this(Line[] ls){
        add_line(ls);
    }
    Lines* opAssign(in Lines ls){ 
        lines = cast(Line[])ls.lines;
        width = ls.width;
        return cast(Lines*)this;
    }
    void set_width(in double d=1){
        width = d;
    }
    // add_lineの前にset_widthが必要
    // 個々のlineの特性を殺すわけじゃない
    void add_line(Line[] ls...){
        foreach(l; ls)
        {
            if(width == double.nan) l.set_width(width);
            lines ~= l;
        }
    }
    @property bool empty()const{
        return lines.empty();
    }
}
final class Rect : Shape{
    double x,y,w,h;
    this(in double xx=0,in double yy=0,in double ww=0,in double hh=0){
        replace(xx,yy,ww,hh);
    }
    void replace(in double xx=0,in double yy=0,in double ww=0,in double hh=0){
        x = xx;
        y = yy;
        w = ww;
        h = hh;
    }
    private void set_gen(T)(T u){
        x = cast(double)u.x;
        y = cast(double)u.y;
        w = cast(double)u.width;
        h = cast(double)u.height;
    }
    this(Rect r){
        this = r;
    }
    this(GtkAllocation ga){
        set_gen(ga);
    }
    void set_by(GtkAllocation ga){
        set_gen(ga);
    }
    // this(cairo_rectangle_int_t cr){
    //     set_gen(cr);
    // }
    T get_struct(T)(){
        return T(cast(int)x,
                 cast(int)y,
                 cast(int)w,
                 cast(int)h);
    }
}
class Tri : Shape{
}
        
class Circle : Shape{
    Point p;
    double radius;
    this(Point x,double r){
        replace(x,r);
    }
    this(double[2] x,double r){
        replace(x,r);
    }
    void replace(Point x,double r){
        p = x;
        radius = r;
    }
    void replace(double[2] x,double r){
        p = new Point(x);
        radius = r;
    }
}
final class Arc : Circle{
    double from,to;
    this(Point x,double r,double angle1,double angle2){
        super(x,r);
        from = angle1;
        to = angle2;
    }
    void replace(Point x,double r,double angle1,double angle2){
        super.replace(x,r);
        from = angle1;
        to = angle2;
    }
}
class Image : Shape{
    ImageSurface image;
    Rect frame;
    // double width,height; // もしもIntでやるとScaleした時に0に落ちるの困るよねっていう 
    this(string path,Rect f)
        out{
        assert(image);
        assert(frame);
        assert(frame.w > 0 && frame.h > 0);
        }
    body{
        image = ImageSurface.createFromPng(path);
        frame = f;
    }
}

final class Arrow : Shape{
    Point from;
    Point to;
    this(Point f,Point t){
        from = f;
        to = t;
    }
    this(double[2] f,double[2] t){
        from = new Point(f);
        to = new Point(t);
    }
}
