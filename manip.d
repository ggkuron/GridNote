module manip;

import misc.direct;
import cell.boxes;
import cell.cell;

enum focus_mode{ normal,select,edit }
class ManipTable{
    CellTable focused_table;
    CellBOX focused_box;

    ManipTextBOX manip_text;

    focus_mode mode;
    Cell focus;
    CellBOX select;
    this(CellTable table){
        focused_table = table;
        focus = Cell(3,3); 
        select = new CellBOX(CellBOX.selecter_id);
    }
        
    void delete_from_select(Cell c){
        select.remove(c);
    }
    void delete_focus_from_select(){
        select.remove(focus);
    }
    void move_focus(Direct dir){
        move_cell(focus,dir);
    }
    void fucus_to_box(){
        focused_table.whichBOX(focus);
    }
    void start_select(){
        mode = focus_mode.select;
        select.add(focus);
    }
    void expand_select(Direct dir)
    in{ assert(mode == focus_mode.select);
    }out{
        assert(mode == focus_mode.select);
        assert(focus == focus);
    }body{
        auto adjacent = focus; // Cell は struct . focusは変わらない
        move_cell(adjacent,dir);
        select.add(adjacent); // 
    }
    void delete_from_select(){
        select.remove(focus);
    }
    void return_to_normal_mode()
    in{
        assert(mode == focus_mode.select);
    }out{
        assert(mode == focus_mode.normal);
    }body{
        select.clear();
        select = new CellBOX(CellBOX.selecter_id);
        mode = focus_mode.normal;
    }
}

class ManipCellBOX{
    void reconcider_my_shape(){
    }
}
class ManipTextBOX : ManipCellBOX{
    TextBOX createBOX(){
        return new TextBOX();
    }
    void move_cursor(TextBOX box, Direct dir){
        void move_R(){
        if(box.cursor < box.text.line[box.current_line].length)
            ++box.cursor;
        }
        void move_L(){
            if(box.cursor != 0)
                --box.cursor;
        }
        void move_D(){
            if(box.text.num_of_lines > box.current_line)
                ++box.current_line;
        }
        void move_U(){
            if(box.current_line != 0)
                --box.current_line;
        }
        final switch(dir){
            case Direct.right:
                move_R(); return;
            case Direct.left:
                move_L(); return;
            case Direct.up:
                move_U(); return;
            case Direct.down:
                move_D(); return;
        }
        assert(0);
    }
}
