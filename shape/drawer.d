module shape.drawer;

import std.math;
import deimos.cairo.cairo;
import derelict.sdl2.sdl;
import shape.shape;

class Drawer{
    cairo_t* cr;
    abstract void set();
    abstract void set_color();
    abstract void fill();
    abstract void fill_p();
    abstract void stroke();
    abstract void stroke_p();
    abstract void clip();
    void init(){}; // ctr uses for each shape
    void set_width(){} // indicate to format with default value, shape.width
                       // but not all shapes have width so keep it blank
    void set_width(double w){}
    private:
    final add(Point p){
        cairo_move_to(cr,p.x,p.y);
    }
    final line_to(Point p){
        cairo_line_to(cr,p.x,p.y);
    }
}
mixin template drw_imp(T){
    static if(is(T == Point))
    {
        Circle shape;
        this(cairo_t* c,T p){
            cr = c;
            shape = new Circle(p,2);
        }
    }else
    {
        T shape;
        this(cairo_t* c, T s){
            cr = c;
            shape = s;
            init();
        }
    }
    static if(is(T == Image)){
        void set_color(){}
    }else{
        void set_color()
        {
            auto c = shape.color;
            assert(c.r != double.nan);
            assert(c.g != double.nan);
            assert(c.b != double.nan);
            assert(c.a != double.nan);

            cairo_set_source_rgba(cr,c.r/255,c.g/255,c.b/255,c.a/255);
            import std.stdio;
        }
    }

    void fill(){
        set_color();
        set_width();
        set();
        cairo_fill(cr);
    }
    void fill_p(){
        set_color();
        set();
        cairo_fill_preserve(cr);
    }
    void stroke(){
        set_color();
        set_width();
        set();
        cairo_stroke(cr);
    }
    void stroke_p(){
        set_color();
        set_width();
        set();
        cairo_stroke_preserve(cr);
    }
    void clip(){
        set_color();
        set();
        cairo_clip(cr);
        cairo_new_path(cr);
    }
}
class PointDrawer : Drawer{
    void set(){}
    mixin drw_imp!(Point);
}

class CircleDrawer : Drawer{
    void set(){
        auto c = cast(Circle)shape;
        cairo_arc(cr,c.p.x, c.p.y, c.radius, 0, 2 * PI);
    }
    mixin drw_imp!(Circle);
}

class LineDrawer : Drawer{
    this(){} // need to implicit super() call from LinesDrawer
    void set(){
        add(shape.start);
        line_to(shape.end);
    }
    void set_width(){
        cairo_set_line_width(cr,shape.width);
    }
    mixin drw_imp!(Line);
}
class LinesDrawer : LineDrawer{
    void set(){
        foreach(l; shape.lines)
        {
            add(l.start);
            line_to(l.end);
        }
    }
    void set_width(){
        foreach(l; shape.lines)
            cairo_set_line_width(cr,shape.width);
    }
    mixin drw_imp!(Lines);
}
class RectDrawer : Drawer{
    void set(){
        cairo_rectangle(cr,shape.x,shape.y,shape.w,shape.h);
        import std.stdio;
        // writefln("r:%f g:%f b:%f",shape.color.r,shape.color.g,shape.color.b);
    }
    mixin drw_imp!(Rect);
}
class ImageDrawer : Drawer{
    void set()
        in{
        assert(sx != 0 && sx != double.nan);
        assert(sy != 0 && sy != double.nan);
        assert(shape.frame.width > 0 && shape.frame.width != double.nan);
        assert(shape.frame.height > 0 && shape.frame.width != double.nan);
        assert(shape.image);
        }
    body{
        cairo_set_source_surface(cr,shape.image,0,0);
        cairo_paint(cr);
    }
    override void init(){
        scale_to(shape.frame);
    }
    void draw(){
        set();
    }
    private void scale_to(Rect r)
        in{
            assert(r.w != 0 && r.w != double.nan);
            assert(r.h != 0 && r.h != double.nan);
            // assert(shape.width > 0 && shape.width != double.nan);
            // assert(shape.height > 0 && shape.width != double.nan);
        }
    body{
        auto w = cairo_image_surface_get_width(shape.image);
        auto h = cairo_image_surface_get_height(shape.image);
        cairo_scale(cr,r.w/w,r.h/h);
    }
    ~this(){
        //cairo_surface_destroy(shape.image);
    }
    mixin drw_imp!(Image);
}
        
