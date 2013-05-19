module shape.shape;

import cell.cell;
import cell.table;
import cell.contentbox;
import std.string;
import cairo.ImageSurface;
// import gtkc.gdktypes;
import gtkc.gtktypes;

public import misc.color;

class Shape{
    Color color;
    void attach(ContentBOX box){}
    void set_color(Color c){
        color = c;
    }
    void scale(){}
}

class Point : Shape{
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
class Line : Shape{
    Point start,end;
    double width;
    this(){}
    this(Point p1,Point p2){
        start = p1;
        end = p2;
    }
    this(Point p1,Point p2,double w){
        this(p1,p2);
        set_width(w);
    }
    void set_width(double w){
        width = w;
    }
}
        
class Lines : Line{
    Line[] lines;
    double width;
    this(){}
    Lines* opAssign(const Lines ls){ 
        lines = cast(Line[])ls.lines;
        width = ls.width;
        return cast(Lines*)this;
    }
    void set_width(double d){
        width = d;
    }
    void add_line(Line l){
        if(width != double.nan) l.set_width(width);
        l.set_color(color);
        lines ~= l;
    }
}
class Rect : Shape{
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
}
class Arc : Circle{
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
    //  ~this(){ cairo_surface_destroy(image); }
}
