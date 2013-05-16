module cell.content;

import cell.cell;
import cell.table;
import cell.box;
import util.array;
import util.direct;

// ContentBOXは内部のRangeを操作後Tableに伝える
// TableにあわせたRangeBOXの操作
abstract class ContentBOX : CellContent{
private:
    BoxTable table;
    alias int ROW;
    alias int COL;
    int _box_id;
protected:
    invariant(){
        assert(table !is null);
    }
public:
    RangeBOX _inner_rb;
    alias _inner_rb this;
    this(BoxTable attach)
        out{
        assert(table !is null);
        }
    body{
        table = attach;
        _inner_rb = new RangeBOX();
    }
    bool require_create_in(const Cell c)
    {
        if(table.try_create_in(this,c))
        {
            _inner_rb.create_in(c);
            return true;
        }else return false;
    }
    bool require_move(const Cell c){
        ubyte result;
        if(c.row)
        if(require_move(down,c.row))
        {
            _inner_rb.move(down,c.row);
            ++result;
        }
        if(c.column)
        if(require_move(left,c.column))
        {
            _inner_rb.move(left,c.column);
            ++result;
        }
        if(result == 2) return true;
        else return false;
    }
    bool require_move(const Direct to,int width=1){
        if(table.try_move(this,to,width))
        {
            _inner_rb.move(to,width);
            return true;
        }else return false;
    }
    unittest{
        debug(cell) writeln("@@@@ TableBOX unittest start @@@@");
        import cell.textbox;
        BoxTable table = new BoxTable;
        auto cb = new TextBOX(table);
        cb.require_create_in(Cell(3,3));
        cb.require_expand(Direct.right);
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,4));
        cb.require_move(Direct.right);
        assert(cb.top_left == Cell(3,4));
        assert(cb.bottom_right == Cell(3,5));
        cb.require_move(Direct.up);
        assert(cb.top_left == Cell(2,4));
        assert(cb.bottom_right == Cell(2,5));
        debug(cell) writeln("#### TableBOX unittest end ####");
    }
    // 実行できたかどうかは知りたい
    bool require_expand(const Direct to,int width=1){
        if(table.try_expand(this,to,width))
        {
            _inner_rb.expand(to,width);
            return true;
        }else return false;
    }
    void require_remove(const Direct dir,int width=1){
        if(_inner_rb.is_a_cell)
            return;
        table.remove_content_edge(this,dir,width);
        _inner_rb.remove(dir,width);
    }
    void remove_from_table(){
        spoiled = true;
        auto result = table.try_remove(this);
        assert(result);
        _inner_rb.clear();
    }
    // 削除対象かいなか
    private bool spoiled;
    bool is_to_spoil(){
        debug(cell) writeln(spoiled, box.empty());
        return spoiled ||empty();
    };
    void set_id(int id){
        _box_id = id;
    }
    @property int id()const{
        return _box_id;
    }
    alias _inner_rb this;
    @property const (Cell[][Direct]) edge_line()const{
        debug(cell) writefln("min_row %d max_row %d\n min_col %d max_col %d",min_row,max_row,min_col,max_col);
        return  [Direct.right:all_in_column(max_col),
                 Direct.left:all_in_column(min_col),
                 Direct.up:all_in_row(min_row),
                 Direct.down:all_in_row(max_row)];
    }
    @property bool empty()const{
        return _inner_rb.empty();
    }
    auto get_range(){
        return _inner_rb.get_range();
    }
    @property Cell top_left()const{
        return _inner_rb.top_left;
    }
    @property Cell bottom_right()const{
        return _inner_rb.bottom_right;
    }
    @property Cell top_right()const{
        return _inner_rb.top_right;
    }
    @property Cell bottom_left()const{
        return _inner_rb.bottom_left;
    }
    @property int min_row()const{
        return _inner_rb.min_row;
    }
    @property int max_row()const{
        return _inner_rb.max_row;
    }
    @property int min_col()const{
        return _inner_rb.min_col;
    }
    @property int max_col()const{
        return _inner_rb.max_col;
    }
    const int numof_row()const{
        return _inner_rb.numof_row;
    }
    const int numof_col()const{
        return _inner_rb.numof_col;
    }
    bool is_in(const Cell c)const{
        return _inner_rb.is_in(c);
    }
    const(Cell)[] get_cells()const{
        return _inner_rb.get_cells();
    }
}

