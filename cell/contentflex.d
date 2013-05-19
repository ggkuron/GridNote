module cell.contentflex;

import cell.cell;
import cell.contentbox;
import cell.collection;
import cell.table;

import util.direct;
import util.array;
import util.range;
debug(table) import std.stdio;

// Collection をTableに取り付けるように拡張した形
// Cell[] box はTableもどのみち持つことになるので
// 取り除き、boxが要求される部分はTableにrequestする。
// そのことで、Collectionと似て非なる
abstract class ContentFlex : CellContent{
private:
    BoxTable table;
    int _content_id;

    Collection _inner_collec;
package:
    // table に渡す
protected:
    invariant(){
        assert(table !is null);
    }
public:
    alias _inner_collec this;
    this(BoxTable attach, Collection taken)
        out{
        assert(table !is null);
        }
    body{
        this(attach);
    }
    this(BoxTable attach)
        out{
        assert(table !is null);
        }
    body{
        table = attach;
        _inner_collec = new Collection();
    }
    this(Collection cb){
        if(!_inner_collec.empty())
            table.add_box(this);
    }
    bool require_create_in(const Cell c){
        if(table.try_create_in(this,c))
        {
            return true;
        }else
        return false;
    }
    bool require_move(const Direct to,int width=1){
        debug(move){
            writeln("ContentCollection::move start");
        }
        if(table.try_move(this,to,width))
        {
            debug(move) writeln("moved");
            return true;
        }
        debug(move) writeln("not moved");
        return false;
    }
    unittest{
        debug(cell) writeln("@@@@ TableBOX unittest start @@@@");
        import cell.textbox;
        BoxTable table = new BoxTable;
        auto cb = new TextBOX(table);
        cb.require_create_in(Cell(3,3));
        cb.require_expand(Direct.right);
        assert(cb.top_left == Cell(3,3));
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
    bool require_expand(const Direct to,int width=1){
        if(table.try_expand(this,to,width))
        {
            _inner_collec.expand(to,width);
            return true;
        }else return false;
    }
    void require_remove(const Direct dir,int width =1){
        table.remove_content_edge(this,dir,width);
    }
    void remove_from_table(){
        spoiled = true;
        auto result = table.try_remove(this);
        assert(result);
    }
    // 削除対象かいなか
    private bool spoiled;
    bool is_to_spoil(){
        debug(cell) writeln(spoiled, empty());
        return spoiled || empty();
    };
    int id()const{ return _content_id; }
    void set_id(const int id){
        _content_id = id;
    }
    @property bool empty()const{
        return _inner_collec.empty();
    }
}

