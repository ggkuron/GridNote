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

class RenderTextBOX : RenderBOX{
    // TTF_Font[string] fonts; // key: fontname , size
    TTF_Font* font;
    ubyte fontsize=40;
    SDL_Color color = {0,0,0};
    this(SDL_Renderer* r,PageView pv)
        in{
        }out{
            assert(font !is null);
    }body{
        super(r, pv);
        fontsize = cast(ubyte)pv.gridSpace;
        font = TTF_OpenFont("Ricty-Regular.ttf",fontsize);
        import std.stdio;
        import std.conv;
        assert(TTF_WasInit());
        writefln(" -> Error: %s", to!(string)(TTF_GetError()));
    }
    void setBOX(TextBOX box){
        // fonts[box.fontname] = TTF_OpenFont(box.fontname.toStringz,box.font_size); 
        assert(box !is null);
        import std.stdio;
        import std.string;
        auto srf = TTF_RenderUTF8_Blended(font,box.c_str,color);
        box.texture = SDL_CreateTextureFromSurface(renderer,srf);
        SDL_FreeSurface(srf);
        box.loaded_flg = true;
    }
    void render(TextBOX box){
        import std.stdio;
        // if(!box.loaded_flg) return;
            setBOX(box);
            auto pos = get_position(box); // Cell.Cell::get_position
            writef("%d %d %d %d :\n",pos.x,pos.y,pos.w,pos.h);
            SDL_RenderCopy(renderer,box.texture,null,&pos);
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
 
