module cell.tablebox;

import cell.cell;
import cell.table;
import cell.contentbox;

import util.direct;

final class TableBOX : ContentBOX{  
private:
    double _ratio;
public:
    BoxTable _inner_table;
    alias _inner_table this;
    this(BoxTable table,in int grid_size){ 
        super(table);
        _inner_table = new BoxTable(grid_size);

    }
    this(BoxTable table,in int grid_size,in Cell tl,in int w,in int h){
        super(table,tl,w,h);
        _inner_table = new BoxTable(grid_size);
    }
    override bool require_create_in(in Cell c)
    {
        return _table.try_create_in(this,c);
    }
    override bool is_to_spoil()const{
        return super.is_to_spoil() || _inner_table.empty();
    }
}
