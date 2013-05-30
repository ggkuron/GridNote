module text.text;

import cell.cell;
import std.array;
import util.array;
import util.direct;
import util.color;
import util.range;
import gtkc.pangotypes;
import std.string;
import std.algorithm;
import std.utf;
debug(text) import std.stdio; // printf dbg

struct TextPoint{
    int line;
    int pos;
    int opCmp(in TextPoint tp)const{
        if(tp.line == line)
            return pos - tp.pos;
        else
            return line - tp.line;
    }
    bool opEquals(in TextPoint r)const{
        return line == r.line && pos == r.pos;
    }
    Cell opBinary(string op)(in int rhs)const if(op =="+"){
        return  TextPoint(line, pos+rhs);
    }
}

// Range!(int)のような操作は提供しない
// lineの持つpos幅を知る必要があるため
// 範囲を特定するためのマーカーとしてTextが使う
struct TextRange{
private:
    TextPoint _min ;
    TextPoint _max ;  // 
    ubyte _set_flg;
    enum ubyte
      not_set = 0,
      one_hand_set = 1,
      set_finish = 2;      
public:
    void set(in TextPoint s,in TextPoint e)
        in{
        assert(s <= e);
        }
    body{
        _min = s;
        _max = e;
        _set_flg = set_finish;
    }
    void set_start(in TextPoint s){
        _min = s;
        if(_set_flg == one_hand_set)
            _set_flg = set_finish;
        else if(_set_flg == not_set)
            _set_flg = one_hand_set;
    }
    void set_end(in TextPoint e){
        _max = e;
        if(_set_flg == one_hand_set)
            _set_flg = set_finish;
        else if(_set_flg == not_set)
            _set_flg = one_hand_set;
    }
    int opCmp(in TextPoint i)const{
        if(_max < i) return -1;
        else if(_min > i ) return 1;
        else if(is_hold(i)) return 0;
        assert(0);
    }
    bool opEquals(in TextPoint rhs)const{
        return is_hold(rhs);
    }
    bool opEquals(in TextRange rhs)const{
        return _min == rhs._min && _max == rhs._max;
    }
    // operator == と等価
    @property bool is_hold(in TextPoint v)const{
        return _min <= v && v <= _max;
    }
    @property TextPoint min()const{
        return _min;
    }
    @property TextPoint max()const{
        return _max;
    }
    bool is_set()const{
        return _set_flg == set_finish;
    }
    bool is_opened()const{
        return _set_flg == one_hand_set;
    }
}

struct Text
{   // TextBOX itemBOX その他で使われる文字列表現TextBuffer相当
    this(Text t){
        _lines = t._lines;
        _caret = t._caret;
        _current.line = t._current.line;
        _current.pos = t._current.pos;
        _writing = t._writing.dup;
    }
private:
    int _lines = 1;
    Cell _caret;

    alias int pos;
    alias int line;
    alias PangoUnderline Underline;
    // 設定されるために開かれたRange
    TextRange _current_range;
    TextRange _current_font_color_range;

    dchar[pos][line] _writing;
    Color[TextRange] _font_color;
    Underline[TextRange] _under_line;
    TextPoint _current;

    invariant(){
        assert(_current.line < _lines);
    }
    void deleteChar(in int pos){
        _writing[current_line].remove(pos);
    }
    void set_caret(){
        _caret = Cell(_current.line,_current.pos);
    }
    TextPoint backward_pos(){
        if(!_current.pos)
            if(!_current.line)
            {
                auto above_line = _current.line-1;
                return TextPoint(above_line,writing[above_line].keys.sort[$]);
            }else return TextPoint(0,0);
        else return TextPoint(_current.line,_current.pos-1);
    }
public:
    ulong insert(in dchar c){
        _writing[current_line][_current.pos++] = c;
        _caret.move(Direct.right);
        debug(text) writef("insert : %s\n",writing[current_line]);
        return writing[current_line].length;
    }
    @property bool empty()const{
        return (_writing.keys.empty())
        || (writing.length == 1 && _writing[0].keys.empty());
    }
    // 行始でfalse 通常true
    bool backspace(){
        if(_current.pos)
        {
            deleteChar(--_current.pos);
            return true;
        }
        else if(_current.line)
            line_join();
        return false;
    }
    @property string str(in int line){
        if(!_writing.keys.empty()
        || !_writing[line].values.empty())
        {
            dstring s;   
            foreach(i; _writing[line].keys.sort())
                s ~= _writing[line][i];
            return toUTF8(s);
        }else return "";
    }   
    @property string[int] strings(){
        string[int] result;
        foreach(line_num,one_line; _writing)
            result[line_num] = str(line_num);
        return result;
    }
    bool line_feed(){ // 新しい行を作ったか
        if(_current.line !in _writing)
            _writing[_current.line] = null;

        ++_current.line;
        _current.pos = 0;
        if(_current.line == _lines)
        {
            ++_lines;
            return true;
        }
        return false;
    }
    bool line_join(){
        if(!_current.line || _current.line !in _writing) return false;
 
        auto cl = str(_current.line);
        --_current.line;
        --_lines;
        if(_current.line in _writing && !_writing[_current.line].keys.empty()
        || _current.line == 0 )
            _current.pos = _writing[_current.line].keys.sort()[$-1] + 1;
        set_caret();
        foreach(dchar dc; cl)
            insert(dc);
        return true;
    }
    int right_edge_pos(){
        auto linepos = _writing[_current.line].keys.sort();
        debug(text) writefln("type:%s",typeid(linepos));
        return linepos[$-1];
    }
    bool move_caretR(){
        if(_caret.column < right_edge_pos())
        {
            _caret.move(Direct.right);
            return true;
        }else return false;
    }
    bool move_caretL(){
        if(_caret.column != 0)
        {
            _caret.move(Direct.left);
            return true;
        }else return false;
    }
    bool move_caretU(){
        if(_current.line != 0)
        {
            --_current.line;
            _caret.move(Direct.up);
            return true;
        }else return false;
    }
    bool move_caretD(){
        debug(text) writeln("text feed");
        _caret.move(Direct.down);
        if(_lines-1 == _current.line)
        {
            debug(text) writeln("feeded");
            return line_feed();
        }
        else return false;
    }
    void set_color(in Color c){
        if(_current_font_color_range.is_opened)
        {
            _current_font_color_range.set_end(backward_pos());
            _font_color[_current_font_color_range] = c;
        }
        _current_font_color_range = TextRange();
        _current_font_color_range.set_start(_current);
    }
    // アクセサ
    @property int current_line()const{
        return _current.line;
    }
    @property int numof_lines()const{
        return _lines;
    }
    @property Cell caret()const{
        return _caret;
    }
    @property auto writing()const{
        return _writing;
    }
}

