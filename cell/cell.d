module cell.cell;

import misc.direct;
import std.array;
import std.algorithm;
import misc.array;
import std.exception;
import std.math;

import std.typecons;
debug(cell) import std.stdio;
debug(move) import std.stdio;

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
private:
    Cell top_left;
    Cell bottom_right;
    int numof_row,
        numof_col;
    Cell[] box;
    bool box_fixed;

    unittest{
        auto cb = new CellBOX();
        cb.create_in(Cell(3,3));
        assert(cb.is_in(Cell(3,3)));
        assert(!cb.is_in(Cell(3,4)));
        cb.expand(Direct.right);
        assert(cb.is_in(Cell(3,4)));
    }
    Cell search_top_left(const Cell[] cells)const{
        Cell result = Cell(int.max,int.max);
        foreach(c; box)
            if(c < result) result = c;
        return result;
    }
    Cell search_top_left()const{
        return search_top_left(box);
    }
    int count_lined(const Cell from,const Direct to)const{
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
    final void add(const Cell c){
        box ~= c;
    }
    unittest{
        auto cb = new CellBOX();
        cb.create_in(Cell(5,5));
        cb.expand(Direct.right);
        cb.expand(Direct.down);
        assert(cb.count_lined(Cell(5,5),Direct.right) == 1);
        assert(cb.count_lined(Cell(5,5),Direct.down) == 1);
    }
    void update_info(){
        debug(cell) writeln("update_info start");
        if(!box.empty())
        {
            top_left = search_top_left();
            auto row_lined = count_lined(top_left,Direct.down);
            auto col_lined = count_lined(top_left,Direct.right);
            bottom_right = Cell(top_left.row+row_lined,top_left.column+col_lined);
            numof_row = ++row_lined;
            numof_col = ++col_lined;
            debug(cell){
                writefln("upper left %s",top_left);
                writeln(numof_row," " ,numof_col);
            }
        }
        debug(cell) writeln("end");
    }
    unittest{
        debug(cell) writeln("update_info unittest start");
        auto cb = new CellBOX();
        cb.create_in(Cell(5,5));
        assert(cb.top_left == Cell(5,5));
        assert(cb.numof_row == 1);
        assert(cb.numof_col == 1);

        // ctor call hold call update_info
        // and try calling again
        cb.hold_tl(Cell(0,0),5,5);
        cb.update_info();
        // ... may cause nothing
        assert(cb.top_left == Cell(0,0));
        assert(cb.numof_row == 5);
        assert(cb.numof_col == 5);
        assert(cb.bottom_right == Cell(4,4));
        debug(cell) writeln("end");
    }
    Cell[] in_column(const int column)const{
        Cell[] result;
        foreach(c; box)
        {
            if(c.column == column)
                result ~= c;
        }
        return result;
    }
    Cell[] in_row(const int row)const{
        Cell[] result;  // このくらいの冗長さは許されるだろう
        foreach(c; box)
        {
            if(c.row == row)
                result ~= c;
        }
        return result;
    }
    static int id_counter;
    int box_id; // 0: invalid id
    void set_id(){
        if(id_counter == int.max){
            // TODO change to throw exception
            assert(0);
        }
        box_id = id_counter++;
    }
protected:
    void take_over(CellBOX oldone)
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
public:
    void remove(const Direct dir){
        debug(cell) writeln("remove start");
        Cell[] delete_line;

        if(dir.is_horizontal && numof_col <= 1
        || dir.is_vertical && numof_row <= 1 )
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
    void clear(){
        box.clear();
    }
    bool is_in(const Cell c)const{
        return .is_in(box,c);
    }
    // 破壊的にboxの中身を入れ替える
    // check == false はis_box でのチェック用
    // is_box でのチェックを行わない
    bool box_change(const Cell[] newone,bool check=true){
        if(check) 
            if(is_box(newone)) return false;
        box = newone.dup;
        update_info();
        return true;
    }
    this(){
        set_id();
    }
    this(Cell ul,int rw,int cw){
        debug(cell){ 
            writeln("ctor start");
            writefln("rw %d cw %d",rw,cw);
        }
        set_id();
        hold_tl(ul,rw,cw);
        debug(cell)writeln("ctor end");
    }
    void move(const Direct dir){
        expand(dir);
        remove(dir.reverse);
        // update_info は既に2回呼ばれてるっていう
    }
    unittest{
        debug(cell) writeln("CellBOX move test start");
        auto cb = new CellBOX(Cell(5,5),5,5);
        cb.move(Direct.up);
        assert(cb.top_left == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));
        cb.move(Direct.left);
        assert(cb.top_left == Cell(4,4));
        assert(cb.bottom_right == Cell(8,8));
        cb.move(Direct.right);
        assert(cb.top_left == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));

        debug(cell) writeln("end");
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
    void expand(const Direct dir)
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
        debug(cell) writeln("is_on_edge unittest start");
        auto cb = new CellBOX();
        auto c = Cell(3,3);
        cb.create_in(c);
        assert(cb.is_on_edge(c));
        foreach(idir; Direct.min .. Direct.max+1)
        {   // 最終的に各方向に1Cell分拡大
            auto dir = cast(Direct)idir;
            cb.expand(dir);
            assert(cb.is_on_edge(cb.get_top_left));
            assert(cb.is_on_edge(cb.get_bottom_right));
        }
        debug(cell) writeln("end");
    }
    bool is_on_edge(const Cell c,Direct on)const{
        return edge_cells[on].is_in(c);
    }
    @property Cell[][Direct] edge_cells()const{
        Cell[][Direct] result;
        int min_column = top_left.column;
        int min_row = top_left.row;
        int max_column = bottom_right.column;
        int max_row = bottom_right.row;

        result[Direct.left] = in_column(min_column);
        result[Direct.right] = in_column(max_column);
        result[Direct.up] = in_row(min_row);
        result[Direct.down] = in_row(max_row);

        return result;
    }
    @property bool empty()const{
        return box.empty();
    }
    // TODO 名前変えて実装
    // void set_fixed(bool b){ 固定化されたか
    //     box_fixed = b;
    // }
    // bool is_fixed()const{
    //     return box_fixed;
    // }
    void hold_tl(const Cell start,int h,int w) // TopLeft
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
    void hold_br(const Cell lr,int h,int w) // BottomRight
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
        hold_tl(start,h,w);
    }
    unittest{
        auto cb = new CellBOX();
        cb.hold_br(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
    }
    void hold_tr(const Cell ur,int h,int w)
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
        hold_tl(start,h,w);
    }
    unittest{
        auto cb = new CellBOX();
        cb.hold_tr(Cell(5,5),3,3);

        assert(cb.top_left == Cell(5,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
    }
    void hold_bl(const Cell ll,int h,int w)
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
        hold_tl(start,h,w);
    }
    unittest{
        auto cb = new CellBOX();
        cb.hold_bl(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,5));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
    }
    unittest{
        auto cb = new CellBOX();
        cb.hold_tl(Cell(3,3),5,5);

        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(7,7));
        cb = new CellBOX();
        cb.hold_tl(Cell(3,3),0,0);
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,3));
    }

    // getter:
    final:
    const int numof_vcell()const{
        return numof_row;
    }
    const int numof_hcell()const{
        return numof_col;
    }
    const(Cell[]) get_box()const{
        return box;
    }
    Cell[] get_box_dup()const{
        return box.dup;
    }
    Cell[] get_box_raw(){
        return box;
    }
    Cell get_top_left()const{
        return top_left;
    }
    Cell get_bottom_right()const{
        return bottom_right;
    }
}

