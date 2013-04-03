module cell.textbox;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import cell.cell;
import text.text;
import std.string;
import misc.direct;

class TextBOX : CellBOX
{   // text の行数を Cellの高さに対応させてみる
    this(CellBOX box){ super(box); }
    this(TextBOX replace){
        super(replace);
    }
    ~this(){ SDL_DestroyTexture(texture); }

    Text text;
    Cell text_offset;

    bool loaded_flg;
    int cursor;
    int current_line;
    string font_name;
    char[] composition;
    int font_size;
    SDL_Color font_color;
    SDL_Texture* texture;
    invariant(){
        assert(current_line <= text.num_of_lines);
    }
    Text exportText(){
        return text;
    }
}
