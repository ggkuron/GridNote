module text.text;

import std.array;
import misc.array;
import std.string;
import std.algorithm;

import std.stdio; // printf dbg
class Text
{   // あらゆるところで触られるよ 変えたらだめだよ
    this(){
        static int cnt;
        writefln("i am created for %d times",cnt++);
    }
    int lines = 1;
    int cursor;
    alias int pos;
    alias int line;
    char[pos][line] writing;
    int current_line;
    int position;
    ulong insert(int line_num,char c){
        writing[line_num][position++] = c;
        writef("%s\n",writing[line_num]);
        return writing[line_num].length;
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
            string s;   // こざかしいこと
            foreach(i; writing[current_line].keys.sort())
                s ~= writing[current_line][i];
            return s;
        }else return null;
        return null;
    }   
    void line_feed(){
        ++current_line;
        if(current_line > lines) lines = current_line;
    }
    int right_edge_pos(){
        auto linepos = writing[current_line].keys.sort();
        writefln("type:%s",typeid(linepos));
        return linepos[$-1];
    }
    void move_cursor(alias pred, alias manip_cursor)(){
        if(mixin (pred))
            mixin (manip_cursor);
    }
    void set_cursor()(int pos)
        // move_cursor に課せられたpred を全部課したい
    {
        cursor = pos;
    }
}

