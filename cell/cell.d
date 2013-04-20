module cell.cell;

import derelict.sdl2.sdl;
import misc.direct;
import std.array;
import std.algorithm;
import misc.array;
import std.exception;

struct Cell
{
    int row;
    int column;
    Cell opBinary(string op)(Cell rhs) if(op =="+"){
        return  Cell(row + rhs.row, column + rhs.column);
    }
    Cell opBinary(string op)(Cell rhs) if(op =="-"){
        auto result = Cell(row - rhs.row, column - rhs.column);
        enforce(result.row >= 0 && result.column >= 0);
        return result;
    }
}

Cell move_own(ref Cell cell,Direct dir){
    // 端点でテーブル自体にオフセットかける？
    final switch(dir){
        case Direct.right: 
            ++cell.column;
            break;
        case Direct.left:
            --cell.column;
            break;
        case Direct.up:
            --cell.row;
            break;
        case Direct.down:
            ++cell.row;
            break;
    }
    return cell;
}
Cell if_moved(const Cell c,Direct to){
    Cell result = c;
    move_own(result,to);
    return result;
}

bool[Direct] adjacent_info(const Cell[] cells,const Cell searching){
    if(cells.empty) assert(0);
    bool[Direct] result;
    foreach(dir; Direct.min .. Direct.max+1){ result[cast(Direct)dir] = false; }

    foreach(a; cells)
    {
        if(a.column == searching.column)
        {   // adjacent to up or down
            if(a.row == searching.row-1)  result[Direct.up] = true;
            if(a.row == searching.row+1)  result[Direct.down] = true;
        } 
        if(a.row == searching.row)
        {
            if(a.column == searching.column-1) result[Direct.left] = true;
            if(a.column == searching.column+1) result[Direct.right] = true;
        }
    }
    return result;
}

alias int BOX_ID;

class CellBOX{
    TableBOX attached; // table にアタッチされていない状態(== null)も取りうる

    // alias table_area.keys managed_area;
    Cell[Cell] managed_area;

    // singletonもどきたちのための
    enum num_of_special_id = 30;  // stored for special BOX like selecter
    enum empty_cell_id = 0;
    enum selecter_id = 1; // box user creates
    enum view_id = 2; // user view of table
    enum table_id = 3;
    static BOX_ID _id_counter = num_of_special_id;
    BOX_ID id;
    this(BOX_ID special_id,TableBOX a)
        in{
        assert(special_id <  num_of_special_id);
        assert(special_id != empty_cell_id );
    }body{
         id = special_id; 
         attached = a;
    }
    this(TableBOX a){
        id = _id_counter++;
        attached = a;
    }
    this(TableBOX a,Cell[] area){
        this(a);
        add(area);
    }
    bool changed_flg;
    void notify()
        in{ // 
        assert(attached !is null);
    }body{ // notify need window to redraw 
        attached.changed_flg= true;
    }
    // Manipulations
    final void add(const Cell c){
        managed_area[c] = c;
    }
    final void add(const Cell[] area){
        foreach(c; area)
            add(c);
    }
    final void remove(const Cell c){
        managed_area.remove(c);
    }

    final void hold(int row,int column,int w,int h){
        foreach(r; row .. w)
        foreach(c; column .. h)
        {
            add(Cell(r,c));
        }
    }
    // final void hold(CellBOX b,int row,int column,int w,int h){
    //     foreach(r; row .. w)
    //     foreach(c; column .. h)
    //     {
    //         add(Cell(r,c),b);
    //     }
    // }
    final void hold(const Cell c,int w,int h){
        hold(c.row,c.column,w,h);
    }
    bool is_on_edge(Cell c){
        foreach(each_edged; this.edge_cells)
        {
            if(is_in(each_edged,c)) return true;
            else continue;
        }
        return false;
    }
    final bool is_on_edge(const Cell c,Direct on)const{
        return is_in(edge_cells[on], c);
    }
    final @property Cell[][Direct] edge_cells()const{
        Cell[][Direct] result;
        int min_column = int.max;
        int min_row = int.max;
        int max_column, max_row;
        foreach(c; managed_area.keys)
        {
            if(c.row > max_row) max_row = c.row;
            if(c.row < min_row) min_row = c.row;
            if(c.column > max_column) max_column = c.column;            
            if(c.column < min_column) min_column = c.column;            
        }
        result[Direct.left] = cells_in_column(min_column);
        result[Direct.right] = cells_in_column(max_column);
        result[Direct.up] = cells_in_row(min_row);
        result[Direct.down] = cells_in_row(max_row);

        return result;
    }
    final void expand(Direct dir){
        auto one_edges = edge_cells[dir];
        foreach(c; one_edges)
        {
            move_own(c,dir);
            add(c);
        }
    }
    final void move(Direct dir){
        // 端点でテーブル自体にオフセットかける？
        Cell[Cell] result;
        foreach(cell; managed_area.keys)
        {   // in this block brought no influence on member or external values
            const current = cell;
            const next = if_moved(cell,dir);
            result[next] = managed_area[current];
        }
        managed_area = result;
    }
    // Get Info

