module text.text;

import std.array;
import misc.array;
import std.string;
import std.algorithm;
import std.utf;

debug(text) import std.stdio; // printf dbg
class Text
{   // あらゆるところで触られるよ 変えたらだめだよ
    this(){
        static int cnt;
        debug(text) writefln("Text created up %d times",cnt++);
    }
    int lines = 1;
    int caret;
    alias int pos;
    alias int line;
    dchar[pos][line] writing;
    int current_line;
    int position;
    ulong insert(dchar c){
        writing[current_line][position++] = c;
        debug(text) writef("insert : %s\n",writing[current_line]);
        return writing[current_line].length;
    }
    @property bool empty(){
        return writing.keys.empty();
    }
    void deleteChar(int pos){
        writing[current_line].remove(pos);
    }
    @property string str(){
        if(!writing.keys.empty())
        if(!writing[current_line].values.empty()){
            dstring s;   // こざかしいこと
            foreach(i; writing[current_line].keys.sort())
                s ~= writing[current_line][i];
            return toUTF8(s);
        }else return null;
        return null;
    }   
    @property auto c_str(){
        string s;
        s = toUTF8(str);
        import std.stdio;
        debug(text){
            writeln("the text is ", s);
            writeln("to_string ", s.toStringz);
        }
        return s.toStringz;
    }
    void line_feed(){
        ++current_line;
        if(current_line > lines) lines = current_line;
    }
    int right_edge_pos(){
        auto linepos = writing[current_line].keys.sort();
        debug(text) writefln("type:%s",typeid(linepos));
        return linepos[$-1];
    }
    void move_caret(alias pred, alias manip_caret)(){
        if(mixin (pred))
            mixin (manip_caret);
    }
    void set_caret()(int pos)
        // move_caret に課せられたpred を全部課したい
    {
        caret = pos;
    }
}