abstract class ContentBOX : CellBOX{
private:
    BoxTable table;
public:
    this(BoxTable attach, ContentBOX taken)
        out{
        assert(table !is null);
        }
    body{
        table = attach;
        box = taken.box;
    }
    this(BoxTable attach)
        out{
        assert(table !is null);
        }
    body{
        table = attach;
    }
    invariant(){
        assert(table !is null);
    }
    override void move(const Direct to){
        debug(move) writeln("ContentBOX::move start");
        debug(move) writefln("the cell is %s",this.box);
        debug(move) writefln("the direct is %s",to);
        if(table.require_move(this,to))
        {
            super.expand(to);
            super.remove(to.reverse);
            // CellBOX.move(to);
        }
        debug(move) writefln("the cell is %s",this.box);
        debug(cell) writeln("end");
    }
    unittest{
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
    }
    override void expand(const Direct to){
        if(table.require_expand(this,to))
            super.expand(to);
    }
    abstract bool is_to_spoil();
    int get_id()const{ return box_id; }
    // 削除対象かいなか
}

class Holder : ContentBOX{
    BoxTable inner_table;
    alias inner_table this;
    this(BoxTable table,ContentBOX area){
        super(table,area);
        inner_table = new BoxTable;
    }
    override bool is_to_spoil(){
        return false;
    }
}

