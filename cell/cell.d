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
    // assert(0); // box is empty or null
    return false;
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
    Cell[LeftRight][UpDown] edge;

    int numof_row,
        numof_col;
    alias int ROW;
    alias int COL;

    Cell[] box;
    Cell[][ROW] row_table;
    Cell[][COL] col_table;

    int min_row = int.max;
    int min_col = int.max;
    int max_row , max_col;

    bool box_fixed;

    unittest{
        auto cb = new CellBOX();
        cb.create_in(Cell(3,3));
        assert(cb.is_in(Cell(3,3)));
        assert(!cb.is_in(Cell(3,4)));
        cb.expand(Direct.right);
        assert(cb.is_in(Cell(3,4)));
    }
    int count_lined(const Cell from,const Direct to)const{
        // debug(cell) writeln("count_lined start");
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
            // debug(cell) writeln("end");
        return result-1; // if(box is null) return -1;
    }
    final void add(const Cell c){
        box ~= c;
        row_table[c.row] ~= c;
        col_table[c.column] ~= c;
        if(c.row < min_row) min_row = c.row;
        if(c.column < min_column) min_col = c.column;
        if(c.row > max_row) max_row = c.row;
        if(c.column > max_col) max_col = c.column;
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
        void update_edge_info(){

            _edge_line[Direct.left] = in_column(min_column);
            _edge_line[Direct.right] = in_column(max_column);
            _edge_line[Direct.up] = in_row(min_row);
            _edge_line[Direct.down] = in_row(max_row);
        }

        if(!box.empty())
        {
            auto sortedbox = box.dup.sort();
            edge[up][left] = sortedbox[0];
            edge[down][right]  = sortedbox[$-1];
            edge[up][right] = Cell(top_left.row,bottom_right.column);
            edge[down][left] = Cell(bottom_right.row,top_left.column);
            numof_row = bottom_left.row - top_left.row + 1;
            numof_col = top_right.column - top_left.column + 1;

            update_edge_info();
        }else{
            edge[up][left] = Cell(0,0);
            edge[down][right] = Cell(0,0);
            edge[up][right] = Cell(0,0);
            edge[down][left] = Cell(0,0);
            numof_row = 1;
            numof_col =1;

            update_edge_info();
        }


        debug(cell) writeln("end");
    }
    unittest{
        debug(cell) writeln("update_info unittest start");
        auto cb = new CellBOX();
        cb.create_in(Cell(5,5));
        assert(cb.edge[up][left] == Cell(5,5));
        assert(cb.numof_row == 1);
        assert(cb.numof_col == 1);

        // ctor call hold call update_info
        // and try calling again
        cb.hold_tl(Cell(0,0),5,5);
        cb.update_info();
        // ... may cause nothing
        assert(cb.edge[up][left] == Cell(0,0));
        debug(cell) writeln("numof_row:",cb.numof_row);
        debug(cell) writeln("numof_col:",cb.numof_col);
        assert(cb.numof_row == 5);
        assert(cb.numof_col == 5);
        assert(cb.bottom_right == Cell(4,4));
        debug(cell) writeln("end");
    }
    Cell[] in_column(const int column)const{
        return col_table[column];
    }
    Cell[] in_row(const int row)const{
        return row_table[row];
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
    void remove(const Direct dir,bool check=true){
        debug(cell) writeln("@@@@ CellBOX.remove start @@@@");

        if(dir.is_horizontal && numof_col <= 1
        || dir.is_vertical && numof_row <= 1 )
            return;
        auto delete_line = edge_line[dir];
        foreach(c; delete_line)
        {
           misc.array.remove!(Cell)(box,c);
           debug(cell) writefln("deleted %s",c);
        }
        if(check) update_info();
        debug(cell) writeln("#### CellBOX.remove end ####");
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
        edge = [up:[left:Cell(0,0),right:Cell(0,0)],
           down:[left:Cell(0,0),right:Cell(0,0)]];
        update_info();
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
    void move(const Direct dir){
        expand(dir,false);
        remove(dir.reverse);
    }
    unittest{
        debug(cell) writeln("CellBOX move test start");
        auto cb = new CellBOX(Cell(5,5),5,5);
        cb.move(Direct.up);
        assert(cb.edge[up][left] == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));
        cb.move(Direct.left);
        assert(cb.edge[up][left] == Cell(4,4));
        assert(cb.bottom_right == Cell(8,8));
        cb.move(Direct.right);
        assert(cb.edge[up][left] == Cell(4,5));
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

        // update_info でもいい
        edge[up][left] = c;
        edge[down][right] = c;
        edge[up][right] = c;
        edge[down][left] = c;
        numof_row = 1;
        numof_col =1;
        _edge_line.clear();
        foreach(i; Direct.min .. Direct.max+1)
            _edge_line[cast(Direct)i] ~=c;

    }
    // aliways return true,
    // オーバーライドさせるのに都合がいいからというだけ
    bool expand(const Direct dir,bool check=true)
        in{
        assert(is_box(box));
        }
        out{
        assert(is_box(box));
        }
    body{
        debug(cell) writeln("@@@@ expand start @@@@");
        auto one_edges = edge_line[dir];
        foreach(c; one_edges)
        {
            add(c.if_moved(dir));
        }
        if(check) update_info();
        debug(cell) writeln("#### expand end ####");
        return true;
    }
    bool is_on_edge(Cell c)const{
        foreach(each_edged; edge_line())
        {
            if(each_edged.is_in(c)) return true;
            else continue;
        }
        return false;
    }
    unittest{
        debug(cell) writeln("@@@@is_on_edge unittest start@@@@");
        auto cb = new CellBOX();
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
        return edge_line[on].is_in(c);
    }
    private Cell[][Direct] _edge_line;
    @property const (Cell[][Direct]) edge_line()const{
        writeln("edge_line is ",_edge_line);
        return _edge_line;
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
        debug(cell) writeln("@@@@hold_br unittest start@@@@");
        auto cb = new CellBOX();
        cb.hold_br(Cell(5,5),3,3);

        assert(cb.edge[up][left] == Cell(3,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("####hold_br unittest end####");
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
        debug(cell) writeln("@@@@ hold_tr unittest start @@@@");
        auto cb = new CellBOX();
        cb.hold_tr(Cell(5,5),3,3);

        assert(cb.edge[up][left] == Cell(5,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("#### hold_tr unittest start ####");
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
        debug(cell) writeln("@@@@ hold_bl unittest start @@@@");
        auto cb = new CellBOX();
        cb.hold_bl(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,5));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("#### hold_bl unittest end ####");
    }
    unittest{
        debug(cell) writeln("@@@@ hold_tl unittest start @@@@");
        auto cb = new CellBOX();
        cb.hold_tl(Cell(3,3),5,5);

        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(7,7));
        cb = new CellBOX();
        cb.hold_tl(Cell(3,3),0,0);
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,3));
        debug(cell) writeln("#### hold_tl unittest end ####");
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
    @property Cell top_left()const{
        return edge[up][left];
    }
    @property Cell bottom_right()const{
        return edge[down][right];
    }
    @property Cell top_right()const{
        return edge[up][right];
    }
    @property Cell bottom_left()const{
        return edge[down][left];
    }
}

abstract class ContentBOX : CellBOX{
private:
    BoxTable table;
protected:
    alias CellBOX.take_over take_over;
    void take_over(ContentBOX cb){
        super.take_over(cb);

        table.add_box(this);
        cb.remove_from_table();
    }
    // invariant(){
    //     assert(table !is null);
    // }
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
    override void create_in(const Cell c){
        if(table.is_vacant(c))
        {
            super.create_in(c);
            table.add_box(this);
        }
    }
    override void move(const Direct to){
        debug(move){
            writeln("ContentBOX::move start");
            writefln("the cell is %s",this.box);
            writefln("the direct is %s",to);
        }
        if(table.require_move(this,to))
        {
            super.expand(to);
            super.remove(to.reverse);
            // super.move(to); 何がこれと違うのかわからない今
        }
        debug(move) writefln("the cell is %s",this.box);
        debug(cell) writeln("end");
    }
    void remove_from_table(){
        table.tryto_remove(this);
        clear();
    }
    unittest{
        debug(cell) writeln("@@@@ TableBOX unittest start @@@@");
        import cell.textbox;
        debug(cell) writeln("1"); BoxTable table = new BoxTable;
        debug(cell) writeln("2"); auto cb = new TextBOX(table);
        debug(cell) writeln("3"); cb.create_in(Cell(3,3));
        debug(cell) writeln("4"); cb.expand(Direct.right);
        debug(cell) writeln("5"); assert(cb.edge[up][left] == Cell(3,3));
        debug(cell) writeln("6"); assert(cb.bottom_right == Cell(3,4));
        debug(cell) writeln("7"); cb.move(Direct.right);
        debug(cell) writeln("8"); assert(cb.edge[up][left] == Cell(3,4));
        debug(cell) writeln("9"); assert(cb.bottom_right == Cell(3,5));
        debug(cell) writeln("#### TableBOX unittest end ####");
    }
    // 実行できたかどうかは知りたい
    override bool expand(const Direct to,bool check=true){
        if(table.require_expand(this,to))
        {
            super.expand(to,check);
            return true;
        }else return false;
    }
    // 削除対象かいなか
    bool is_to_spoil(){
        return empty();
    };
    int get_id()const{ return box_id; }
}

// class Holder : ContentBOX{
//     BoxTable inner_table;
//     alias inner_table this;
//     this(BoxTable table,ContentBOX area){
//         super(table,area);
//         inner_table = new BoxTable;
//     }
//     override bool is_to_spoil(){
//         return false;
//     }
// }

class BoxTable : CellBOX{
private:
    ContentBOX[int] content_table;
    string[int] type_table;
    int[Cell] keys;

protected:
    auto refer_content_table(){
        return content_table;
    }
    auto refer_type_table(){
        return type_table;
    }
    auto refer_keys(){
        return keys;
    }
    bool has_key(Cell c)const{
        return cast(bool)(c in keys);
    }
    auto get_content(int key){
        assert(keys.values.is_in(key));
        return tuple(type_table[key],content_table[key]);
    }
public:
    this(){
        content_table[0] = null;
        type_table[0] = "none";
        super();
    }
    this(BoxTable r){
        content_table = r.content_table;
        type_table = r.type_table;
        keys = r.keys;
        this();
    }
    invariant(){
        assert(content_table[0] is null);
        assert(type_table[0] == "none");
    }
    // offsetはReferTable のために開けた穴なので適正塞いで
    void add_box(T)(T u,Cell offset=Cell(0,0))
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
            keys[c+offset] = box_id;
            // add(c);
        }
        type_table[box_id] = u.toString;
        content_table[box_id] = u;

        assert(box_id in content_table);
        assert(box_id in type_table);
        debug(move){
            writeln("type: ",u.toString);
            writeln("table key(box_id): ",box_id);
            writeln("boxes are: ",u.get_box());
            writeln("end");
        }
    }
    Tuple!(string,ContentBOX) get_content(const Cell c){
        int key;
        debug(move) if(c !in keys) writeln("this cell is empty, no content return");
        if(c !in keys)
            return tuple("none",content_table[0]);
        else
        {   // 現在は必要ないけど念の為
            key = keys[c];
            if(key == 0)
                return tuple("none",content_table[0]);
        }
        return tuple(type_table[key],content_table[key]);
    }

    // Tableに登録されたBOXは、自身の変形が可能か
    // Tableに尋ねる。そのためのmethod。prefix: 
    // 可能なときには処理も行なってしまう
    //      分ける必要のある要件があったら統一して分離させる
    bool require_expand(ContentBOX box,const Direct to){
        debug(move) writeln("expand box start");
        auto id = box.get_id();
        auto edge = box.edge_line;
        Cell[] tobe_expanded;
        if(box.empty()) return false;
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
        {
            keys[c] = id;
        }

        // if(!box.empty())
        // {
        //     assert(id in content_table);
        //     assert(id in type_table);
        // }
        if(id !in content_table)
            content_table[id] = box;


        debug(move) writeln("expanded");
        return true;

    }
    // 移動できたらtrue そうでなければfalse
    bool require_move(ContentBOX box,const Direct to){
        if(require_expand(box,to))
        {
            foreach(c; box.edge_line[reverse(to)])
                keys.remove(c);
            return true;
        }else
            return false;
    }
    void tryto_remove(ContentBOX u)
        in{
        assert(u.table == this);
        }
    body{
        if(!u.is_to_spoil()) return;

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
    final void clear(){
        keys.clear();
        edge[up][left] = Cell(0,0);
        edge[down][right] = Cell(0,0);
        edge[up][right] = Cell(0,0);
        edge[down][left] = Cell(0,0);
        numof_row = 1;
        numof_col =1;
    }
    bool is_vacant(Cell c){
        return cast(bool)(c !in keys);
    }
}

