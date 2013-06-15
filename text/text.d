module text.text;

import cell.cell;
import std.array;
import util.array;
import util.direct;
import util.color;
import util.span;
import gtkc.pangotypes;
import std.string;
import std.algorithm;
import std.typecons;
import std.utf;
import text.tag;
debug(text) import std.stdio; 
import std.stdio;

/+  memo
    .範囲を持たないspanでsetされたtag
    を_tag_poolから取り除くようにする
    .各tagを統一的に扱えるようにする
+/

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
    TextPoint opBinary(string op)(in int rhs)const if(op =="+"){
        return  TextPoint(line, pos+rhs);
    }
    TextPoint opBinary(string op)(in TextPoint rhs)const if(op =="+"){
        return  TextPoint(line+rhs.line, pos+rhs.pos);
    }
    TextPoint opBinary(string op)(in TextPoint rhs)const if(op =="-"){
        return  TextPoint(line-rhs.line, pos-rhs.pos);
    }
}
unittest{
    auto lower = TextPoint(1,1);
    auto upper = TextPoint(1,5);
    assert(lower < upper);
    auto upper2 = TextPoint(1,5);
    assert(upper == upper2);
    auto upper3 = TextPoint(2,0);
    assert(upper < upper3);
}

// Span!(int)のような操作は提供しない
// lineの持つpos幅を知る必要があるため
// 範囲を特定するためのマーカーとしてTextが使う
struct TextSpan{
private:
    TextPoint _min ;
    TextPoint _max ;
    ubyte _set_flg = not_set;
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
    int opCmp(in TextSpan rhs)const{
        auto tmp = _min - rhs._min ;
        return tmp.line * 1024 + tmp.pos;
    }
    const hash_t toHash(){
        hash_t hash;
        hash = _min.line * 255 + _min.pos * 15 + _set_flg;
        return hash;
    }
    bool opEquals(in TextPoint rhs)const{
        return is_hold(rhs);
    }
    // 完全に同じ範囲を指しているか
    bool opEquals(in TextSpan rhs)const{
        return _min == rhs._min && _max == rhs._max;
    }
    // operator == と等価
    @property bool is_hold(in TextPoint v)const{
        return _min <= v && v <= _max;
    }
    // 包含するか
    @property bool is_hold(in TextSpan s)const{
        return _min <= s._min && _max >= s._max;
    }
    @property TextPoint min()const{
        return _min;
    }
    @property TextPoint max()const{
        return _max;
    }
    @property bool is_set()const{
        return _set_flg == set_finish;
    }
    @property bool is_opened()const{
        return _set_flg == one_hand_set && _min != _max;
    }
}

struct Text
{   // TextBOX itemBOX で使われる文字列表現
    this(Text t){
        _lines = t._lines;
        _caret = t._caret;
        _current.line = t._current.line;
        _current.pos = t._current.pos;
        _writing = t._writing.dup;
        _line_length = t._line_length;
    }
    this(string[] dat){
        writeln("ok");
        _lines = to!int(chomp(dat[4]));
        foreach(l; 8 .. 8 + _lines)
        {
            if(l == 8 + _lines -1
            && dat[l][$-1] == '\n')
                dat[l] = dat[l][0 .. $-1];

            append(dat[l]);
            // if(l != 8 + _lines - 1)
            // {
            //     line_feed();
            //     // writeln("FEED");
            // }
        }
        writeln(_writing);
        writeln("ok");
        foreach(l; 0  ..  _lines)
            _line_length[l] = to!int(chomp(dat[9+_lines+l]));
        writeln(_line_length.values);
        writeln("ok");
        _caret = to!int(chomp(dat[9+_lines])); 
        writeln("ok");
        writeln(dat.length);
        auto s = std.string.split(dat[9+_lines*2],":");
        writeln(s);
    }
private:
    TextSpan _current_fontcolor_span;
    TextSpan _current_fontsize_span;
    TextSpan _current_underline_span;
    TextPoint _current;
    TextPoint _text_end;
    int _caret;

    alias int Pos;
    alias int Line;
    alias ubyte FontSize;

    // int _cursor;
    int _lines = 1;
    SpanTag[TextSpan] _tag_pool;
    dchar[Pos][Line] _writing;
    int[int] _line_length ;
    ubyte _current_fontsize;

