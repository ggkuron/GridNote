module cell.boxes;

import cell.cell;
import text.text;
import std.string;
import misc.direct;

class TextBOX : CellBOX
{   // text の行数を Cellの高さに対応させてみる
    this(){ super(); }
    Text text;
    int cursor;
    int current_line;
    invariant(){
        assert(current_line <= text.num_of_lines);
    }
    Text exportText(){
        return text;
    }
}
    
