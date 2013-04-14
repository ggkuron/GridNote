module shape.shape;
// cairo wraper

import derelict.sdl2.sdl;
import deimos.cairo.cairo;
import cell.cell;
import std.string;

struct Color{
    double r,g,b,a;
    // 初期値赤 初期化されてない色が存在しないように
    // 色という要素が存在するのなら初期化されない == 画面に出てはいけない
    this(double rr=255,double gg=0,double bb=0,double aa=255){
        r = rr; g = gg; b = bb; a = aa;
    }
    this(SDL_Color c){
        r = c.g; g = c.g; b = c.b;
    }
}
static white = Color(255,255,255,255);
static black = Color(0,0,0,255);
static red = Color(255,0,0,255);
    
class Shape{
    Color color;
    void attach(ContentBOX box){}
    void set_color(Color c= Color(255,255,255,255)){
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
    this(Rect r){
        this = r;
    }
    static Rect opCall(SDL_Rect r){
        Rect t = new Rect(r.x, r.y, r.w, r.h);
        return t;
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
    cairo_surface_t* image;
    Rect frame;
    // double width,height; // if it were int and you want to scale Image, may cause droping 0 problem 
    this(string path,Rect f)
        out{
        assert(image);
        // assert(width > 0 && height > 0);
        assert(frame);
        }
    body{
        image = cairo_image_surface_create_from_png(path.toStringz);
        frame = f;
    }
    ~this(){ cairo_surface_destroy(image); }
}
