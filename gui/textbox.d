module gui.textbox;
import gui.render_box;
import text.text;
import cell.textbox;
import cell.cell;
import gui.gui;
import std.array;
import std.string;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import deimos.cairo.cairo;
import std.stdio;
import shape.shape;

class RenderTextBOX : RenderBOX{
    cairo_t* cr;
    cairo_text_extents_t extents;
    const(char)* str;
    ubyte fontsize=40;
    Color fontcolor;
    this(PageView pv)
    body{
        cr = pv.cr;
        super(cr, pv);
        fontsize = cast(ubyte)pv.gridSpace;
        cairo_select_font_face(cr,"Sans",CairoFontSlant.Normal,CairoFontWeight.Bold);
        cairo_set_font_size(cr,fontsize);
        fontcolor = black;
        cairo_text_extents(cr,str,&extents);
    }
    void setBOX(TextBOX box){
        assert(box !is null);
        box.loaded_flg = true;
    }
    void render(TextBOX box)
        in{
        assert(!box.cells.keys.empty);
        }
    body{
        setBOX(box);
        auto pos = get_position(box); // gui.render_box::get_position
        str = box.c_str;
        writef("%f %f %f %f :\n",pos.x,pos.y,pos.w,pos.h);
        cairo_move_to(cr,pos.x,pos.y);
        cairo_show_text(cr,str);
        writeln("wt ",str);
    }
    ~this(){}
    private:
}
 