    static final Cell[] cells_in_row(const Cell[] ary,const int row){
        Cell[] result;
        foreach(c; ary)
        {
            if(c.row == row)
                result ~= c;
        }
        return result;
    }
    final static Cell[] cells_in_column(const Cell[] ary,const int column){
        Cell[] result;
        foreach(c; ary)
        {
            if(c.column == column)
                result ~= c;
        }
        return result;
    }
    final Cell[] cells_in_row(const int row)const{
        return cells_in_row(managed_area.keys,row);
    }
    final Cell[] cells_in_column(const int column)const{
        return cells_in_column(managed_area.keys,column);
    }
    // out of date
//     unittest{
//         CellBOX box = new CellBOX(null);
//         foreach(i; 0 .. 3)
//         {
//             box.add(Cell(i,5));
//         }
//         assert(box.cells_in_column(5) == box.table_area.keys);
//         assert(box.cells_in_column(5) == [Cell(0,5),Cell(1,5),Cell(2,5)]);
//         assert(box.cells_in_row(2) == [Cell(2,5)]);
//         assert(box.upper_left(box.table_area.keys) == Cell(0,5));
//     }
    static int _recursion;
    final int recursive_depth(){
        _recursion = 0;
        return check_recursion();
    }
    final int check_recursion(){
        if(attached)
        {   ++_recursion;
            return attached.check_recursion();
        }else return _recursion;
    }
    // 求めらなっかたらnull  -> ToDO exception
    static Cell upper_left(const Cell[] cells)
    body{
        int min_column = int.max;
        int min_row = int.max;

        foreach(c; cells)
            if(c.column < min_column)  min_column = c.column;
        Cell[] on_left_edge = cells_in_column(cells,min_column);
        // assert(!on_left_edge.empty); throw Exception
        foreach(c; on_left_edge)
            if(c.row <= min_row) min_row = c.row;
        if(min_column == int.max || min_row == int.max){
            import std.stdio;
            writeln("!!!! upper_left が求められなかった");
            assert(0);
        }
        return Cell(min_row,min_column);
    }

    int count_linedcells(Cell from,Direct to)const{
        int result;
        while(is_in(managed_area.keys, from))
        {
            from = if_moved(from,to);
            ++result;
        }
        return result-1; // 自身のセルの分の1
    }
}

// ContentBOX change_with(TableBOX table,ContentBOX content)
//     in{
//     assert(content.attached is table);
//     }
//     out{
//     assert(is(content == TableBOX));
//     assert(is(table == ContentBOX));
//     }
// body{
//     content.attached = null;
//     auto conv = cast(CellBOX)content;
//     content = cast(TableBOX)conv;
//     table.attached = content;
//     table.using_area = content.using_area;
//     auto result = new ContentBOX(content,content.using_area);
//     content.using_area.clear();
//     table.clear();
//     return result;
//     // tableはもう捨てる
//     // 型変更できるならその方がいい
//     // 力不足
// }

class ContentBOX : CellBOX{
    this(BOX_ID special_id, TableBOX attach, Cell[] area){
        super(special_id,attach);
    }
    this(TableBOX attach, Cell[] area){
        super(attach,area);
    }
    this(TableBOX attach){
        super(attach);
    }
}
class TableBOX : CellBOX{
    CellBOX[Cell] table_area;

    this(){
        attached = null;
        super(null);
    }
    // invariant(){
    //     assert(attached is null);
    // }
//     final void add_box(const Cell c){
//         table_area[c] = null;
//         add(c);
//     }
    // final void add_box(CellBOX box){
    //     table_area[c] = box;
    //     add(c);
    // }
    final void remove(Cell target){
        table_area.remove(target);
    }
    final void add_box(CellBOX box){
        foreach(c; box.managed_area.keys)
        {
            table_area[c] = box;
            add(c);
        }
    }
    final void remove(CellBOX box){
        foreach(c; box.managed_area.keys)
        {
            table_area.remove(c);
            remove(c);
        }
    }
    final void clear(){
        table_area.clear();
    }
   //  private void attach_to(ContentBOX content){
   //      import std.stdio;
   //      foreach(cell; content.managed_area.keys)
   //      {   // insert into own cells
   //          writeln("insert:", cell);

   //          // insert into attached using
   //          if(cell in table_area) continue;
   //          else  add_box(cell,content);
   //          // テーブルに空でなければそのCellから参照できない
   //          // in case attached table has non empty cell in this key,
   //          //  the table couldn't be known 
   //      }
   //  }

}

class ReferBOX : TableBOX{
    Cell offset;
    this(TableBOX attach, Cell ul,int w,int h)
    body{
        // super(view_id,attach);
        attached = attach;
        capture(ul,w,h);
    }
//     final private void capture(Cell os,int w,int h){
//         offset = os;
//         foreach(ref b,c; attached.table_area)
//         {
//             auto insert = c-offset;
//             if(insert.column >= 0 
//                     && insert.row >=0);
//             {
//                 this.table_area[insert] = b;
//                 add(insert);
//             }
//         }
//     }
    void capture(Cell ul,int w,int h){
        offset = ul;
        foreach(r; 0 .. w)
        foreach(c; 0 .. h)
        {
            auto itr = Cell(r,c);
            auto set_cell = itr + offset;
            // if((set_cell.column >= 0 && set_cell.row >= 0)
            if(is_in(attached.table_area.keys,itr))
            {
                this.table_area[set_cell] = attached.table_area[itr];
                add(itr);
                import std.stdio;
                writeln("captured ",itr);
            }
        }
    }
}
class SelectBOX : CellBOX{
    Cell focus;
    this(TableBOX attach,Cell cursor)
    body{
        super(selecter_id,attach);
        this.focus = cursor;
    }
}
