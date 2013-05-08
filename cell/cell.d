module cell.cell;

import misc.direct;
import std.array;
import std.algorithm;
import misc.array;
import std.exception;
import std.math;

import std.typecons;
debug(cell) import std.stdio;

struct Cell
{
    int row;
    int column;
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
        if(row < rhs.row) return -1;
        else if(row == rhs.row)
        {
            if(column < rhs.column) return -1;
            else if(column == rhs.column) return 0;
            else return 1;
        }else return 1;
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

Cell diff(in Cell a,in Cell b){
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
Cell if_moved(const Cell c,const Direct to){
    Cell result = c;
    result.move(to);
    return result;
}

// test 用
// CellBOX になれる構造かどうかチェック
// 四角い要素を持っているかどうか
bool is_box(const Cell[] box){
    if(box.length == 1) return true;
    auto check_box = new CellBOX(); // この判定方法だとpureになれない
    check_box.box_change(box,false); // check is false

    foreach(c; box)
    {
        auto same_row = check_box.in_row(c.row);
        int column_length;
        foreach(r; same_row)
        {
            auto upper = check_box.count_lined(r,Direct.up);
            auto downer = check_box.count_lined(r,Direct.down);
            auto total = upper + downer;

            if(!column_length)
            {
                column_length = upper+downer;
            }

            if(column_length == total) continue;
            else return false;
        }
        return true;
    }
    assert(0); // box is empty or null
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

// 四角い領域を持つこと
// 領域の管理方法
class CellBOX{
    Cell upper_left;
    Cell lower_right;
    int row_num,
        col_num;
    Cell[] box;

    public bool is_in(const Cell c)const
    body{
        return .is_in(box,c);
    }
    unittest{
        auto cb = new CellBOX();
        cb.create_in(Cell(3,3));
        assert(cb.is_in(Cell(3,3)));
        assert(!cb.is_in(Cell(3,4)));
        cb.expand(Direct.right);
        assert(cb.is_in(Cell(3,4)));
    }
    private void add(const Cell c){
        box ~= c;
    }
    public void remove(const Direct dir){
        debug(cell) writeln("remove start");
        Cell[] delete_line;

        if(dir.is_horizontal && col_num <= 1
        || dir.is_vertical && row_num <= 1 )
            return;
        delete_line = edge_cells[dir];
        foreach(c; delete_line)
        {
           misc.array.remove!(Cell)(box,c);
           debug(cell) writefln("deleted %s",c);
        }
        update_info();
        debug(cell) writeln("end");
    }
    public void clear(){
        box.clear();
    }
    // 破壊的にboxの中身を入れ替える
    // check == false はis_box でのチェック用
    // is_box でのチェックを行わない
    public bool box_change(const Cell[] newone,bool check=true){
        if(check) 
            if(is_box(newone)) return false;
        box = newone.dup;
        update_info();
        return true;
    }
    protected void take_after(CellBOX oldone)
        in{
        assert(!oldone.get_box_raw().empty);
        }
        out{
        assert(!box.empty);
        }
    body{
        debug(cell) writeln("take after start");
        box = oldone.get_box_raw();
        update_info();

        oldone = null;
        debug(cell) writeln("end");
    }
    public const(Cell[]) get_box()const{
        return box;
    }
    public Cell[] get_box_dup()const{
        return box.dup;
    }
    public Cell[] get_box_raw(){
        return box;
    }

    this(){}
    this(Cell ul,int rw,int cw){
        debug(cell){ 
            writeln("ctro start");
            writefln("rw %d cw %d",rw,cw);
        }
        hold_ul(ul,rw,cw);
        debug(cell)writeln("ctor end");
    }
    private void update_info()
    body{
        debug(cell) writeln("update_info start");
        if(!box.empty())
        {
            upper_left = search_upper_left();
            auto row_lined = count_lined(upper_left,Direct.down);
            auto col_lined = count_lined(upper_left,Direct.right);
            lower_right = Cell(upper_left.row+row_lined,upper_left.column+col_lined);
            row_num = ++row_lined;
            col_num = ++col_lined;
            debug(cell){
                writefln("upper left %s",upper_left);
                writeln(row_num," " ,col_num);
            }
        }else{

        }

        debug(cell) writeln("end");
    }
    unittest{
        writeln("update_info unittest start");
        auto cb = new CellBOX();
        cb.create_in(Cell(5,5));
        assert(cb.upper_left == Cell(5,5));
        assert(cb.row_num == 1);
        assert(cb.col_num == 1);

        // ctor call hold call update_info
        // and try calling again
        cb.hold_ul(Cell(0,0),5,5);
        cb.update_info();
        // ... may cause nothing
        assert(cb.upper_left == Cell(0,0));
        assert(cb.row_num == 5);
        assert(cb.col_num == 5);
        assert(cb.lower_right == Cell(4,4));
        writeln("end");
    }
        
    void move(const Direct dir){
        expand(dir);
        remove(dir.reverse);
        update_info();
    }
    void create_in(const Cell c)
        in{
        assert(box.empty);
        }
        out{
        assert(is_box(box));
        }
    body{ // create initial box
        add(c);
        update_info();
    }
    void expand(Direct dir)
        in{
        assert(is_box(box));
        }
        out{
        assert(is_box(box));
        }
    body{
        debug(cell) writeln("expand start");
        auto one_edges = edge_cells[dir];
        foreach(c; one_edges)
        {
            c.move(dir);
            add(c);
        }
        update_info();
        debug(cell) writeln("end");
    }
    bool is_on_edge(Cell c)const{
        foreach(each_edged; edge_cells())
        {
            if(each_edged.is_in(c)) return true;
            else continue;
        }
        return false;
    }
    unittest{
        writeln("is_on_edge unittest start");
        auto cb = new CellBOX();
        auto c = Cell(3,3);
        cb.create_in(c);
        assert(cb.is_on_edge(c));
        foreach(idir; Direct.min .. Direct.max+1)
        {   // 最終的に各方向に1Cell分拡大
            auto dir = cast(Direct)idir;
            cb.expand(dir);
            assert(cb.is_on_edge(cb.get_upper_left));
            assert(cb.is_on_edge(cb.get_lower_right));
        }
        writeln("end");
    }
    bool is_on_edge(const Cell c,Direct on)const{
        return edge_cells[on].is_in(c);
    }
    @property Cell[][Direct] edge_cells()const{
        Cell[][Direct] result;
        int min_column = upper_left.column;
        int min_row = upper_left.row;
        int max_column = lower_right.column;
        int max_row = lower_right.row;

        result[Direct.left] = in_column(min_column);
        result[Direct.right] = in_column(max_column);
        result[Direct.up] = in_row(min_row);
        result[Direct.down] = in_row(max_row);

        return result;
    }
    @property public bool empty()const{
        return box.empty();
    }
    private Cell[] in_column(const int column)const{
        Cell[] result;
        foreach(c; box)
        {
            if(c.column == column)
                result ~= c;
        }
        return result;
    }
    private Cell[] in_row(const int row)const{
        Cell[] result;  // このくらいの冗長さは許されるだろう
        foreach(c; box)
        {
            if(c.row == row)
                result ~= c;
        }
        return result;
    }
    void hold_ul(const Cell start,int h,int w)
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        box.clear();
        create_in(start);
        if(!w && !h) return;

        if(w)--w;
        if(h)--h;
        while(!(w==0 && h==0))
        {
            if(w > 0)
            {
                expand(Direct.right);
                --w;
            }
            if(h > 0)
            {
                expand(Direct.down);
                --h;
            }
        }
        update_info();
    }
    void hold_lr(const Cell lr,int h,int w)
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        auto s_r = lr.row-h+1;
        if(s_r < 0) s_r = 0;
        auto s_c = lr.column-w+1;
        if(s_c < 0) s_c = 0;
        auto start = Cell(s_r,s_c);
        hold_ul(start,h,w);
    }
    unittest{
        auto cb = new CellBOX();
        cb.hold_lr(Cell(5,5),3,3);

        assert(cb.upper_left == Cell(3,3));
        assert(cb.row_num == 3);
        assert(cb.col_num == 3);
    }
    void hold_ur(const Cell ur,int h,int w)
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        auto s_r = ur.row;
        auto s_c = ur.column-w+1;
        if(s_c<0){
            w += s_c;
            s_c = 0;
        }
        auto start = Cell(s_r,s_c);
        hold_ul(start,h,w);
    }
    unittest{
        auto cb = new CellBOX();
        cb.hold_ur(Cell(5,5),3,3);

        assert(cb.upper_left == Cell(5,3));
        assert(cb.row_num == 3);
        assert(cb.col_num == 3);
    }
    void hold_ll(const Cell ll,int h,int w)
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        auto s_r = ll.row-h+1;
        if(s_r < 0) s_r = 0;
        auto s_c = ll.column;
        auto start = Cell(s_r,s_c);
        hold_ul(start,h,w);
    }
    unittest{
        auto cb = new CellBOX();
        cb.hold_ll(Cell(5,5),3,3);

        assert(cb.upper_left == Cell(3,5));
        assert(cb.row_num == 3);
        assert(cb.col_num == 3);
    }
    unittest{
        auto cb = new CellBOX();
        cb.hold_ul(Cell(3,3),5,5);

        assert(cb.upper_left == Cell(3,3));
        assert(cb.lower_right == Cell(7,7));
        cb = new CellBOX();
        cb.hold_ul(Cell(3,3),0,0);
        assert(cb.upper_left == Cell(3,3));
        assert(cb.lower_right == Cell(3,3));
    }
    Cell get_upper_left()const{
        return upper_left;
    }
    Cell get_lower_right()const{
        return lower_right;
    }

    private Cell search_upper_left(const Cell[] cells)const{
        Cell result = Cell(int.max,int.max);
        foreach(c; box)
            if(c < result) result = c;
        return result;
    }
    private Cell search_upper_left()const{
        return search_upper_left(box);
    }
    private int count_lined(const Cell from,const Direct to)const{
        debug(cell) writeln("count_lined start");
        int result;
        Cell c = from;
        while(is_in(c))
        {
            ++result;
            if(to == Direct.left && c.column == 0)
                break;
            if(to == Direct.up && c.row == 0)
                break;
            c.move(to);
        }
        debug(cell) writeln("end");
        return result-1; // if(box is null) return -1;
    }
    unittest{
        auto cb = new CellBOX();
        cb.create_in(Cell(5,5));
        cb.expand(Direct.right);
        cb.expand(Direct.down);
        assert(cb.count_lined(Cell(5,5),Direct.right) == 1);
        assert(cb.count_lined(Cell(5,5),Direct.down) == 1);
    }
    public const int get_numof_vcell()const{
        return row_num;
    }
    public const int get_numof_hcell()const{
        return col_num;
    }
}

