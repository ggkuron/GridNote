module cell.rangecell;

import cell.cell;
import util.direct;
import util.range;
debug(cb) import std.stdio;

// Rangeを1つのスケールしたCellとして扱う
class RangeCell{
    Range _row;
    Range _col;
private:
    ref Range row_or_col(in Direct dir){
        if(dir.is_horizontal)
            return  _col;
        else // (dir.is_vertical)
            return  _row;
    }
public:
    this(){
       //  _row = new Range();
       //  _col = new Range();
    }
    this(RangeCell rhs){
        _row = rhs._row;
        _col = rhs._col;
        rhs.clear();
    }
    void clear(){
        _row.clear();
        _col.clear();
    }
    void add(in Cell c){ 
        _row.add(c.row);
        _col.add(c.column);
        debug(cb) writeln("tl ",top_left);
        debug(cb) writeln("br ",bottom_right);
    }
    // Rangeを矩形として扱うのでCollectionで使える場面は限られる
    void expand(in Direct dir,in int width=1)
        in{
        assert(!_row.empty());
        assert(!_col.empty());
        assert(width > 0);
        }
    body{
        if(dir.is_negative)
        {       // Rangeでoverrun 訂正期待
            row_or_col(dir).pop_back(width);
        }
        else // if(dir.is_positive)
            row_or_col(dir).pop_front(width);

        debug(cb) writeln("tl ",top_left);
        debug(cb) writeln("br ",bottom_right);
    }
    void remove(in Direct dir,in int width=1)
        in{
        assert(width > 0);
        }
    body{
        debug(cell) writeln("@@@@ RangeCell.remove start @@@@");

        if(is_a_cell()) // 消し去りたいならclear()
            return;

        // Range row_or_col(dir) = row_or_col(dir);
        if(dir.is_negative)
            row_or_col(dir).remove_back(width);
        else // (dir.is_positive)
            row_or_col(dir).remove_front(width);
        debug(cell) writeln("#### RangeCell.remove end ####");
    }
    bool is_hold(in Cell c)const{
        return _row.is_hold(c.row)
            && _col.is_hold(c.column);
    }
    // あくまで矩形として扱ったときのedge判定
    bool is_on_edge(in Cell c)const{
        return _row.is_hold(c.row) && _col.is_hold(c.column);
    }
    bool is_on_edge(in Cell c,in Direct on)const{
        final switch(on)
        {
            case Direct.left:
                return c.column == _col.min;
            case Direct.right:
                return c.column == _col.max;
            case Direct.up:
                return c.row  == _row.min;
            case Direct.down:
                return c.row == _row.max;
        }
        assert(0);
    }

    bool is_a_cell()const{
        return _row.min == _row.max &&
        _row.max == _col.min && _col.min == _col.max;
    }
    final void move(in Cell c){
        if(c.row)
            move(down,c.row);
        if(c.column)
            move(right,c.column);
    } 
    final void move(in Direct dir,in int pop_cnt=1){

        if(dir.is_negative)
        {   // overrunしてもRangeで訂正してくれる（のを期待してる）
            row_or_col(dir).move_back(pop_cnt);
        }
        else // (dir.is_positive)
            row_or_col(dir).move_front(pop_cnt);
    }
    const(Cell)[] get_cells()const{
        Cell[] result;
        foreach(r; _row.get())
        foreach(c; _col.get())
            result ~= Cell(r,c);
        return result;
    }
    Cell[] all_in_column(in int col)const{
        Cell[] result;
        foreach(r; _row.get())
            result ~= Cell(r,col);
        return result;
    }
    Cell[] all_in_row(in int row)const{
        Cell[] result;
        foreach(c; _col.get())
            result ~= Cell(row,c);
        return result;
    }
    @property Cell[] edge_forward_cells(in Direct dir)const{
        final switch(dir){
            case Direct.right:
                return  all_in_column(max_col+1);
            case Direct.left:
                return all_in_column(min_col-1);
            case Direct.up:
                return all_in_row(min_row-1);
            case Direct.down:
                return all_in_row(max_row+1);
        }
        assert(0);
    }
    @property ref Range row(){
        return _row;
    }
    @property ref Range col(){
        return _col;
    }
    @property const(Cell[][Direct]) edge_line()const{
        debug(cell) writefln("min_row %d max_row %d\n min_col %d max_col %d",min_row,max_row,min_col,max_col);
        return  [Direct.right:all_in_column(max_col),
                 Direct.left:all_in_column(min_col),
                 Direct.up:all_in_row(min_row),
                 Direct.down:all_in_row(max_row)];
    }
    @property int min_row()const{
        return _row.min;
    }
    @property int max_row()const{
        return _row.max;
    }
    @property int min_col()const{
        return _col.min;
    }
    @property int max_col()const{
        return _col.max;
    }
    @property Cell top_left()const{
        return Cell(_row.min,_col.min);
    }
    @property Cell bottom_right()const{
        return Cell(_row.max,_col.max);
    }
    @property Cell top_right()const{
        return Cell(_row.min,_col.max);
    }
    @property Cell bottom_left()const{
        return Cell(_row.max,_col.min);
    }
    @property bool empty()const{
        return _row.empty() && _col.empty();
    }
    @property int numof_row()const{
        return _row.length;
    }
    @property int numof_col()const{
        return _col.length;
    }
}
