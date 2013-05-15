module cell.refer;

import std.typecons;
import util.direct;
import util.array;
import cell.cell;
import cell.table;
debug(refer) import std.stdio;

// Viewの移動の際、
// 原点方向にはTableの中身をシフトする形で展開するが
// Cellの増加方向がPageViewの原点位置に来たときにTableを切り出す必要がある
// 他、Tableを切り出すとHolderになるし便利(そう)
class ReferTable : BoxTable{
private:
    BoxTable master; // almost all manipulation acts on this table
    Cell _offset;
    Cell _max_range; // table(master)の座標での取りうる最大値

    bool check_range(const Cell c)const{
        return  (c <=  _max_range);
    }
public:
    this(BoxTable attach, Cell ul,int w,int h)
        in{
        assert(attach !is null);
        assert(h>0);
        assert(w>0);
        }
    body{
        super();
        master = attach; // manipulating ReferBOX acts on attached Table
        set_range(ul,w,h);
    }
    unittest{
        import cell.textbox;
        auto table = new BoxTable();
        auto rtable = new ReferTable(table,Cell(3,3),8,8);
        assert(rtable._max_range == Cell(10,10));
        auto tb = new TextBOX(table);
        tb.require_create_in(Cell(4,4));
        auto items = rtable.get_content(Cell(1,1));
        assert(items[1] !is null);
        assert(tb.box_id == items[1].box_id);
        tb.require_expand(Direct.right);
        items = rtable.get_content(Cell(1,2));
        assert(items[1] !is null);
        auto all_items = rtable.get_contents();
        assert(all_items[0] == items);
        assert(tb.box_id == items[1].box_id);
        auto tb2 = new TextBOX(table);
        tb2.require_create_in(Cell(6,6));
    }
    void set_range(Cell ul,int w,int h)
        in{
        assert(h>0);
        assert(w>0);
        }
    body{
        _offset = ul;
        auto row = _offset.row + h-1;
        auto col = _offset.column + w-1;
        _max_range = Cell(row,col);
        debug(refer) writefln("range h:%d w:%d",h,w);
    }
    override Tuple!(string,ContentBOX) get_content(const Cell c){
        return master.get_content(c+_offset);
    }
    // master のtableのなかでview に含まれるものを包めて返す
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
        {
            if(k == 0) continue;
            auto content = master.get_content(k);
            result ~= master.get_content(k);
        }
        return result;
    }

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
    Cell get_position(const CellBOX b)const{
        assert(!b.empty());
        return b.top_left + _offset;
    }
    bool empty(){
        return master.refer_keys().keys.empty();
    }
}