abstract class ContentBOX : CellBOX{
    BoxTable table;
    this(BoxTable attach, ContentBOX taken)
        in{
        assert(attach !is null);
        assert(taken !is null);
        }
    body{
        table = attach;
        box = taken.box;
    }
    this(BoxTable attach)
        in{
        assert(attach !is null);
        }
    body{
        table = attach;
    }
    public BoxTable get_table(){
        return table;
    }
    // BoxTable 以外から触るべからず
    // Tableが識別に使うためのid
    // Appが生きてる間は一貫してるかもしれない
    private int table_key; // 状態を保存するときには初期化必須
    final:
    public void set_table_key(int a){
        table_key = a;
    }
    public void delete_table_key(){
        table_key = 0;
    }
}

class MiniTable : ContentBOX{
    BoxTable inner_table;
    alias inner_table this;
    this(BoxTable table,ContentBOX area){
        super(table,area);
        inner_table = new BoxTable;
    }
}

class BoxTable : CellBOX{
    private int id_counter;

    ContentBOX[int] content_table;
    string[int] type_table;
    int[Cell] keys;

    this(){}

    invariant(){
    }
    public:
    void add_box(T)(T u)
        in{
        assert(u.table == this);
        }
        out{
            // keys.keysはこのbox以外も含む
        // assert(keys.keys == box);
        }
    body{
        debug(cell) writeln("add_box start");
        assert(cast(ContentBOX)u !is null);
        u.set_table_key(++id_counter); // id == 0 は未初期化値として使う
        assert(!u.get_box().empty);
        foreach(c; u.get_box())
        {
            keys[c] = id_counter;
            add(c);
        }
        type_table[id_counter] = u.toString;
        content_table[id_counter] = u;
        debug(cell){
            writeln("type: ",u.toString);
            writeln("table key: ",id_counter);
            writeln("end");
        }
    }
    void remove(ContentBOX u)
        in{
        assert(u.table == this);
        }
        out{
        assert(keys.keys == box);
        }
    body{
        auto content_cells = u.get_box();
        foreach(c; content_cells)
        {
            keys.remove(c);
        }
        content_table.remove(u.table_key);
        type_table.remove(u.table_key);
        u.delete_table_key();
    }
    unittest{
        auto cb = new CellBOX(Cell(0,0),5,5);
        cb.remove(Direct.up);
        assert(cb.upper_left == Cell(1,0));
        assert(cb.col_num == 5);
        assert(cb.row_num == 4);
        assert(cb.lower_right == Cell(4,4));
        cb.remove(Direct.right);
        assert(cb.upper_left == Cell(1,0));
        assert(cb.col_num == 4);
        assert(cb.row_num == 4);
        assert(cb.lower_right == Cell(4,3));
        cb.remove(Direct.left);
        assert(cb.upper_left == Cell(1,1));
        assert(cb.col_num == 3);
        assert(cb.row_num == 4);
        assert(cb.lower_right == Cell(4,3));
        cb.remove(Direct.down);
        assert(cb.upper_left == Cell(1,1));
        assert(cb.col_num == 3);
        assert(cb.row_num == 3);
        assert(cb.lower_right == Cell(3,3));
    }
    public Tuple!(string,ContentBOX) get_content(const Cell c){
        if(!(c in keys)) writeln("this cell is empty, no content return");
        auto key = keys[c];
        return tuple(type_table[key],content_table[key]);
    }
    const Cell[] get_used()const{
        return keys.keys;
    }
    final void clear(){
        keys.clear();
    }
}

