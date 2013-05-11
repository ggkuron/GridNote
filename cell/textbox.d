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
private:
    Text text;

    public int cursor_pos; // 描画側（IM)が教えるために使う
                           // こいつに関してはTextBOXは面倒見ない 
    public int font_size = 32;
    public Color font_color;

    string font_name = "Sans Bold";
    char[] composition;
    void insert_char(const dchar c){
        text.insert(c);
    }
public:
    void insert(string s){
        foreach(dchar c; s)
            text.insert(c);
    }
    void backspace(){
        text.backspace();
    }
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
