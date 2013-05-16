module cell.cell;

import util.range;
import util.direct;
import std.algorithm;
import util.array;
import std.exception;
import std.math;

import std.typecons;
debug(cell) import std.stdio;
debug(move) import std.stdio;
debug(table) import std.stdio;
debug(refer) import std.stdio;

struct Cell
{
    int row;
    int column;
    public:
    Cell opBinary(string op)(const Cell rhs)const if(op =="+"){
        return  Cell(row + rhs.row, column + rhs.column);
    }
    Cell opBinary(string op)(const Cell rhs)const if(op =="-"){
        int minus_tobe_zero(int x){
            return x<0?0:x;
        }
        auto r = minus_tobe_zero(row - rhs.row);
        auto c = minus_tobe_zero(column - rhs.column);
        auto result = Cell(r,c);
        return result;
    }
    unittest{
        Cell a = Cell(5,5);
        Cell b = Cell(10,10);
        auto c = a-b;
        auto d = a+b;
        assert(c == Cell(0,0));
        assert(d == Cell(15,15));
    }
    invariant(){
        assert(row >= 0);
        assert(column >= 0);
    }
    int opCmp(const Cell rhs)const{
        auto row_result = row - rhs.row;
        auto col_result = column - rhs.column;
        if(!row_result) return col_result;
        else return row_result;
    }
    unittest{
        Cell c = Cell(3,3);
        assert(c.opCmp(c) == 0);
        Cell a = Cell(1,3);
        Cell b = Cell(3,1);
        Cell d = Cell(3,4);
        Cell e = Cell(4,3);
        assert(a < c);
        assert(c > a);
        assert(d > c);
        assert(c == Cell(3,3));
    }
}

pure Cell diff(in Cell a,in Cell b){
    auto r = a.row - b.row;
    auto c = a.column - b.column;
    auto dr = (r<0)?-r:r;
    auto dc = (c<0)?-c:c;
    return Cell(dr,dc);
}
unittest{
    Cell a = Cell(5,5);
    Cell b = Cell(10,10);
    auto c = diff(a,b);
    assert(c == Cell(5,5));
}
void move(ref Cell cell,const Direct to){
    final switch(to){
        case Direct.right: 
            ++cell.column;
            break;
        case Direct.left:
            if(cell.column != 0)
                --cell.column;
            break;
        case Direct.up:
            if(cell.row != 0)
                --cell.row;
            break;
        case Direct.down:
            ++cell.row;
            break;
    }
}
pure Cell if_moved(const Cell c,const Direct to){
    Cell result = c;
    final switch(to){
        case Direct.right: 
            ++result.column;
            break;
        case Direct.left:
            if(result.column != 0)
                --result.column;
            break;
        case Direct.up:
            if(result.row != 0)
                --result.row;
            break;
        case Direct.down:
            ++result.row;
            break;
    }
    return result;
}

// 矩形しか持たないならいらないかもしれない
pure int count_lined(const(Cell)[] box,const Cell from,const Direct to){
    // debug(cell) writeln("count_lined start");
    int result;
    Cell c = from;
    while(box.is_in(c))
    {
        ++result;
        if(to == Direct.left && c.column == 0)
            break;
        if(to == Direct.up && c.row == 0)
            break;
        c = c.if_moved(to);
    }
        // debug(cell) writeln("end");
    return result-1; // if(box is null) return -1;
}

// test 用
// CellBOX になれる構造かどうかチェック
bool is_box(const Cell[] box){
    if(box.length == 1) return true;
    Cell[][int] row_table;
    Cell[][int] col_table;
    foreach(c; box)
    {
        row_table[c.row] ~= c;
        col_table[c.column] ~= c;
    }
    int[] all_row = row_table.keys.sort.dup;
    int[] all_col = col_table.keys.sort.dup;
    int[] width;
    foreach(leftside_cell; col_table[all_col[0]])
    {
        width ~= box.count_lined(leftside_cell,Direct.right);
    }
    int i;
    // width == 0 はありえない
    assert(width != 0);
    foreach(r; width){
        if(i && r!=i) return false;
        i = r;
    }
    return true;
}
unittest{
    Cell[] box =[Cell(2,2),Cell(3,3),Cell(2,3),Cell(3,2)];
    assert(is_box(box));
    box =[Cell(3,3)];
    assert(is_box(box));
    box =[Cell(3,3),Cell(3,4)];
    assert(is_box(box));
    box =[Cell(2,3),Cell(3,3)];
    assert(is_box(box));
}

// 独立して存在できる
// 各々が各々のTableを持っている
interface CellStructure{
    @property Cell top_left();
    @property Cell top_right();
    @property Cell bottom_left();
    @property Cell bottom_right();
    @property bool empty();
    void move(const Cell c);
    void move(const Direct,int pop_cnt=1);
    void create_in(const Cell);
    void expand(const Direct,int width=1);
    void remove(const Direct,int width=1);
    void clear();
    bool is_in(const Cell c)const;
    Cell[] get_cells()const;
    int numof_col()const;
    int numof_row()const;
}

// 構造をTableに持たせる
// Table上のCellContentと空間を共有する
interface CellContent{
    @property Cell top_left();
    @property Cell top_right();
    @property Cell bottom_left();
    @property Cell bottom_right();
    @property bool empty();
    @property int id()const;
    bool require_create_in(const Cell);
    bool require_move(const Direct,int width=1);
    bool require_expand(const Direct,int width=1);
    void require_remove(const Direct,int width=1);
    bool is_to_spoil()const;
    void remove_from_table();
    void set_id(int);
}

