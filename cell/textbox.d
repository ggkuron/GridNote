module cell.textbox;

import cell.cell;
import text.text;
import std.string;
import std.utf;
import misc.direct;
import shape.shape;

class TextBOX : ContentBOX{  
    // text の行数を Cellの高さに対応させてみる
    this(BoxTable table){ 
        super(table);
        text = new Text();
    }
    ~this(){}

    Text text;
    Cell text_offset; // boxのtext が格納されている場所へのoffset

    int caret;
    string font_name;
    char[] composition;
    int font_size;
    Color font_color;
    Text getText(){
        return text;
    }
    void insert_char(const dchar c){
        text.insert(c);
    }
    void insert(dstring s){
        foreach(c; s)
            text.insert(c);
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
    public:
    final void move_caretR(){
        text.move_caret!("caret < right_edge_pos()","++caret;")();
    }
    final void move_caretL(){
        text.move_caret!("caret != 0","--caret;")();
    }
    final void move_caretD(){
        text.move_caret!("lines > current_line","++current_line;")();
    }
    final void move_caretU(){
        text.move_caret!("current_line != 0","--current_line;")();
    }
    void set_caret()(int pos){
        text.set_caret(pos); // 
    }
}