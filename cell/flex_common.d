module cell.flex_common;

import cell.cell;
public import cell.rangecell;
import std.traits;
import util.direct;
import util.array;
// import util.range;

// 自由変形できる構造
mixin template flex_common(alias box_body){
private:
    Cell[LR][UpDown] _edge;

    int _numof_row = 1;  // 
    int _numof_col = 1;
    
    RangeCell _range;

    // _min_row 等に依存
    // rangeとは独立している
    Cell[][Direct] _edge_line;

    // Range をクロスさせた状態を表現する
    int _min_row = int.max;
    int _min_col = int.max;
    int _max_row = int.min;
    int _max_col = int.min;

    @property Cell[] box(){
        return mixin (box_body);
    }


    bool _fixed;
    unittest{
        auto cb = new Collection();
        cb.create_in(Cell(3,3));
        assert(cb.is_in(Cell(3,3)));
        assert(!cb.is_in(Cell(3,4)));
        cb.expand(Direct.right);
        assert(cb.is_in(Cell(3,4)));
        cb = new Collection();
        cb.create_in(Cell(5,5));
        cb.expand(Direct.right);
        cb.expand(Direct.down);
        assert(cb.box.count_lined(Cell(5,5),Direct.right) == 1);
        assert(cb.box.count_lined(Cell(5,5),Direct.down) == 1);
        debug(cell) writeln("@@@@ update_info unittest start @@@@@");
        cb = new Collection();
        cb.create_in(Cell(5,5));
        assert(cb.top_left == Cell(5,5));
        assert(cb._numof_row == 1);
        assert(cb._numof_col == 1);

        cb.hold_tl(Cell(0,0),5,5);

        debug(cell) writefln("!!!! top_left %s",cb.edge[up][left]);
        debug(cell) writefln("!!!! box %s",cb.box);
        assert(cb.top_left == Cell(0,0));
        assert(cb.bottom_right == Cell(4,4));
        debug(cell) writeln("_numof_row:",cb._numof_row);
        debug(cell) writeln("_numof_col:",cb._numof_col);
        assert(cb._numof_row == 5);
        assert(cb._numof_col == 5);
        debug(cell) writeln("#### update_info unittest end ####");
    }
    final void expand1(in Direct dir)
    body{
        debug(cell) writeln("@@@@ expand start @@@@");
        debug(cell) writeln("direct is ",dir);


        const Cell[] one_edges = edge_line[dir];
        foreach(c; one_edges) //one_edgesが配列でないとexpanded_edgeがsortされない
        {
            auto moved = c.if_moved(dir);
            box ~= moved;
            _range.add(moved);
        }
        if(dir.is_horizontal)
        {
          edge[up][dir].move(dir);
          edge[down][dir].move(dir);
          ++_numof_col;
          if(dir.is_positive)
              ++_max_col;
          else 
              --_min_col;
        }
        else // if(dir.is_vertical)
        {
          edge[dir][left].move(dir);
          edge[dir][right].move(dir);
          ++_numof_row;
          if(dir.is_positive)
              ++_max_row;
          else 
              --_min_row;
        }
        range.expand(dir);

        debug(cell) writeln("#### expand end ####");
        // debug(cell) writeln("boxes are ",box);
        debug(move) writeln("min col ",min_col);
        debug(move) writeln("max col ",max_col);
        debug(move) writeln("col_table are ",col_table);
        debug(move) writeln("row_table are ",row_table);
        return true;
    }
    final void remove1(in Direct dir){
        debug(cell) writeln("@@@@ Collection.remove start @@@@");

        if(dir.is_horizontal && _numof_col <= 1
        || dir.is_vertical && _numof_row <= 1 )
            return;
        auto delete_line = edge_line[dir];
        foreach(c; delete_line)
        {
           util.array.remove!(Cell)(box,c);
           debug(cell) writefln("deleted %s",c);
        }

        if(dir.is_horizontal)
        {
          edge[up][dir].move(dir.reverse);
          edge[down][dir].move(dir.reverse);
          --_numof_col;
          if(dir.is_positive)
              --_max_col;
          else 
              ++_min_col;
        }
        else // if(dir.is_vertical)
        {
          edge[dir][left].move(dir.reverse);
          edge[dir][right].move(dir.reverse);
          --_numof_row;
          if(dir.is_positive)
              --_max_row;
          else 
              ++_min_row;
        }
        range.remove(dir);
            
        debug(cell) writeln("#### Collection.remove end ####");
        debug(move) writeln("col_table are ",col_table);
        debug(move) writeln("row_table are ",row_table);
    }
    final void move1(in Direct dir){
        // この順番でないと1Cellだけのときに失敗する
        expand(dir);
        remove(dir.reverse);
    }
public:
    void create_in(in Cell c){
        clear(); // <- range.clear()
        box ~= c;
        range.add(c);
        min_row = max_row = c.row;
        min_col = max_col = c.column;
        edge[up][left] = c;
        edge[up][right] = c;
        edge[down][left] = c;
        edge[down][right] = c;
        _edge_line[Direct.left] ~= c;
        _edge_line[Direct.right] ~= c;
        _edge_line[Direct.up] ~= c;
        _edge_line[Direct.down] ~= c;
    }
    // 任意のタイミングで行う操作
    void add(in Cell c)
        in{
        assert(!box.empty);
        }
        out{
        assert(is_box(box));
        }
    body{ // create initial box
        bool min_row_f,min_col_f,max_row_f,max_col_f;
        box ~= c;

        if(c.row < range.row)
        {
            mon_row_f = true;
            _edge_line[Direct.up].clear();
            _edge_line[Direct.up] ~= c.row;
        }
        else if(c.row > range.row)
        {
            max_row_f = true;
            _edge_line[Direct.down].clear();
            _edge_line[Direct.down] ~= c.row;
        }
        else if(c.row == range.row)
            _edge_line[Direct.up] ~= c.row;
        else // if(c.row == row_table.max)
            _edge_line[Direct.down] ~= c.row;

        if(c.column < range.col)
        {
            min_row_f = true;
            _edge_line[Direct.left].clear();
            _edge_line[Direct.left] ~= min_col;
        }
        else if(c.column > range.col)
        {
            max_col_f = true;
            _edge_line[Direct.right].clear();
            _edge_line[Direct.right] ~= max_col;
        }
        else if(c.column == col_table.min)
            _edge_line[Direct.left] ~= c.column;
        else // if(c.column == col_table.max)
            _edge_line[Direct.right] ~= c.column;

        // cellを判定後に更新
        _range.add(c);

        if(max_col_f && max_row_f)
            edge[down][right] = c;
        if(max_col_f && min_row_f)
            edge[up][right] = c;
        if(min_col_f && max_row_f)
            edge[down][left] = c;
        if(min_col_f && min_row_f)
            edge[up][left] = c;
    }
    void expand(in Direct dir,int width=1){
        while(width--)
            expand1(dir);
    }
    void remove(in Direct dir,int width=1){
        while(width--)
            remove1(dir);
    }
    void clear(){
        box.clear();
        range.clear();
        _numof_row =1;
        _numof_col =1;
        max_row = int.min;
        max_col = int.min;
        min_row = int.max;
        min_col = int.max;
        edge.clear();
        edge_line.clear();
    }
    // 線形探索:要素数は小さいものしか想定してないから
    // box.lenthでアルゴリズム切り分ける必要があるかも
    bool is_in(in Cell c){
        return .is_in(box,c);
    }
    
    void move(in Cell c){
        if(!c.row)
            move(right,c.row);
        if(!c.column)
            move(down,c.column);
    }
    void move(in Direct dir,int width){
        while(width--)
            move1(dir);
    }
    unittest{
        debug(cell) writeln("@@@@ Collection move unittest start @@@@");
        auto cb = new Collection(Cell(5,5),5,5);
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

        debug(cell) writeln("#### Collection move unittest end ####");
    }
    bool is_on_edge(Cell c){
            
        foreach(each_edged; edge_line())
        {
            if(each_edged.is_in(c)) return true;
            else continue;
        }
        return false;
    }
    unittest{
        debug(cell) writeln("@@@@is_on_edge unittest start@@@@");
        auto cb = new Collection();
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
    }
    bool is_on_edge(in Cell c,in Direct on){
        return edge_line[on].is_in(c);
    }
    @property const (Cell[][Direct]) edge_line(){
        debug(cell) writefln("min_row %d max_row %d\n min_col %d max_col %d",min_row,max_row,min_col,max_col);
        return  [Direct.right:all_in_column(max_col),
                 Direct.left:all_in_column(min_col).dup,
                 Direct.up:all_in_row(min_row),
                 Direct.down:all_in_row(max_row)];
    }
    @property bool empty(){
        return box.empty();
    }
    // 初期段階に矩形領域を確保するために使う
    void hold_tl(in Cell start,int h,int w) // TopLeft
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        clear();
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
    void hold_br(in Cell lr,int h,int w) // BottomRight
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        clear();
        auto s_r = lr.row-h+1;
        if(s_r < 0) s_r = 0;
        auto s_c = lr.column-w+1;
        if(s_c < 0) s_c = 0;
        auto start = Cell(s_r,s_c);
        hold_tl(start,h,w);
    }
    unittest{
        debug(cell) writeln("@@@@hold_br unittest start@@@@");
        auto cb = new Collection();
        cb.hold_br(Cell(5,5),3,3);

        assert(cb.edge[up][left] == Cell(3,3));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
        debug(cell) writeln("####hold_br unittest end####");
    }
    void hold_tr(in Cell ur,int h,int w)
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        clear();
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
        auto cb = new Collection();
        cb.hold_tr(Cell(5,5),3,3);

        assert(cb.edge[up][left] == Cell(5,3));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
        debug(cell) writeln("#### hold_tr unittest start ####");
    }
    void hold_bl(in Cell ll,int h,int w)
        in{
        assert(h >= 0);
        assert(w >= 0);
        }
        out{
        assert(is_box(box));
        }
    body{
        clear();
        auto s_r = ll.row-h+1;
        if(s_r < 0) s_r = 0;
        auto s_c = ll.column;
        auto start = Cell(s_r,s_c);
        hold_tl(start,h,w);
    }
    unittest{
        debug(cell) writeln("@@@@ hold_bl unittest start @@@@");
        auto cb = new Collection();
        cb.hold_bl(Cell(5,5),3,3);

        assert(cb.top_left == Cell(3,5));
        assert(cb._numof_row == 3);
        assert(cb._numof_col == 3);
        debug(cell) writeln("#### hold_bl unittest end ####");
    }
    unittest{
        debug(cell) writeln("@@@@ hold_tl unittest start @@@@");
        auto cb = new Collection();
        cb.hold_tl(Cell(3,3),5,5);

        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(7,7));
        cb = new Collection();
        cb.hold_tl(Cell(3,3),0,0);
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,3));
        debug(cell) writeln("#### hold_tl unittest end ####");
    }

    // getter:
    final:
    int numof_row(){
        return _numof_row;
    }
    int numof_col(){
        return _numof_col;
    }
    @property int min_row(){
        return _min_row;
    }
    @property int max_row(){
        return _max_row;
    }
    @property int min_col(){
        return _min_col;
    }
    @property int max_col(){
        return _max_col;
    }
    const(Cell)[] get_cells(){
        return box;
    }
    @property Cell top_left(){
        return edge[up][left];
    }
    @property Cell bottom_right(){
        return edge[down][right];
    }
    @property Cell top_right(){
        return edge[up][right];
    }
    @property Cell bottom_left(){
        return edge[down][left];
    }
}

