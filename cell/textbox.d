module cell.textbox;

import derelict.sdl2.sdl;
import derelict.sdl2.ttf;
import cell.cell;
import text.text;
import std.string;
import std.utf;
import misc.direct;
import shape.shape;

class TextBOX : ContentBOX
{   // text の行数を Cellの高さに対応させてみる
    this(ContentBOX parent,Cell[] offset){ 
        text = new Text();
        super(parent,offset);
    }
    ~this(){ }

    Text text;
    Cell text_offset;

    bool loaded_flg;
    int caret;
    int current_line;
    string font_name;
    char[] composition;
    int font_size;
    Color font_color;
    invariant(){
        assert(current_line <= text.lines);
    }
    Text exportText(){
        return text;
    }
    @property auto c_str(){
        return text.c_str;
    }
    void insert_char(const dchar c){
        import std.stdio;
        text.insert(current_line,c);
    }
    void insert(dstring s){
        import std.stdio;
        foreach(c; s)
            text.insert(current_line,c);
    }
    void insert_char(char[32LU] cs){
        import std.stdio;
        dstring s = cast(dstring)cs;
        insert_char(s[0]);
    }

    void line_feed(){
        expand(Direct.down);
        move_caretD();
    }
    void move_caretR(){
        text.move_caret!("caret < right_edge_pos()",
            "++caret;" )();
    }
    alias text.move_caret!("caret != 0",
            "--caret;" )  move_caretL; 
    alias text.move_caret!("lines > current_line",
            "++current_line;" )  move_caretD; 
    alias text.move_caret!("current_line != 0",
            "--current_line;" )  move_caretU; 
    void set_caret()(int pos){
        text.set_caret(pos); // 
    }
}
