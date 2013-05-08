module cell.textbox;

import cell.cell;
import text.text;
import std.string;
import std.utf;
import misc.direct;
import shape.shape;

class TextBOX : ContentBOX{  
    this(BoxTable table){ 
        super(table);
        text = new Text();
    }
    ~this(){}

    private:
    Text text;
    Cell text_offset; // boxのtext が格納されている場所へのoffset

    int caret;
    string font_name = "Sans Bold";
    char[] composition;
    int font_size;
    Color font_color;
    private final void insert_char(const dchar c){
        text.insert(c);
    }
    public final void insert(string s){
        foreach(dchar c; s)
            text.insert(c);
    }
    public final void insert_char(char[32LU] cs){
        import std.stdio;
        dstring s = cast(dstring)cs;
        insert_char(s[0]);
    }
    public final void backspace(){
        text.backspace();
    }
    public final void line_feed(){
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
    // アクセサ
    public:
    string get_fontname(){
        return font_name;
    }
    Text getText(){
        return text;
    }

}
