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

import std.stdio;
import shape.shape;

class RenderTextBOX : RenderBOX{
    cairo_text_extents_t extents;
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
    }
    void render(Context cr,TextBOX box)
        in{
        assert(!box.empty);
        }
    body{
        cr.setSourceRgb(1,1,0);
        cr.selectFontFace("cairo:monospace",cairo_font_slant_t.NORMAL,cairo_font_weight_t.NORMAL);
        cr.setFontSize(fontsize);//cr,fontsize);

        setBOX(box);
        auto pos = get_position(box); // gui.render_box::get_position
        str = box.getText().str;
        cr.moveTo(pos.x,pos.y+page_view.get_gridSize());
        // cairo_move_to(cr,0.5-extents.width/2 - extents.x_bearing,
                //0.5-extents.height/2 - extents.y_bearing);
        cr.showText(str);
        writefln("wt %s",str);
    }
    ~this(){}
    private:
}
 