class ReferTable : BoxTable{
    BoxTable master; // almost all manipulation acts on this table
    Cell offset;
    private int range_of_row,range_of_col;

    this(BoxTable attach, Cell ul,int w,int h)
        in{
        assert(attach !is null);
        }
    body{
        master = attach; // manipulating ReferBOX acts on attached Table
        set_table_size(ul,h,w);
        data_sync();
    }
    public void set_table_size(Cell ul,int h,int w){
        offset = ul;
        range_of_row = offset.row + h;
        range_of_col = offset.column + w;
        writefln("range_r %d range_c %d",range_of_row,range_of_col);
    }
    public void data_sync(){
        auto masterbox = master.get_box;
        box.clear();
        foreach(c; 0 .. range_of_col)
        foreach(r; 0 .. range_of_row)
        {
            auto itr = Cell(r,c)+offset;
            if(itr in master.keys)
                box ~= itr;
        }
    }
    public:
    private auto get_content(const Cell c){
        master.get_content(c);
        if(!(c in master.keys)) writeln("this cell is empty, no content return");
        auto key = master.keys[c];
        return tuple(master.type_table[key],master.content_table[key]);
    }
    auto get_contents(){
        Tuple!(string,ContentBOX)[ContentBOX] i_have;

        foreach(c; box)
        {
            writeln("get_contents works");
            auto item = get_content(c);
            i_have[item[1]] = item;
        }
        return i_have;
    }
    // add_box は直接table番地に反映させる
    // 
    override void add_box(T)(T u)
        in{
        assert(u.table == master);
        }
    body{
        assert(cast(ContentBOX)u !is null);
        debug(cell) writeln("add_box :",u.get_box());
        foreach(c; u.get_box())
        {
            master.table[c+offset] = u;
            add(c);
        }
    }
    // master のtableのなかでview に含まれるもの
    // get_box()
    public void move_focus(const Direct to){
        offset.move(to);
    }
    Cell get_view_position(const CellBOX b)const{
        auto tmp = b.get_upper_left();
        writeln("tmp : ",tmp);
        writeln("box : ",b.box);
        // pos(0,0)で止まる
        return tmp - offset;
    }
    /+ void remove(const ContentBOX) 
       Cell[] get_struct()
       ContentBOX get_content(const Cell)
        +/
    // you can use super class's difinition 
}

