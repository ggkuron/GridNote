module gui.textbox;

import gui.gui;
import gui.render_box;
import cell.textbox;
import cell.cell;
import text.text;
import misc.direct;
import std.array;
import std.string;

import cairo.Context;
import cairo.FontOption;
import cairo.Surface;
import cairo.ImageSurface;

import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;

import std.stdio;
import shape.shape;

class RenderTextBOX : BoxRenderer{
    private:
    cairo_text_extents_t extents;
    PgLayout layout;
    PgFontDescription desc;
    string str;
    ubyte fontsize;
    int width,height;
    Color fontcolor;
    public:
    this(PageView pv)
        out{
        assert(fontsize != 0);
        }
    body{
        super(pv);
        fontsize = cast(ubyte)pv.get_gridSize;
        fontcolor = black;
    }
    private void setBOX(TextBOX box){
        assert(box !is null);
        desc = PgFontDescription.fromString(box.get_fontname~fontsize);
    }
    public void render(Context cr,TextBOX box)
        in{
        assert(!box.empty);
        }
    body{
        debug(gui) writeln("textbox render start");
        layout = PgCairo.createLayout(cr);
        setBOX(box);
        auto pos = get_position(box); // gui.render_box::get_position
        layout.setFontDescription(desc);
        desc.free();
        debug(gui) writeln("write position: ",pos.x,pos.y);
        cr.moveTo(pos.x,pos.y+page_view.get_gridSize()/2);
        cr.setSourceRgb(fontcolor.r,fontcolor.g,fontcolor.b);

        str = box.getText().str;
        layout.setText(str);
        PgCairo.updateLayout(cr,layout);
        PgCairo.showLayout(cr,layout);

        modify_boxsize(box);
        writefln("wt %s",str);

        debug(gui) writeln("text render end");
    }
    private void  modify_boxsize(TextBOX box){
        layout.getPixelSize(width,height);
        auto box_width = page_view.get_gridSize() * box.col_num;
        debug(gui) writefln("layout width %d",width);
        debug(gui) writefln("box width %d",box_width);

        if(width > box_width)
            box.expand(Direct.right); else
        if(width < box_width - page_view.get_gridSize())
        {
            box.remove(Direct.right);
            writeln("DELETED!!!!");
        }
    }

}
 
