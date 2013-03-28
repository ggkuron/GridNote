module cell.cell;

import misc.direct;

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

class CellBOX{
    // int table_key;
    CellTable attachedTable;

    Cell cell;
    int width,height;
    this(){}
    void notify(){ 
        attachedTable.update();
    }
    void move(Direct dir){
        // 端点でテーブル自体にオフセットかける？
        move_cell(cell,dir);
    }
}

class CellTable{
    CellBOX[][Cell] table;

    void atach(CellBOX cell_obj)
    {
        // cell_obj.table_key = table.length+1;
        table[cell_obj.cell] ~= cell_obj;
    }
    void detach(CellBOX cell_obj){
        table.remove(cell_obj.cell);
    }
    CellBOX[] whichBOX(Cell c){
        return table[c];
    }
    void update(){}
}