class BoxTable : CellBOX{
private:
    ContentBOX[int] content_table;
    string[int] type_table;
    int[Cell] keys;

public:
    this(){
        content_table[0] = null;
        type_table[0] = "none";
    }
    invariant(){
        assert(content_table[0] is null);
        assert(type_table[0] == "none");
    }
    void add_box(T)(T u)
        in{
        assert(u.table == this);
        }
    body{
        debug(move) writeln("add_box start");
        assert(cast(ContentBOX)u !is null); // 静的に書き換えたい
        assert(!u.get_box().empty);

        auto box_id = u.get_id();
        foreach(c; u.get_box())
        {
            keys[c] = box_id;
            add(c);
        }
        type_table[box_id] = u.toString;
        content_table[box_id] = u;
        debug(move){
            writeln("type: ",u.toString);
            writeln("table key(box_id): ",box_id);
            writeln("boxes are: ",u.get_box());
            writeln("end");
        }
    }
    // Tableに登録されたBOXは、自身の変形が可能か
    // Tableに尋ねる。そのためのmethod。prefix: 
    // 可能なときには処理も行なってしまう
    //      分ける必要のある要件があったら統一して分離させる
    bool require_expand(ContentBOX box,const Direct to){
        debug(move) writeln("expand box start");
        auto id = box.get_id();
        auto edge = box.edge_cells;
        Cell[] tobe_expanded;
        foreach(c; edge[to]) // just check
        {
            auto the_cell = c.if_moved(to);
            tobe_expanded ~= the_cell;
            if(the_cell in keys)
            { 
                debug(move) writeln("not expanded");
                return false;
            }
        }
        foreach(c; tobe_expanded)
            keys[c] = id;

        debug(move) writeln("expanded");
        return true;

    }
    // 移動できたらtrue そうでなければfalse
    bool require_move(ContentBOX box,const Direct to){
        if(require_expand(box,to))
        {
            foreach(c; box.edge_cells[reverse(to)])
                keys.remove(c);
            return true;
        }else
            return false;
    }

