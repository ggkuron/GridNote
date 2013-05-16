module cell.select;

import util.direct;
import cell.cell;
import cell.collection;
import cell.table;
import cell.textbox;
import util.array;

// 継承による贅肉付き過ぎてる感ある
// focus 使わずにbox使ってfocus表現できる。
final class SelectBOX : CellCollection{
private:
    BoxTable table;
    Cell _focus;
    Cell _pivot;
    void set_pivot(const Cell p)
        in{
        assert(get_box.empty());
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
            else if(cl.column < _pivot.column) // 3
                hold_tr(_pivot,dr,dc);
            else 
                hold_tl(_pivot,dr,dc); // 4
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
        assert(!get_box.empty());
        }
        out{
        assert(is_box(get_box()));
        }
    body{
        debug(cell) writeln("expand_to__focus start");
        pivot_bound(_focus);
        debug(cell) writeln("end");
    }
    override void expand(const Direct dir){
        super.expand(dir);
    }
    this(BoxTable attach,Cell cursor=Cell(2,2))
    body{
        table = attach;
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
        box.clear();
        debug(cell) writeln("end");
        return tb;
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
    override void clear(){
        box.clear();
    }
}
