module text.text;

import misc.array;
import std.string;
struct Text
{
    int num_of_lines;
    char[][int] line;
    int current_line;
    @property auto str(){
        string tmp = cast(string)line[current_line];
        return tmp.toStringz;
    }
    void insert(int line_num,char c){
        line[line_num] ~= c;
    }
    void insert(int line_num,char[32LU] c){
        line[line_num] = c;
    }
    void insertLine(int line_num,string str){
        line[line_num] = cast(char[])str;
    }
    void deleteChar(int line_num,int pos){
        remove(line[line_num],pos);
    }
}



