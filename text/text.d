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
import std.regex;

/+  memo
    -範囲を持たないspanでsetされたtag
     を_tag_poolから取り除くようにする
    -各tagを統一的に扱えるようにする
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
            debug(text) writeln(dat);
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
unittest{
    TextPoint t1 = TextPoint(2,2);
    TextPoint t2 = TextPoint(1,1);
    TextPoint t3 = TextPoint(3,3);
    assert(t1 > t2);
    assert((t1+t2) == t3);
}

// Span!(int)のような操作は提供しない
// lineの持つpos幅を知る必要があるため
// 範囲を特定するためのマーカーとしてTextが使う

struct TextSpan{
    private:
        TextPoint _min ;
        TextPoint _max ;
    public:
        void set(in TextPoint s,in TextPoint e)
            in{
            assert(s <= e);
            }
        body{
            _min = s;
            _max = e;
        }
        void set_start(in TextPoint s){
            _min = s;
        }
        void set_end(in TextPoint e){
            _max = e;
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
        }
        int opCmp(in TextPoint i)const{
            if(_max < i) return -1;
            else if(_min > i ) return 1;
            else if(is_hold(i)) return 0;
            assert(0);
        }
        int opCmp(in TextSpan rhs)const{
            if(_min < rhs._min)
            {
                if(_max < rhs._max
                        || rhs._max == invalid)
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
            hash = _min.line * 31 + _min.pos * 19; 
            return hash;
        }
        bool opEquals(in TextPoint rhs)const{
            return is_hold(rhs);
        }
        // 完全に指す範囲が一致しているか
        bool opEquals(in TextSpan rhs)const{
            return _min == rhs._min && _max == rhs._max;
        }
        // operator == と等価
        bool is_hold(in TextPoint v)const{
            return _min <= v && v <= _max;
        }
        // 包含するか
        bool is_hold(in TextSpan s)const{
            return _min <= s._min && _max >= s._max;
        }
        @property TextPoint min()const{
            return _min;
        }
        @property TextPoint max()const{
            return _max;
        }
        bool is_set()const{
            return (_min != invalid) && (_max != invalid) && (_min <= _max);
        }
        bool is_opened()const{
            return 
                (_min != TextPoint.init && _max == TextPoint.init)
                    ||
                (_max != TextPoint.init && _min == TextPoint.init);
        }
        @property bool is_not_set()const{
            return _min == invalid && _max == invalid;
        }
        this(string dat){
            dat = dat[1 .. $-1];
            auto elems = split(dat,"),(");
            _min = TextPoint(elems[0]~')');
            _max = TextPoint('('~elems[1]);
        }
        string dat()const{
            string result = "(";
            result ~= _min.dat() ~",";
            result ~= _max.dat() ;
            return result ~ ")";
        }
        void clear(){
            _min = TextPoint(-1,-1);
            _max = TextPoint(-1,-1);
        }
        // この２つを違う値にするとText::_apply_tagsとかが死ぬ
        static TextSpan init(){
            return invalid;
        }
        static TextSpan invalid(){
            return TextSpan();
        }
        unittest{
            auto span = TextSpan();
            span.set_start(TextPoint(0,0));
            assert(span.is_opened);
            auto dat = span.dat();
            debug(text) writeln(dat);
            assert(dat == "((0,0),(-1,-1))");
            span.set_end(TextPoint(2,2));
            assert(span.is_set());
            auto dspan = TextSpan("((0,0),(2,2))");
            assert(span == dspan);
        }
}

alias Tuple!(string,SpanTag) HighlightString;

struct Text {   // TextBOX itemBOX で使われる文字列表現
        this(Text t){
            _lines = t._lines;
            _caret = t._caret;
            _current.line = t._current.line;
            _current.pos = t._current.pos;
            _writing = t._writing.dup;
            _line_length = t._line_length;
            _highlight = t._highlight;
        }
        // 一時しのぎフォーマットもうかえない
        this(string[] dat){
            const lines = to!int(chomp(dat[0]));
            int ln;
            debug(text) writeln("l:",_lines);
            foreach(l; 0 .. lines)
            {
                debug(text) writeln(dat[4+l]);

                auto line_str = dat[4+l];
                if(l == lines -1)
                    append(chomp(line_str)); // dat()時に仕込んだ改行文字を取り除く
                else
                    append(line_str);
                debug(text) writeln("per line length:",dat[l+lines+5]);
                _line_length[l+lines] = to!int(chomp(dat[l+lines+5]));
            }
            _lines = lines; // append後の値と一致してればそれはそれでいい assert(lines == _lines); 
            debug(text) writeln("caret:",dat[4+_lines*2]);
            _caret = to!int(chomp(dat[4+_lines*2])); 

            auto tag_line = chomp(dat[4+_lines*2+1]);
            if(!tag_line.empty && tag_line != "\n")
            {
                tag_line = tag_line[1 .. $-1];
                auto pairs = split(tag_line,"><");
                foreach(one_pair; pairs)
                {   // spanとtagは既に一対にまとめられている。同じSpanならSpanTagひとつで表現される。
                    auto elems = split(one_pair,"*");
                    auto span = TextSpan(elems[0]);
                    auto tag = SpanTag(elems[1]);
                    assert(span !in _tag_pool);
                    _tag_pool[span] = tag;
                }
            }
            // set cnt point
            auto c_str = (chomp(dat[2]))["TextPoint".length .. $];
            _current = TextPoint(removechars(c_str," "));
        }
    private:
        // 各tagの種類ごとに現在の適用範囲を記録しておく
        // 適応する範囲はそれぞれ異なることができないといけない
        // TextSpan[TagType] _opened_span;

