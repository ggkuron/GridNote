module cell.collection;

import cell.cell;
import util.direct;
import util.array;

// 自由変形できる構造
class CellCollection : CellStructure{
private:
    Cell[LR][UpDown] edge;

    int _numof_row = 1;  // 
    int _numof_col = 1;
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
        auto cb = new CellCollection();
        cb.create_in(Cell(3,3));
        assert(cb.is_in(Cell(3,3)));
        assert(!cb.is_in(Cell(3,4)));
        cb.expand(Direct.right);
        assert(cb.is_in(Cell(3,4)));
        cb = new CellCollection();
        cb.create_in(Cell(5,5));
        cb.expand(Direct.right);
        cb.expand(Direct.down);
        assert(cb.box.count_lined(Cell(5,5),Direct.right) == 1);
        assert(cb.box.count_lined(Cell(5,5),Direct.down) == 1);
        debug(cell) writeln("@@@@ update_info unittest start @@@@@");
        cb = new CellCollection();
        cb.create_in(Cell(5,5));
        assert(cb.edge[up][left] == Cell(5,5));
        assert(cb._numof_row == 1);
        assert(cb._numof_col == 1);

        cb.hold_tl(Cell(0,0),5,5);

        debug(cell) writefln("!!!! top_left %s",cb.edge[up][left]);
        debug(cell) writefln("!!!! box %s",cb.box);
        assert(cb.edge[up][left] == Cell(0,0));
        assert(cb.bottom_right == Cell(4,4));
        debug(cell) writeln("_numof_row:",cb._numof_row);
        debug(cell) writeln("_numof_col:",cb._numof_col);
        assert(cb._numof_row == 5);
        assert(cb._numof_col == 5);
        debug(cell) writeln("#### update_info unittest end ####");
    }
    const(Cell)[] all_in_column(const int column)const{
        Cell[] result;
        if(column in col_table)
        foreach(r,b; col_table[column])
        {   // このifは確認を怠らなければ取り除ける
            if(b)
            result ~= Cell(r,column);
        }
        return result;
    }
    const(Cell)[] all_in_row(const int row)const{
        Cell[] result;
        if(row in row_table)
        foreach(c,b; row_table[row])
        {   // このifは確認を怠らなければ取り除ける
            if(b)
            result ~= Cell(row,c);
        }
        return result;
    }
public:
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
    void expand(const Direct dir,int width=1){
        while(width--)
            expand(dir);
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
                ++_numof_col;
                --min_col;
                edge[up][left].move(Direct.left);
                edge[down][left].move(Direct.left);
                break;
            case Direct.right:
                ++_numof_col;
                ++max_col;
                edge[up][right].move(Direct.right);
                edge[down][right].move(Direct.right);
                break;
            case Direct.up:
                ++_numof_row;
                --min_row;
                edge[up][left].move(Direct.up);
                edge[up][right].move(Direct.up);
                break;
            case Direct.down:
                ++_numof_row;
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
    void remove(const Direct dir,int width=1){
        while(width--)
            remove(dir);
    }
    void remove(const Direct dir){
        debug(cell) writeln("@@@@ CellCollection.remove start @@@@");

        if(dir.is_horizontal && _numof_col <= 1
        || dir.is_vertical && _numof_row <= 1 )
            return;
        auto delete_line = edge_line[dir];
        foreach(c; delete_line)
        {
           util.array.remove!(Cell)(box,c);
           row_table[c.row].remove(c.column);
           col_table[c.column].remove(c.row);
           debug(cell) writefln("deleted %s",c);
        }
        final switch(dir){ // 
            case Direct.left:
                edge[up][left].move(Direct.right);
                edge[down][left].move(Direct.right);
                --_numof_col;
                ++min_col;
                break;
            case Direct.right:
                edge[up][right].move(Direct.left);
                edge[down][right].move(Direct.left);
                --_numof_col;
                --max_col; // 負数になるようなとき (_numof_col or _numof_row <= 1)
                break;
            case Direct.up:
                edge[up][left].move(Direct.down);
                edge[up][right].move(Direct.down);
                --_numof_row;
                ++min_row;
                break;
            case Direct.down:
                edge[down][left].move(Direct.up);
                edge[down][right].move(Direct.up);
                --_numof_row;
                --max_row;
                break;
        }
        debug(cell) writeln("#### CellCollection.remove end ####");
        debug(move) writeln("col_table are ",col_table);
        debug(move) writeln("row_table are ",row_table);
    }
    void clear(){
        box.clear();
        _numof_row =1;
        _numof_col =1;
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
    this(){}
    this(Cell ul,int rw,int cw){
        debug(cell){ 
            writeln("ctor start");
            writefln("rw %d cw %d",rw,cw);
        }
        this();
        hold_tl(ul,rw,cw);
        debug(cell)writeln("ctor end");
    }
    this(CellCollection oldone)
        in{
        assert(!oldone.get_box_raw().empty);
        }
        out{
        assert(!box.empty);
        }
    body{
        debug(cell) writeln("take after start");
        box = oldone.get_box_dup();
        edge = oldone.edge.dup();
        min_col = oldone.min_col;
        max_col = oldone.max_col;
        min_row = oldone.min_row;
        max_row = oldone.max_row;
        row_table = oldone.row_table.dup();
        col_table = oldone.col_table.dup();

        oldone.clear();
        debug(cell) writeln("end");
    }
    void move(const Direct dir){
        // この順番でないと1Cellだけのときに失敗する
        expand(dir);
        remove(dir.reverse);
    }
    unittest{
        debug(cell) writeln("@@@@ CellCollection move unittest start @@@@");
        auto cb = new CellCollection(Cell(5,5),5,5);
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

        debug(cell) writeln("#### CellCollection move unittest end ####");
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
        auto cb = new CellCollection();
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
        return  [Direct.right:all_in_column(max_col),
                 Direct.left:all_in_column(min_col).dup,
                 Direct.up:all_in_row(min_row),
                 Direct.down:all_in_row(max_row)];
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
        auto cb = new CellCollection();
        cb.hold_br(Cell(5,5),3,3);

        assert(cb.edge[up][left] == Cell(3,3));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
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
        auto cb = new CellCollection();
        cb.hold_tr(Cell(5,5),3,3);

        assert(cb.edge[up][left] == Cell(5,3));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
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
        auto cb = new CellCollection();
        cb.hold_bl(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,5));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
        debug(cell) writeln("#### hold_bl unittest end ####");
    }
    unittest{
        debug(cell) writeln("@@@@ hold_tl unittest start @@@@");
        auto cb = new CellCollection();
        cb.hold_tl(Cell(3,3),5,5);

        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(7,7));
        cb = new CellCollection();
        cb.hold_tl(Cell(3,3),0,0);
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,3));
        debug(cell) writeln("#### hold_tl unittest end ####");
    }

    // getter:
    final:
    const int numof_row()const{
        return _numof_row;
    }
    const int numof_col()const{
        return _numof_col;
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

