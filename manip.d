module manip;

import misc.direct;
public import cell.cell;

enum focus_mode{ normal,select,edit }
class ManipTable{
    CellTable focused_table;
    CellBOX focused_box;

    focus_mode mode;
    Cell focus;
    CellBOX select;
    this(CellTable table){
        focused_table = table;
        focus = Cell(3,3); 
        select = new CellBOX();
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
    }body{
        auto adjacent = focus; // Cell は struct
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
        mode = focus_mode.normal;
    }
        
}
