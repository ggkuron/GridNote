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

bool[Direct] adjusted_info(const Cell[] cells,const Cell searching){
    bool[Direct] result;
    if(cells.empty) return null;
        foreach(a; cells)
        {
            if(a.column == searching.column)
            {
                if(a.row-1 == searching.row)  result[Direct.up] = true;
                else result[Direct.up] = false;
                if(a.row+1 == searching.row)  result[Direct.down] = true;
                else result[Direct.down] = false;
            }else{ 
                result[Direct.up] = result[Direct.down] = false;
            }
            if(a.row == searching.row)
            {
                if(a.column-1 == searching.column) result[Direct.left] = true;
                else result[Direct.left] = false;
                if(a.column+1 == searching.column) result[Direct.right] = true;
                else result[Direct.right] = false;
            }else{
                result[Direct.left] = result[Direct.right] = false;
            }
        }
        return result;
}

class CellBOX{
    CellTable attachedTable;

    static int __id_counter;
    int id;
    this(){ id = __id_counter++; }

    Cell[] cells;
    int width,height;
    void notify(){ // notify to make window redraw 
        attachedTable.changed_flg= true;
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
