module shape.drawer;

import std.math;
import shape.shape;
public import cairo.Context;
public import cairo.Surface;
import cairo.ImageSurface;

void set_color(Context cr,in Color c)
{
    cr.setSourceRgba(cast(double)c.r/255,
                     cast(double)c.g/255,
                     cast(double)c.b/255,
                     cast(double)c.a/255);
}

interface Drawer{
    void set(Context);
    void set_color(Context);
    void fill(Context);
    void fill_p(Context);
    void stroke(Context);
    void stroke_p(Context);
    void clip(Context);
    void set_width(Context); // indicate to format with default value, shape.width
                       // but not all shapes have width so keep it blank
    void set_width(double w);
    private:
    final move(Context cr, Point p){
        cr.moveTo(p.x,p.y);
    }
    final line_to(Context cr, Point p){
        cr.lineTo(p.x,p.y);
    }
}
mixin template drw_imp(T){
    static if(!is(T == Point))
    {
        T shape;
        this(T s){
            set_new(s);
        }
        this(){}
        void set_new(T s){
            shape = s;
        }
    }
    static if(!is(T == Image))
    {
        void set_color(Context cr){
            cr.set_color(shape.color);
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
        set_width(cr);
        set(cr);
        cr.clip();
        cr.newPath();
    }
}
class PointDrawer : Drawer{
    void set(Context cr){}
    Circle shape;
    this(Point p){
        shape = new Circle(p,2);
    }
    mixin drw_imp!(Point);
    void set_width(Context){} // indicate to format with default value, shape.width
    void set_width(double w){}
}

class CircleDrawer : Drawer{
    void set(Context cr){
        cr.arc(shape.p.x, shape.p.y, shape.radius, 0, 2 * PI);
    }
    mixin drw_imp!(Circle);
    void set_width(Context){} // indicate to format with default value, shape.width
    void set_width(double w){}
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
    void set_width(double w){
        shape.width = w;
    }
}
class LinesDrawerEach : Drawer{
    Lines _shape;
    LineDrawer _ldrwer;
    this(Lines ls){
        assert(!ls.empty());
        _shape = ls;
        _ldrwer = new LineDrawer();
    }
    void set(Context cr){
        foreach(l;_shape.lines)
        {
            _ldrwer.set_new(l);
            _ldrwer.set(cr);
        }
    }
    void set_color(Context cr){}
    void fill(Context cr){}
    void fill_p(Context cr){}
    void stroke(Context cr){
        foreach(l;_shape.lines)
        {
            _ldrwer.set_new(l);
            _ldrwer.stroke(cr);
        }
    }
    void stroke_p(Context cr){
        foreach(l;_shape.lines)
        {
            _ldrwer.set_new(l);
            _ldrwer.stroke_p(cr);
        }
    }
    void clip(Context cr){
        set_width(cr);
        set(cr);
        cr.clip();
        cr.newPath();
    }

    void set_width(Context){} // indicate to format with default value, shape.width
    void set_width(double w){}
}

// 複数のlineをまとめて扱う
// 個々の長さとか色は見ない
// それぞれの特性が問題になるならLineDrawerに渡す
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
    void set_width(double w){}
}
class RectDrawer : Drawer{
    void set(Context cr){
        cr.rectangle(shape.x,shape.y,shape.w,shape.h);
    }
    mixin drw_imp!(Rect);
    void set_width(Context){} // indicate to format with default value, shape.width
    void set_width(double w){}
}
class ImageDrawer : Drawer{
    void set_color(Context cr){}
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
        }
    body{
        auto w = shape.image.getWidth();
        auto h = shape.image.getHeight();
        cr.scale(r.w/w,r.h/h);
    }
    mixin drw_imp!(Image);
    void set_width(Context){} // indicate to format with default value, shape.width
    void set_width(double w){}

}
        
