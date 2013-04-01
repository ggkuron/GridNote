module cell.cell;

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

class CellBOX{
    CellTable attachedTable; // table にアタッチされていない状態(== null)も取りうる

    immutable num_of_special_id = 30;  // stored for special BOX like selecter
    immutable selecter_id = 0; // box user creates
    static int __id_counter = num_of_special_id;
    int id;
    this(){ id = __id_counter++; }
    this(int special_id)
    in{
        assert(special_id <  num_of_special_id);
    }body{
         id = special_id; 
    }

    Cell[] cells;
    int width,height;
    void notify()
    in{ // 
        assert(attachedTable !is null);
    }body{ // notify to make window redraw 
        attachedTable.changed_flg= true;
    }
    void add(Cell c){
        cells ~= c;
    }
    void remove(Cell target){
        misc.array.remove(cells,target);
    }
    private int edge_num(Direct dir){
        return get_edge_info()[dir];
    }
    private int[Direct] get_edge_info(){
        int[Direct] edge_info; // left,right:colum num 
                               // up,down: row num 
        int min_column = int.max;
        int min_row = int.max;
        int max_column, max_row;
        foreach(c; cells)
        {
            auto row = c.row;
            auto column = c.column;
            if(row > max_row) max_row = row;
            if(row < min_row) min_row = row;
            if(column > max_column) max_column = column;            
            if(column < min_column) min_column = column;            
        }
        edge_info[Direct.left] = min_column;
        edge_info[Direct.right] = max_column;
        edge_info[Direct.up] = min_row;
        edge_info[Direct.down] = max_row;
        return edge_info;
    }
    Cell[] in_row(int row){
        Cell[] result;
        foreach(c; cells)
        {
            if(c.row == row)
                result ~= c;
        }
        return result;
    }
    Cell[] in_column(int column){
        Cell[] result;
        foreach(c;cells)
        {
            if(c.column == column)
                result ~= c;
        }
        return result;
    }
    void expand(Direct dir){
        auto edge_cells = in_column(edge_num(dir));
        foreach(c; edge_cells)
        {
            move_cell(c,dir);
            add(c);
        }
    }
    void move(Direct dir){
        // 端点でテーブル自体にオフセットかける？
        foreach(cell; cells)
            move_cell(cell,dir);
    }
}

class CellTable{
    CellBOX[int][Cell] box_table; // Cellに対応するCellBOXesのidによるmapがtable
    bool changed_flg;

    void atach(CellBOX cell_obj)
    {
        foreach(cell;cell_obj.cells)
            box_table[cell][cell_obj.id] = cell_obj;
    }
    void detach(CellBOX cell_obj){
        foreach(cell;cell_obj.cells)
            box_table[cell].remove(cell_obj.id);
    }
    CellBOX[int] whichBOX(Cell c){
        return box_table[c];
    }
}
