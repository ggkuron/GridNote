module text.text;

import cell.cell;
import std.array;
import util.array;
import util.direct;
import util.color;
import util.span;
import gtkc.pangotypes;
import glib.SimpleXML;
import std.string;
import std.algorithm;
import std.exception;
import std.typecons;
import std.utf;
import std.conv;
import std.traits;   
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
    // 渡すstring例: "(12,4)" 
    this(string dat){
        writeln(dat);
        dat = dat[1 .. $-1];
        auto lpstr = split(dat,",");
        line = to!int(lpstr[0]);
        pos = to!int(lpstr[1]);
    }
    string dat()const{
        return "("~to!string(line) ~","~to!string(pos)~")";
    }
    static @property TextPoint init(){
        return TextPoint(-1,-1);
    }
    void claer(){
        this = init;
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
            if(_min > _max && _max != TextPoint.init)
                _set_flg = not_set;
            else
                _set_flg = set_finish;
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
            if(_min > _max)
                _set_flg = not_set;
            else
                _set_flg = set_finish;
        }
        else if(_set_flg == not_set)
        {
            _set_flg = one_hand_set;
            _max = e;
        }
    }
    // has_no_spanとis_openedの違い
    // is_opened ならば has_no_span
    bool has_no_span()const{
        return _min == _max 
            || (_min != TextPoint.init && _max == TextPoint.init)
            || (_max != TextPoint.init && _min == TextPoint.init);
    }
    void re_open(LR tail = Right)
    {
        if(tail == Right)
            _max = TextPoint(-1,-1);
        else
            _min = TextPoint(-1,-1);
        _set_flg = one_hand_set;
    }
    int opCmp(in TextPoint i)const{
        if(_max < i) return -1;
        else if(_min > i ) return 1;
        else if(is_hold(i)) return 0;
        assert(0);
    }
    // 等価比較はできない
    int opCmp(in TextSpan rhs)const{
        if(_min < rhs._min)
        {
            if(_max < rhs._max)
                return -1;
            else
                return 0;
        }else if(_min > rhs._min)
        {
            if(_max > rhs._max)
                return 1;
            else
                return 0;
        }else
            return 0;
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
        return 
            (_set_flg == one_hand_set)
            && 
            (
                (_min <= _max)
                || 
                ( 
                    (_min != TextPoint.init && _max == TextPoint.init)
                    ||
                    (_max != TextPoint.init && _min == TextPoint.init)
                )
            );
    }
    @property bool is_not_set()const{
        return _set_flg == not_set;
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
    // この２つを違う値にするText::_apply_tagsとかが死ぬ
    static TextSpan init(){
        return TextSpan();
    }
    static TextSpan invalid(){
        return TextSpan();
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
        const lines = to!int(chomp(dat[0]));
        int ln;
        writeln("l:",_lines);
        foreach(l; 0 .. lines)
        {
            writeln(dat[4+l]);

            auto line_str = dat[4+l];
            if(l == lines -1)
                append(chomp(line_str)); // dat()時に仕込んだ改行文字を取り除く
            else
                append(line_str);
            writeln("per line length:",dat[l+lines+5]);
            _line_length[l+lines] = to!int(chomp(dat[l+lines+5]));
        }
        _lines = lines; // append後の値と一致してればそれはそれでいい assert(lines == _lines); 
        writeln("caret:",dat[5+_lines*2]);
        _caret = to!int(chomp(dat[5+_lines*2])); 

        auto tag_line = chomp(dat[5+_lines*2+1]);
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
        // set _current
        auto c_str = (chomp(dat[2]))["TextPoint".length .. $];
        _current = TextPoint(removechars(c_str," "));
        // _current = TextPoint(c_str);
    }
private:
    TextSpan[TagType] _current_opened_span;
    TextPoint _current = TextPoint(0,0);
    TextPoint _text_end;
    int _caret; // byte数でのカウント.pangoのせい

    alias int Pos;
    alias int Line;
    alias ubyte FontSize;

    int _lines = 1;
    SpanTag[TextSpan] _tag_pool;
    TextSpan[TextPoint] _tag_end_table;
    dchar[Pos][Line] _writing;
    int[int] _line_length;

    invariant(){
        assert(_current.line < _lines);
    }
    void deleteChar(in TextPoint tp){
        assert(_is_valid_pos(tp));
        const line = tp.line;
        const bytesize = _byte_size(tp);
        const line_len = _line_length[line];
        auto line_save = _writing[line];
        
        foreach_reverse(ref span;_tag_pool.keys)
        {
            const snap = span;
            if(span.max == pos_next)
            {
                _move_back(span);
                writefln("move at %s",_current);
                writefln("flg %s",span._set_flg);
                writefln("max : %s",span.max);
                writefln("min : %s",span.min);
            }
            else if(span.min == pos_next && span.has_no_span)
                _tag_pool.remove(span);
        }
        deleteChar(pos_next);
        return true;
        }
        return false;

        foreach(p; tp.pos .. line_len-1)
            _writing[line][p] = _writing[line][p+1];
        enforce(_writing[line].remove(line_len-1));

        --_line_length[line];
        _caret -= bytesize;
        if(!_line_length[current_line])
        {
            line_join(current_line);
        }
    }
    unittest{
        Text t1;
        t1.append("0123456789");
        assert(t1._line_length[0] == 10);
        assert(t1._caret == 10);
        t1.deleteChar(TextPoint(0,5));
        writeln(t1._plane_string());
        assert(t1._plane_string == "012346789");
        assert(t1._line_length[0] == 9);
        assert(t1._caret == 9);
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
    // _tag_pool内に存在するtag内で
    // 一番大きい_maxを持つもののtags を_current_opened_spanに適用する
    // 後ろから読んでいくから、tagの重複を別の部分で取り除かないいけない
    // tagの重複させないためにどうすればいいのか
    //  .設定時は重複を許してあとで取り除くか
    //  .設定時に重複しないように工夫するか
    // 後者のがもちろんいい
    // そのためにはtagの前後関係をとれるようにしないといけない

    // tpを含む最大方向のtagを適応する
    // has_no_spanがtrueになるtagが入ってると
    // 期待と違う動きするかも
    // openedなno_spanを認めるためにこのなかではhas_no_spanは放置する

    void _set_current_value(in TagType tt,in Color c){
        switch(tt){
            case foreground_tag:
                _current_foreground.set(c);
                break;
            case background_tag:
                _current_background.set(c);
                break;
            default:
                assert(0);
        }
    }
    void _set_current_value(in TagType tt,in ubyte b){
        switch(tt){
            case font_size_tag:
                _current_fontsize.set(b);
                break;
            default:
                assert(0);
        }
    }

    TextSpan _used_span_in_tags(in TextPoint tp,TagType tt){
        TextSpan itr;
        foreach(span; _tag_pool.keys.sort)
        {
            if(span.is_hold(tp) && _tag_pool[span].is_set(tt)
                    && itr < span)
                itr = span;
        }
        return itr;
    }
    void _apply_tags(in TextPoint tp){
        foreach(tt; EnumMembers!(TagType))
        {
            auto span = _used_span_in_tags(tp,tt);
            // writeln("hit span is ",span);
            _current_opened_span[tt] = span;
            if(span == TextSpan.invalid) continue;
            auto tag = _tag_pool[span];
            if(span.is_set) 
            {
                _tag_pool.remove(span);
                span.re_open();
            }else assert(0);
            _current_opened_span[tt] = span;
            _tag_pool[span] = tag;
            assert(span.is_opened);
            // writeln("set opened ",span);
            switch(tt){
                case foreground_tag:
                    _set_current_value(tt,tag.foreground[1]);
                    break;
                    default:
                        assert(0); // 未実装
            }
        }
        // writeln(_tag_pool);
    }
    // 与えられて_tag_pool内のSpanを押し戻す
    // 未
    void _reopen_spantag(ref TextSpan ts){
        const snap = ts;
        _apply_tags(_backward_pos(ts.min));
        _tag_pool.remove(snap);
    }
    /+ tag_pool内のspanの後ろ側終端を
       閉じたspan
     
    +/
    void _move_back(ref TextSpan ts){
        const snap = ts;
        auto tg = _tag_pool[ts];
        auto tts = tg.tag_types();
        if(snap.is_set)
        {   
            if(snap.has_no_span)
            {
                _tag_pool.remove(ts);
                _apply_tags(_backward_pos(snap.min));
            }
            else 
            {
                // writeln(snap," is not set and has span");
                ts.set_end(_backward_pos(ts.max));
                _apply_tags(ts.min);
            }
        }
        else if(snap.is_opened)
        {  
            if(snap.has_no_span)
            {
                // writeln(snap," is opened and has no span");
                _tag_pool.remove(snap);
                _apply_tags(_backward_pos(snap.min));
            }
            else
            {
                // writeln(snap," is opened and has span");
                ts.set_end(_backward_pos(ts.max));
                _apply_tags(ts.max);
            }
        }
        // writeln(_tag_pool);
    }
    // lineが存在しないなら""を返す
    // これに依存、str(TextPoint,TextPoint)
    // escapeされてない文字が返る
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
        {
            // writeln(tp);
            throw new Exception("out of range");
        }
        return _writing[tp.line][tp.pos];
    }
    @property string _plane_string()const{
        string result;
        foreach(l; 0 .. _lines)
            result ~= _str(l);
        return SimpleXML.escapeText(result,result.length);
    }
    bool _is_valid_pos(in TextPoint tp)const{
        return tp.line in _writing && tp.pos in _writing[tp.line];
    }
    // endを含む
    string _ranged_str(in TextPoint start,in TextPoint end)const{
        if(!_is_valid_pos(start) || !_is_valid_pos(end))
        {
            // writeln("start pos ",start);
            // writeln("end pos ",end);
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
    bool _is_line_end(in TextPoint tp )const{
        return tp.pos == _line_length[tp.line];
    }
    bool _is_line_head(in TextPoint tp)const{
        return tp.pos == 0;
    }
    bool _above_line_exist(in int l)const{
        return l != 0;
    }
    bool _next_line_exist(in int l)const{
        return l < _lines-1;
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
    TextPoint _forward_point(in TextPoint tp = _current)const{
        TextPoint p = tp;
        if(_is_line_end(p))
        {
            if(_next_line_exist(p.line)) 
                return _line_head(p.line+1);
            else
                return _line_end(p.line);
        }
        else
        {
            ++p.pos;
            assert(p.line in _line_length);
            return p;
        }
    }
    unittest{
        import std.stdio;
        Text text;
        text.append("123456789");
        writeln(text._current);
        assert(text._current == TextPoint(0,9));
        assert(text._backward_point(text._current) == TextPoint(0,8));
        assert(text._is_line_end(text._current));
        text.line_feed();
        assert(text._line_end(0) == TextPoint(0,9));
        assert(text._is_line_end(TextPoint(0,9)));
        // assert(text._is_line_end(TextPoint(0,10)));
        assert(text.numof_lines == 2);
        assert(text._next_line_exist(0));
        assert(text._current == TextPoint(1,0));
        text.backspace();
        assert(text.numof_lines == 1);
        assert(!text._next_line_exist(0));
        text.line_feed();
        text.append("123456789\n");
        writeln(text._current);
        // assert(text._current == TextPoint(1,9));
        // assert(text._backward_point(text._current) == TextPoint(0,8));
        // assert(text._is_line_end(text._current));
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
            return null;

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
        {   // "</span>" for opened span
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
                // 一文字ずつエスケープしてる効率は
                string one_char = [cast(char)(_writing[line][pos])];
                writef("%s",one_char);
                // 二重にエスケープしてしまわないようにはじければいらない
                if(one_char == "&" || one_char == "<" || one_char == ">")
                    result ~= SimpleXML.escapeText(one_char,one_char.length);
                else
                    result ~= _writing[line][pos];
            }
        }
        auto end_of_buffer = _forward_point(end);
        if(end_of_buffer in tag_pos)
            foreach(end_tag; tag_pos[end_of_buffer])
                result ~= end_tag;
        // writeln("opened:",opened_cnt);
        foreach(i;0 .. opened_cnt)
            result ~= "</span>";
        writeln(_tag_pool);
        writeln(_writing);
        writeln(result);
        return result;
    }
    // .. カプセル化壊すがCell.TextBOXでappendするときにbyte数をとれるから
    // void impel_caret(in ulong s){
    //     _caret += s;
    // }
    void move_caret(in Direct dir){
    }

    // private void _char_in(in TextPoint tp,in dchar c){
    //     _writing[tp.line][tp.pos] = c;
    // }
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
        
        if(c == '\n')   line_feed;
        const cp = current_pos;
        if(current_line !in _line_length)
            _line_length[current_line] = cp;
        else if(_line_length[current_line] < cp) 
            _line_length[current_line] = cp;
        if(_current > _text_end)
            _text_end = _current;

        return _current.pos;
    }
    void insert(in TextPoint tp,in dchar c){
        assert(_is_valid_pos(tp));
        const line_len = _line_length[tp.line];
        auto line_p = _writing[tp.line].dup;
        _writing[tp.line][tp.pos] = c;
        foreach(p; tp.pos+1 .. line_len +1)
            _writing[tp.line][p] = line_p[p-1];
        assert(_line_length[tp.line] == line_len);
        ++_line_length[tp.line];
    }
    unittest{
        Text t1;
        t1.append("0123456789");
        assert(t1._line_length[0] == 10);
        writeln(t1._plane_string);
        t1.insert(TextPoint(0,5),'x');
        writeln(t1._plane_string);
        assert(t1._plane_string == "01234x56789");
        assert(t1._line_length[0] == 11);
    }
    void caret_move_forward(in ulong u){
        _caret += u;
    }
    // TextBOXとは別パス。BOXの大きさの制約を受けないとき用途。TextBOXからは呼んではいけない。
    void append(string s){
        caret_move_forward(s.length);
        foreach(dchar c; s)
        {
            append(c);
        }
        // _caret += s.length;
    }
    @property bool empty()const{
        return (_writing.keys.empty())
        || (_lines == 1 && _writing[0].keys.empty());
    }
    // Writing内文字のbyte数
    ulong _byte_size(in TextPoint tp){
        return to!string(_get_char(tp)).length;
    }
    // 行始でfalse 通常true
    void move_caret(in Direct dir){
        final switch(dir){
            case right:
                if(_line_length[current_line] == current_pos)
                    return;
                else
                {
                    ++_current.pos;
                    _caret += _byte_size(_forward_point(_current));
                }
                break;
            case left:
               if(!current_pos)
                   return;
               else
               {
                   --_current.pos;
                   _caret += _byte_size(_current);
               }
               break;
            case up:
                if(_above_line_exist(current_line))
                {   // バイト数カウントすべきところあとでまとめる
                    const str = _ranged_str(TextPoint(current_line-1,current_pos),
                                            _backward_pos(_current));
                    --_current.line;
                }
                break;
            case down:
                if(_next_line_exist(current_line))
                {
                    const str = _ranged_str(_current,TextPoint(current_line+1,current_pos-1));                                                 _backward_pos(_currentline));
                    _caret += str.length;
                    ++_current.line;
                }
                break;
        }
    }
    bool backspace(){
        const pos_next = _backward_pos(_current);
        if(deleteChar(pos_next))

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
        ++_caret;
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
    bool line_join(in int line){
        // 0行目では結合できない
        if(line == 0) 
            return false;
 
        immutable cl = _str(line);
        immutable upper_line = line-1;
        if(upper_line in _writing)
        {
            auto c_line = _writing[line];
            foreach(l; line .. _lines)
                _writing[l] = _writing[l+1];
            _writing.remove(_lines);
            --_lines;
            const upper_len = _line_length[line-1];
            const join_len = _line_length[line];

            foreach(p; 0 .. join_len)
                _writing[line-1][upper_len+p] = _writing[line][p];
            _line_length[line-1] += join_len;
            return true;
        }
        return false;
    }
    // int right_edge_pos()const{
    //     auto current_line_positions = _writing[_current.line].keys.dup;
    //     auto sorted_positions = current_line_positions.sort();
    //     return sorted_positions[$-1];
    //     debug(text) writefln("type:%s",typeid(linepos));
    // }
    private text.tag.Foreground _current_foreground;
    private text.tag.Background _current_background;
    private text.tag.FontSize _current_fontsize;
    private text.tag.Underline _current_underline;
    private text.tag.Weight _current_weight;

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
    private auto _opened_tag(TagType t){
        assert(t in _current_opened_span);
        return _tag_pool[_current_opened_span[t]];
    }
    private void _set_pooled_tag(TagType t,in TextSpan s,Color v){
        assert(s in _tag_pool);
        switch(t){
            case foreground_tag:
                _tag_pool[s].set_foreground(v);
                break;
            case background_tag:
                _tag_pool[s].set_background(v);
                break;
            default:
                assert(0);
                break;
        }
    }
    private void _set_pooled_tag(TagType t,in TextSpan s,ubyte v){
        assert(s in _tag_pool);
        switch(t){
            case font_size_tag:
                _tag_pool[s].set_font_size(v);
                break;
            default:
                assert(0);
                break;
        }
    }
    private void _cut_tagpool(in TextPoint end){
        foreach(span; _tag_pool.keys)
        {
            if(span.is_set && span.max < end)
            {
                auto tag = _tag_pool[span];
                _tag_pool.remove(span);
                span.re_open();
                _tag_pool[span] = tag;
            }
        }
    }
    // current位置に適用する
    private void _set_tag(TagType tt,T)(in T val,ref T state_val){
        if(tt !in _current_opened_span)
        {   // この初期化は初回一回だけなのでctorに移動したい。
            _current_opened_span[tt] = TextSpan.init;
        }
        if(val == state_val) return;
        const opened = _opened(tt); 
        if(opened.is_opened)
        {   
            assert(opened in _tag_pool);
            _opened(tt).set_end(_backward_pos(_current));
            const closed = _opened(tt); 
            auto current_opened = _tag_pool[opened];
            if(closed in _tag_pool)
            {   // 同じ期間で閉じているtag-span対があればそのtagに属性を追加する
                current_opened = _tag_pool[closed];
                enforce(_tag_pool.remove(closed));
            }
            enforce(_tag_pool.remove(opened));
            if(closed.is_set())
            {
                _tag_pool[closed] = current_opened;
                _set_pooled_tag(tt,closed,state_val);
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
        _set_tag!(foreground_tag,Color)(c,_current_foreground.value);
        _color_is_set = true;
    }
    void set_background(in Color c){
        _set_tag!(background_tag,Color)(c,_current_background.value);
    }
    void set_fontsize(in ubyte fsz){
        _set_tag!(font_size_tag,ubyte)(fsz,_current_fontsize.value);
    }
    // アクセサ
    @property int current_line()const{
        return _current.line;
    }
    @property int current_pos()const{
        return _current.pos;
    }
    @property ubyte current_fontsize()const{
        return _current_fontsize.value;
    }
    @property Tuple!(const bool,const Color) current_foreground()const{
        return tuple(_color_is_set,_current_foreground.value);
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
    void clear(){
        this = Text();
    }
    string dat(){
        string result;
        result ~= to!string(_lines) ~ '\n';
        result ~= to!string(_color_is_set) ~ '\n';
        result ~= to!string(_current) ~ '\n';
        result ~= to!string(_text_end) ~ '\n';
        _writing[_text_end.line][_text_end.pos] = '\n'; // !!!currentが行終端い
        foreach(l; 0 .. _lines)
            result ~= _str(l);
        result ~= '\n';
        foreach(l; 0 .. _lines)
            if(l in _line_length)
                result ~= to!string(_line_length[l]) ~ '\n';
            else
                result ~= '\n';
        result ~= to!string(_caret) ~ '\n';
        foreach(span,tag; _tag_pool)
            if(!(span.is_set && span.has_no_span))
            result ~= "<"~span.dat ~"*"~tag.dat() ~">";
        result ~= "\n";
        foreach(span; _current_opened_span)
            result ~= to!string(span) ~ '\n';
        return result;
    }
    // unittest{
    //     Text t1;
    //     t1.append("123456789");
    //     t1.line_feed();
    //     t1.set_foreground(red);
    //     string t1_dat = t1.dat();
    //     auto dat = split(t1_dat,"\n");
    //     foreach(d; dat)
    //         writeln(d);

    //     Text t2 = Text(dat);
    // }
}

