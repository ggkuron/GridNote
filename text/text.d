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
import std.exception;
import std.typecons;
import std.utf;
import std.conv;
import text.tag;
debug(text) import std.stdio; 
import std.stdio;

/+  memo
    .範囲を持たないspanでsetされたtag
    を_tag_poolから取り除くようにする
    .各tagを統一的に扱えるようにする
+/

unittest{
    auto lower = TextPoint(1,1);
    auto upper = TextPoint(1,5);
    assert(lower < upper);
    auto more_upper = TextPoint(1,5);
    assert(upper == more_upper);
    auto middle = TextPoint(2,0);
    assert(upper < middle);
}
struct TextPoint{
    int line = -1;
    int pos = -1;
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
    this(int l,int p){
        line = l;
        pos = p;
    }
    this(string dat){
        dat = dat[1 .. $-1];
        auto lpstr = split(dat,",");
        line = to!int(lpstr[0]);
        pos = to!int(lpstr[1]);
    }
    string dat()const{
        return "("~to!string(line) ~","~to!string(pos)~")";
    }
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
    invariant(){
        assert(_set_flg >= not_set);
        assert(_set_flg <= set_finish);
    }
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
        {
            _set_flg = set_finish;
            if(_min > _max)
                _set_flg = not_set;
        }
        else if(_set_flg == not_set)
        {
            _set_flg = one_hand_set;
            _max = s;
        }
    }
    void set_end(in TextPoint e){
        _max = e;
        if(_set_flg == one_hand_set)
        {
            _set_flg = set_finish;
            if(_min > _max)
                _set_flg = not_set;
        }
        else if(_set_flg == not_set)
        {
            _set_flg = one_hand_set;
            _min = e;
        }
    }
    void re_open(LR tail = Right)
    {
        if(tail == Right)
            _max = _min;
        else
            _min = _max;
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
    unittest{
        auto a = TextSpan();
        a.set_start(TextPoint(0,0));
        a.set_end(TextPoint(0,0));
        assert( a == TextPoint(0,0));
        auto b = TextSpan();
        b.set_start(TextPoint(1,0));
        assert( a < b);
        b.set_start(TextPoint(0,1));
        assert( a < b);
        b.set_start(TextPoint(1,1));
        assert( a < b);
    }
    const hash_t toHash(){
        hash_t hash;
        hash = _min.line * 31 + _min.pos * 19 + _set_flg;
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
        return _set_flg == one_hand_set && _min <= _max ;
    }
    this(string dat){
        dat = dat[1 .. $-1];
        _set_flg = to!ubyte([dat[0]]);
        dat = dat[2 .. $];
        auto elems = split(dat,"),(");
        _min = TextPoint(elems[0]~')');
        _max = TextPoint('('~elems[1]);
    }
    string dat()const{
        string result = "(";
        result ~= to!string(_set_flg)~",";
        result ~= _min.dat() ~",";
        result ~= _max.dat() ;
        return result ~ ")";
    }
    void clear(){
        _min = TextPoint(-1,-1);
        _max = TextPoint(-1,-1);
        _set_flg = not_set;
    }
    unittest{
        auto span = TextSpan();
        span.set_start(TextPoint(0,0));
        assert(span.is_opened);
        auto dat = span.dat();
        assert(dat == "(1,(0,0),(0,0))");
        span.set_end(TextPoint(2,2));
        assert(span.is_set());
        auto dspan = TextSpan("(2,(0,0),(2,2))");
        assert(span == dspan);
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
        _lines = to!int(chomp(dat[4]));
        foreach(l; 8 .. 8 + _lines)
        {
            if(l == 8 + _lines -1
            && dat[l][$-1] == '\n')
                dat[l] = dat[l][0 .. $-1];

            append(dat[l]);
        }
        foreach(l; 0  ..  _lines)
            _line_length[l] = to!int(chomp(dat[9+_lines+l]));
        _caret = to!int(chomp(dat[9+_lines])); 

        auto tag_line = chomp(dat[9+_lines*2]);
        if(!tag_line.empty && tag_line != "\n")
        {
            tag_line = tag_line[1 .. $-1];
            auto pairs = split(tag_line,"><");
            foreach(one_pair; pairs)
            {   // spanとtagは既に一対にまとめられている。同じSpanならSpanTagひとつで表現される。
                auto elems = split(one_pair,"*");
                auto span = TextSpan(elems[0]);
                auto tag = SpanTag(elems[1]);
                if(span.is_opened)
                {
                    auto tag_types = tag.tag_types();
                    foreach(t; tag_types)
                    {
                        _current_opened_span[t] = span;
                    }
                }
                assert(span !in _tag_pool);
                _tag_pool[span] = tag;
            }
        }
    }
private:
    TextSpan[TagType] _current_opened_span;
    TextPoint _current = TextPoint(0,0);
    TextPoint _text_end;
    int _caret;

    alias int Pos;
    alias int Line;
    alias ubyte FontSize;

    int _lines = 1;
    SpanTag[TextSpan] _tag_pool;
    TextSpan[TextPoint] _tag_end_table;
    dchar[Pos][Line] _writing;
    int[int] _line_length;
    ubyte _current_fontsize;

    invariant(){
        assert(_current.line < _lines);
    }
    // current line のposを指定して削除
    void _deleteChar(in int pos){
        _writing[current_line].remove(pos);
    }
    TextPoint _backward_pos(in TextPoint tp){
        if(!tp.pos)
        {
            if(tp.line)
            {
                auto above_line = tp.line-1;
                return TextPoint(above_line,writing[above_line].keys.sort[$-1]);
            }else
                return TextPoint(0,0);
        }else 
            return TextPoint(tp.line,tp.pos-1);
    }
    TextPoint _backward_pos(){
        return _backward_pos(_current);
    }
    void _move_back(ref TextSpan ts)
    in{
    assert(ts.is_set());
    }
    body{
        if(!ts.is_set()) return;
        ts.set_end(_backward_pos(ts.max));
    }
    // lineが存在しないなら""を返す
    // これに依存、str(TextPoint,TextPoint)
    @property string _str(in int line)const{
        if(_writing
        && !_writing.keys.empty()
        && line in _writing
        && !_writing[line].values.empty())
        {
            dstring s;   
            foreach(i; _writing[line].keys.sort())
                s ~= _writing[line][i];
            return toUTF8(s);
        }else return "";
    }   
    dchar _get_char(in TextPoint tp)const{
        if(tp.line !in _writing || tp.pos !in _writing[tp.line])
            throw new Exception("out of range");
        return _writing[tp.line][tp.pos];
    }
    @property string _plane_string()const{
        string result;
        foreach(l; 0 .. _lines)
            result ~= _str(l);
        return result;
    }
    bool _is_valid_pos(in TextPoint tp)const{
        return tp.line in _writing && tp.pos in _writing[tp.line];
    }
    // endを含む
    string _ranged_str(in TextPoint start,in TextPoint end)const{
        if(!_is_valid_pos(start) || !_is_valid_pos(end))
        {
            writeln("start pos ",start);
            writeln("end pos ",end);
            throw new Exception("not in range"); 
        }
        auto start_line = _writing[start.line];
        if(start.line == end.line)
        {
            if(start.pos == end.pos)
                return [_str(start.line)[start.pos]];

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
       
        return toUTF8(result);

        assert(0);
    }
    string _ranged_str(in TextSpan span)const{
        return _ranged_str(span.min,span.max);
    }
    unittest{
        Text text;
        text.append("なんかかっこいいこと言いたかった人生だった");
        auto start = TextPoint(0,16);
        auto end = TextPoint(0,17);
        auto result = text._ranged_str(start,end);
        assert(result == "人生");
    }
    @property TextPoint _end_point(){
        auto line = _line_length.keys.sort[$-1];
        auto pos = line_length(line);
        if(pos)
            return TextPoint(line,pos-1);
        else
            return TextPoint(line,0);
    }
    @property TextPoint _back_point(){
        auto endp = _end_point();
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
    bool _is_line_end(in TextPoint tp)const{
        return tp.pos == _line_length[tp.line];
    }
    bool _is_line_head(in TextPoint tp)const{
        return tp.pos == 0;
    }
    bool _above_line_exist(in int l)const{
        return l != 0;
    }
    bool _next_line_exist(in int l)const{
        return cast(bool)((l+1) in _writing);
    }
    int line_length(in int line)const{
        assert(line in _line_length); 
        return _line_length[line];
    }
    TextPoint _line_end(in int line)const{
        return TextPoint(line,line_length(line));
    }
    void _move_to_next_head(){
        if(!_next_line_exist(_current.line))
        {
            line_feed();
        }
        else 
        {
            ++_current.line;
            _current.pos = 0;
        }
    }
    TextPoint _line_head(in int line)const{
        return TextPoint(line,0);
    }
    TextPoint _forward_point(in TextPoint tp)const{
        TextPoint result = tp;
        if(_is_line_end(result))
        {
            if(_next_line_exist(result.line)) 
                return _line_head(result.line+1);
            else
                return _line_end(result.line);
        }
        else
        {
            ++result.pos;
            assert(result.line in _line_length);
            return result;
        }
    }
    TextPoint _backward_point(in TextPoint tp)const{
        TextPoint result = tp;
        if(_is_line_head(result))
        {
            if(_above_line_exist(result.line))
                return _line_head(result.line);
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
            return _plane_string();
        if(empty())
            return "";

        TextPoint end = _end_point();
        _writing.values.sort();
        string[][TextPoint] tag_pos;
        int opened_cnt;
        
        foreach(line,char_arry; _writing)
        foreach(pos,dc; char_arry)
        {
            auto tp = TextPoint(line,pos);
            auto bp = _backward_point(tp);
            auto fp = _forward_point(tp);
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
        auto end_of_buffer = _forward_point(end);
        if(end_of_buffer in tag_pos)
            foreach(end_tag; tag_pos[end_of_buffer])
                result ~= end_tag;
        writeln("opened:",opened_cnt);
        foreach(i;0 .. opened_cnt)
            result ~= "</span>";
        return result;
    }
    // 改行文字
    // _writing行終に'\n'として入れてる
    // _writingが行ごとに分割したテーブルになってるので
    // 読み出すときのための書き出しルール
    // preformatということになるのだろうか

    // current.pos はこれから値が入る位置.既に入ってるわけではない
    //     名前caretの方がいいかもしれない
    // だから_line_lengthはcurrent.posを含まず考慮する
    // ただ、長さなのでcurrent.posと一致することになる

    // _line_lengthの伸ばす方向の変更は今のところここのみ
    // Textに文字を入れる操作は最終的にここを通る
    ulong append(in dchar c){
        _writing[current_line][_current.pos] = c;
        if(c != '\n')
            ++_current.pos;
        ++_caret;
        
        if(c == '\n')   line_feed;
        const cp = current_pos;
        if(current_line !in _line_length)
            _line_length[current_line] = cp;
        else if(_line_length[current_line] < cp) 
            _line_length[current_line] = cp;

        debug(text) writef("insert : %s\n",writing[current_line]);
        return _current.pos;
    }
    // TextBOXとは別パス。BOXの大きさの制約を受けないとき用途。TextBOXからは呼んではいけない。
    void append(string s){
        foreach(dchar c; s)
        {
            append(c);
            // if(c == '\n')
            //     line_feed();
        }
    }
    @property bool empty()const{
        return (_writing.keys.empty())
        || (writing.length == 1 && _writing[0].keys.empty());
    }
    // 行始でfalse 通常true
    bool backspace(){
        const pos_next = _backward_pos(_current);
        if(current_pos)
        {
            foreach_reverse(ref span;_tag_pool.keys)
            {
                if(span.max == _current)
                    _move_back(span);
                if(span.min == _current && span.is_opened)
                {
                    _tag_pool.remove(span);
                }
            }

            _deleteChar(--_current.pos);
            if(_line_length[current_line])
                --_line_length[current_line]; // pos に一致してるから負数にはならないとおもいきや、削除後に0になってるところでbackすると0になってるので
            return true;
        }
        else if(_current.line)
            line_join();
        return false;
    }
    @property string[int] strings(){
        string[int] result;
        foreach(line_num,one_line; _writing)
            result[line_num] = _str(line_num);
        return result;
    }
    // この関数内ではinvariantは成立していないので
    // アクセサを使ってはだめ
    bool line_feed(){ // 新しい行を作ったか
        if(current_line !in _writing)
            _writing[current_line][0] = '\n';
        else
            _writing[current_line][current_pos] = '\n';

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
        if(current_line == 0) 
            return false;
 
        immutable cl = _str(current_line);
        immutable upper_line = current_line-1;
        if(upper_line in _writing 
        && !(_writing[upper_line].keys.empty())
        && current_pos == 0)
        {
            _writing.remove(current_line);
            --_current.line;
            --_lines;
            auto sorted_upper = _writing[upper_line].keys.sort();
            const upper_last_pos = sorted_upper[$-1];
            _current.pos = upper_last_pos + 1;
        }
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
    private Color _current_background;

    // 色の未定義値表現がないからこんなことに
    // optionalかnullableで包みたい
    // 上の層に設定されてるかどうか知らせる必要がある
    // 入力中の文字色をこの層で設定してなくて上の層で設定している状態を持てるように設計してるから
    // 階層的にtag適用できる設計は必要だと思う
    // さもなくば文字列の修飾なんてつまらないものになるか、制御が難しくなるか

    private bool _color_is_set = false;
    private ref TextSpan _opened(TagType t){
        assert(t in _current_opened_span);
        return _current_opened_span[t];
    }
    private void _set_pooled_tag(TagType t,in TextSpan s,Color v){
        switch(t){
            case foreground_tag:
                _tag_pool[s].foreground(v);
                break;
            case background_tag:
                _tag_pool[s].background(v);
                break;
            default:
                assert(0);
                break;
        }
    }
    private void _set_pooled_tag(TagType t,in TextSpan s,ubyte v){
        switch(t){
            case font_size_tag:
                _tag_pool[s].font_size(v);
                break;
            default:
                assert(0);
                break;
        }
    }
    // UNDIFINED
    //         case underline_ta:
    //         case font_desc_tag:
    //         case font_family_tag:
    //         case face_tag:
    //         case style_tag:
    //         case weight_tag:
    private void _set_tag(TagType tt,T)(in T val,ref T state_val){
        if(tt !in _current_opened_span)
        {   // この初期化は初回一回だけなのでctorに移動したい。
            _current_opened_span[tt] = TextSpan.init;
        }
        if(val == state_val) return;
        const opened = _opened(tt); // openedは単なるコピー
        if(opened.is_opened)
        {   
            assert(opened in _tag_pool);
            _opened(tt).set_end(_backward_pos(_current));
            const closed = _opened(tt); 
            auto current_tag = _tag_pool[opened];
            if(closed in _tag_pool)
            {   // 同じ期間で閉じているtag-span対があればそのtagに属性を追加する
                current_tag = _tag_pool[closed];
                enforce(_tag_pool.remove(closed));
            }
            enforce(_tag_pool.remove(opened));
            if(closed.is_set())
            {
                _tag_pool[closed] = current_tag;
                _set_pooled_tag(tt,closed,val);
            }
        }
        _opened(tt).clear();
        _opened(tt).set_start(_current);
        const opened_new = _opened(tt);
        if(opened_new !in _tag_pool)
            _tag_pool[opened_new] = SpanTag.init;
        _set_pooled_tag(tt,_opened(tt),val);
        state_val = val;
    }
    void set_foreground(in Color c){
        _set_tag!(foreground_tag,Color)(c,_current_foreground);
        _color_is_set = true;
    }
    void set_background(in Color c){
        _set_tag!(background_tag,Color)(c,_current_background);
    }
    void set_fontsize(in ubyte fsz){
        _set_tag!(font_size_tag,ubyte)(fsz,_current_fontsize);
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
    string dat(){
        string result;
        result ~= to!string(_lines) ~ '\n';
        result ~= to!string(_color_is_set) ~ '\n';
        result ~= to!string(_current) ~ '\n';
        result ~= to!string(_text_end) ~ '\n';
        foreach(l; 0 .. _lines)
            result ~= _str(l);
        result ~= '\n';
        foreach(l; 0 .. _lines)
            if(l in _line_length)
            result ~= to!string(_line_length[l]) ~ '\n';
        result ~= to!string(_caret) ~ '\n';
        foreach(span,tag; _tag_pool)
            result ~= "<"~span.dat ~"*"~tag.dat() ~">";
        result ~= "\n";
        foreach(span; _current_opened_span)
            result ~= to!string(span) ~ '\n';
        return result;
    }
}