        // 現在位置と最終位置
        TextPoint _current = TextPoint(0,0);
        TextPoint _text_end = TextPoint(0,0); // Textの終わりに一致、_currentが動ける最大範囲
        // byte数での現在位置。Pangoはこちらで指定しなければいけない。
        int _caret; 

        alias int Pos;
        alias int Line;
        alias ubyte FontSize;

        int _lines = 1;
        SpanTag[TextSpan] _tag_pool;
        dchar[Pos][Line] _writing;
        string[Line] _stored_line;
        int[int] _line_length;

        Tuple!(string[],SpanTag)[] _highlight;

        invariant(){
            assert(_current.line < _lines);
        }
        TextSpan[] _tag_span_in(in TextPoint tp)const{
            TextSpan[] result;
            foreach(span; _tag_pool.keys)
                if(span.is_hold(tp))
                    result ~= span;
            return result;
        }
        TextSpan[] _tag_span_in(in TextPoint tp,in TagType tt)const{
            TextSpan[] result;
            foreach(span; _tag_pool.keys)
                if(span.is_hold(tp) 
                        && _tag_pool[span].is_set(tt))
                    result ~= span;
            return result;
        }

        public bool deleteChar(){
            if(_current == _text_end)
                return false;
            if(!_is_valid_pos(_current))
                return false;
            const line = _current.line;
            const bytesize = _byte_size(_current);
            const line_len = _line_length[line];
            const fp = _forward_point(_current);

            if(_is_line_end(_current) && _next_line_exist(_current.line)) 
            {   // 右端では下の行との結合
                const result = _line_join(_current.line+1);
                _current.line = line;
                _set_end_point();

                return result;
            }
          
            foreach(p; _current.pos .. line_len-1)
            {   // 現在行の要素をずらす
                _writing[line][p] = _writing[line][p+1];
            }

            --_line_length[line];
            if(line_len in _writing[line]) 
            {
               // 行終端の\nの移動と削除。'\n'は最終行では入っていない。
                _writing[line][line_len-1] = _writing[line][line_len];
                writefln("%d",_writing[line][line_len]);
                assert(_writing[line][line_len] == '\n');
                _writing[line].remove(line_len);
            }
            else
            {   // ずらしたことに依る重複文字の削除
                enforce(_writing[line].remove(line_len-1));
            }

            if(_text_end.line == line)
                --_text_end.pos; // update text_end
            if(_text_end.line == _current.line && _text_end < _current)
                _current = _text_end; // currentが終端を超えていた場合、

            if(!_line_length[line])
            {   // 行がもはやなければ上行と結合
                if(_lines != 1) 
                {
                    if(_line_join(line+1)) // 同一行に_currentがあれば--_current.line
                    {
                        _current = _line_head(line);
                        _set_caret();
                    }
                    else if(line == 0)
                    {   // 0行目がなくなったときは下からスライド
                        foreach(l; 1 .. _lines)
                        {
                            _writing[l-1] = _writing[l];
                            _line_length[l-1] = _line_length[l];
                        }
                        _writing.remove(_lines);
                        _line_length.remove(_lines);
                        if(_current.line == _lines) // 最下段に_currentあればスライド
                            --_current.line;
                        --_lines;
                        move_caret(left);
                    }
                }
            }
            debug(text) writeln(_line_length);
            debug(text) writeln(_is_line_end(_current));
            debug(text) writeln(_text_end);
            debug(text) writeln(_line_length);

            return true;
        }
        void _deleteChar(in int pos){
            _writing[current_line].remove(pos);
        }
        TextPoint _backward_pos(in TextPoint tp){
            if(!tp.pos)
            {
                if(tp.line)
                {
                    auto above_line = tp.line-1;
                    debug(text) writeln(above_line);
                    debug(text) writeln(_writing);
                    return TextPoint(above_line,_writing[above_line].keys.sort[$-1]);
                }else
                    return TextPoint(0,0);
            }else 
                return TextPoint(tp.line,tp.pos-1);
        }
        TextPoint _backward_pos(){
            return _backward_pos(_current);
        }
        // 多態させるためのスイッチャー
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

