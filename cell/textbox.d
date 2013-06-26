module cell.textbox;

import cell.cell;
import cell.table;
import cell.contentbox;
public import text.text;
import text.tag;
import std.string;
import std.utf;
import std.conv;
import std.stdio;
import std.ascii;
import std.exception;
import glib.SimpleXML;
import util.direct;
import shape.shape;
debug(cell) import std.stdio;

import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;
import pango.PgAttribute;
import pango.PgAttributeList;

// Text自体をTableに取り付けるためにBOX領域を管理する
final class TextBOX : ContentBOX{  
private:
    Text _text;
    string _box_fontfamly = "Sans";
    string _box_style = "Normal";
    ubyte  _box_font_size;
    Color _box_foreground = black;
    bool _color_fixed = false;

    string desc_str(){
        _box_font_size = cast(ubyte)_table.grid_size / 2 ;
        return _box_fontfamly~' '~_box_style~' '~to!string(_box_font_size);
    }
public:
    this(BoxTable table,string family = "Sans",string style = "Normal",in Color c = black){ 
        super(table);
        _box_fontfamly = family;
        _box_style = style;
        _box_foreground = c;
        if(family == "Monospace")
        {   // あとで追い出すけどMonospace 用の設定
            set_background_color(black);
            _box_foreground = lightyellow;
            _color_fixed = true;
        }
    }
    this(BoxTable table,in Cell tl,in int w,in int h){
        super(table,tl,w,h);
    }
    this(BoxTable table,TextBOX tb){
        _text = tb._text;
        _box_foreground = tb._box_foreground;

        super(table,tb);
    }
    this(BoxTable table,string markup){
        super(table);
    }
    this(BoxTable table,string[] dat){
        super(table);
        dat[0] = dat[0][6 .. $-1];
        auto pos = std.string.split(dat[0],",");
        int[] pos_num;
        foreach(numstr; pos)
        {
            string num;
            foreach(numc; numstr)
            {
                if(isDigit(numc))
                    num ~= numc;
            }
            pos_num ~= to!int(num);
            writeln(pos_num);
        }

        enforce(pos_num.length == 4);
        require_hold(Cell(pos_num[0],pos_num[1]),pos_num[2],pos_num[3]);
        auto desc = std.string.split(dat[2]," ");
        _box_fontfamly = chomp(desc[0]);
        _box_style = chomp(desc[1]);
        _box_font_size = to!ubyte(chomp(desc[2]));
        _box_foreground = Color(chomp(dat[3]));
        _text = Text(dat[4..$]);
    }        
    bool mark_caret = false;
    void move_caret(in Direct dir){
        _text.move_caret(dir);
    }
    void delete_char(){
        _text.deleteChar();
        if(_text.numof_lines < this.numof_row)
            require_remove(down);
    }

    override bool require_create_in(in Cell c)
    {
        return _table.try_create_in!(TextBOX)(this,c);
    }
    void set_box_default_color(in Color c){
        if(_color_fixed) return;
        _box_foreground = c;
    }
    void set_foreground_color(in Color c){
        if(_color_fixed) return;
        if(_text.empty)
        {
            _box_foreground = c;
        }
        else
            _text.set_foreground(c);
    }
    void set_background_color(in Color c){
        if(_text.empty) // box_colorを設定
            set_color(c); 
        else // 文字の背景色を設定
            _text.set_background(c);
    }
    void set_heading(in ubyte size)
        in{
        assert(size >= 0);
        assert(size <= 6);
        }
    body{
        assert(0);
    }
    void set_font_bigger(){
    }
    void input(string s){
        if(s == "\t" && _box_fontfamly == "Monospace")
            s = "    ";
        if(_text.is_in_end)
            append(s);
        else
            insert(s);
    }
    void insert(in string s){
        foreach(dchar c; s)
        {
            if(c == '\n')
                expand_with_text_feed();
            else
                _text.insert(c);
        }
    }
    void append(in string s){
        int feed_cnt;
        foreach(dchar c; s)
        {
            if(c == '\n') // 入力中は作動せず(改行文字は直接渡されない)、存在するstringを渡した時を想定している
            {
                expand_with_text_feed();
                ++ feed_cnt;
            }
            else
                _text.append(c);
        }
        _text.caret_move_forward(s.length - feed_cnt);
    }
    void backspace(){
        if(!_text.backspace()) // 行始でfalse
            require_remove(down);
    }
    void join(){
        if(_text.line_join())
            require_remove(down);
    }
    // 現状caretは改行時のみの使用になってる
    bool expand_with_text_feed(){
        if(require_expand(down))
        {
            _text.append('\n');
            return true;
        }else 
            return false;
    }
    string markup_string(){
        if(_text.empty) return null;
        SpanTag box_desc;
        box_desc.set_font_desc(desc_str());
        box_desc.set_foreground(_box_foreground);
        auto tmp =  box_desc.tagging(_text.markup_string());
        return tmp;
    }
    // 操作が終わった時にTableから取り除くべきか
    // super.is_to_spoil()は強制削除のためにはかます必要がある
    override bool is_to_spoil()const{
        return super.is_to_spoil() || _text.empty();
    }
    Text getText(){
        return _text;
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
        auto text_status = _text.current_foreground();
        if(text_status[0])
            return text_status[1];
        else 
            return default_foreground();
    }
    @property PgFontDescription font_desc(){
        return PgFontDescription.fromString(desc_str());
    }
    ubyte current_fontsize()const{
        const text_setting = _text.current_fontsize;
        return text_setting?
            text_setting : _box_font_size; 
    }
    int get_caret()const{
        return _text.caret;
    }
    string dat(in Cell offset=Cell(0,0)){
        string result ="[";
        writeln(top_left());
        writeln(offset);
        writeln(top_left - offset);
        result ~= to!string(top_left()-offset) ~',';
        result ~= to!string(numof_row) ~ ',';
        result ~= to!string(numof_col) ~ "]\n";
        result ~= "TextBOX * "~to!string(box_color)~"\n";
        result ~= desc_str ~ '\n';
        result ~= _box_foreground.hex_str ~'\n';
        result ~= _text.dat();
        writeln(result);
        return result;
    }
    void text_clear(){
        _text.clear();
    }
    override void clear(){
        super.clear();
        _text.clear();
    }
    bool text_empty()const{
        return _text.empty();
    }
    override bool empty()const{
        return super.empty && _text.empty;
    }
}
