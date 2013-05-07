module gui.textbox;
import gui.render_box;
import text.text;
import cell.textbox;
import cell.cell;
import gui.gui;
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

class RenderTextBOX : RenderBOX{
    cairo_text_extents_t extents;
    PgLayout layout;
    PgFontDescription desc;
    string str;
    ubyte fontsize=40;
    Color fontcolor;
    this(PageView pv)
    body{
        super(pv);
        fontsize = cast(ubyte)pv.gridSpace;
        fontcolor = black;
    }
    void setBOX(TextBOX box){
        assert(box !is null);
        desc = PgFontDescription.fromString(box.font_name~fontsize);
    }
    void render(Context cr,TextBOX box)
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
        cr.moveTo(pos.x,pos.y+page_view.get_gridSize());
        cr.setSourceRgb(fontcolor.r,fontcolor.g,fontcolor.b);
        // cairo_move_to(cr,0.5-extents.width/2 - extents.x_bearing,
                //0.5-extents.height/2 - extents.y_bearing);
        // layout.getSize(
        str = box.getText().str;
        layout.setText(str);
        PgCairo.updateLayout(cr,layout);
        PgCairo.showLayout(cr,layout);
        writefln("wt %s",str);
        debug(gui) writeln("text render end");
    }
    ~this(){}
    private:
}
 
