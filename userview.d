module userview;

import misc.direct;
public import cell.cell;

class UserPageView{
    CellTable focused_table;
    CellBOX focused_box;
    Cell focus;
    this(){
        focused_table = new CellTable();
        focus = Cell(3,3); 
    }
    void move_focus(Direct dir){
        move_cell(focus,dir);
    }
    void fucus_to_box(){
        focused_table.whichBOX(focus);
    }
    void update(){}
}
