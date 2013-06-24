module cell.select;

import util.direct;
import util.color;
import cell.cell;
import cell.collection;
import cell.table;
import gui.tableview;

// ContentBOX
import cell.textbox;
import cell.imagebox;

import util.array;
debug(cell) import std.stdio;

// focus 使わずにbox使ってfocus表現できる。
final class SelectBOX : Collection {
private:
    BoxTable _table;
    Cell _focus;
    Cell _pivot;
    void set_pivot(in Cell p)
        in{
        assert(get_cells.empty());
        }
    body{
        debug(cell) writeln("set__pivot start");
        _pivot = p;
        super.create_in(_pivot);
        debug(cell) writeln("end");
    }
    void pivot_bound(in Cell cl){
        debug(cell) writeln("privot_bound start");
        if(_pivot == cl)  super.create_in(_pivot); else
        if(_pivot < cl) // _pivot.rowの方が小さいブロック。もしくは同じでcolumnが小さい。
        {
            immutable d = diff(cl,_pivot);
            immutable dr = d.row+1;
            immutable dc = d.column+1;

            if(cl.column == _pivot.column) // 縦軸下
                hold_tl(_pivot,dr,1);
            else if(cl.column < _pivot.column) // 3
                hold_tr(_pivot,dr,dc);
            else 
                hold_tl(_pivot,dr,dc); // 4
        }else{ // if(_pivot > cl) _pivot.rowが大きい
            immutable d = diff(_pivot,cl);
            immutable dr = d.row+1;
            immutable dc = d.column+1;
            if(cl.column == _pivot.column) // 縦軸上
                hold_br(_pivot,dr,1);
            else if(cl.column > _pivot.column) // 1
                hold_tr(cl,dr,dc);
            else // 2
                hold_br(_pivot,dr,dc);
        }
        debug(cell) writeln("end");
    }
public:
    void expand_to_focus()
        in{
        // assert(!get_cells.empty()); 呼ばれても問題はない
        }
        out{
        assert(is_box(get_cells()));
        }
    body{
        debug(cell) writeln("expand_to__focus start");
        pivot_bound(_focus);
        debug(cell) writeln("end");
    }
    override void expand(in Direct dir,in int width=1){
        super.expand(dir,width);
    }
    this(BoxTable attach,in Cell cursor=Cell(2,2))
    body{
        _table = attach;
        _focus = cursor;
    }
    override void move(in Direct dir,in int width=1){
        _focus.move(dir,width);
    }
    void move_to(in Cell c){
        _focus = c;
    }
    void create_in(){
        super.create_in(_focus);
        debug(cell)writefln("create in %s",_focus);
    }
    override void add(in Cell c){
        super.add(c);
    }
    bool is_on_edge()const{
        return super.is_on_edge(_focus);
    }
    bool is_on_edge(in Direct dir)const{
        return super.is_on_edge(_focus,dir);
    }
    TextBOX create_TextBOX(string family ="Sans",string style="Normal",in Color fore = black){
        auto tb = new TextBOX(_table,family,style,fore);
        if(!tb.require_create_in(_focus)) return null;
        selection_clear();
        return tb;
    }
    // ImageBOX create_ImageBOX(string filepath){
    //     debug(cell) writeln("@@@@ create_ImageBOX @@@@");
    //     auto ib = new ImageBOX(_table,filepath);
    //     if(!ib.require_create_in(_focus)) return null;
    //     selection_clear();
    //     debug(cell) writeln("#### create_ImageBOX ####");
    //     return ib;
    // }
    CircleBOX create_CircleCell(in Color c ,TableView tv){
        debug(cell) writeln("@@@@ create_ImageBOX @@@@");
        auto ib = new CircleBOX(_table,tv);
        if(!ib.require_create_in(_focus)) return null;
        ib.set_drawer();
        ib.set_color(c);
        selection_clear();
        debug(cell) writeln("#### create_ImageBOX ####");
        return ib;
    }
    RectBOX create_RectCell(in Color c ,TableView tv){
        debug(cell) writeln("@@@@ create_ImageBOX @@@@");
        auto ib = new RectBOX(_table,tv);
        if(!ib.require_create_in(_focus)) return null;
        ib.set_drawer();
        ib.set_color(c);
        selection_clear();
        debug(cell) writeln("#### create_ImageBOX ####");
        return ib;
    }
    void set_pivot(){
        set_pivot(_focus);
    }
    @property Cell focus()const{
        return _focus;
    }
    @property Cell pivot()const{
        return _pivot;
    }
        // focusは残す
    void selection_clear(){
        super.clear();
    }
}
