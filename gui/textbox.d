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
    cairo_text_extents_t extents;
    const(char)* str;
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
        box.loaded_flg = true;
    }
    void render(TextBOX box)
        in{
        assert(!box.managed_area.keys.empty);
        }
    body{
        cairo_set_source_rgb(cr,1,1,0);
        cairo_select_font_face(cr,"cairo:monospace",CairoFontSlant.Normal,CairoFontWeight.Bold);
        cairo_set_font_size(cr,fontsize);//cr,fontsize);
        // cairo_text_extents(cr,"hello",&extents);

        setBOX(box);
        auto pos = get_position(box); // gui.render_box::get_position
        str = box.c_str;
        cairo_move_to(cr,pos.x,pos.y+page_view.gridSpace);
        // cairo_move_to(cr,0.5-extents.width/2 - extents.x_bearing,
                //0.5-extents.height/2 - extents.y_bearing);
        cairo_show_text(cr,str);
        writefln("wt %s",str);
    }
    ~this(){}
    private:
}
 
