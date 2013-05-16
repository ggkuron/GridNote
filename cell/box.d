module cell.box;

import cell.cell;
import util.range;
import util.array;
import util.direct;
import std.math;
import std.algorithm;
import std.typecons;
// 四角い領域
// BoxRangeがそのすべて
// 領域の操作方法をまとめてるけど、
// BoxRangeである以上矩形という絶対条件は守られるので、
// 外からの操作も、get_box()で取得できるBoxRangeで自由にしても構わない。

// 範囲によって矩形を表現する
// 必要であればCell[]を生成する
// 2つのRangeのための構造なのかもしれない
class RangeBOX : CellStructure{
private:
    alias int ROW;
    alias int COL;
    alias Tuple!(Range,Range) BoxRange;

    Range row_range;
    Range col_range;
    bool box_fixed;

    unittest{
        auto cb = new RangeBOX();
        cb.create_in(Cell(3,3));
        assert(cb.is_in(Cell(3,3)));
        assert(!cb.is_in(Cell(3,4)));
        cb.expand(Direct.right);
        assert(cb.is_in(Cell(3,4)));
        cb = new RangeBOX();
        cb.create_in(Cell(5,5));
        cb.expand(Direct.right);
        cb.expand(Direct.down);
        // assert(cb.box.count_lined(Cell(5,5),Direct.right) == 1);
        // assert(cb.box.count_lined(Cell(5,5),Direct.down) == 1);
        debug(cell) writeln("@@@@ update_info unittest start @@@@@");
        cb = new RangeBOX();
        cb.create_in(Cell(5,5));
        assert(cb.top_left == Cell(5,5));
        assert(cb.numof_row == 1);
        assert(cb.numof_col == 1);

        cb.hold_tl(Cell(0,0),5,5);

        debug(cell) writefln("!!!! top_left %s",cb.edge[up][left]);
        assert(cb.top_left == Cell(0,0));
        assert(cb.bottom_right == Cell(4,4));
        debug(cell) writeln("numof_row:",cb.numof_row);
        debug(cell) writeln("numof_col:",cb.numof_col);
        assert(cb.numof_row == 5);
        assert(cb.numof_col == 5);
        debug(cell) writeln("#### update_info unittest end ####");
    }
public:
    const(Cell)[] all_in_column(const int column)const{
        Cell[] result;
        int[] range = row_range.get();
        foreach(r; range)
            result ~= Cell(r,column);
        return result;
    }
    const(Cell)[] all_in_row(const int row)const{
        Cell[] result;
        foreach(c; col_range.get())
            result ~= Cell(row,c);
        return result;
    }
    int _box_id; // 0: invalid id
    void create_in(const Cell c)
        in{
        assert(row_range.empty);
        assert(col_range.empty);
        }
    body{ // create initial box
        clear();

        row_range.set(c.row,c.row);
        col_range.set(c.column,c.column);
    }
    void expand(const Direct dir,int width=1)
        in{
        assert(row_range.empty);
        assert(col_range.empty);
        assert(width > 0);
        }
    body{
        Range r_or_c_range;
        if(dir.is_horizontal)
            r_or_c_range = col_range;
        else // (dir.is_vertical)
            r_or_c_range = row_range;

        // 0以下にならない条件をここでさばいてる。が、Rangeに条件課したほうが
        if(dir.is_negative)
            if(r_or_c_range.min >= width)
                r_or_c_range.pop_back(width);
            else
                r_or_c_range.pop_back(r_or_c_range.min);
        else // (dir.is_positive)
            r_or_c_range.pop_front(width);
    }
    void remove(const Direct dir,int width=1){
        debug(cell) writeln("@@@@ RangeBOX.remove start @@@@");

        if(dir.is_horizontal && numof_col <= 1
        || dir.is_vertical && numof_row <= 1 )
            return;

        Range r_or_c_range;
        if(dir.is_horizontal)
            r_or_c_range = col_range;
        else // (dir.is_vertical)
            r_or_c_range = row_range;

        if(dir.is_negative)
            r_or_c_range.remove_back(width);
        else // (dir.is_positive)
            r_or_c_range.remove_front(width);
    }
    void clear(){
        row_range.clear();
        col_range.clear();
    }
    bool is_in(const Cell c)const{
        return row_range.is_in(c.row)
            && col_range.is_in(c.column);
    }
    bool is_a_cell()const{
        return min_row == max_row &&
            max_row == min_col && min_col == max_row;
    }

