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
private:
    Text text;

    // このpublicはそのうちどっかに
    public int cursor_pos; // 描画側（IM)が教えるために使う
                           // こいつに関してはTextBOXは面倒見ない 
    public int font_size = 32;
    public Color font_color;

    string font_name = "Sans Normal";
    char[] composition;
    void insert_char(const dchar c){
        text.insert(c);
    }
public:
    this(BoxTable table){ 
        super(table);
        text = new Text();
    }
    void insert(string s){
        foreach(dchar c; s)
            text.insert(c);
    }
    void backspace(){
        text.backspace();
    }
    // userの意思でcaretを動かすとき
    bool move_caretR(){
        return text.move_caretR();
    }
    bool move_caretL(){
        return text.move_caretL();
    }
    bool move_caretD(){
        if(require_expand(Direct.down)
            && text.move_caretD())
        {
            debug(cell) writeln("expanded");
            return true;
        }else return false;
    }
    bool move_caretU(){
        return text.move_caretU();
    }
    void set_caret()(int pos){
        text.set_caret(pos); // 
    }
    // 操作が終わった時にTableから取り除くべきか
    // super.is_to_spoil()は強制削除のためにはかます必要がある
    override bool is_to_spoil(){
        return super.is_to_spoil() || text.empty();
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