// Viewの移動の際、
// 原点方向にはTableの中身をシフトする形で展開するが
// Cellの増加方向がPageViewの原点位置に来たときにTableを切り出す必要がある
// 他、Tableを切り出すとHolderになるし便利(そう)
class ReferTable : BoxTable{
private:
    BoxTable master; // almost all manipulation acts on this table
    Cell _offset;
    Cell max_range; // table(master)の座標での最大値

    bool check_range(const Cell c)const{
        return  (c <=  max_range);
    }
    invariant(){
        assert(top_left == Cell(0,0));
        assert(check_range(top_left));
        assert(check_range(bottom_right));
        // assert(bottom_right == max_range - _offset );
    }
public:
    this(BoxTable attach, Cell ul,int w=0,int h=0)
        in{
        assert(attach !is null);
        }
    body{
        super();
        master = attach; // manipulating ReferBOX acts on attached Table
        set_range(ul,h,w);
    }
    unittest{
        auto table = new BoxTable();
        auto rtable = new ReferTable(table,Cell(3,3),8,8);
        assert(rtable.edge[up][left] == Cell(0,0)); // rtable のtop_left は(0,0)固定
        assert(rtable.bottom_right == Cell(7,7));
        assert(rtable.max_range == Cell(10,10));
        auto tb = new TextBOX(table);
        tb.create_in(Cell(4,4));
        auto items = rtable.get_content(Cell(1,1));
        assert(items[1] !is null);
        assert(tb.get_id == items[1].get_id);
        tb.expand(Direct.right);
        items = rtable.get_content(Cell(1,2));
        assert(items[1] !is null);
        auto all_items = rtable.get_contents();
        assert(all_items[0] == items);
        assert(tb.get_id == items[1].get_id);
        auto tb2 = new TextBOX(table);
        tb2.create_in(Cell(6,6));

    }
    void set_range(Cell ul,int h,int w)
        in{
        assert(h>0);
        assert(w>0);
        }
    body{
        _offset = ul;
        auto row = _offset.row + h-1;
        auto col = _offset.column + w-1;
        max_range = Cell(row,col);
        hold_tl(Cell(0,0),h,w);
    }
    override Tuple!(string,ContentBOX) get_content(const Cell c){
        return master.get_content(c+_offset);
    }
    // master のtableのなかでview に含まれるものすべて
    auto get_contents(){
        Tuple!(string,ContentBOX)[] result;
        int[int] ranged_keys;
        auto master_keys = master.refer_keys();

        foreach(c; box)
        {
            if(c in master_keys)
            {
                auto cells_key = master_keys[c];
                ranged_keys[cells_key] = cells_key;
            }
        }
        foreach(k; ranged_keys.keys)
            result ~= master.get_content(k);
        return result;
    }
    // add_box は直接table番地に反映させる
    // 
    override void add_box(T)(T u)
        in{
        assert(u.table == master);
        }
    body{
        if(!check_range) assert(0);
        master.add_box(u,_offset);
    }
    override void move(const Direct to){
        _offset.move(to);
        max_range.move(to);
        super.move(to); // <- update_info()
    }
    @property Cell offset()const{
        return _offset;
    }
    // 位置はCellBOX(ContentBOX::box)で決まるという事にした
    Cell get_position(CellBOX b){
        assert(!b.empty());
        return b.top_left + _offset;
    }
    override bool empty(){
        return master.keys.keys.empty();
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
