module gui.textbox;

import gui.gui;
import gui.render_box;
import cell.textbox;
import cell.cell;
import text.text;
import misc.direct;
import std.array;
import std.string;
import std.typecons;

import gtk.IMContext;

import cairo.Context;
import cairo.FontOption;
import cairo.Surface;
import cairo.ImageSurface;

import gtkc.pangotypes;
import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;
import pango.PgAttributeList;

import std.stdio;
import shape.shape;

class RenderTextBOX : BoxRenderer{
    private:
    TextBOX render_target;
    Rect box_pos;
    cairo_text_extents_t extents;
    PgLayout[int] layout;
    PgFontDescription desc;
    PgAttributeList attrlist;
    PangoRectangle preedit_line_rect;
    int cursor_pos;
    string[int] strings;
    int currentline;
    string preedit;
    ubyte fontsize;
    int[int] width,height;
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
    private void checkBOX(TextBOX box){
        assert(box !is null);
        if(render_target != box){
            if(render_target) desc.free();
            strings.clear();
            currentline = 0;
            preedit.clear();
            layout.clear();
            fontsize = 0;
            width.clear();
            height.clear();
            desc = PgFontDescription.fromString(box.get_fontname~fontsize);
            render_target = box;
        }
        else
        {
        }
    }
    public void render(Context cr,TextBOX box)
        in{
        assert(!box.empty);
        }
    body{
        debug(gui) writeln("render textbox start");
        // 
        auto gridSize = page_view.get_gridSize();
        box_pos = get_position(box); // gui.render_box::get_position
        box_pos.y += gridSize/3;
        auto numof_lines = box.getText().numof_lines();
        currentline = box.getText().currentline();
            
        void  modify_boxsize()
        {   // 入力に合わせて自動でBOXを変形させる挙動
            // 何通りかの挙動が考えられる
            //    1行目の横幅で自動改行
            //    入力停止
            //    自動expnad <= 下の実装
            //    横に圧縮
            //    Cellごと縮小
                
            auto box_width = page_view.get_gridSize() * box.numof_hcell();
            debug(gui) writefln("box width %d",box_width);

            auto sorted_width = width.values.sort;
            auto max_width = sorted_width[$-1];
            // auto min_width = sorted_width[0];

            // 浮動小数点的に動きまわる時があるので余裕を少々
            if(max_width > box_width)
                box.expand(Direct.right); 
            else
            if(max_width < box_width-gridSize/2)
            {
                box.remove(Direct.right);
            }
        }
        void render_preedit()
        {
            debug(gui) writeln("render preedit start");
            // if(currentline !in layout)  <- 改行後現れなくなる
            {
                layout[currentline] = PgCairo.createLayout(cr); // 
                layout[currentline].setFontDescription(desc);
            }
            if(currentline !in width)   // この2つのifまとめられそうだけど精神的衛生上
                width[currentline] = 0;

            layout[currentline].setAttributes(attrlist);
            layout[currentline].setText(preedit);
            cr.moveTo(box_pos.x+width[currentline],box_pos.y+currentline*gridSize);
            PgCairo.updateLayout(cr,layout[currentline]);
            PgCairo.showLayout(cr,layout[currentline]);

            set_preeditting(false);
        }

        checkBOX(box);
        strings = box.getText().strings;
        debug(text) writeln("strings are ",strings);

        foreach(line,one_line; strings)
        {
            if(one_line.empty) break;
            // if(line !in layout) <- IMのpreedit位置が最初の位置にも反映されてしまう
            {
                layout[line] = PgCairo.createLayout(cr);
                layout[line].setFontDescription(desc);
            }
            debug(gui) writeln("write position: ",box_pos.x," ",box_pos.y);
            cr.setSourceRgb(fontcolor.r,fontcolor.g,fontcolor.b);


            auto lines_y = box_pos.y + gridSize * line;
            cr.moveTo(box_pos.x,lines_y);
            layout[line].setText(one_line);
            PgCairo.updateLayout(cr,layout[line]);
            PgCairo.showLayout(cr,layout[line]);

            // get real using width and height
            // render_preedit より前に取得する必要がある
            layout[line].getPixelSize(width[line],height[line]);
            debug(gui) writefln("layout width %d",width[line]);

            debug(gui) writefln("wt %s",one_line);
        }

        if(is_preediting()) render_preedit();
        if(!strings.keys.empty) modify_boxsize();
        debug(gui) writeln("text render end");
    }
    public void prepare_preedit(IMContext imc){
        imc.getPreeditString(preedit,attrlist,cursor_pos);
        set_preeditting(true);
    }
    public void retrieve_surrouding(IMContext imc){
    }
    private bool preeditting;
    private bool is_preediting(){
        return preeditting;
    }
    private void set_preeditting(bool b){
        preeditting = b;
    }
    public auto get_surrounding(){
        cursor_pos = render_target.getText.get_caret().column;
        writeln("cursor_pos: ",cursor_pos); 
        return tuple(strings[currentline],cursor_pos);
    }
}
 
