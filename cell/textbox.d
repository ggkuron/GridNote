module cell.textbox;

import cell.cell;
import cell.table;
import cell.contentbox;
import text.text;
import std.string;
import std.utf;
import util.direct;
import shape.shape;
debug(cell) import std.stdio;

// Text自体をTableに取り付けるためにBOX領域を管理する
final class TextBOX : ContentBOX{  
private:
    Text _text;
    int _cursor_pos; // 描画側（IM)が教えるために使う
    ubyte _font_size = 32;
    Color _font_color = blue;
    string _font_name = "Sans Normal";
    void insert_char(in dchar c){
        _text.insert(c);
    }
public:
    this(BoxTable table){ 
        super(table);
    }
    this(BoxTable table,in Cell tl,in int w,in int h){
        super(table,tl,w,h);
    }
    this(BoxTable table,TextBOX tb){
        _text = tb._text;
        _cursor_pos = tb.cursor_pos;
        _font_color = tb.font_color;

        super(table,tb);
    }
    override bool require_create_in(in Cell c)
    {
        return table.try_create_in(this,c);
    }
    void set_font_color(in Color c){
        _font_color = c;
        _text.set_color(c);
    }
    void insert(string s){
        foreach(dchar c; s)
            _text.insert(c);
    }
    void backspace(){
        if(!_text.backspace())
            require_remove(Direct.down);
    }
    // userの意思でcaretを動かすとき
    // caret関連完全未実装
    bool move_caretR(){
        return _text.move_caretR();
    }
    bool move_caretL(){
        return _text.move_caretL();
    }
    bool move_caretD(){
        if(require_expand(Direct.down)
            && _text.move_caretD())
        {
            debug(cell) writeln("expanded");
            return true;
        }else return false;
    }
    bool move_caretU(){
        return _text.move_caretU();
    }
    void set_caret()(in int pos){
        _text.set_caret(pos); // 
    }
    // 操作が終わった時にTableから取り除くべきか
    // super.is_to_spoil()は強制削除のためにはかます必要がある
    override bool is_to_spoil()const{
        return super.is_to_spoil() || _text.empty();
    }
    // アクセサ
    string get_fontname()const{
        return _font_name;
    }
    Text getText(){
        return _text;
    }
    void set_cursor_pos(in int p){
        _cursor_pos = p;
    }
    @property int cursor_pos()const{
        return _cursor_pos;
    }
    @property Color font_color()const{
        return _font_color;
    }
    @property ubyte font_size()const{
        return _font_size;
    }
}
