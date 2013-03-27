import cell.cell;
import misc.direct;

class UserView{
    Cell focus;
    this(){ focus = {row:0,column:0,width:1,height:1}; }
    void move_focus(Direct dir){
        move_cell(focus,dir);
    }
}