    invariant(){
        assert(_current.line < _lines);
    }
    void deleteChar(in int pos){
        _writing[current_line].remove(pos);
    }
    TextPoint backward_pos(in TextPoint tp){
        if(!tp.pos)
        {
            if(tp.line)
            {
                auto above_line = tp.line-1;
                return TextPoint(above_line,writing[above_line].keys.sort[$-1]);
            }else
                return TextPoint(0,0);
        }
        else 
            return TextPoint(tp.line,tp.pos-1);
    }
    TextPoint backward_pos(){
        return backward_pos(_current);
    }
    void move_back(ref TextSpan ts)
        in{
        assert(ts.is_set());
        }
    body{
        if(!ts.is_set()) return;
        ts.set_end(backward_pos(ts.max));
    }
    // lineが存在しないなら""を返す
    // これに依存、str(TextPoint,TextPoint)
    @property string str(in int line)const{
        if(!_writing
        || !_writing.keys.empty()
        || line !in _writing
        || !_writing[line].values.empty())
        {
            dstring s;   
            foreach(i; _writing[line].keys.sort())
                s ~= _writing[line][i];
            return toUTF8(s);
        }else return "";
    }   
    dchar get_char(in TextPoint tp)const{
        if(tp.line !in _writing || tp.pos !in _writing[tp.line])
            throw new Exception("out of range");
        return _writing[tp.line][tp.pos];
    }
    @property string plane_string()const{
        string result;
        foreach(l; 0 .. _lines)
            result ~= str(l);
        return result;
    }
    bool is_valid_pos(in TextPoint tp)const{
        return tp.line in _writing && tp.pos in _writing[tp.line];
    }
    // endを含む
    string ranged_str(in TextPoint start,in TextPoint end)const{
        if(!is_valid_pos(start) || !is_valid_pos(end))
        {
            writeln("start pos ",start);
            writeln("end pos ",end);
            throw new Exception("not in range"); 
        }
        auto start_line = _writing[start.line];
        if(start.line == end.line)
        {
            if(start.pos == end.pos)
                return [str(start.line)[start.pos]];

            dstring result;
            foreach(i; start.pos .. end.pos+1)
            {
                result ~= _writing[start.line][i];
            }

            return toUTF8(result);
        }
        auto result = _writing[start.line].values;
        foreach(l; start.line+1 .. end.line)
        {   // 間に空行が存在してもstrが""返してくれるのを期待してる
            result ~= _writing[l].values;
        }
       
        foreach(i; 0 .. end.pos+1)
        {
            result ~= _writing[end.line][i];
        }
       
        writeln( toUTF8(result));
        return toUTF8(result);

        assert(0);
    }
    string ranged_str(in TextSpan span)const{
        return ranged_str(span.min,span.max);
    }
    unittest{
        Text text;
        text.append("なんかかっこいいこと言いたかった人生だった");
        auto start = TextPoint(0,16);
        auto end = TextPoint(0,17);
        auto result = text.ranged_str(start,end);
        assert(result == "人生");
        writeln(result);
    }
    @property TextPoint end_point(){
        auto line = _line_length.keys.sort[$-1];
        auto pos = _line_length[line];
        if(pos)
            return TextPoint(line,pos-1);
        else
            return TextPoint(line,0);
    }
    @property TextPoint back_point(){
        auto endp = end_point();
        if(endp.pos == 0)
            if(endp.line == 0)
                return TextPoint(0,0);
            else
            {
                auto l = endp.line -1;
                auto p = _line_length[l] -1;
                return TextPoint(l,p);
            }
        else
            return TextPoint(endp.line,endp.pos-1);
    }
    bool is_line_end(in TextPoint tp)const{
        return tp.pos == _line_length[tp.line];
    }
    bool is_line_head(in TextPoint tp)const{
        return tp.pos == 0;
    }
    bool above_line_exist(in int l)const{
        return l != 0;
    }
    bool next_line_exist(in int l)const{
        return cast(bool)((l+1) in _writing);
    }
    int line_length(in int line)const{
        assert(line in _line_length); 
        return _line_length[line];
    }
    TextPoint line_end(in int line)const{
        return TextPoint(line,line_length(line));
    }
    void move_to_next_head(){
        if(!next_line_exist(_current.line))
        {
            line_feed();
        }
        else 
        {
            ++_current.line;
            _current.pos = 0;
        }
    }
    TextPoint line_head(in int line)const{
        return TextPoint(line,0);
    }
    void check_line_length(in TextPoint tp){
        assert(tp.line in _line_length);
        if(_line_length[tp.line] < tp.pos)
            _line_length[tp.line] = tp.pos;
    }
    // check_line_lengthによるlengthのキャッシュ更新を行わないのに注意
    // ...constでいたいから
    TextPoint forward_point(in TextPoint tp)const{
        TextPoint result = tp;
        if(is_line_end(result))
        {
            if(next_line_exist(result.line)) 
                return line_head(result.line+1);
            else
                return line_end(result.line);
        }
        else
        {
            ++result.pos;
            assert(result.line in _line_length);
            return result;
        }
    }
    TextPoint backward_point(in TextPoint tp)const{
        TextPoint result = tp;
        if(is_line_head(result))
        {
            if(above_line_exist(result.line))
                return line_head(result.line);
            else
                return TextPoint(0,0);
        }
        else
        {
            --result.pos;
            assert(result.pos >= 0);
            return result;
        }
    }
public:
    string markup_string(){
        if(_tag_pool.keys.empty)
            return plane_string();
        if(empty())
            return null;

        TextPoint itr;
        TextPoint end = end_point();
        _writing.values.sort();
        string[][TextPoint] tag_pos;
        int opened_cnt;
        
        foreach(line,char_arry; _writing)
        foreach(pos,dc ; char_arry)
        {
            auto tp = TextPoint(line,pos);
            auto bp = backward_point(tp);
            auto fp = forward_point(tp);
            foreach(span; _tag_pool.keys)
            {   
                if(span.is_set && span.max == tp)
                {   // tag打ち後に文字を入れるので
                    tag_pos[fp] ~= _tag_pool[span].end_tag();
                }
                if(span.min == fp)
                {
                    auto tag = _tag_pool[span].start_tag();
                    tag_pos[fp] ~= tag;
                }
            }
        }
        foreach(span; _tag_pool.keys)
        {
            if(span.is_opened)
                ++opened_cnt;
        }
        if(opened_cnt < 0) 
            opened_cnt = 0;
        writeln(tag_pos);
        string result;
        foreach(line; _writing.keys.sort)
        {
            foreach(pos; _writing[line].keys.sort())
            {
                auto tp = TextPoint(line,pos);
                if(tp in tag_pos)
                {
                    foreach(tag; tag_pos[tp].sort)
                        result ~= tag;
                }
                result ~= _writing[line][pos];
            }
        }
        auto end_of_buffer = forward_point(end);
        writeln(end_of_buffer);
        if(end_of_buffer in tag_pos)
            foreach(end_tag; tag_pos[end_of_buffer])
                result ~= end_tag;
        writeln("opened:",opened_cnt);
        foreach(i;0 .. opened_cnt)
            result ~= "</span>";
        writeln(result);
        return result;
    }
    // 改行文字どうしよ
    // tag打つかpreformatとして仕込むか
    // current.pos はこれから値が入る位置.既に入ってるわけではない
    //     名前caretの方がいいかもしれない
    // だから_line_lengthはcurrent.posを含まず考慮する
    // ただ、長さなのでcurrent.posと一致することになる
    // _line_lengthは伸ばす方向のみこのメソッドでは扱う
    ulong append(in dchar c){
        _writing[current_line][_current.pos] = c;
        if(c != '\n')
        {
            ++_current.pos;
            ++_caret;
        }
        if(current_line !in _line_length)
            _line_length[current_line] = _current.pos;
        else if(_line_length[current_line] < _current.pos) 
            _line_length[current_line] = _current.pos;

        debug(text) writef("insert : %s\n",writing[current_line]);
        return _current.pos;
    }
    // TextBOXとは別パス。BOXの大きさの制約を受けないとき用途。TextBOXからは呼んではいけない。
    void append(string s){
        foreach(dchar c; s)
        {
            append(c);
            if(c == '\n')
                line_feed();
        }
    }
    @property bool empty()const{
        return (_writing.keys.empty())
        || (writing.length == 1 && _writing[0].keys.empty());
    }
    // 行始でfalse 通常true
    bool backspace(){
        if(_current.pos)
        {
            foreach_reverse(ref span;_tag_pool.keys)
            {
                if(span.max == _current)
                    move_back(span);
                if(span.min == _current && span.is_opened)
                    _tag_pool.remove(span);
            }

            deleteChar(--_current.pos);
            --_line_length[_current.line];
            return true;
        }
        else if(_current.line)
            line_join();
        return false;
    }
    @property string[int] strings(){
        string[int] result;
        foreach(line_num,one_line; _writing)
            result[line_num] = str(line_num);
        return result;
    }
    bool line_feed(){ // 新しい行を作ったか
        writeln("works");
        if(_current.line !in _writing)
            _writing[_current.line][0] = '\n';
        else
            _writing[_current.line][_current.pos] = '\n';
        ++_current.line;
        _current.pos = 0;
        _line_length[_current.line] = 0;
        if(_current.line !in _writing)
            _writing[_current.line] = null;
        if(_current.line == _lines)
        {
            ++_lines;
            return true;
        }
        return false;
    }
    bool line_join(){
        // 0行目とでは結合できない
        if(_current.line == 0) 
            return false;
 
        immutable cl = str(_current.line);
        immutable upper_line = _current.line-1;
        if(upper_line in _writing 
        && !(_writing[upper_line].keys.empty())
        && _current.pos == 0)
        {
            _writing.remove(_current.line);
            --_current.line;
            --_lines;
            auto sorted_upper = _writing[upper_line].keys.sort();
            const upper_last_pos = sorted_upper[$-1];
            _current.pos = upper_last_pos + 1;
        }
        // set_caret();
        foreach(dchar dc; cl)
            append(dc);
        return true;
    }
    // int right_edge_pos()const{
    //     auto current_line_positions = _writing[_current.line].keys.dup;
    //     auto sorted_positions = current_line_positions.sort();
    //     return sorted_positions[$-1];
    //     debug(text) writefln("type:%s",typeid(linepos));
    // }
    private Color _current_foreground;
    private bool _color_is_set = false;
    void set_foreground(in Color c){
        if(_current_fontcolor_span.is_opened)
        {   // 既にtag_poolに同一のSpanがあればそちらを共用する
            auto current_tag = _tag_pool[_current_fontcolor_span];
            _tag_pool.remove(_current_fontcolor_span);

            if(_current_fontcolor_span.min != _current)
            {   // 範囲のない指定に意味はない
                _current_fontcolor_span.set_end(backward_pos(_current));
                _tag_pool[_current_fontcolor_span] = current_tag;
                _tag_pool[_current_fontcolor_span].foreground(_current_foreground);
            }
        }
        _current_fontcolor_span = TextSpan();
        _current_fontcolor_span.set_start(_current);
        _tag_pool[_current_fontcolor_span] = SpanTag.init;
        _tag_pool[_current_fontcolor_span].foreground(c);
        _current_foreground = c;
        _color_is_set = true;
    }
    // 冗長
    // gui側の要請でとりあえずこぴぺるけど
    // tagをtag_typeをキーとした連想配列にして
    // templateの引数指定でtag_typeと引数の型をわたして実体化させる方向で書きなおす
    void set_fontsize(in ubyte fsz){
        if(_current_fontsize_span.is_opened)
        {   // 既にtag_poolに同一のSpanがあればそちらを共用する
            auto current_tag = _tag_pool[_current_fontcolor_span];
            _tag_pool.remove(_current_fontsize_span);

            if(_current_fontsize_span.min != _current)
            {   // 範囲のない指定に意味はない
                _current_fontsize_span.set_end(backward_pos(_current));
                _tag_pool[_current_fontsize_span] = current_tag;
                _tag_pool[_current_fontsize_span].font_size(_current_fontsize);
            }
        }
        _current_fontsize_span = TextSpan();
        _current_fontsize_span.set_start(_current);
        _tag_pool[_current_fontsize_span] = SpanTag.init;
        _tag_pool[_current_fontsize_span].font_size(fsz);
        _current_fontsize = fsz;
    }
    // アクセサ
    @property int current_line()const{
        return _current.line;
    }
    @property int current_pos()const{
        return _current.pos;
    }
    @property ubyte current_fontsize()const{
        return _current_fontsize;
    }
    @property Tuple!(bool,const Color) current_foreground()const{
        if(_color_is_set) 
            return tuple(true,_current_foreground);
        else return tuple(false,_current_foreground); 
    }
    @property int numof_lines()const{
        return _lines;
    }
    @property int caret()const{
        return _caret;
    }
    @property auto writing()const{
        return _writing;
    }
    import std.conv;
    string get_data_expression(){
        string result;
        result ~= to!string(_lines) ~ '\n';
        result ~= to!string(_color_is_set) ~ '\n';
        result ~= to!string(_current) ~ '\n';
        result ~= to!string(_text_end) ~ '\n';
        foreach(l; 0 .. _lines)
            result ~= str(l);
        result ~= '\n';
        foreach(l; 0 .. _lines)
            result ~= to!string(_line_length[l]) ~ '\n';
        result ~= to!string(_caret) ~ '\n';
        result ~= (to!string(_tag_pool))[1 .. $-1] ~ '\n';
        result ~= to!string(_current_fontsize) ~ '\n';
        result ~= to!string(_current_fontcolor_span) ~ '\n';
        result ~= to!string(_current_fontsize_span) ~ '\n';
        result ~= to!string(_current_underline_span) ~ '\n';
        return result;
    }
}

