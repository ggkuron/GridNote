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
debug(table) import std.stdio;

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
int count_lined(const(Cell)[] box,const Cell from,const Direct to){
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
        c.move(to);
    }
        // debug(cell) writeln("end");
    return result-1; // if(box is null) return -1;
}

// test 用
// CellBOX になれる構造かどうかチェック
// 四角い要素を持っているかどうか
// 
bool is_box(const Cell[] box){
    if(box.length == 1) return true;
    //  auto check_box = new CellBOX(); // この判定方法だとpureになれない
    // check_box.box_change(box,false); // check is false
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
    foreach(r; width){
        // width == 0 はありえない
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

// 四角い領域を持つこと
// 領域の管理方法
class CellBOX{
private:
    Cell[LeftRight][UpDown] edge;

    int numof_row = 1;  // 
    int numof_col = 1;
    alias int ROW;
    alias int COL;

    Cell[] box;
    bool[COL][ROW] row_table; // rowでtableを得られるテーブル。ややこしい。名前
    bool[ROW][COL] col_table;

    int min_row = int.max;
    int min_col = int.max;
    int max_row = int.min;
    int max_col = int.min;

    bool box_fixed;

    unittest{
        debug(cell) writeln("1"); auto cb = new CellBOX();
        debug(cell) writeln("2"); cb.create_in(Cell(3,3));
        debug(cell) writeln("3"); assert(cb.is_in(Cell(3,3)));
        debug(cell) writeln("4"); assert(!cb.is_in(Cell(3,4)));
        debug(cell) writeln("5"); cb.expand(Direct.right);
        debug(cell) writeln("6"); assert(cb.is_in(Cell(3,4)));
        debug(cell) writeln("7"); cb = new CellBOX();
        debug(cell) writeln("8"); cb.create_in(Cell(5,5));
        debug(cell) writeln("9"); cb.expand(Direct.right);
        debug(cell) writeln("10"); cb.expand(Direct.down);
        debug(cell) writeln("11"); assert(cb.box.count_lined(Cell(5,5),Direct.right) == 1);
        debug(cell) writeln("12"); assert(cb.box.count_lined(Cell(5,5),Direct.down) == 1);
        debug(cell) writeln("13"); debug(cell) writeln("@@@@ update_info unittest start @@@@@");
        debug(cell) writeln("14"); cb = new CellBOX();
        debug(cell) writeln("15"); cb.create_in(Cell(5,5));
        debug(cell) writeln("16"); assert(cb.edge[up][left] == Cell(5,5));
        debug(cell) writeln("17"); assert(cb.numof_row == 1);
        debug(cell) writeln("18"); assert(cb.numof_col == 1);

        debug(cell) writeln("19"); cb.hold_tl(Cell(0,0),5,5);

        debug(cell) writeln("20"); debug(cell) writefln("!!!! top_left %s",cb.edge[up][left]);
        debug(cell) writeln("20"); debug(cell) writefln("!!!! box %s",cb.box);
        debug(cell) writeln("21"); assert(cb.edge[up][left] == Cell(0,0));
        debug(cell) writeln("26"); assert(cb.bottom_right == Cell(4,4));
        debug(cell) writeln("22"); debug(cell) writeln("numof_row:",cb.numof_row);
        debug(cell) writeln("23"); debug(cell) writeln("numof_col:",cb.numof_col);
        debug(cell) writeln("24"); assert(cb.numof_row == 5);
        debug(cell) writeln("25"); assert(cb.numof_col == 5);
        debug(cell) writeln("27"); debug(cell) writeln("#### update_info unittest end ####");
    }
    const(Cell)[] in_column(const int column)const{
        Cell[] result;
        if(column in col_table)
        foreach(r,b; col_table[column])
        {   // このifは確認を怠らなければ取り除ける
            if(b)
            result ~= Cell(r,column);
        }
        return result;
    }
    const(Cell)[] in_row(const int row)const{
        Cell[] result;
        if(row in row_table)
        foreach(c,b; row_table[row])
        {   // このifは確認を怠らなければ取り除ける
            if(b)
            result ~= Cell(row,c);
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
//    void take_over(CellBOX oldone)
//        in{
//        assert(!oldone.get_box_raw().empty);
//        }
//        out{
//        assert(!box.empty);
//        }
//    body{
//        debug(cell) writeln("take after start");
//        box = oldone.get_box_dup();
//        edge = oldone.edge.dup();
//        min_col = oldone.min_col;
//        max_col = oldone.max_col;
//        min_row = oldone.min_row;
//        max_row = oldone.max_row;
//        row_table = oldone.row_table.dup();
//        col_table = oldone.col_table.dup();
//
//        oldone.clear();
//        debug(cell) writeln("end");
//    }
    void create_in(const Cell c)
        in{
        assert(box.empty);
        }
        out{
        assert(is_box(box));
        }
    body{ // create initial box
        bool min_row_f,min_col_f,max_row_f,max_col_f;
        clear();
        box ~= c;

        row_table[c.row][c.column] = true;
        col_table[c.column][c.row] = true;

        if(c.row < min_row)
        {
            min_row = c.row;
            min_row_f = true;
        }
        if(c.column < min_col)
        {
            min_col = c.column;
            min_col_f = true;
        }
        if(c.row > max_row)
        {
            max_row = c.row;
            max_row_f = true;
        }
        if(c.column > max_col)
        {
            max_col = c.column;
            max_col_f = true;
        }

        if(max_col_f && max_row_f)
            edge[down][right] = c;
        if(max_col_f && min_row_f)
            edge[up][right] = c;
        if(min_col_f && max_row_f)
            edge[down][left] = c;
        if(min_col_f && min_row_f)
            edge[up][left] = c;

    }

    void expand(const Direct dir)
        in{
        assert(is_box(box));
        }
        out{
        assert(is_box(box));
        }
    body{
        debug(cell) writeln("@@@@ expand start @@@@");
        debug(cell) writeln("direct is ",dir);

        if((dir == Direct.left && !min_col) 
                || (dir == Direct.up && !min_row))
            return;

        const(Cell[]) one_edges = edge_line[dir];
        foreach(c; one_edges) //one_edgesが配列でないとexpanded_edgeがsortされない
        {
            auto moved = c.if_moved(dir);
            box ~= moved;
            row_table[moved.row][moved.column] = true;
            col_table[moved.column][moved.row] = true;
        }

        final switch(dir){ // 
            case Direct.left:
                ++numof_col;
                --min_col;
                edge[up][left].move(Direct.left);
                edge[down][left].move(Direct.left);
                break;
            case Direct.right:
                ++numof_col;
                ++max_col;
                edge[up][right].move(Direct.right);
                edge[down][right].move(Direct.right);
                break;
            case Direct.up:
                ++numof_row;
                --min_row;
                edge[up][left].move(Direct.up);
                edge[up][right].move(Direct.up);
                break;
            case Direct.down:
                ++numof_row;
                ++max_row;
                edge[down][left].move(Direct.down);
                edge[down][right].move(Direct.down);
                break;
        }
        debug(cell) writeln("#### expand end ####");
        debug(cell) writeln("boxes are ",box);
        debug(move) writeln("min col ",min_col);
        debug(move) writeln("max col ",max_col);
        debug(move) writeln("col_table are ",col_table);
        debug(move) writeln("row_table are ",row_table);
        return true;
    }
    void remove(const Direct dir){
        debug(cell) writeln("@@@@ CellBOX.remove start @@@@");

        if(dir.is_horizontal && numof_col <= 1
        || dir.is_vertical && numof_row <= 1 )
            return;
        auto delete_line = edge_line[dir];
        foreach(c; delete_line)
        {
           misc.array.remove!(Cell)(box,c);
           row_table[c.row].remove(c.column);
           col_table[c.column].remove(c.row);
           debug(cell) writefln("deleted %s",c);
        }
        final switch(dir){ // 
            case Direct.left:
                edge[up][left].move(Direct.right);
                edge[down][left].move(Direct.right);
                --numof_col;
                ++min_col;
                break;
            case Direct.right:
                edge[up][right].move(Direct.left);
                edge[down][right].move(Direct.left);
                --numof_col;
                --max_col; // 負数になるようなとき (numof_col or numof_row <= 1)
                break;
            case Direct.up:
                edge[up][left].move(Direct.down);
                edge[up][right].move(Direct.down);
                --numof_row;
                ++min_row;
                break;
            case Direct.down:
                edge[down][left].move(Direct.up);
                edge[down][right].move(Direct.up);
                --numof_row;
                --max_row;
                break;
        }
        debug(cell) writeln("#### CellBOX.remove end ####");
        debug(move) writeln("col_table are ",col_table);
        debug(move) writeln("row_table are ",row_table);

    }

public:
    void clear(){
        box.clear();
        numof_row =1;
        numof_col =1;
        max_row = int.min;
        max_col = int.min;
        min_row = int.max;
        min_col = int.max;
        row_table.clear();
        col_table.clear();
        edge.clear();
    }
    // 名前の短さに反して遅い
    bool is_in(const Cell c)const{
        return .is_in(box,c);
    }
    this(){
        set_id();
//         edge = [up:[left:Cell(0,0),right:Cell(0,0)],
//            down:[left:Cell(0,0),right:Cell(0,0)]];
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
        // この順番でないと1Cellだけのときに失敗する
        expand(dir);
        remove(dir.reverse);
    }
    unittest{
        debug(cell) writeln("@@@@ CellBOX move unittest start @@@@");
        auto cb = new CellBOX(Cell(5,5),5,5);
        assert(cb.top_left == Cell(5,5));
        assert(cb.bottom_right == Cell(9,9));
        assert(cb.top_right == Cell(5,9));
        assert(cb.bottom_left == Cell(9,5));
        assert(cb.min_row == 5);
        assert(cb.min_col == 5);
        assert(cb.max_row == 9);
        assert(cb.max_col == 9);
        cb.move(Direct.up);
        assert(cb.edge[up][left] == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));
        assert(cb.top_right == Cell(4,9));
        assert(cb.bottom_left == Cell(8,5));
        assert(cb.min_row == 4);
        assert(cb.min_col == 5);
        assert(cb.max_row == 8);
        assert(cb.max_col == 9);
        cb.move(Direct.left);
        assert(cb.edge[up][left] == Cell(4,4));
        assert(cb.bottom_right == Cell(8,8));
        assert(cb.top_right == Cell(4,8));
        assert(cb.bottom_left == Cell(8,4));
        assert(cb.min_row == 4);
        assert(cb.min_col == 4);
        assert(cb.max_row == 8);
        assert(cb.max_col == 8);
        cb.move(Direct.right);
        assert(cb.edge[up][left] == Cell(4,5));
        assert(cb.bottom_right == Cell(8,9));
        assert(cb.top_right == Cell(4,9));
        assert(cb.bottom_left == Cell(8,5));
        assert(cb.min_row == 4);
        assert(cb.min_col == 5);
        assert(cb.max_row == 8);
        assert(cb.max_col == 9);

        debug(cell) writeln("#### CellBOX move unittest end ####");
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
    @property const (Cell[][Direct]) edge_line()const{
        debug(cell) writefln("min_row %d max_row %d\n min_col %d max_col %d",min_row,max_row,min_col,max_col);
        return  [Direct.right:in_column(max_col),
                 Direct.left:in_column(min_col).dup,
                 Direct.up:in_row(min_row),
                 Direct.down:in_row(max_row)];
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
        while(w || h)
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
    alias CellBOX.create_in create_in;
    alias CellBOX.expand expand;
    alias CellBOX.move move;
protected:
    // alias CellBOX.take_over take_over;
    // void take_over(ContentBOX cb){
    //     super.take_over(cb);

    //     table.add_box(this);
    //     cb.remove_from_table();
    // }
    invariant(){
        assert(table !is null);
    }
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
    bool require_create_in(const Cell c){
        if(table.is_vacant(c))
        {
            super.create_in(c);
            table.add_box(this);
            return true;
        }
        return false;
    }
    bool require_move(const Direct to){
        debug(move){
            writeln("ContentBOX::move start");
            // writefln("the cell is %s",this.box);
            // writefln("the direct is %s",to);
        }
        if(table.tryto_move(this,to))
        {
            // CellBOX.expand(to);
            // CellBOX.remove(to.reverse);
            CellBOX.move(to);
            debug(move) writeln("moved");
            return true;
            // super.move(to); 何がこれと違うのかわからない今
        }
        // debug(move) writefln("the cell is %s",this.box);
        debug(move) writeln("not moved");
        return false;
    }
    void remove_from_table(){
        spoiled = true;
        table.tryto_remove(this);
        clear();
    }
    unittest{
        debug(cell) writeln("@@@@ TableBOX unittest start @@@@");
        import cell.textbox;
        BoxTable table = new BoxTable;
        auto cb = new TextBOX(table);
        cb.create_in(Cell(3,3));
        cb.expand(Direct.right);
        assert(cb.edge[up][left] == Cell(3,3));
        assert(cb.bottom_right == Cell(3,4));
        cb.move(Direct.right);
        assert(cb.edge[up][left] == Cell(3,4));
        assert(cb.bottom_right == Cell(3,5));
        cb.move(Direct.up);
        assert(cb.top_left == Cell(2,4));
        assert(cb.bottom_right == Cell(2,5));
        debug(cell) writeln("#### TableBOX unittest end ####");
    }
    // 実行できたかどうかは知りたい
    bool require_expand(const Direct to){
        if(table.tryto_expand(this,to))
        {
            super.expand(to);
            return true;
        }else return false;
    }
    void require_remove(const Direct dir){
        table.remove_content_edge(this,dir);
        super.remove(dir);
    }


    // 削除対象かいなか
    private bool spoiled;
    bool is_to_spoil(){
        return spoiled || empty();
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
class BoxTable{
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
    auto refer_keys()const{
        return keys;
    }
    auto get_content(int key){
        // 継承先はこのTableのkeyを知れるのでcheckはあまく
        // 特定のContent idを指定しては呼び出さないだろうと仮定しているということ
        assert(keys.values.is_in(key));
        return tuple(type_table[key],content_table[key]);
    }
public:
    this(){
        content_table[0] = null;
        type_table[0] = "none";
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
    void add_box(T)(T u)
        in{
        assert(u.table == this);
        assert(cast(ContentBOX)u !is null); // 静的に書き換えたい
        assert(!u.get_box().empty);
        }
    body{
        debug(move) writeln("add_box start");

        auto box_id = u.get_id();
        foreach(c; u.get_box())
        {
            keys[c] = box_id;
        }
        type_table[box_id] = u.toString;
        content_table[box_id] = u;

        assert(box_id in content_table);
        assert(box_id in type_table);
        debug(table){
            writeln("type: ",u.toString);
            writeln("table key(box_id): ",box_id);
            writeln("boxes are: ",u.get_box());
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
    void remove_content_edge(ContentBOX box,const Direct dir){
        auto edge = box.edge_line[dir];
        foreach(c; edge)
        {
            assert(c in keys); // 入ってないのは想定外
            keys.remove(c);
        }
    }

    // Tableに登録されたBOXは、自身の変形が可能か
    // Tableに尋ねる。そのためのmethod。prefix: 
    // 可能なときには処理も行なってしまう
    //      分ける必要のある要件があったら統一して分離させる
    bool tryto_expand(ContentBOX box,const Direct to){
        debug(move) writeln("expand box start");
        //debug(table) writefln("min_r %d \n min_c %d\n max_r %d\n max_c %d\n edge is ",box.min_row,box.min_col,box.max_row,box.max_col,box.edge_line);
        auto id = box.get_id();
        auto edge = box.edge_line[to];
        debug(move) writeln("edge ",edge);
        Cell[] tobe_expanded;
        if(box.empty()) return false;
        foreach(c; edge) // just check
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

        if(id !in content_table)
            content_table[id] = box;

        debug(table) writeln("expanded");
        return true;

    }
    // 移動できたらtrue そうでなければfalse
    // boxの整形は呼び出し側の責任
    bool tryto_move(ContentBOX box,const Direct to){
        if(tryto_expand(box,to))
        {
            foreach(c; box.edge_line[reverse(to)])
                keys.remove(c);
            return true;
        }else
            return false;
    }
    bool tryto_remove(ContentBOX u)
        in{
        assert(u.table == this);
        }
    body{
        if(!u.is_to_spoil()) return false;

        auto content_cells = u.get_box();
        auto box_id = u.get_id();
        foreach(c; content_cells)
        {
            keys.remove(c);
        }
        content_table.remove(box_id);
        type_table.remove(box_id);

        assert(keys.values.empty || !keys.values.is_in(u.get_id()));
        return true;
    }
    unittest{
        auto cb = new CellBOX(Cell(0,0),5,5);
        cb.move(Direct.up);
        assert(cb.top_left == Cell(0,0));
        assert(cb.numof_col == 5);
        assert(cb.numof_row == 4);
        assert(cb.bottom_right == Cell(3,4));
        assert(cb.min_row == 0);
        assert(cb.min_col == 0);
        assert(cb.max_row == 3);
        assert(cb.max_col == 4);

        cb = new CellBOX(Cell(0,0),5,5);
        cb.remove(Direct.up);
        assert(cb.top_left == Cell(1,0));
        assert(cb.numof_col == 5);
        assert(cb.numof_row == 4);
        assert(cb.bottom_right == Cell(4,4));
        assert(cb.min_row == 1);
        assert(cb.min_col == 0);
        assert(cb.max_row == 4);
        assert(cb.max_col == 4);

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
        type_table.clear();
        content_table.clear();
    }
    bool is_vacant(Cell c)const{
        return cast(bool)(c !in keys);
    }
    bool has(Cell c)const{
        return cast(bool)(c in keys);
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
    Cell _max_range; // table(master)の座標での最大値

    bool check_range(const Cell c)const{
        return  (c <=  _max_range);
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
        assert(rtable._max_range == Cell(10,10));
        auto tb = new TextBOX(table);
        tb.require_create_in(Cell(4,4));
        auto items = rtable.get_content(Cell(1,1));
        assert(items[1] !is null);
        assert(tb.get_id == items[1].get_id);
        tb.require_expand(Direct.right);
        items = rtable.get_content(Cell(1,2));
        assert(items[1] !is null);
        auto all_items = rtable.get_contents();
        assert(all_items[0] == items);
        assert(tb.get_id == items[1].get_id);
        auto tb2 = new TextBOX(table);
        tb2.require_create_in(Cell(6,6));
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
        _max_range = Cell(row,col);
    }
    override Tuple!(string,ContentBOX) get_content(const Cell c){
        return master.get_content(c+_offset);
    }
    // master のtableのなかでview に含まれるものすべて
    auto get_contents(){
        Tuple!(string,ContentBOX)[] result;
        int[int] ranged_keys;
        auto master_keys = master.refer_keys();

        auto itr = offset;
        while(1)
        {
            if(itr in master_keys)
            {
                auto cells_key = master_keys[itr];
                ranged_keys[cells_key] = cells_key; // 重複を避けるため
            }
            if(itr.column < _max_range.column)
                ++itr.column;
            else
            {
                ++itr.row;
                itr.column = offset.column;
            }

            if(itr == _max_range)
                break;
        }
        foreach(k; ranged_keys.values)
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
        master.add_box(u+_offset);
    }
    void move(const Direct to){
        _offset.move(to);
        _max_range.move(to);
    }
    @property Cell offset()const{
        return _offset;
    }
    Cell get_position(CellBOX b){
        assert(!b.empty());
        return b.top_left + _offset;
    }
    bool empty(){
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
    void expand(const Direct dir){
        super.expand(dir);
    }
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
        auto tb = new TextBOX(table);
        if(!tb.require_create_in(_focus)) return null;
        // tb.take_over(this);
        clear();
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
