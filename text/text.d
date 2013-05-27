module text.text;

import cell.cell;
import std.array;
import util.array;
import util.direct;
import std.string;
import std.algorithm;
import std.utf;

debug(text) import std.stdio; // printf dbg
struct Text
{   // TextBOX itemBOX その他で使われる文字列表現TextBuffer相当
    this(Text t){
        _lines = t._lines;
        _caret = t._caret;
        _current_line = t._current_line;
        _position = t._position;
        _writing = t._writing.dup;
    }
private:
    int _lines = 1;
    Cell _caret;
    alias int pos;
    alias int line;
    dchar[pos][line] _writing;
    int _current_line; 
    int _position;
    invariant(){
        assert(_current_line < _lines);
    }
    void deleteChar(int pos){
        _writing[current_line].remove(pos);
    }
    void set_caret(){
        _caret = Cell(_current_line,_position);
    }
public:
    ulong insert(dchar c){
        _writing[current_line][_position++] = c;
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
        if(_position)
        {
            deleteChar(--_position);
            return true;
        }
        else if(_current_line)
            line_join();
        return false;
    }
    @property string str(int line){
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
        if(_current_line !in _writing)
            _writing[_current_line] = null;

        ++_current_line;
        _position = 0;
        if(_current_line == _lines)
        {
            ++_lines;
            return true;
        }
        return false;
    }
    bool line_join(){
        if(!_current_line || _current_line !in _writing) return false;
 
        auto cl = str(_current_line);
        --_current_line;
        --_lines;
        if(_current_line in _writing && !_writing[_current_line].keys.empty()
        || _current_line == 0 )
            _position = _writing[_current_line].keys.sort()[$-1] + 1;
        set_caret();
        foreach(dchar dc; cl)
            insert(dc);
        return true;
    }
    int right_edge_pos(){
        auto linepos = _writing[_current_line].keys.sort();
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
        if(_current_line != 0)
        {
            --_current_line;
            _caret.move(Direct.up);
            return true;
        }else return false;
    }
    bool move_caretD(){
        debug(text) writeln("text feed");
        _caret.move(Direct.down);
        if(_lines-1 == _current_line)
        {
            debug(text) writeln("feeded");
            return line_feed();
        }
        else return false;
    }
    // アクセサ
    @property int current_line()const{
        return _current_line;
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

