module gui.textbox;
import gui.render_box;
import text.text;
import cell.textbox;
import cell.cell;
import gui.gui;
import std.array;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

class RenderTextBOX : RenderBOX{
    // TTF_Font[string] fonts; // key: fontname , size
    TTF_Font* font;
    ubyte fontsize=40;
    SDL_Color color = {0xff,0xff,0xff};
    this(SDL_Renderer* r,PageView pv)
    {
        super(r, pv);
        font = TTF_OpenFont("Ricty-Regular.ttf",fontsize/*page_view.gridSpace*/);
        fontsize = cast(ubyte)pv.gridSpace;
    }
    void setBOX(TextBOX box){
        // fonts[box.fontname] = TTF_OpenFont(box.fontname.toStringz,box.font_size); 
        import std.stdio;
        import std.string;
        writef("%s",box.text.str);
        auto srf = TTF_RenderUTF8_Blended(font,box.text.str,color);
        box.texture = SDL_CreateTextureFromSurface(renderer,srf);
        SDL_FreeSurface(srf);
        box.loaded_flg = true;
    }
    void render(TextBOX box){
        import std.stdio;
        writeln("ok");
        if(!box.text.line.keys.empty()) setBOX(box);
        auto pos = get_position(box);
        writef("%d %d %d %d :SDL \n",pos.x,pos.y,pos.w,pos.h);
        SDL_RenderCopy(renderer,box.texture,null,&pos);
        // assert(box.texture !is null);
    }
    ~this()
    {
        // foreach(font; fonts)
            TTF_CloseFont(font);
    }
    private:
    void set_color(ubyte R,ubyte G,ubyte B)
    {
        color= SDL_Color(R,G,B); 
    }
}
 
