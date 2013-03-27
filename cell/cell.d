module cell;

public import misc.direct;

struct Cell
{
    int row;
    int column;
    int width;
    int height;
}
void move_cell(Cell cell,Direct dir){
    // 端点でテーブル自体にオフセットかける？
    final switch(dir){
        case Direct.right: 
            ++cell.column;
            return;
        case Direct.left:
            --cell.column;
            return
        case Direct.up:
            --cell.row;
            return;
        case Direct.down:
            ++cell.row;
            return;
    }
    assert(0);
}

mixin template CellBOX_common{
    int table_key;
    CellTable attachedTable;
    Cell owned;

    Cell[] ownedCells;
    this(){}
    void notify(){ 
        attachedTable.update();
    }
    void move(Direct dir){
        // 端点でテーブル自体にオフセットかける？
        move_cell(owned,dir);
    }
}

interface CellBOX{
    void move(Direct);
    void notify(){
}

class CellTable{
    CellBOX[int] table;
    // CellBOX focusedBOX;
    void atach(CellBOX cell_obj)
    {
        cell_obj.table_key = table.length+1;
        table[$+1] = cell_obj;
    }
    void detach(CellBOX cell_obj){
        table.remove(cell_obj.table_key);
    }
    void update();
}
