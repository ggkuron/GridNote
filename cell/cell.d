module cell.cell;

import derelict.sdl2.sdl;
import misc.direct;
import std.array;
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
void show(Cell c){
    import std.stdio;
    writefln("column:%d,row:%d",c.column,c.row);
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
    CellBOX attached; // table にアタッチされていない状態(== null)も取りうる
    Cell[] using_cells;
    CellBOX[Cell] cells;

    // singletonもどきたちのための
    enum num_of_special_id = 30;  // stored for special BOX like selecter
    enum empty_cell_id = 0;
    enum selecter_id = 1; // box user creates
    enum view_id = 2; // user view of table
    enum table_id = 3;
    static BOX_ID _id_counter = num_of_special_id;
    BOX_ID id;
    this(BOX_ID special_id,CellBOX a)
        in{
        assert(special_id <  num_of_special_id);
        assert(special_id != empty_cell_id );
    }body{
         id = special_id; 
         attached = a;
    }
    this(CellBOX a){
        id = _id_counter++;
        attached = a;
    }
    bool changed_flg;
    void notify()
        in{ // 
        assert(attached !is null);
    }body{ // notify need window to redraw 
        attached.changed_flg= true;
    }
    // Manipulations
    void add(const Cell c){
        cells[c] = null;
    }
    void add(Cell c,CellBOX box){
        cells[c] = box;
    }
    void remove(Cell target){
        cells.remove(target);
    }
    private void add(CellBOX box){
        foreach(c; box.cells.keys)
            cells[c] = box;
    }
    void remove(CellBOX box){
        foreach(c; box.cells.keys)
            cells.remove(c);
    }
    void clear(){
        cells.clear();
    }
    void hold(int row,int column,int w,int h){
        foreach(r; row .. w)
        foreach(c; column .. h)
        {
            add(Cell(r,c));
        }
    }
    void hold(CellBOX b,int row,int column,int w,int h){
        foreach(r; row .. w)
        foreach(c; column .. h)
        {
            add(Cell(r,c),b);
        }
    }
    void hold(Cell c,int w,int h){
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
    bool is_on_edge(Cell c, Direct on){
        return is_in(edge_cells[on], c);
    }
    @property Cell[][Direct] edge_cells(){
        Cell[][Direct] result;
        int min_column = int.max;
        int min_row = int.max;
        int max_column, max_row;
        foreach(c; cells.keys)
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
    void expand(Direct dir){
        auto _cells = edge_cells[dir];
        foreach(c; _cells)
        {
            move_own(c,dir);
            add(c);
        }
    }
    void move(Direct dir){
        // 端点でテーブル自体にオフセットかける？
        CellBOX[Cell] result;
        foreach(cell; cells.keys)
        {   // in this block brought no influence on member or external values
            auto saved = cell;
            auto next = if_moved(cell,dir);
            result[next] = cells[saved];
        }
        cells = result;
    }
    // Get Info
    Cell[] cells_in_row(const int row)const{
        Cell[] result;
        foreach(c; cells.keys)
        {
            if(c.row == row)
                result ~= c;
        }
        return result;
    }
    Cell[] cells_in_column(const int column)const{
        Cell[] result;
        foreach(c;cells.keys)
        {
            if(c.column == column)
                result ~= c;
        }
        return result;
    }
    static int _recursion;
    int recursive_depth(){
        _recursion = 0;
        return check_recursion();
    }
    int check_recursion(){
        if(attached)
        {   ++_recursion;
            return attached.check_recursion();
        }else return _recursion;
    }
    @property Cell upper_left(){
        return upper_left(cells.keys);
    }
    @property Cell upper_left(const Cell[] cells){
        int min_column = int.max;
        int min_row = int.max;
        foreach(c; cells)
            if(c.column <= min_column)  min_column = c.column;
        Cell[] on_left_edge = cells_in_column(min_column);
        foreach(c; cells)
            if(c.row <= min_row) min_row = c.row;
        assert(min_column != int.max && min_row != int.max);
        if(min_column == int.max || min_row == int.max){
            import std.stdio;
            writeln("!!!! somethingi is wrong with func 'upper_left' !!, but it ");
            return cast(Cell)null;
        }
        return Cell(min_row,min_column);
    }

    int count_linedcells(Cell from,Direct to){
        int result;
        while(is_in(cells.keys, from))
        {
            from = if_moved(from,to);
            ++result;
        }
        return result-1; // 自身のセルの分の1
    }
}


ContentBOX change_with(TableBOX table,ContentBOX content)
    in{
    assert(content.attached is table);
    }
    out{
    assert(is(content == TableBOX));
    assert(is(table == ContentBOX));
    }
body{
    content.attached = null;
    content = cast(TableBOX)content;
    table.attached = content;
    table.using_cells = content.using_cells;
    auto result = new ContentBOX(content,content.using_cells);
    content.using_cells.clear();
    table.clear();
    return result;
    // tableはもう捨てる
    // 型変更できるならその方がいい
    // D言語力不足
}

class ContentBOX : CellBOX{
    this(BOX_ID special_id, CellBOX attach, Cell[] contents_area){
        super(special_id,attach);
        attach_to(contents_area);
    }
    this(ContentBOX attach, Cell[] contents_area){
        super(attach);
        attach_to(contents_area); 
    }
    this(ContentBOX attach){
        super(attach);
    }
    private void attach_to(Cell[] contents_area){
        using_cells = contents_area;
        auto offset = upper_left(using_cells);
        foreach(c,box; cells)
        {
            if(!(c in attached.cells))
            attached.cells[c + offset] = box; 
            // テーブルに空きがないと無視されるぞ！！
        }
    }
}
class TableBOX : ContentBOX{
    this(){
        attached = null;
        super(null);
    }
    invariant(){
        assert(attached is null);
    }
}
class ReferBOX : CellBOX{
    Cell offset;
    this(ContentBOX attach, Cell ul,int w,int h)
    body{
        super(view_id,attach);
        capture_to(ul,w,h);
    }
    void capture_to(Cell ul,int w,int h){
        offset = ul;
        foreach(r; ul.row .. w)
        foreach(c; ul.column .. h)
        {
            auto itr = Cell(r,c);
            if(is_in(attached.cells.keys,ul+itr))
                add(itr, attached.cells[ul + itr]);
        }
    }
    override @property Cell upper_left(){
        return offset;
    }
}
class SelectBOX : CellBOX{
    Cell cursor;
    this(ContentBOX attach,Cell cursor)
    body{
        super(selecter_id,attach);
        this.cursor = cursor;
    }
}
