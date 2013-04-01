module cell.cell;

import misc.direct;
import std.array;

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
    CellTable attachedTable;
    int[Direct] edge_info; // left,right:colum num 
                           // up,down: row num 
    static int __id_counter;
    int id;
    this(){ id = __id_counter++; }

    Cell[] cells;
    int width,height;
    void notify(){ // notify to make window redraw 
        attachedTable.changed_flg= true;
    }
    void add(Cell c){
        cells ~= c;
    }
    void remove(Cell target){
        foreach(i,c ; cells)
        {
            if(c == target)
            {
                auto init = cells[0 .. i];
                auto tail = cells[i+1 .. $];
                cells = init ~ tail;
                return;
            }
        }
    }
    void update_edge_info(){
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
    }
    void move(Direct dir){
        // 端点でテーブル自体にオフセットかける？
        foreach(cell; cells)
            move_cell(cell,dir);
    }
}

class CellTable{
    CellBOX[int][Cell] table; // Cellに対応するCellBOXsのidによるmapがtable
    bool changed_flg;

    void atach(CellBOX cell_obj)
    {
        foreach(cell;cell_obj.cells)
            table[cell][cell_obj.id] = cell_obj;
    }
    void detach(CellBOX cell_obj){
        foreach(cell;cell_obj.cells)
            table[cell].remove(cell_obj.id);
    }
    CellBOX[int] whichBOX(Cell c){
        return table[c];
    }
}
