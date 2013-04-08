module cell.textbox;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import cell.cell;
import text.text;
import std.string;
import misc.direct;

class TextBOX : CellBOX
{   // text の行数を Cellの高さに対応させてみる
    this(CellBOX replace){ 
        text = new Text();
        super(replace);
    }
    ~this(){ SDL_DestroyTexture(texture); }

    Text text;
    Cell text_offset;

    bool loaded_flg;
    // int cursor;
    int current_line;
    string font_name;
    char[] composition;
    int font_size;
    SDL_Color font_color;
    SDL_Texture* texture;
    invariant(){
        assert(current_line <= text.lines);
    }
    Text exportText(){
        return text;
    }
    @property auto c_str(){
        return text.str.toStringz;
    }
    SDL_Texture* get_texture()
        in{
            assert(texture != null);
    }body{
        return texture;
    }
    void insert_char(char c){
        import std.stdio;
        writefln("insert :%c",c);
        writefln("current_line :%d",current_line);
        writefln("position :%d",text.position);
        text.insert(current_line,c);
    }
    void line_feed(){
        expand(Direct.down);
        move_cursorD();

    }
    void move_cursorR(){
        text.move_cursor!("cursor < right_edge_pos()",
            "++cursor;" )();
    }
    alias text.move_cursor!("cursor != 0",
            "--cursor;" )  move_cursorL; 
    alias text.move_cursor!("lines > current_line",
            "++current_line;" )  move_cursorD; 
    alias text.move_cursor!("current_line != 0",
            "--current_line;" )  move_cursorU; 
    void set_cursor()(int pos){
        text.set_cursor(pos); // 
    }
}
