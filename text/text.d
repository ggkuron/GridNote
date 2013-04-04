module text.text;

import std.array;
import misc.array;
import std.string;

import std.stdio; // printf dbg
class Text
{
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
    void deleteChar(int line_num,int pos){
        writing[line_num].remove(pos);
    }
    @property string str(){

        if(!writing.keys.empty() || !writing[current_line].values.empty()) return null;
        return cast(string)(writing[current_line].values);
    }   
    int right_edge_pos(){
        int[] line_arry = writing[current_line].keys;
        return max_in(line_arry);
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