        // (現在使われている設定値に対応するtag)に対応するspanを返す
        // deprecated
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

        // lineが存在しないなら""を返す
        // これに依存、str(TextPoint,TextPoint)
        @property string _str(in int line,string pre_in = ""){
            // if(!line_empty(line))

            if(line == _current.line 
                    || (line !in _stored_line && line_length(line) >= 1))
            {
                string s;   
                debug(text) writeln(_writing);
                foreach(i; _writing[line].keys.sort())
                {
                    if(_current == TextPoint(line,i))
                        s ~= pre_in;
                    s ~= _writing[line][i];
                }
                s =  SimpleXML.escapeText(s,s.length);
                foreach(h; _highlight)
                {
                    foreach(word; h[0])
                    s = replace(s,regex(word,"g"),h[1].tagging("$&"));
                }

                _stored_line[line] = s;

            }

            if(line in _stored_line)
                return _stored_line[line] ;
            else
                return "";
        }   
        dchar _get_char(in TextPoint tp)const{
            if(tp.line !in _writing || tp.pos !in _writing[tp.line])
            {
                debug(text) writeln(tp);
                debug(text) writeln(_writing);
                debug(text) writeln(tp.line !in _writing);
                debug(text) writeln(tp.pos !in _writing[tp.line]);
                throw new Exception("out of range");
            }
            return _writing[tp.line][tp.pos];
        }
        @property string _plane_string(string default_out=""){
            string result;
            foreach(l; 0 .. _lines)
            {
                const str = _str(l,default_out);
                result ~= str;
            }
            return result; 
        }
        bool _is_valid_pos(in TextPoint tp)const{
            return (tp.line in _writing)
                && (tp.pos in _writing[tp.line]);
        }
        // endを含む
        string _ranged_str(in TextPoint start,in TextPoint end){
            if(!_is_valid_pos(start) || !_is_valid_pos(end))
            {
                debug(text) writeln("start pos ",start);
                debug(text) writeln("end pos ",end);
                throw new Exception("not in range"); 
            }
            assert(end.pos != -1);
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
                result ~= _writing[end.line][i];

            return toUTF8(result);
        }
        string _ranged_str(in TextSpan span){
            return _ranged_str(span.min,span.max);
        }
        unittest{
            Text text;
            text.append("なんかかっこいいこと言いたかった人生だった");
            auto start = TextPoint(0,16);
            auto end = TextPoint(0,17);
            auto result = text._ranged_str(start,end);
            assert(result == "人生");
            debug(text) writeln(text._line_length);
            assert(text.line_length(0) == 21);
            Text t2;
            t2.append("12345");
            assert(t2.line_length(0) == 5);
        }
        void _set_end_point(){
            const line = _lines-1;
            _text_end = TextPoint(line,_line_length[line]);
            debug(text)
            {
                Text calc_another;
                auto line = _line_length.keys.sort[$-1];
                auto pos = line_length(line);
                if(pos)
                    calc_another = TextPoint(line,pos-1);
                else
                    calc_another = TextPoint(line,0);

                assert(_text_end == calc_another);
            }
        }
        // 行終端\nが入るか、入力位置となっている場所で最下行に当たる場所
        TextPoint _end_point()const{
            return _text_end;
        }
        TextPoint _back_point(){
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
        bool _is_line_end(in TextPoint tp ,in int l)const{
            return (tp.line in _line_length && tp.pos == _line_length[l])||empty;
        }
        bool _is_line_end(in TextPoint tp)const{
            return _is_line_end(tp,tp.line);
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
                line_feed();
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
                debug(text) writeln(p.line);
                debug(text) writeln(_line_length);
                assert(p.line in _line_length);
                return p;
            }
        }
        unittest{
            import std.stdio;
            Text text;
            text.append("123456789");
            debug(text) writeln(text._current);
            assert(text._current == TextPoint(0,9));
            assert(text._backward_point(text._current) == TextPoint(0,8));
            assert(text._is_line_end(text._current));
            text.line_feed();
            assert(text._line_end(0) == TextPoint(0,9));
            assert(text._is_line_end(TextPoint(0,9)));
            assert(text.numof_lines == 2);
            assert(text._next_line_exist(0));
            assert(text._current == TextPoint(1,0));
            text.backspace();
            assert(text.numof_lines == 1);
            assert(!text._next_line_exist(0));
            text.line_feed();
            text.append("123456789\n");
            debug(text) writeln(text._current);
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
        text.tag.Foreground _current_foreground;
        text.tag.Background _current_background;
        text.tag.FontSize _current_fontsize;
        text.tag.Underline _current_underline;
        text.tag.Weight _current_weight;

        // 階層的にtag適用できる設計は必要だと思う
        bool _color_is_set = false;
        void _set_pooled_tag(TagType t,in TextSpan s,in Color v){
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
        void _set_pooled_tag(TagType t,in TextSpan s,in ubyte v){
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
        void _cut_tagpool(in TextPoint end){
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
        /+
            現在位置を始点にtagを設定する
            現在のspanが開いていれば現在位置手前で閉じる

        +/
        void _set_tag(TagType tt,T)(in T val,ref T state_val){
            TextSpan ts;
            ts.set_start(_current);
            if(ts !in _tag_pool)
                _tag_pool[ts] = SpanTag.init;
            _set_pooled_tag(tt,ts,val);
            state_val = val;
        }

    public:
        string markup_string(string default_out=""){
            writeln(_highlight);
            if(_tag_pool.keys.empty)
                return _plane_string(default_out);
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
                    if(_current == tp) // test
                        result ~= default_out;
                    // 一文字ずつエスケープしてる効率は
                    string one_char = [cast(char)(_writing[line][pos])];
                    // 二重にエスケープしてしまわないようにはじければいらない
                    // どっちの処理が軽いか知らない
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
            foreach(i;0 .. opened_cnt)
                result ~= "</span>";
            debug(text) writeln(_writing);
            debug(text) writeln(result);
            return result;
        }
        bool move_caret(in Direct dir){
            debug(text) writeln(_current);
            const back_pos = _backward_pos(_current);
            final switch(dir){
                case right:
                    if(_is_line_end(_current))
                    {
                        if(!_next_line_exist(current_line))
                            return false;
                        _current = _forward_point(_current);
                        break;
                    }
                    else if(_current.pos < _line_length[_current.line])
                        ++_current.pos;
                    else
                        return false;
                    break;
                case left:
                    if(_is_line_head(_current) && _current.line != 0)
                    {
                        --_current.line;
                        _current.pos = _line_length[_current.line];
                        break;
                    }
                    else if(!_is_line_head(_current))
                        --_current.pos;
                    else 
                        return false;
                    break;
                case up:
                    if(current_line == 0)
                        return false;
                    else 
                    {
                        --_current.line;
                        const lens = line_length(current_line);
                        if(current_pos > lens)
                            _current.pos = lens;
                    }
                    break;
                case down:
                    if(!_next_line_exist(current_line))
                        return false;
                    else
                    {
                        ++_current.line;
                        const lens = line_length(current_line);
                        if(current_pos > lens)
                            _current.pos = lens;
                    }
                    break;
            }
            _set_caret();
            return true;
        }
        // _text_end は拡張方向のみチェック
        // _text_end の縮小方向はbackspace とかのdeleteCharとかの削除系でチェック
        private void _set_caret(){
            if(_current > _text_end)
                _text_end = _current;

            if(_current == TextPoint(0,0))
            {
                _caret = 0;
                return;
            }
            auto str = _ranged_str(TextPoint(0,0),_backward_pos(_current));
            debug(text) writeln(str);
            _caret = cast(int)str.length;
        }
        void set_highlight(string[] word, SpanTag tag)
        out{
            assert(!_highlight.empty);
            }
        body{
            _highlight ~= tuple(word,tag);
        }

        unittest{
            Text t1;
            t1.append("012");
            t1.set_foreground(red);
            t1.append("34");
            t1.line_feed();
            t1.append("56");
            t1.set_foreground(blue);
            t1.append("789");
            // assert(t1._current == TextPoint(1,5));
            // t1.move_caret(left);
            // assert(t1._current == TextPoint(1,4));
            // t1.move_caret(up);
            // assert(t1._current == TextPoint(0,4));
            // t1.move_caret(left);
            // assert(t1._current == TextPoint(0,3));
            // t1.deleteChar();
            // assert(t1._current == TextPoint(0,3));
            // assert(t1._line_length[0] == 5);
            // t1.deleteChar();
            // write("\n");
            // assert(t1._line_length[0] == 4);
            // assert(t1._current == TextPoint(0,3));
            // writeln(t1.markup_string());
            // t1.deleteChar();
            // write("\n");
            // writeln(t1.markup_string());
            // assert(t1._line_length[0] == 4);
            // assert(t1._current == TextPoint(0,3));
            // t1.move_caret(left);
            // t1.deleteChar();
            // write("\n");
            // writeln(t1.markup_string());
            // writeln(t1._current);
            // assert(t1._line_length[0] == 3);
            // assert(t1._current == TextPoint(0,2));
            // t1.move_caret(left);
            // write("\n");
            // t1.deleteChar();
            // writeln(t1._current);
            // writeln(t1.markup_string());
            // t1.move_caret(right);
            // writeln(t1._line_length[0]);
            // assert(t1._line_length[0] == 1);
            // assert(t1._current == TextPoint(0,1));
            // t1.move_caret(right);
            // assert(t1._current == TextPoint(0,1));
            // t1.deleteChar();
            // assert(t1._current == TextPoint(0,1));
            // assert(t1._line_length[0] == 1);
            // t1.insert(t1._current,'a');
            // write("\n");
            // writeln(t1._current);
            // writeln(t1.markup_string());
            // t1.insert(t1._current,'b');
            // write("\n");
            // writeln(t1._current);
            // writeln(t1.markup_string());
            // write("\n");
            // writeln(t1._current);
            // writeln(t1.markup_string());
        }

        unittest{
            Text t1;
            t1.append("0123456789");
            t1.set_foreground(red);
            assert(t1._line_length[0] == 10);
            debug(text) writeln(t1._caret);
            assert(t1._caret == 10);
        }

        // current.pos はこれから値が入る位置.既に入ってるわけではない
        // だから_line_lengthはcurrent.posを含まず考慮する
        // ただ、長さなのでcurrent.posと一致することになる

        // _line_lengthの伸ばす方向の変更は今のところここのみ
        // Textに文字を入れる操作は最終的にここを通る
        // byte数ここではもうとらない
        ulong append(in dchar c){
            debug(text) writeln(_text_end);
            debug(text) writeln(_current);
    //         assert(_text_end == _current);
    //         _writing[current_line][_current.pos] = c;
    //         if(c != '\n')
    //             ++_current.pos;
    //         else // if(c == '\n')
    //             line_feed();
    //         const cp = current_pos;
    //         _line_length[current_line] = cp;
    //         _text_end = _current;
    //         _caret += toUTF8([c]).length;

            insert(c);
            return _current.pos;
        }
        void insert(in TextPoint tp,in dchar c){
            if(!_is_valid_pos(tp))
            {
                if(!_is_line_end(tp))
                {
                    debug(text) writeln("invalid point:",tp);
                    assert(0);
                }
            }
            const line = tp.line;
            foreach(span; _tag_pool.keys)
            {
                debug(text) writeln("");
                debug(text) writeln(span);
                debug(text) writeln(tp);
                debug(text) writeln(_current);
                auto tag = _tag_pool[span];
                _tag_pool.remove(span);

                // if(!span.is_opened)
                {
                    if(span.max >= tp && span.max.line == line && !span.is_opened)
                    {
                        with(span)
                        set_end(TextPoint(max.line,min.pos+1));
                    }
                    if(span.min > tp && span.min.line == line)
                    {
                        with(span)
                        set_start(TextPoint(min.line,min.pos+1));
                    }

                }
                _tag_pool[span] = tag;
            }
            const line_len = _line_length[tp.line];
            dchar[int] line_p;
            if(tp.line in _writing)
                line_p = _writing[tp.line].dup;
            _writing[tp.line][tp.pos] = c;

            // 増加方向へ文字位置をスライド
            foreach(p; tp.pos+1 .. line_len +1)
                _writing[tp.line][p] = line_p[p-1];
            assert(_line_length[tp.line] == line_len);
            if(tp.line != _text_end.line)
            {   // 最終行以外は'\n'で終端
                _writing[tp.line][line_len+1] = '\n';
            }

            ++_line_length[tp.line];
            if(tp.line == _text_end.line)
            {
                ++_text_end.pos;
            }
            debug(text) writeln(_writing);

        }
        void insert(in dchar c){
            if(c == '\n')
                return line_feed();
            const cp = current_pos;
            if(current_line !in _line_length)
                _line_length[current_line] = cp;

            insert(_current,c);
            _caret += toUTF8([c]).length;
            ++_current.pos;
        }
        unittest{
            Text t1;
            t1.append("0123456789");
            assert(t1._line_length[0] == 10);
            debug(text) writeln(t1._plane_string);
            t1.insert(TextPoint(0,5),'x');
            writeln(t1._plane_string);
            assert(t1._plane_string == "01234x56789");
            assert(t1._line_length[0] == 11);
        }
        void caret_move_forward(in ulong u){
            _caret += u;
        }
        void append(string s){
            // caret_move_forward(s.length);
            foreach(dchar c; s)
            {
                append(c);
            }
        }
        @property bool empty()const{
            return (_writing.keys.empty())
            || (_lines == 1 && _writing[0].keys.empty())
            || _line_length.keys.empty;
        }
        bool line_empty(in int line)const{
            return !(_writing
            && !_writing.keys.empty()
            && line in _writing
            && !_writing[line].values.empty());
        }

        // Writing内文字のbyte数
        ulong _byte_size(in TextPoint tp){
            return to!string(_get_char(tp)).length;
        }
        private dchar[] _head,_tail; // 二分割、分割値は_tail
        void _devide_line(in TextPoint tp){
            _head.clear();
            _tail.clear();
            foreach(n; _writing[tp.line].keys.sort)
            {
                if(n < tp.pos)
                    _head ~= _writing[tp.line][n];
                else
                    _tail ~= _writing[tp.line][n];
            }
        }
        unittest{
            Text t1;
            t1.append("12345");
            t1._devide_line(TextPoint(0,2));
            debug(text) writeln(t1._head);
            debug(text) writeln(t1._tail);
            assert(t1._head == "12");
            assert(t1._tail == "345");
        }

        // 行始でfalse 
        bool backspace(){
            if(empty) return false;
            const bp = _backward_pos(_current);
            const line_len = _line_length[_current.line];

            foreach(span; _tag_pool.keys)
            {
                const snap = span;

                if(span.max == bp && span.min == bp
                || span.min == bp && span.is_opened)
                    _tag_pool.remove(snap);
                    // span.set_end(_backward_pos(bp));
                else
                {
                    if(span.max == bp)
                        span.set_end(_backward_pos(bp));
                    if(span.min == bp)
                        span.set_start(_backward_pos(bp));
                }
            }

            if(current_pos)
            {
                // _move_back_tag!(true)(bp);
                foreach(p; _current.pos .. line_len-1)
                    _writing[_current.line][p] = _writing[_current.line][p+1];
                if(line_len in _writing[_current.line]) // maybe in '\n'
                {   // 行終端の\nは入ってないかも知れない
                    // あれば、それもスライドして保存する
                    _writing[_current.line][line_len-1] = _writing[_current.line][line_len];
                    debug(text) writeln(_writing[current_line][line_len]);
                    assert(_writing[current_line][line_len] == '\n');
                    _writing[current_line].remove(line_len);
                    --_line_length[current_line];
                }
                else
                {
                    --_line_length[current_line];
                    enforce(_writing[current_line].remove(line_len-1));
                }

                move_caret(left);
                _current = bp;
                _set_end_point();

                return true;
            }
            else if(_current.line)
            {
                const upper_len = _line_length[_current.line-1];
                if(_line_length[_current.line] == 0)
                {
                    enforce(_line_join(current_line)); // _currentは操作されて上の行に移動する
                }
                else
                    --_current.line;
                // なので、move_caretは使わない
                _current.pos = upper_len;
                if(_current.line == _lines -1 // 結合して最終行になったときに、最後の改行文字を消す
                        && current_pos in _writing[current_line]
                        && _writing[current_line][current_pos] == '\n')
                    _writing[current_line].remove(current_pos);
                _set_caret();
                _set_end_point();
                return false;
            }
            else 
                return false;
        }
        unittest{
            Text t1;
            t1.append("01234");
            assert(t1.numof_lines == 1);
            t1.line_feed();
            assert(t1.numof_lines == 2);
            t1.backspace();
            assert(t1.numof_lines == 1);
            assert(t1.current_line == 0);
            debug(text) writeln(t1.current_pos);
            assert(t1.current_pos == 5);
            assert(t1._caret == 5);
            auto plane = t1._plane_string;
            debug(text) writeln(plane);
            debug(text) writeln(t1._writing);
            assert(plane == "01234");
            t1.append("56789");
            plane = t1._plane_string();
            debug(text) writeln(t1._writing);
            debug(text) writeln(t1._current);
            debug(text) writeln(plane);
            assert(plane == "0123456789");
        }
        unittest{
            Text t1;
            t1.append("12345");
            t1.line_feed();
            t1.append("12345");
            foreach(i;0 .. 5)
            t1.move_caret(left);
            assert(t1._current == TextPoint(1,0));
            t1.backspace();
            writeln(t1._str(0));
            writeln(t1._str(1));
            assert(t1._str(0) == "12345\n");
            assert(t1._str(1) == "12345");
            debug(text) writeln(t1._current);
            assert(t1._current == TextPoint(0,5));
            assert(t1.line_length(0) == 5);
            assert(t1.line_length(1) == 5);
            t1.backspace();
            assert(t1._current == TextPoint(0,4));
            debug(text) writeln(t1._str(0));
            assert(t1._str(0) == "1234\n");
            assert(t1._str(1) == "12345");
            assert(t1.line_length(0) == 4);
            assert(t1.line_length(1) == 5);
            foreach(i; 0 .. 4)
            {
                t1.backspace();
                assert(t1.line_length(0) == 3-i);
                assert(t1.line_length(1) == 5);
            }
            assert(t1.numof_lines == 2);
            t1.deleteChar();
            assert(t1.numof_lines == 1);
            assert(t1._str(0) == "12345");
            assert(t1.line_length(0) == 5);

        }
        @property string[int] strings(){
            string[int] result;
            foreach(line_num,one_line; _writing)
                result[line_num] = _str(line_num);
            return result;
        }
        private void init(){
            _line_length[0] = 0;
        }
        bool is_in_end(){
            if(empty)
                init();
            debug(text) writeln(_text_end);
            debug(text) writeln(_current);
            return _text_end == _current;
        }
        
        void line_feed(){ // 新しい行を作ったか

            dchar[] line_tail;
            const line = _current.line;
            const line_len = _line_length[line];
            if(current_line in _writing)
            {
                if(!_is_line_end(_current)) 
                {
                    foreach(p; current_pos .. line_len)
                    {
                        line_tail ~= _writing[line][p];
                        _writing[line].remove(p);
                    }
                    _writing[line].remove(line_len); // 改行文字があれば
                }
                _writing[line][current_pos] = '\n';
            }
            else 
            {   // 
                _writing[line][0] = '\n';
            }

            debug(text) writeln(line_tail);

            ++_current.line;
            ++_caret;
            const next_line = _current.line;

            _line_length[line] = _current.pos;
            const next_line_len = cast(int)line_tail.length;
            _current.pos = 0;
            foreach(l; next_line .. _lines)
            {
                _writing.remove(l+1);
                _writing[l+1] = _writing[l].dup;
                _line_length[l+1] = _line_length[l];
            }

            _writing.remove(next_line);
            foreach(int i,dc; line_tail)
                _writing[next_line][i] = dc;
            _line_length[next_line] = next_line_len;
            if(next_line != _lines)
            {
                _writing[next_line][next_line_len] = '\n';
            }

            if(line in _stored_line)
                _stored_line[line].clear;
            foreach(i; _writing[line].keys.sort())
            {   // 改行行の_stored_lineを更新する
                _stored_line[line] ~= _writing[line][i];
            }
            auto line_str = _stored_line[line];
            _stored_line[line] = SimpleXML.escapeText(line_str,line_str.length);
            line_str = _stored_line[line];
            foreach(h; _highlight)
            {
                foreach(word; h[0])
                    _stored_line[line] = replace(_stored_line[line],regex(word,"g"),h[1].tagging("$&"));
            }


            ++_lines;
            _set_end_point();
            if(_current.line !in _writing)
                _writing[_current.line] = null;
            void _span_modify(){
                foreach(span; _tag_pool.keys)
                {
                    auto tag = _tag_pool[span];
                    _tag_pool.remove(span);
                    if(span.min.line == line
                    && span.min.pos == _line_length[line])
                        span.set_start(TextPoint(next_line,0));
                    if(span.max.line == line
                    && span.max.pos == _line_length[line])
                        span.set_end(TextPoint(next_line,0));

                    _tag_pool[span] = tag;
                }
            }
            _span_modify();
        }

        // 指定行を上の行と結合.指定行より下の行は繰り上がり
        // 同一行に_currentがあれば移動させる
        // 結合したらtrue
        private bool _line_join(in int line){
            // 0行目では結合できない
            if(line == 0 || line >= _lines) 
                return false;
     
            immutable cl = _str(line);
            immutable bottom_line = _lines-1;
            immutable upper_line = line-1;
            assert(upper_line in _writing);

            auto c_line = _writing[line];
            foreach(l; line .. _lines-1)
                _writing[l] = _writing[l+1];
            --_lines;
            const upper_len = _line_length[line-1];
            const join_len = _line_length[line];

            debug(text) writeln(_writing[line]);
            foreach(p; 0 .. join_len)
                _writing[upper_line][upper_len+p] = _writing[line][p];
            _line_length[upper_line] += join_len;
            enforce(_writing.remove(bottom_line));
            enforce(_line_length.remove(bottom_line));
            if(_current.line == line)
                --_current.line;
            if(_text_end.line == line)
            {
                --_text_end.line;
                _text_end.pos = _line_length[upper_line];
            }
            return true;
            // return false;
        }
        bool line_join(){
            return _line_join(_current.line);
        }
        unittest{
            Text t1;
            t1.append("01234");
            t1.line_feed();
            t1.append("56789");
            t1._line_join(1);
            auto plane = t1._plane_string();
            debug(text) writeln(plane);
            debug(text) writeln(t1._current);
            assert(plane == "0123456789");
            assert(t1.line_length(0) == 10);
            t1.line_feed(); // カーソル位置は1行目行頭へ
            t1.append("abcde");
            debug(text) writeln(t1.line_length(1));
            debug(text) writeln(t1._current);
            assert(t1.line_length(1) == 10);
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
        unittest{
            Text t1;
            t1.append("012345");
            t1.set_foreground(red);
            t1.line_feed();
            t1.append("5");
            debug(text) writeln(t1.markup_string());
            debug(text) writeln(t1._tag_pool);
            assert(t1.markup_string() == "012345\n<span foreground=\"red\">5</span>");
            t1.backspace();
            debug(text) writeln(t1._tag_pool);
            writeln(t1.markup_string());
            assert(t1.markup_string() == "012345\n");
            t1.backspace();
            debug(text) writeln(t1._tag_pool);
            assert(t1.markup_string() == "012345");
            t1.markup_string();
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
                foreach(w; _writing[l].keys.sort)
                    result ~= _writing[l][w];
                // result ~= _str(l);
            // result ~= '\n';
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
            // foreach(span; _opened_span)
            //     result ~= to!string(span) ~ '\n';
            return result;
        }
}

