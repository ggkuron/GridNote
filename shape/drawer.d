module shape.drawer;

import std.math;
import util.color;
import shape.shape;
public import cairo.Context;
public import cairo.Surface;
import cairo.ImageSurface;

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
    void set_width(in double w);
private:
    final move(Context cr, in Point p){
        cr.moveTo(p.x,p.y);
    }
    final line_to(Context cr, Point p){
        cr.lineTo(p.x,p.y);
    }
}
mixin template drw_imp(T:Shape){
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
    double _width=1;
    void set(Context cr){
        _cd.set(cr);
    }
    Circle shape;
    CircleDrawer _cd;
    this(Point p){
        shape = new Circle(p,2);
        _cd = new CircleDrawer(shape);
    }
    mixin drw_imp!(Point);
    void set_width(Context cr){
        cr.setLineWidth(_width);
    } 
    void set_width(in double w){
        _width = w;
    }
}

class CircleDrawer : Drawer{
    double _width=1;
    void set(Context cr){
        cr.arc(shape.p.x, shape.p.y, shape.radius, 0, 2 * PI);
    }
    mixin drw_imp!(Circle);
    void set_width(Context cr){
        cr.setLineWidth(_width);
    } 
    void set_width(in double w){
        _width = w;
    }
}

final class LineDrawer : Drawer{
    this(){} // need to implicit super() call from LinesDrawer
    void set(Context cr){
        move(cr,shape.start);
        line_to(cr,shape.end);
    }

    // 形状ままの太さで描く
    void set_width(Context cr){
        cr.setLineWidth(shape.width);
    }
    mixin drw_imp!(Line);
    // 描く側の描きたいようにはさせる
    // 線の太さを変えるなら描く線の特性も書き換える
    // Lineの太さは形状自体の個性だと思うので
    // 形状保存したいなら使わない
    // 形状を既に作り上げてるのならこんなもの必要ないわけで
    // 1つの形状を使いまわして何かを描くときに使うんだから
    // 形状保存しなくていいよね。別に破壊する必要もないけど。
    void set_width(in double w){
        shape.width = w;
    }
}
final class LinesDrawerEach : Drawer{
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
    void set_width(in double w){}
}

// 複数のlineをまとめて扱う
// 個々の長さとか色は見ない
// それぞれの特性が問題になるならLineDrawerに渡す
final class LinesDrawer : Drawer{
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
    void set_width(in double w){}
}
final class RectDrawer : Drawer{
    void set(Context cr){
        cr.rectangle(shape.x,shape.y,shape.w,shape.h);
    }
    mixin drw_imp!(Rect);
    void set_width(Context){} // indicate to format with default value, shape.width
    void set_width(in double w){}
}
final class ImageDrawer : Drawer{
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
    void set_width(in double w){}

}

final class ArrowDrawer : Drawer{
    Arrow _shape;
    final class ArrowOpen : ArrowHead{
        override void draw(Context cr,in Point s,in Point e){
            calc_vertexes(s,e);
            
            cr.set_color(this.outer._shape.color);
            this.outer.move(cr,e);
            cr.lineTo(x1,y1);
            cr.stroke();
            this.outer.move(cr,e);
            cr.lineTo(x2,y2);
            cr.stroke();
        }
    }
    this(Arrow s){
        set_new(s);
    }
    this(){}
    void set_new(Arrow s){
        _shape = s;
    }

    void set(Context cr){
        cr.setLineWidth(3);
        cr.moveTo(_shape.from.x,_shape.from.y);
        cr.lineTo(_shape.to.x,_shape.to.y);
    }
    void set_color(Context cr){;
        cr.set_color(_shape.color);
    }
    void fill(Context){}

    void fill_p(Context){}
    void stroke(Context){}
    void stroke_p(Context){}
    void clip(Context){}
    void set_width(Context){}
    void set_width(in double){}
}
import std.math;
abstract class ArrowHead{
    double x1,x2,y1,y2;
    double _arrow_lenth;
    double _arrow_degrees;
    final void calc_vertexes(in Point start,in Point end){
        immutable sx = start.x;
        immutable sy = start.y;
        immutable ex = end.x;
        immutable ey = end.y;
        auto angle = atan2(ey - sy,ex-sx) + PI;
        x1 = ex + _arrow_lenth * cos(angle - _arrow_degrees);
        y1 = ey + _arrow_lenth * sin(angle - _arrow_degrees); 
        x2 = ex + _arrow_lenth * cos(angle + _arrow_degrees); 
        y2 = ey + _arrow_lenth * sin(angle + _arrow_degrees); 
    }
    void draw(Context,in Point, in Point);
}

