module cell.content;

import cell.cell;
import cell.table;
import util.array;
import util.direct;

// ContentBOXは内部のRangeを操作後Tableに伝える
// TableにあわせたRangeBOXの操作
abstract class ContentBOX : CellContent{
private:
    BoxTable table;
    alias int ROW;
    alias int COL;
    RangeBOX _inner_rb;
    alias _inner_rb this;
protected:
    invariant(){
        assert(table !is null);
    }
public:
    this(BoxTable attach)
        out{
        assert(table !is null);
        }
    body{
        table = attach;
        _inner_rb = new RangeBOX();
    }
    bool create_in(const Cell c)
    {
        _inner_rb.create_in(c);
        table.try_create_in(this,c);
    }
    bool move(const Direct to){
    }
    unittest{
        debug(cell) writeln("@@@@ TableBOX unittest start @@@@");
        import cell.textbox;
        BoxTable table = new BoxTable;
        auto cb = new TextBOX(table);
        cb.create_in(Cell(3,3));
        cb.expand(Direct.right);
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,4));
        cb.move(Direct.right);
        assert(cb.top_left == Cell(3,4));
        assert(cb.bottom_right == Cell(3,5));
        cb.move(Direct.up);
        assert(cb.top_left == Cell(2,4));
        assert(cb.bottom_right == Cell(2,5));
        debug(cell) writeln("#### TableBOX unittest end ####");
    }
    // 実行できたかどうかは知りたい
    bool expand(const Direct to){
    }
    void remove(const Direct dir){
    }
    void remove_from_table(){
        spoiled = true;
        auto result = table.try_remove(this);
        assert(result);
    }
    // 削除対象かいなか
    private bool spoiled;
    bool is_to_spoil(){
        debug(cell) writeln(spoiled, box.empty());
        return spoiled || box.empty();
    };
    void set_id(int id){
        if(id_counter == int.max){
            // throw exception
            assert(0);
        }
        _box_id = id;
    }
    @property int id()const{
        return _box_id;
    }
    @property const (Cell[][Direct]) edge_line()const{
        debug(cell) writefln("min_row %d max_row %d\n min_col %d max_col %d",min_row,max_row,min_col,max_col);
        return  [Direct.right:all_in_column(max_col),
                 Direct.left:all_in_column(min_col),
                 Direct.up:all_in_row(min_row),
                 Direct.down:all_in_row(max_row)];
    }
    @property bool empty()const{
        return row_range.empty && col_range.empty;
    }
}