    this(){
        row_range = new Range(-1,-1);
        col_range = new Range(-1,-1);
    }
    this(Cell ul,int rw,int cw){
        debug(cell){ 
            writeln("ctor start");
            writefln("rw %d cw %d",rw,cw);
        }
        this();
        hold_tl(ul,rw,cw);
        debug(cell)writeln("ctor end");
    }
    this(RangeBOX oldone)
    body{
        debug(cell) writeln("take after start");
        auto ranges = oldone.get_range();

        row_range = ranges[0];
        col_range = ranges[1];

        oldone.clear();
        debug(cell) writeln("end");
    }
    // 増加方向のみ
    final void move(const Cell c){
        if(c.row)
            move(down,c.row);
        if(c.column)
            move(right,c.column);
    }
    final void move(const Direct dir,int pop_cnt=1){
        Range r_or_c_range;
        if(dir.is_horizontal)
            r_or_c_range = col_range;
        else // (dir.is_vertical)
            r_or_c_range = row_range;

        // 0以下にならない条件をここでさばいてる。が、Rangeに条件課したほうが
        if(dir.is_negative)
        {
            auto overlapped = pop_cnt - r_or_c_range.min;
            if(overlapped <= 0)
                r_or_c_range.move_back(pop_cnt);
            else
            {
                r_or_c_range.move_back(r_or_c_range.min);
                r_or_c_range.remove_front(overlapped);
            }
        }
        else // (dir.is_positive)
            r_or_c_range.move_front(pop_cnt);
    }
    unittest{
        debug(cell) writeln("@@@@ RangeBOX move unittest start @@@@");
        auto cb = new RangeBOX(Cell(5,5),5,5);
        assert(cb.top_left == Cell(5,5));
        assert(cb.bottom_right == Cell(9,9));
        assert(cb.top_right == Cell(5,9));
        assert(cb.bottom_left == Cell(9,5));
        assert(cb.min_row == 5);
        assert(cb.min_col == 5);
        assert(cb.max_row == 9);
        assert(cb.max_col == 9);
        cb.move(Direct.up);
        assert(cb.top_left == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));
        assert(cb.top_right == Cell(4,9));
        assert(cb.bottom_left == Cell(8,5));
        assert(cb.min_row == 4);
        assert(cb.min_col == 5);
        assert(cb.max_row == 8);
        assert(cb.max_col == 9);
        cb.move(Direct.left);
        assert(cb.top_left == Cell(4,4));
        assert(cb.bottom_right == Cell(8,8));
        assert(cb.top_right == Cell(4,8));
        assert(cb.bottom_left == Cell(8,4));
        assert(cb.min_row == 4);
        assert(cb.min_col == 4);
        assert(cb.max_row == 8);
        assert(cb.max_col == 8);
        cb.move(Direct.right);
        assert(cb.top_left == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));
        assert(cb.top_right == Cell(4,9));
        assert(cb.bottom_left == Cell(8,5));
        assert(cb.min_row == 4);
        assert(cb.min_col == 5);
        assert(cb.max_row == 8);
        assert(cb.max_col == 9);

        debug(cell) writeln("#### RangeBOX move unittest end ####");
    }
    bool is_on_edge(Cell c)const{
        return row_range.is_in(c.row) && col_range.is_in(c.column);
    }
    unittest{
        debug(cell) writeln("@@@@is_on_edge unittest start@@@@");
        auto cb = new RangeBOX();
        auto c = Cell(3,3);
        cb.create_in(c);
        assert(cb.is_on_edge(c));
        foreach(idir; Direct.min .. Direct.max+1)
        {   // 最終的に各方向に1Cell分拡大
            auto dir = cast(Direct)idir;
            cb.expand(dir);
            assert(cb.is_on_edge(cb.top_left));
            assert(cb.is_on_edge(cb.bottom_right));
        }
        debug(cell) writeln("####is_on_edge unittest end####");
    }
    bool is_on_edge(const Cell c,Direct on)const{
        // 迂回路
        // return edge_line[on].is_in(c);
        final switch(on)
        {
            case Direct.left:
                return c.column == col_range.min;
            case Direct.right:
                return c.column == col_range.max;
            case Direct.up:
                return c.row  == row_range.min;
            case Direct.down:
                return c.row == row_range.max;
        }
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
    // TODO 名前変えて
    // void set_fixed(bool b){ 固定化されたか
    //     box_fixed = b;
    // }
    // bool is_fixed()const{
    //     return box_fixed;
    // }
    void hold(UpDown ud,LR lr)(const Cell start,int h,int w) // TopLeft
        in{
        assert(h >= 1);
        assert(w >= 1);
        }
    body{
        clear();
        create_in(start);
        --w;
        --h;
        if(!w && !h) return;
        expand(cast(Direct)(lr).reverse,w);
        expand(cast(Direct)(ud).reverse,h);
    }
    alias hold!(UpDown.up,LR.left) hold_tl;
    alias hold!(UpDown.up,LR.right) hold_tr;
    alias hold!(UpDown.down,LR.left) hold_bl;
    alias hold!(UpDown.down,LR.right) hold_br;
    unittest{
        debug(cell) writeln("@@@@hold_br unittest start@@@@");
        auto cb = new RangeBOX();
        cb.hold_br(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_tr unittest start @@@@");
        cb = new RangeBOX();
        cb.hold_tr(Cell(5,5),3,3);

        assert(cb.top_left == Cell(5,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_bl unittest start @@@@");
        cb = new RangeBOX();
        cb.hold_bl(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,5));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_tl unittest start @@@@");
        cb = new RangeBOX();
        cb.hold_tl(Cell(3,3),5,5);

        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(7,7));
        cb = new RangeBOX();
        // cb.hold_tl(Cell(3,3),0,0);
        cb.create_in(Cell(3,3));
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,3));
        debug(cell) writeln("#### hold_tl unittest end ####");
    }

    // getter:
    final:
    @property int min_row()const{
        return row_range.min;
    }
    @property int max_row()const{
        return row_range.max;
    }
    @property int min_col()const{
        return col_range.min;
    }
    @property int max_col()const{
        return col_range.max;
    }
    const int numof_row()const{
        return row_range.length;
    }
    const int numof_col()const{
        return col_range.length;
    }
    const(Cell)[] get_cells()const{
        Cell[] result;
        foreach(r; row_range.get())
        foreach(c; col_range.get())
            result ~= Cell(r,c);

        return result;
    }
    @property Cell top_left()const{
        return Cell(row_range.min,col_range.min);
    }
    @property Cell bottom_right()const{
        return Cell(row_range.max,col_range.max);
    }
    @property Cell top_right()const{
        return Cell(row_range.min,col_range.max);
    }
    @property Cell bottom_left()const{
        return Cell(row_range.max,col_range.min);
    }
    @property int id()const{
        return _box_id;
    }
    BoxRange get_range(){
        return tuple(row_range,col_range);
    }
}