    void remove(ContentBOX u)
        in{
        assert(u.table == this);
        }
    body{
        auto content_cells = u.get_box();
        auto box_id = u.get_id();
        foreach(c; content_cells)
        {
            keys.remove(c);
        }
        content_table.remove(box_id);
        type_table.remove(box_id);
    }
    unittest{
        auto cb = new CellBOX(Cell(0,0),5,5);
        cb.remove(Direct.up);
        assert(cb.top_left == Cell(1,0));
        assert(cb.numof_col == 5);
        assert(cb.numof_row == 4);
        assert(cb.bottom_right == Cell(4,4));
        cb.remove(Direct.right);
        assert(cb.top_left == Cell(1,0));
        assert(cb.numof_col == 4);
        assert(cb.numof_row == 4);
        assert(cb.bottom_right == Cell(4,3));
        cb.remove(Direct.left);
        assert(cb.top_left == Cell(1,1));
        assert(cb.numof_col == 3);
        assert(cb.numof_row == 4);
        assert(cb.bottom_right == Cell(4,3));
        cb.remove(Direct.down);
        assert(cb.top_left == Cell(1,1));
        assert(cb.numof_col == 3);
        assert(cb.numof_row == 3);
        assert(cb.bottom_right == Cell(3,3));
    }
    Tuple!(string,ContentBOX) get_content(const Cell c){
        debug(move) if(c !in keys) writeln("this cell is empty, no content return");
        if(c !in keys) return tuple("none",content_table[0]);
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

// Viewの移動の際、
// 原点方向にはTableの中身をシフトする形で展開するが
// Cellの増加方向がPageViewの原点位置に来たときにTableを切り出す必要がある
// 他、Tableを切り出すとHolderになるし便利(そう)
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
        debug(cell) writefln("range_r %d range_c %d",range_of_row,range_of_col);
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
        debug(cell) if(!(c in master.keys)) writeln("this cell is empty, no content return");
        auto key = master.keys[c];
        return tuple(master.type_table[key],master.content_table[key]);
    }
    auto get_contents(){
        Tuple!(string,ContentBOX)[ContentBOX] i_have;

        foreach(c; box)
        {
            debug(cell) writeln("get_contents works");
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
        debug(cell) writeln("get_view_position start");
        auto tmp = b.get_top_left();
        debug(cell) writeln("top left : ",tmp);
        debug(cell) writeln("box : ",b.box);
        // pos(0,0)で止まる
        return tmp - offset;
        debug(cell) writeln("end");
    }
    /+ void remove(const ContentBOX) 
       Cell[] get_struct()
       ContentBOX get_content(const Cell)
        +/
    // you can use super class's difinition 
}

import cell.textbox;

class SelectBOX : ContentBOX{
private:
    Cell _focus;
    Cell _pivot;
    /+ inherited
       CellBOX box
       alias box this +/
    void set_pivot(const Cell p)
        in{
        assert(box.empty());
        }
    body{
        debug(cell) writeln("set__pivot start");
        _pivot = p;
        super.create_in(_pivot);
        debug(cell) writeln("end");
    }
    void pivot_bound(Cell cl){
        debug(cell) writeln("privot_bound start");
        if(_pivot == cl)  hold_tl(_pivot,1,1); else
        if(_pivot < cl) // _pivot.rowの方が小さいブロック
        {
            auto d = diff(cl,_pivot);
            auto dr = d.row+1;
            auto dc = d.column+1;

            if(cl.column == _pivot.column) // 縦軸下
                hold_tl(_pivot,dr,1);
            else if(cl.column < _pivot.column) // 第3象限
                hold_tr(_pivot,dr,dc);
            else 
                hold_tl(_pivot,dr,dc); // 第四象限
        }else{ // if(_pivot > cl) _pivot.rowが大きい
            auto d = diff(_pivot,cl);
            auto dr = d.row+1;
            auto dc = d.column+1;
            if(cl.column == _pivot.column) // 縦軸上
                hold_br(_pivot,dr,1);
            else if(cl.column > _pivot.column) // 1
                hold_tr(cl,dr,dc);
            else // 3象限
                hold_br(_pivot,dr,dc);
        }
        debug(cell) writeln("end");
    }
public:
    void expand_to_focus()
        in{
        assert(!box.empty());
        }
        out{
        assert(is_box(box));
        }
    body{
        debug(cell) writeln("expand_to__focus start");
        pivot_bound(_focus);
        debug(cell) writeln("end");
    }
    this(BoxTable attach,Cell cursor=Cell(3,3))
    body{
        super(attach);
        _focus = cursor;
    }
    override void move(const Direct dir){
        _focus.move(dir);
    }
    void create_in(){
        super.create_in(_focus);
        debug(cell)writefln("create in %s",_focus);
    }
    bool is_on_edge()const{
        return super.is_on_edge(_focus);
    }
    bool is_on_edge(Direct dir)const{
        return super.is_on_edge(_focus,dir);
    }
    TextBOX create_TextBOX(){
        debug(cell) writeln("create_TextBOX start");
        create_in();
        auto tb = new TextBOX(table);
        tb.take_over(this);
        box.clear();
        debug(cell) writeln("end");
        return tb;
    }
    void set_pivot(){
        set_pivot(_focus);
    }

    override bool is_to_spoil(){
        return false;
    }
    @property Cell focus()const{
        return _focus;
    }
    @property Cell pivot()const{
        return _pivot;
    }
}
