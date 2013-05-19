// module cell.rangebox;
// 
// import cell.cell;
// import cell.table;
// import cell.cellrange;
// import util.range;
// import util.array;
// import util.direct;
// import std.math;
// import std.algorithm;
// import std.typecons;
// // 四角い領域
// // BoxRangeがそのすべて
// // 領域の操作方法をまとめてるけど、
// // BoxRangeである以上矩形という絶対条件は守られるので、
// // 外からの操作も、get_box()で取得できるBoxRangeで自由にしても構わない。
// 
// // 範囲によって矩形を表現する
// // 必要であればCell[]を生成できる
// class RangeBOX : CellRange,CellStructure{
// private:
// package:
//     // Cell[] all_in_column(const int column)const{
//     //     return _range.all_in_column(column);
//     // }
//     // Cell[] all_in_row(const int row)const{
//     //     return _range.all_in_row(row);
//     // }
// public:
//     // 最初の1Cellのみに対して行う操作
//     // CellRange _range;
//     // alias _range this;
//     void create_in(const Cell c)
//         in{
//         assert(range.empty);
//         }
//     body{ // create initial box
//         clear(); // <- range.clear()
//         add(c);
//     }
//     // void expand(const Direct dir,int width=1)
//     //     in{
//     //     assert(width > 0);
//     //     }
//     // body{
//     //     _range.expand(dir,width);
//     // }
//     override void remove(const Direct dir,int width=1){
//         debug(cell) writeln("@@@@ RangeBOX.remove start @@@@");
// 
//         if(dir.is_horizontal && numof_col <= 1
//         || dir.is_vertical && numof_row <= 1 )
//             return;
//         remove(dir,width);
//     }
//     // void clear(){
//     //     range.clear();
//     // }
//     // bool is_hold(const Cell c)const{
//     //     return _range.is_hold(c);
//     // }
//     // bool is_a_cell()const{
//     //     return _range.is_a_cell();
//     // }
//     this(){
//         clear();
//         super();
//     }
//     this(Cell ul,int rw,int cw){
//         debug(cell){ 
//             writeln("ctor start");
//             writefln("rw %d cw %d",rw,cw);
//         }
//         this();
//         hold_tl(ul,rw,cw);
//         debug(cell)writeln("ctor end");
//     }
//     this(RangeBOX oldone)
//     body{
//         debug(cell) writeln("take after start");
// 
//         super(oldone);
//         debug(cell) writeln("end");
//     }
//     // 増加方向のみ
//     // final void move(const Cell c){
//     //     range.move(c);
//     // }
//     // final void move(const Direct dir,int pop_cnt=1){
//     //     range.move(dir,pop_cnt);
//     // }
//     // bool is_on_edge(const Cell c)const{
//     //     return _range.row.is_in(c.row) && _range.col.is_in(c.column);
//     // }
//     // bool is_on_edge(const Cell c,const Direct on)const{
//     //     // 迂回路
//     //     // return edge_line[on].is_in(c);
//     //     // _range.is_on_edge(c,dir);
//     // }
//     // @property const (Cell[][Direct]) edge_line()const{
//     //     debug(cell) writefln("min_row %d max_row %d\n min_col %d max_col %d",min_row,max_row,min_col,max_col);
//     //     return  [Direct.right:all_in_column(max_col),
//     //              Direct.left:all_in_column(min_col),
//     //              Direct.up:all_in_row(min_row),
//     //              Direct.down:all_in_row(max_row)];
//     // }
// 
//     // @property bool empty()const{
//     //     return _range.row.empty && _range.col.empty;
//     // }
// 
//     // @property Cell[] edge_forward_cells(const Direct dir)const{
//     //     return _range.edge_forward_cells(dir);
//     // }
//     // RangeBOX オリジナル
//     void hold(UpDown ud,LR lr)(const Cell start,int h,int w) // TopLeft
//         in{
//         assert(h >= 1);
//         assert(w >= 1);
//         }
//     body{
//         clear();
//         create_in(start);
//         --w;
//         --h;
//         if(!w && !h) return;
//         expand(cast(Direct)(lr).reverse,w);
//         expand(cast(Direct)(ud).reverse,h);
//     }
//     alias hold!(UpDown.up,LR.left) hold_tl;
//     alias hold!(UpDown.up,LR.right) hold_tr;
//     alias hold!(UpDown.down,LR.left) hold_bl;
//     alias hold!(UpDown.down,LR.right) hold_br;
//     // getter:
//     // 
//     final:
//     CellRange grab_range(){
//         return this;
//     }
// }
// 
// 
