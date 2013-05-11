module text.text;

import cell.cell;

import std.array;
import misc.array;
import misc.direct;
import std.string;
import std.algorithm;
import std.utf;

debug(text) import std.stdio; // printf dbg
final class Text
{   // TextBOX itemBOX その他で使われる文字列表現TextBuffer相当
    this(){
        static int cnt;
        debug(text) writefln("Text created up %d times",cnt++);
    }
    private:
    int lines = 1;
    Cell caret;
    alias int pos;
    alias int line;
    dchar[pos][line] writing;
    int current_line; 
    int position;
    invariant(){
        assert(current_line < lines);
    }
    public:
    ulong insert(dchar c){
        writing[current_line][position++] = c;
        caret.move(Direct.right);
        debug(text) writef("insert : %s\n",writing[current_line]);
        return writing[current_line].length;
    }
    @property bool empty(){
        return (writing.keys.empty())
        || (writing.length == 1 && writing[0].keys.empty());
    }
    void deleteChar(int pos){
        writing[current_line].remove(pos);
    }
    void backspace(){
        if(position)
            deleteChar(--position);
    }
    @property string str(int line){
        if(!writing.keys.empty()
        || !writing[line].values.empty())
        {
            dstring s;   // こざかしいこと
            foreach(i; writing[line].keys.sort())
                s ~= writing[line][i];
            return toUTF8(s);
        }else return "";
    }   
    @property string[int] strings(){
        string[int] result;
        foreach(line_num,one_line; writing)
            result[line_num] = str(line_num);
        return result;
    }
    bool line_feed(){ // 新しい行を作ったか
        if(currentline !in writing)
            writing[currentline] = null;

        ++current_line;
        position = 0;
        if(current_line == lines)
        {
            ++lines;
            return true;
        }
        return false;
    }
    int right_edge_pos(){
        auto linepos = writing[current_line].keys.sort();
        debug(text) writefln("type:%s",typeid(linepos));
        return linepos[$-1];
    }
    bool move_caretR(){
        if(caret.column < right_edge_pos())
        {
            caret.move(Direct.right);
            return true;
        }else return false;
    }
    bool move_caretL(){
        if(caret.column != 0)
        {
            caret.move(Direct.left);
            return true;
        }else return false;
    }
    bool move_caretU(){
        if(current_line != 0)
        {
            --current_line;
            caret.move(Direct.up);
            return true;
        }else return false;
    }
    bool move_caretD(){
        debug(text) writeln("text feed");
        caret.move(Direct.down);
        if(lines-1 == current_line)
        {
            debug(text) writeln("feeded");
            return line_feed();
        }
        else return false;
    }
    // アクセサ
    int currentline()const{
        return current_line;
    }
    int numof_lines()const{
        return lines;
    }
    Cell get_caret()const{
        return caret;
    }
}

