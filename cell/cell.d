module cell.cell;

import derelict.sdl2.sdl;
import misc.direct;
import std.array;
import misc.array;

struct Cell
{
    int row;
    int column;
}

void move_cell(ref Cell cell,Direct dir){
    // 端点でテーブル自体にオフセットかける？
    final switch(dir){
        case Direct.right: 
            ++cell.column;
            return;
        case Direct.left:
            --cell.column;
            return;
        case Direct.up:
            --cell.row;
            return;
        case Direct.down:
            ++cell.row;
            return;
    }
    assert(0);
}
Cell move(const Cell c,Direct to){
    Cell result = c;
    move_cell(result,to);
    return result;
}

Cell minus(Cell a, Cell b){
    return Cell(a.row - b.row,
                a.column - b.column);
}
bool[Direct] adjacent_info(const Cell[] cells,const Cell searching){
    if(cells.empty) assert(0);
    bool[Direct] result;
    foreach(dir; Direct.min .. Direct.max+1){ result[cast(Direct)dir] = false; }

    foreach(a; cells)
    {
        if(a.column == searching.column)
        {   // may be adjacent to up or down
            if(a.row == searching.row-1)  result[Direct.up] = true;
            if(a.row == searching.row+1)  result[Direct.down] = true;
        } 
        if(a.row == searching.row)
        {
            if(a.column == searching.column-1) result[Direct.left] = true;
            if(a.column == searching.column+1) result[Direct.right] = true;
        }
    }
    return result;
}

alias int BOX_ID;

class CellBOX{
    CellBOX attached; // table にアタッチされていない状態(== null)も取りうる
    Cell offset;
    CellBOX[Cell] cells;

    // singletonもどきたちのための
    enum num_of_special_id = 30;  // stored for special BOX like selecter
    enum empty_cell_id = 0;
    enum selecter_id = 1; // box user creates
    enum view_id = 2; // largest BOX in window
    enum table_id = 3;
    static BOX_ID __id_counter = num_of_special_id;
    BOX_ID id;
    // this(){ id = __id_counter++; }
    this(BOX_ID special_id)
    in{
        assert(special_id <  num_of_special_id);
        assert(special_id != empty_cell_id );
    }body{
         id = special_id; 
    }
    this(CellBOX replace){
        replace_of(replace);
    }
    this(CellBOX attach, Cell _offset){
        attached_to(attach,_offset);
    }
    this(BOX_ID special_id, CellBOX attach, Cell _offset){
        this(special_id);
        attached_to(attach,_offset);
    }
    void attached_to(CellBOX box,Cell _offset){
        attached = box;
        offset = _offset;
        box.cells[offset] = this; 
    }
    void replace_of(CellBOX box){
        attached = box.attached;
        offset = box.offset;
        cells = box.cells;
    }

    bool changed_flg;
    void notify()
    in{ // 
        assert(attached !is null);
    }body{ // notify need window to redraw 
        attached.changed_flg= true;
    }
    // Manipulations
    void add(Cell c){
        cells[c] = null;
    }
    void add(Cell c,CellBOX box){
        cells[c] = box;
    }
    void remove(Cell target){
        cells.remove(target);
    }
    private void add(CellBOX box){
        foreach(c; box.cells.keys)
            cells[c] = box;
    }
    void remove(CellBOX box){
        foreach(c; box.cells.keys)
            cells.remove(c);
    }
    void clear(){
        cells.clear();
    }
    void hold(int row,int column,int w,int h){
        foreach(r ; row .. w)
        foreach(c ; column .. h)
        {
            add(Cell(r,c));
        }
    }
    void hold(Cell c,int w,int h){
        hold(c.row,c.column,w,h);
    }
    bool is_on_edge(Cell c){
        foreach(each_edged; this.edge_cells)
        {
            if(is_in(each_edged,c)) return true;
            else continue;
        }
        return false;
    }
    bool is_on_edge(Cell c, Direct on){
        return is_in(this.edge_cells[on], c);
    }
    @property Cell[][Direct] edge_cells(){
        Cell[][Direct] result;
        int min_column = int.max;
        int min_row = int.max;
        int max_column, max_row;
        foreach(c; cells.keys)
        {
            if(c.row > max_row) max_row = c.row;
            if(c.row < min_row) min_row = c.row;
            if(c.column > max_column) max_column = c.column;            
            if(c.column < min_column) min_column = c.column;            
        }
        result[Direct.left] = in_column(min_column);
        result[Direct.right] = in_column(max_column);
        result[Direct.up] = in_row(min_row);
        result[Direct.down] = in_row(max_row);

        return result;
    }
    void expand(Direct dir){
        auto _cells = edge_cells[dir];
        foreach(c; _cells)
        {
            move_cell(c,dir);
            add(c);
        }
    }
    void move(Direct dir){
        // 端点でテーブル自体にオフセットかける？
        CellBOX[Cell] tmp;
        foreach(cell; cells.keys)
        {
            auto saved = cell;
            move_cell(cell,dir);
            tmp[cell] = cells[saved];
        }
        cells = tmp;
    }
    // Get Info
    Cell[] in_row(const int row)const{
        Cell[] result;
        foreach(c; cells.keys)
        {
            if(c.row == row)
                result ~= c;
        }
        return result;
    }
    Cell[] in_column(const int column)const{
        Cell[] result;
        foreach(c;cells.keys)
        {
            if(c.column == column)
                result ~= c;
        }
        return result;
    }
    static int __recursion;
    int recursive_depth(){
        __recursion = 0;
        return check_recursion();
    }
    int check_recursion(){
        if(attached)
        {
            ++__recursion;
            return attached.check_recursion();
        }else return __recursion;
    }
    @property Cell upper_left(){
        int min_column = int.max;
        int min_row = int.max;
        foreach(c; cells.keys)
            if(c.column <= min_column)  min_column = c.column;
        Cell[] on_left_edge = in_column(min_column);
        foreach(c; cells.keys)
            if(c.row <= min_row) min_row = c.row;
        return Cell(min_row,min_column);
    }
    int count_linedcells(Cell from,Direct to){
        int result;
        if(is_in!(Cell)(cells.keys,.move(from,to))) ++result;
        return result;
    }
}


