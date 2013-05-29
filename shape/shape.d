module shape.shape;

import cell.cell;
import cell.table;
import cell.contentbox;
import std.string;
import std.array;
import cairo.ImageSurface;
import gtkc.gtktypes;

public import util.color;

abstract class Shape{
    Color color;
    void attach(ContentBOX box){}
    void set_color(in Color c){
        color = c;
    }
    void scale(){}
}

final class Point : Shape{
    double x,y;
    this(double xx=0, double yy=0){
        x = xx;
        y = yy;
    }
    this(int xx=0, int yy=0){
        x = xx;
        y = yy;
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
    this(double[2] p1,double[2] p2){
        start = new Point(p1[0],p1[1]);
        end = new Point(p2[0],p2[1]);
    }
    this(Point p1,Point p2,double w){
        this(p1,p2);
        set_width(w);
    }
    void set_width(double w){
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
    void set_width(double d=1){
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
    this(double xx=0,double yy=0,double ww=0,double hh=0){
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
        
class Circle : Shape{
    Point p;
    double radius;
    this(Point x,double r){
        p = x;
        radius = r;
    }
    this(double[2] x,double r){
        p = new Point(x[0],x[1]);
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
}
class Image : Shape{
    ImageSurface image;
    Rect frame;
    // double width,height; // if it were int and you want to scale Image, may cause droping 0 problem 
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
