module cell.cellobject;
import std.string;
import misc.direct;

class Text
{
    int num_of_lines;
    char[][num_of_line+1] line;
}
    
class TextBOX : CellBOX
{
    Text text;
    int cursor;
    int current_line;
    invariant(){
        assert(current_line <= text.num_of_lines);
    }
    Text exportText(){
        return text;
    }
    void reconcider_my_shape(){
    }
    void move_cursor(Direct dir){
        final switch(dir){
            Direct.right:
                move_R; break;
            Direct.left:
                move_L; break;
            Direct.up:
                move_U; break;
            Direct.down:
                move_D; break;
        }
        assert(0);
        void move_R(){
            if(cursor < text.line[current_lines].length)
                ++cursor;
        }
        void move_L(){
            if(cursor != 0)
                --cursor;
        }
        void move_D(){
            if(text.num_of_lines > current_line)
                ++current_line;
        }
        void move_U(){
            if(current_line != 0)
                --current_line;
        }
    }

}
    