import cell.textbox;

class SelectBOX : ContentBOX{
    Cell focus;
    Cell pivot;
    /+ inherited
       CellBOX box
       alias box this +/
    this(BoxTable attach,Cell cursor=Cell(3,3))
    body{
        super(attach);
        focus = cursor;
    }
    override void move(const Direct dir){
        focus.move(dir);
    }
    void create_in(){
        super.create_in(focus);
        debug(cell)writefln("create in %s",focus);
    }
    bool is_on_edge()const{
        return super.is_on_edge(focus);
    }
    bool is_on_edge(Direct dir)const{
        return super.is_on_edge(focus,dir);
    }
    public TextBOX create_TextBOX(){
        debug(cell) writeln("create_TextBOX start");
        create_in();
        auto tb = new TextBOX(table);
        tb.take_after(this);
        box.clear();
        debug(cell) writeln("end");
        return tb;
    }
    private void set_pivot(const Cell p)
        in{
        assert(box.empty());
        }
    body{
        debug(cell) writeln("set_pivot start");
        pivot = p;
        super.create_in(pivot);
        debug(cell) writeln("end");
    }
    public void set_pivot(){
        set_pivot(focus);
    }
    private void pivot_bound(Cell cl){
        debug(cell) writeln("privot_bound start");
        if(pivot == cl)  hold_ul(pivot,1,1); else
        if(pivot < cl) // pivot.rowの方が小さいブロック
        {
            auto d = diff(cl,pivot);
            auto dr = d.row+1;
            auto dc = d.column+1;

            if(cl.column == pivot.column) // 縦軸下
                hold_ul(pivot,dr,1);
            else if(cl.column < pivot.column) // 第3象限
                hold_ur(pivot,dr,dc);
            else 
                hold_ul(pivot,dr,dc); // 第四象限
        }else{ // if(pivot > cl) pivot.rowが大きい
            auto d = diff(pivot,cl);
            auto dr = d.row+1;
            auto dc = d.column+1;
            if(cl.column == pivot.column) // 縦軸上
                hold_lr(pivot,dr,1);
            else if(cl.column > pivot.column) // 1
                hold_ur(cl,dr,dc);
            else // 3象限
                hold_lr(pivot,dr,dc);
        }
        debug(cell) writeln("end");
    }

    public void expand_to_focus()
        in{
        assert(!box.empty());
        }
        out{
        assert(is_box(box));
        }
    body{
        debug(cell) writeln("expand_to_focus start");
        pivot_bound(focus);
        debug(cell) writeln("end");
    }
}
