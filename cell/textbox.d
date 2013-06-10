module cell.textbox;

import cell.cell;
import cell.table;
import cell.contentbox;
import text.text;
import text.tag;
import std.string;
import std.utf;
import std.conv;
import util.direct;
import shape.shape;
debug(cell) import std.stdio;
import std.stdio;

import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;
import pango.PgAttribute;
import pango.PgAttributeList;


// Text自体をTableに取り付けるためにBOX領域を管理する
final class TextBOX : ContentBOX{  
private:
    Text _text;
    int _cursor_pos; // 描画側（IM)が教えるために使う

    string _box_fontfamly = "Sans";
    string _box_style = "Normal";
    int  _box_font_size ;
    Color _box_foreground = black;

    string desc_str()const{
        return _box_fontfamly~' '~_box_style~' '~to!string(_box_font_size);
    }
public:
    this(BoxTable table){ 
        super(table);
        _box_font_size = _table.grid_size * 2 / 3;
    }
    this(BoxTable table,in Cell tl,in int w,in int h){
        super(table,tl,w,h);
    }
    this(BoxTable table,TextBOX tb){
        _text = tb._text;
        _cursor_pos = tb.cursor_pos;
        _box_foreground = tb._box_foreground;

        super(table,tb);
    }
    override bool require_create_in(in Cell c)
    {
        return _table.try_create_in!(TextBOX)(this,c);
    }
    void set_box_default_color(in Color c){
        _box_foreground = c;
    }
    void set_foreground_color(in Color c){
        _text.set_color(c);
    }
    override void set_color(in Color c){
        set_foreground_color(c);
    }
    void append(string s){
        foreach(dchar c; s)
        {
            _text.append(c);
            // if(c == '\n') expand_with_text_feed();
        }
    }
    void backspace(){
        if(!_text.backspace())
            require_remove(down);
    }
    // 現状caretは改行時のみの使用になってる
    // Text::TextPointをcaretとして扱う実装仕様にする

    // bool move_caretR(){
    //     return _text.move_caretR();
    // }
    // bool move_caretL(){
    //     return _text.move_caretL();
    // }
    bool expand_with_text_feed(){
        if(require_expand(down))
        {
            _text.line_feed();
            return true;
        }else 
            return false;
    }
    bool move_caretU(){
        return _text.move_caretU();
    }
    void set_caret()(in int pos){
        _text.set_caret(pos); // 
    }
    string markup_string(){
        if(_text.empty) return null;
        SpanTag box_desc;
        box_desc.font_desc(desc_str());
        box_desc.foreground(_box_foreground);
        auto tmp =  box_desc.tagging(_text.markup_string());
        // writeln(_text.markup_string());
        // writeln(tmp);
        return tmp;
    }
    // 操作が終わった時にTableから取り除くべきか
    // super.is_to_spoil()は強制削除のためにはかます必要がある
    override bool is_to_spoil()const{
        return super.is_to_spoil() || _text.empty();
    }
    // アクセサ
    // string get_fontname()const{
    //     return _box_fontfamly;
    // }
    Text getText(){
        return _text;
    }
    void set_cursor_pos(in int p){
        _cursor_pos = p;
    }
    @property int cursor_pos()const{
        return _text.current_pos;
    }
    @property int cursor_line()const{
        return _text.current_line;
    }
    @property int numof_lines()const{
        return _text.numof_lines;
    }
    @property Color default_foreground()const{
        return _box_foreground;
    }
    @property Color current_foreground()const{
        return _text.current_foreground;
    }
    @property PgFontDescription font_desc(){
        _box_font_size = _table.grid_size * 2 / 3;
        return PgFontDescription.fromString(desc_str());
    }
    // @property ubyte input_font_size()const{
    //     return _box_size;
    // }
}
