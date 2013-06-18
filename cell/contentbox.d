module cell.contentbox;

import cell.cell;
import cell.table;
import cell.rangecell;
import std.traits;
import util.array;
import util.direct;
import util.color;
import data.content;
debug(cb) import std.stdio;
debug(cell) import std.stdio;

// ContentBOX
abstract class ContentBOX : CellContent{
private:
    int _box_id;
package:
protected:
    BoxTable _table;
public:
    RangeCell _inner_range_cell;
    alias _inner_range_cell this;
    this(BoxTable attach)
        out{
        assert(_table !is null);
        }
    body{
        _table = attach;
    }
    final void set_id(int id){
        _box_id = id;
    }
    void create_in(in Cell c)
        in{
        assert(range.empty);
        }
    body{ // create initial box
        clear(); // <- range.clear()
        add(c);
    }
    this(BoxTable t,in Cell ul,in int cw,in int rw){
        debug(cell){ 
            writeln("ctor start");
            writefln("rw %d cw %d",cw,rw);
        }
        this(t);
        require_hold(ul,rw,cw);
        debug(cell)writeln("ctor end");
    }
    this(BoxTable t,BoxShape bs){
        this(t,bs.pivot,bs.w,bs.h);
    }

    this(BoxTable t,ContentBOX oldone){
        debug(cell) writeln("take after start");

        clear();
        _table = t;
        _inner_range_cell = RangeCell(oldone);
        debug(cell) writeln("end");
    }
    // 構造の実装なので持ちたくはないけど
    // 描かれるための構造でもあるので
    // 抽象クラスとしては、描かれるためにフックする部分も必要なわけでもにょる
    // 実装は具現クラスで委譲させる
    void move(in Cell c){
        _inner_range_cell.move(c);
    }
    void move(in Direct dir,in int pop_cnt=1){
        _inner_range_cell.move(dir,pop_cnt);
    }
    void expand(in Direct dir,in int width=1){
        _inner_range_cell.expand(dir,width);
    }
    void remove(in Direct dir,in int width=1){
        debug(cell) writeln("@@@@ ContentBOX.remove start @@@@");

        if(dir.is_horizontal && numof_col <= 1
        || dir.is_vertical && numof_row <= 1 )
            return;
        _inner_range_cell.remove(dir,width);
    }
    void hold(UpDown ud,LR lr)(in Cell start,in int horizontal_cnt,in int vertical_cnt) // TopLeft
        in{
        // assert(vertical_cnt >= 1);
        // assert(horizontal_cnt >= 1);
        }
    body{
        int w = horizontal_cnt;
        int h = vertical_cnt;
        _inner_range_cell.clear();
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
        import cell.textbox;
        BoxTable table = new BoxTable();
        auto cb = new TextBOX(table);
        cb.hold_br(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_tr unittest start @@@@");
        cb = new TextBOX(table);
        cb.hold_tr(Cell(5,5),3,3);

        assert(cb.top_left == Cell(5,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_bl unittest start @@@@");
        cb = new TextBOX(table);
        cb.hold_bl(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,5));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_tl unittest start @@@@");
        cb = new TextBOX(table);
        cb.hold_tl(Cell(3,3),5,5);

        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(7,7));
        cb = new TextBOX(table);
        cb.create_in(Cell(3,3));
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,3));
        debug(cell) writeln("#### hold_tl unittest end ####");
    }
    // これだけはoverrideさせないとTableの特殊化領域に保存されない
    // このままコピペでいいのにぐぬぬ
    // 型潰してRTTIで再び付加するのとどっちがいいのか揺らぐ
    // 二度手間だけどこれのためだけにインターフェースつくるか
    // 継承関係がぐちゃりそうな確信のない嫌気
    // mixin-templateで分離するのには各実装ごとに差分存在するようなしないような
    // 妥協点は、各実装でこれをoverride
    bool require_create_in(in Cell c)
    {
        if(is_registered())
        {
            remove_from_table();
            clear();
        }
        return _table.try_create_in(this,c);
    }
    bool require_move(in Cell c){
        ubyte result;
        if(c.row)
        if(require_move(down,c.row))
        {
            ++result;
        }
        if(c.column)
        if(require_move(left,c.column))
        {
            ++result;
        }
        if(result == 2) return true;
        else return false;
    }
    bool require_move(in Direct to,in int width=1){
        return (_table.try_move(this,to,width));
    }
    unittest{
        debug(cell) writeln("@@@@ TableBOX unittest start @@@@");
        import cell.textbox;
        BoxTable table = new BoxTable;
        auto cb = new TextBOX(table);
        assert(cb.require_create_in(Cell(3,3)));
        assert(cb.require_expand(Direct.right));
        assert(cb.top_left == Cell(3,3));
        debug(cb) writeln("br ",cb.bottom_right);
        debug(cb) writeln("row ",cb.grab_range().row.get());
        debug(cb) writeln("col ",cb.grab_range().col.get());
        assert(cb.bottom_right == Cell(3,4));
        cb.require_move(Direct.right);
        assert(cb.top_left == Cell(3,4));
        assert(cb.bottom_right == Cell(3,5));
        cb.require_move(Direct.up);
        assert(cb.top_left == Cell(2,4));
        assert(cb.bottom_right == Cell(2,5));
        debug(cell) writeln("#### TableBOX unittest end ####");
    }
    // 実行できたかどうかは知りたい
    bool require_expand(in Direct to,in int width=1){
        return (_table.try_expand(this,to,width));
    }
    bool require_hold(in Cell c,in int w,in int h){
        return 
        require_create_in(c)
        && require_expand(right,w-1)
        && require_expand(down,h-1);
    }
    unittest{
        import cell.textbox;
        BoxTable table = new BoxTable;
        auto cb = new TextBOX(table);
        assert(cb.require_hold(Cell(3,3),8,8));
        assert(cb.top_left == Cell(3,3));
        assert(cb.top_right == Cell(3,10));
        assert(cb.bottom_right == Cell(10,10));
        assert(cb.bottom_left == Cell(10,3));
    }
    void require_remove(in Direct dir,in int width=1){
        if(!is_a_cell)
        _table.remove_content_edge(this,dir,width);
    }
    void remove_from_table(){
        _spoiled = true;
        auto result = _table.try_remove(this);
        clear();
        assert(result && empty);
    }
    void clear(){
        _inner_range_cell.clear();
    }
    bool is_hold(in Cell c)const{
        return _inner_range_cell.is_hold(c);
    }
    // 削除対象かいなか
    private bool _spoiled;
    bool is_to_spoil()const{
        debug(cell) writeln(_spoiled, empty());
        return _spoiled ||empty();
    };
    bool is_registered()const{
        return _box_id != 0;
    }
    @property int id()const{
        return _box_id;
    }
    @property const (Cell[][Direct]) edge_line()const{
        debug(cell) writefln("min_row %d max_row %d\n min_col %d max_col %d",min_row,max_row,min_col,max_col);
        return  [Direct.right:all_in_column(max_col),
                 Direct.left:all_in_column(min_col),
                 Direct.up:all_in_row(min_row),
                 Direct.down:all_in_row(max_row)];
    }
    final RangeCell grab_range(){
        return this;
    }
    const(Cell)[] get_cells()const{
        return _inner_range_cell.get_cells();
    }
    @property int min_row()const{
        return _inner_range_cell.min_row;
    }
    @property int max_row()const{
        return _inner_range_cell.max_row;
    }
    @property int min_col()const{
        return _inner_range_cell.min_col;
    }
    @property int max_col()const{
        return _inner_range_cell.max_col;
    }
    @property Cell top_left()const{
        return _inner_range_cell.top_left;
    }
    @property Cell bottom_right()const{
        return _inner_range_cell.bottom_right;
    }
    @property Cell top_right()const{
        return _inner_range_cell.top_right;
    }
    @property Cell bottom_left()const{
        return _inner_range_cell.bottom_left;
    }
    @property int numof_row()const{
        return _inner_range_cell.numof_row;
    }
    @property int numof_col()const{
        return _inner_range_cell.numof_col;
    }
    bool is_on_edge(const Cell c)const{
        return _inner_range_cell.is_on_edge(c);
    }
    bool is_on_edge(const Cell c,const Direct on)const{
        return _inner_range_cell.is_on_edge(c,on);
    }
    @property bool empty()const{
        return _inner_range_cell.empty();
    }
    @property Cell[] edge_forward_cells(const Direct dir)const{
        return _inner_range_cell.edge_forward_cells(dir);
    }

    void set_color(in Color c){}
}
    unittest{
        import cell.textbox;
        auto table = new BoxTable();
        auto cb = new TextBOX(table);
        cb.create_in(Cell(3,3));
        assert(cb.is_hold(Cell(3,3)));
        assert(!cb.is_hold(Cell(3,4)));
        cb.expand(Direct.right);
        assert(cb.is_hold(Cell(3,4)));
        cb = new TextBOX(table);
        cb.create_in(Cell(5,5));
        cb.expand(Direct.right);
        cb.expand(Direct.down);
        assert(cb.get_cells().count_lined(Cell(5,5),Direct.right) == 1);
        assert(cb.get_cells().count_lined(Cell(5,5),Direct.down) == 1);
        debug(cell) writeln("@@@@ update_info unittest start @@@@@");
        cb = new TextBOX(table);
        cb.create_in(Cell(5,5));
        assert(cb.top_left == Cell(5,5));
        assert(cb.numof_row == 1);
        assert(cb.numof_col == 1);

        cb.hold_tl(Cell(0,0),5,5);

        debug(cell) writefln("!!!! top_left %s",cb.top_left);
        assert(cb.top_left == Cell(0,0));
        assert(cb.bottom_right == Cell(4,4));
        debug(cell) writeln("numof_row:",cb.numof_row);
        debug(cell) writeln("numof_col:",cb.numof_col);
        assert(cb.numof_row == 5);
        assert(cb.numof_col == 5);
        debug(cell) writeln("#### update_info unittest end ####");

        debug(cell) writeln("@@@@ ContentBOX move unittest start @@@@");
        cb = new TextBOX(table,Cell(5,5),5,5);
        assert(cb.top_left == Cell(5,5));
        import std.stdio;
        writeln(cb.bottom_right);
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

        debug(cell) writeln("#### ContentBOX move unittest end ####");
        debug(cell) writeln("@@@@is_on_edge unittest start@@@@");
        cb = new TextBOX(table);
        auto c = Cell(3,3);
        cb.create_in(c);
        assert(cb.is_on_edge(c));
        foreach(dir; EnumMembers!Direct)
        {   // 最終的に各方向に1Cell分拡大
            cb.expand(dir);
            assert(cb.is_on_edge(cb.top_left));
            assert(cb.is_on_edge(cb.bottom_right));
        }
        debug(cell) writeln("####is_on_edge unittest end####");
        debug(cell) writeln("@@@@hold_br unittest start@@@@");
        cb = new TextBOX(table);
        cb.hold_br(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_tr unittest start @@@@");
        cb = new TextBOX(table);
        cb.hold_tr(Cell(5,5),3,3);

        assert(cb.top_left == Cell(5,3));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_bl unittest start @@@@");
        cb = new TextBOX(table);
        cb.hold_bl(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,5));
        assert(cb.numof_row == 3);
        assert(cb.numof_col == 3);
        debug(cell) writeln("@@@@ hold_tl unittest start @@@@");
        cb = new TextBOX(table);
        cb.hold_tl(Cell(3,3),5,5);

        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(7,7));
        cb = new TextBOX(table);
        // cb.hold_tl(Cell(3,3),0,0);
        cb.create_in(Cell(3,3));
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,3));
        debug(cell) writeln("#### hold_tl unittest end ####");
    }


