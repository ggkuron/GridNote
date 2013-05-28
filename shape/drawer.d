module shape.drawer;

import std.math;
import shape.shape;
import cairo.Context;
import cairo.Surface;
import cairo.ImageSurface;

class Drawer{
    abstract void set(Context);
    abstract void set_color(Context);
    abstract void fill(Context);
    abstract void fill_p(Context);
    abstract void stroke(Context);
    abstract void stroke_p(Context);
    abstract void clip(Context);
    void init(){}; // ctr uses for each shape
    void set_width(Context){} // indicate to format with default value, shape.width
                       // but not all shapes have width so keep it blank
    void set_width(double w){}
    private:
    final move(Context cr, Point p){
        cr.moveTo(p.x,p.y);
    }
    final line_to(Context cr, Point p){
        cr.lineTo(p.x,p.y);
    }
}
mixin template drw_imp(T){
    static if(is(T == Point))
    {
        Circle shape;
        this(T p){
            shape = new Circle(p,2);
        }
    }else
    {
        T shape;
        this(T s){
            shape = s;
            init();
        }
    }
    static if(is(T == Image)){
        void set_color(Context cr){}
    }else{
        void set_color(Context cr)
        {
            auto c = shape.color;
            cr.setSourceRgba(cast(double)c.r/255,
                             cast(double)c.g/255,
                             cast(double)c.b/255,
                             cast(double)c.a/255);
        }
    }

    void fill(Context cr){
        set_width(cr);
        set(cr);
        set_color(cr);
        cr.fill();
    }
    void fill_p(Context cr){
        set(cr);
        set_color(cr);
        cr.fillPreserve();
    }
    void stroke(Context cr){
        set_width(cr);
        set(cr);
        set_color(cr);
        cr.stroke();
    }
    void stroke_p(Context cr){
        set_width(cr);
        set(cr);
        set_color(cr);
        cr.strokePreserve();
    }
    void clip(Context cr){
        set(cr);
        cr.clip();
        set_color(cr);
        cr.newPath();
    }
}
class PointDrawer : Drawer{
    void set(Context cr){}
    mixin drw_imp!(Point);
}

class CircleDrawer : Drawer{
    void set(Context cr){
        cr.arc(shape.p.x, shape.p.y, shape.radius, 0, 2 * PI);
    }
    mixin drw_imp!(Circle);
}

class LineDrawer : Drawer{
    this(){} // need to implicit super() call from LinesDrawer
    void set(Context cr){
        move(cr,shape.start);
        line_to(cr,shape.end);
    }
    void set_width(Context cr){
        cr.setLineWidth(shape.width);
    }
    mixin drw_imp!(Line);
}
class LinesDrawer : LineDrawer{
    void set(Context cr){
        foreach(l; shape.lines)
        {
            move(cr,l.start);
            line_to(cr,l.end);
        }
    }
    void set_width(Context cr){
        foreach(l; shape.lines)
            cr.setLineWidth(shape.width);
    }
    mixin drw_imp!(Lines);
}
class RectDrawer : Drawer{
    void set(Context cr){
        cr.rectangle(shape.x,shape.y,shape.w,shape.h);
    }
    mixin drw_imp!(Rect);
}
class ImageDrawer : Drawer{
    void set(Context cr)
        in{
        assert(sx != 0 && sx != double.nan);
        assert(sy != 0 && sy != double.nan);
        assert(shape.frame.width > 0 && shape.frame.width != double.nan);
        assert(shape.frame.height > 0 && shape.frame.width != double.nan);
        assert(shape.image);
        }
    body{
        cr.setSourceSurface(shape.image,0,0);
        cr.paint();
    }
    void draw(Context cr){
        set(cr);
    }
    private void scale_to(Context cr,Rect r)
        in{
        assert(r.w != 0 && r.w != double.nan);
        assert(r.h != 0 && r.h != double.nan);
            // assert(shape.width > 0 && shape.width != double.nan);
            // assert(shape.height > 0 && shape.width != double.nan);
        }
    body{
        auto w = shape.image.getWidth();
        auto h = shape.image.getHeight();
        cr.scale(r.w/w,r.h/h);
    }
    mixin drw_imp!(Image);
}
        
