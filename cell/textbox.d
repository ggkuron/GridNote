module cell.textbox;

import cell.cell;
import text.text;
import std.string;
import std.utf;
import misc.direct;
import shape.shape;
debug(cell) import std.stdio;

// Text自体をTableに取り付けるためにBOX領域を管理する
final class TextBOX : ContentBOX{  
    this(BoxTable table){ 
        super(table);
        text = new Text();
    }
    ~this(){}

    private:
    Text text;

    int caret;
    string font_name = "Sans Bold";
    char[] composition;
    int font_size;
    Color font_color;
    private void insert_char(const dchar c){
        text.insert(c);
    }
    public void insert(string s){
        foreach(dchar c; s)
            text.insert(c);
    }
    // public void insert_char(char[32LU] cs){
    //     import std.stdio;
    //     dstring s = cast(dstring)cs;
    //     insert_char(s[0]);
    // }
    public void backspace(){
        text.backspace();
    }
    public:
    // userの意思でcaretを動かすとき
    void move_caretR(){
        text.move_caretR();
    }
    void move_caretL(){
        text.move_caretL();
    }
    void move_caretD(){
        if(text.move_caretD())
        {
            expand(Direct.down);
            debug(cell) writeln("expanded");
        }
    }
    void move_caretU(){
        text.move_caretU();
    }
    void set_caret()(int pos){
        text.set_caret(pos); // 
    }
    // 操作が終わった時にTableから取り除くべきか
    override bool is_to_spoil(){
        return text.empty();
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
