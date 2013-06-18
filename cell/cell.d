module cell.cell;

import util.direct;
import std.algorithm;
import util.array;
import std.exception;
import std.math;
import std.traits;

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
    Cell opBinary(string op)(in Cell rhs)const if(op =="+"){
        return  Cell(row + rhs.row, column + rhs.column);
    }
    Cell opBinary(string op)(in Cell rhs)const if(op =="-"){
        int minus_tobe_zero(int x){
            return x<0?0:x;
        }
        auto r = minus_tobe_zero(row - rhs.row);
        auto c = minus_tobe_zero(column - rhs.column);
        return Cell(r,c);
    }
    Cell opBinary(string op)(in int rhs)const if(op =="/"){
        return  Cell(row/rhs, column/rhs);
    }
    Cell opBinary(string op)(in int rhs)const if(op =="*"){
        return  Cell(row*rhs, column*rhs);
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
    int opCmp(in Cell rhs)const{
        if(row == rhs.row)
            return column - rhs.column;
        else
            return row - rhs.row;
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
void move(ref Cell cell,in Direct to,int width=1){
    final switch(to){
        case right: 
            cell.column += width;
            break;
        case left:
            while(width--)
            if(cell.column != 0)
                --cell.column;
            break;
        case up:
            while(width--)
            if(cell.row != 0)
                --cell.row;
            break;
        case down:
            cell.row += width;
            break;
    }
}
pure Cell if_moved(in Cell c,in Direct to,int width=1){
    Cell result = c;
    final switch(to){
        case right: 
            result.column += width;
            break;
        case left:
            while(width--)
            if(result.column != 0)
                --result.column;
            break;
        case up:
            while(width--)
            if(result.row != 0)
                --result.row;
            break;
        case down:
            result.row += width;
            break;
    }
    return result;
}

// 矩形しか持たないならいらないかもしれない
pure int count_lined(in Cell[] box,in Cell from,in Direct to){
    // debug(cell) writeln("count_lined start");
    int result;
    Cell c = from;
    while(c.is_in(box))
    {
        ++result;
        if(to == left && c.column == 0)
            break;
        if(to == up && c.row == 0)
            break;
        c = c.if_moved(to);
    }
        // debug(cell) writeln("end");
    return result-1; // if(box is null) return -1;
}

// test 用
// CellBOX になれる構造かどうかチェック
bool is_box(in Cell[] box){
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
        width ~= box.count_lined(leftside_cell,right);
    }
    int i;

    assert(width.length != 0);
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
interface CellStructure{
    @property Cell top_left()const;
    @property Cell top_right()const;
    @property Cell bottom_left()const;
    @property Cell bottom_right()const;
    @property bool empty()const;
    void move(in Cell c);
    void move(in Direct,in int pop_cnt=1);
    void create_in(in Cell);
    void expand(in Direct,in int width=1);
    void remove(in Direct,in int width=1);
    void clear();
    bool is_hold(in Cell c)const;
    const(Cell)[] get_cells()const;
    @property int numof_col()const;
    @property int numof_row()const;
}

import util.color;
// 構造をTableに持たせる
// Table上のCellContentと空間を共有する
interface CellContent : CellStructure{
    @property int id()const;
    @property const(Cell[][Direct]) edge_line()const;
    bool require_create_in(in Cell);
    bool require_move(in Cell);
    bool require_move(in Direct,in int width=1);
    bool require_expand(in Direct,in int width=1);
    void require_remove(in Direct,in int width=1);
    bool is_to_spoil()const;
    bool is_registered()const;
    void remove_from_table();
    void set_id(int);
    void set_color(in Color);
    @property Color box_color()const;
    const(Cell)[] get_cells()const;
}

