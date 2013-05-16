module cell.table;

import cell.cell;
import cell.collection;
import cell.box;
import std.typecons;
import util.direct;
import util.array;
import util.range;
import cell.content;

debug(cell) import std.stdio;
debug(move) import std.stdio;
debug(table) import std.stdio;
debug(refer) import std.stdio;

// Cellによる空間を提供する
// 誰がその空間を使っているかを管理する
// どのように空間を使うかは各BOX
class BoxTable{
private:
    alias int KEY;
    alias int ROW;
    alias int COL;

    alias Range RowRange;
    alias Range ColRange;

    CellContent[KEY] content_table;
    string[KEY] type_table;
    Cell[][KEY] collection;
    KEY[Cell] keys;

    int _content_counter;
    void set_id(CellContent c){
        if(_content_counter == int.max)
        {   // throw exception
            assert(0);
        }
        // 0は欠番にしておく
        c.set_id(++_content_counter);
        debug(table){
            assert(_content_counter !in keys);
        }
    }
protected:
public:
    auto export_table(){
        return content_table;
    }
    int[] ranged_keys(Cell start,Cell end)const{
        int[int] ranged_keys;
        auto itr = start;
        auto max_range = end;
        while(1)
        {
            if(itr in keys)
            {
                auto cells_key = keys[itr];
                ranged_keys[cells_key] = cells_key; // 重複を避けるため
            }
            if(itr.column < max_range.column)
                ++itr.column;
            else
            {
                ++itr.row;
                itr.column = start.column;
            }

            if(itr == max_range)
                break;
        }
        return ranged_keys.values;
    }
    auto get_contents(Cell start,Cell end){
         
        Tuple!(string,CellContent)[] result;
        auto keys = ranged_keys(start,end);
        foreach(k; keys)
        {
            if(k==0) continue;
            result ~=tuple(type_table[k],content_table[k]);
        }
        return result;
    }
    bool is_in(Cell c){
        foreach(cb ; content_table.values)
            if(cb.is_in(c)) return true;
        if(c in keys)
            return true;
        return false;
    }
    // int get_boxkey_first_by_row(Cell c)const{
    //     foreach(k,bk; box_keys.keys)
    //     {
    //         if(bk[0].is_in(c))
    //             if(bk[1].is_in(c))
    //                 return k;
    //         else return 0;
    //     }
    // }
    // int get_boxkey_first_by_col(Cell c)const{
    //     foreach(k,bk; box_keys.keys)
    //     {
    //         if(bk[1].is_in(c))
    //             if(bk[0].is_in(c))
    //                 return k;
    //         else return 0;
    //     }
    // }
    Cell[] get_cells(int key){
        assert(key in collection);
        return collection[key];
    }
    Tuple!(string,CellContent) get_content(int key){
        assert(keys.values.is_in(key));
        assert(key in content_table);
        return tuple(type_table[key],content_table[key]);
    }
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
    // content_box[0] にはnullが入っている
    // 他のkeyにはnullは入れない
    final void add_collection(T)(T u)
        in{
        assert(u.table == this);
        assert(cast(ContentCollection)u !is null); // 静的に書き換えたい
        assert(!u.get_box().empty);
        }
    body{
        debug(move) writeln("add_box start");

        set_id(u);
        auto box_id = u.id();
        auto box = u.get_box();
        foreach(c; box)
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
    final bool try_create_in(T:ContentBOX)(T u,Cell c)
        in{
        }
    body{
        if(c in keys) return false;

        if(!u.id()) set_id(u);
        auto box_id = u.id();
        type_table[box_id] = u.toString;
        auto range = u.get_range();
        keys[c] = box_id;
        content_table[box_id] = u;
        return true;
    }
    final void add_box(T:ContentBOX)(T u)
        in{
        assert(u.table == this);
        assert(u !is null);
        assert(cast(ContentBOX)u !is null); // 静的に書き換えたい
        assert(!u.get_box().empty);
        }
    body{
        debug(move) writeln("add_box start");

        set_id(u);
        auto box_id = u.id();
        auto box = u.get_box();
        foreach(r; box[0].get())
        foreach(c; box[1].get())
        {
            keys[Cell(r,c)] = box_id;
        }
        type_table[box_id] = u.toString;
        collection_table[box_id] = u;

        assert(box_id in content_table);
        assert(box_id in type_table);
        debug(table){
            writeln("type: ",u.toString);
            writeln("table key(box_id): ",box_id);
            writeln("boxes are: ",u.get_box());
        }
    }
    final void add_box(T:Collection)(T u)
            in{
            assert(u.table == this);
            assert(u !is null);
            assert(cast(Collection)u !is null); // 静的に書き換えたい
            assert(!u.empty);
            }
        body{
            debug(move) writeln("add_box start");

            set_id(u);
            auto box_id = u.id();
            auto box = u.get_cells();
            foreach(c; box)
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

    Tuple!(string,CellContent) get_content(const Cell c){
        int key;
        debug(move) if(c !in keys) writeln("this cell is empty, no content return");
        if(c !in keys)
            return tuple("none",content_table[0]);
        else
            key = keys[c];
        if(key !in content_table) assert(0);
        return get_content(key);
    }
    final void remove_content_edge(CellContent box,const Direct dir,int width=1){
        while(width--)
        {
            auto edge = box.edge_line[dir];
            foreach(c; edge)
            {
                // assert(c in keys); // <- 1マスCellが引っかかる
                keys.remove(c);
            }
        }
        // if(box.empty()) throw exception
    }
    // Tableに登録されたBOXは、自身の変形が可能か
    // Tableに尋ねる。そのためのmethod。prefix: 
    //      分ける必要のある要件があったら統一して分離させる
    final bool try_expand(CellContent cb,const Direct to,int width=1){
        debug(move) writeln("expand box start");
        auto id = cb.id();
        auto edge = cb.edge_line[to];
        debug(move) writeln("edge ",edge);
        Cell[] tobe_expanded;
        if(cb.empty()) return false;
        foreach(c; edge) // just check
        {
            while(width--)
            {
                auto the_cell = c.if_moved(to);
                tobe_expanded ~= the_cell;
                if(the_cell in keys)
                { 
                    debug(move) writeln("not expanded");
                    return false;
                }
            }
        }
        foreach(c; tobe_expanded)
        {
            keys[c] = id;
        }
        if(id !in content_table)
            content_table[id] = cb;

        debug(table) writeln("expanded");
        return true;
    }
    // 移動できたらtrue そうでなければfalse
    // boxの整形は呼び出し側の責任
    final bool try_move(CellContent cb,const Direct to,int width=1){
            if(try_expand(cb,to,width))
            {
                while(width--)
                {
                    foreach(c; cb.edge_line[reverse(to)])
                        keys.remove(c);
                }
                return true;
            }else
                return false;
    }
    final bool try_remove(CellContent u)
    body{
        if(!u.is_to_spoil()) return false;

        auto content_cells = u.get_cells();
        auto box_id = u.id();
        debug(cell) writefln("keys are:%s",keys);
        debug(cell) writefln("boxes are:%s",content_cells);
        foreach(c; content_cells)
        {
             assert(c in keys);
             keys.remove(c);
        }
        content_table.remove(box_id);
        type_table.remove(box_id);

        assert(keys.keys.empty || !keys.values.is_in(box_id));
        return true;
    }
    unittest{
        auto cb = new RangeBOX(Cell(0,0),5,5);
        cb.move(Direct.up);
        assert(cb.top_left == Cell(0,0));
        assert(cb.numof_col == 5);
        assert(cb.numof_row == 4);
        assert(cb.bottom_right == Cell(3,4));
        assert(cb.min_row == 0);
        assert(cb.min_col == 0);
        assert(cb.max_row == 3);
        assert(cb.max_col == 4);

        cb = new RangeBOX(Cell(0,0),5,5);
        cb.remove(Direct.up);
        writeln(cb.top_left);
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
    final void shift(const Cell o){
        debug(refer) writeln("shift start");
        int[Cell] new_key;
        foreach(c,id; keys)
        {
            assert(id in content_table);
            new_key[c+o] = id;
        }
        keys = new_key;
        foreach(content; content_table)
        {
            if(content is null
                    || content.empty()) continue; // content_table[0]
            debug(refer) writeln("null test through");
            debug(refer) writefln("o: %s\n ",o);
            content.require_move(o);
        }
        debug(refer) writeln("shift end");
    }
    final void clear(){
        keys.clear();
        type_table.clear();
        content_table.clear();
    }
    final bool is_vacant(Cell c)const{
        return cast(bool)(c !in keys);
    }
    final bool has(Cell c)const{
        return cast(bool)(c in keys);
    }
    @property bool empty()const{
        return keys.keys.empty();
    }

}

abstract class Collection : CellContent{
private:
    BoxTable table;
    CellCollection _inner_cc;
    int _content_id;
protected:
    invariant(){
        assert(table !is null);
    }
public:
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
        _inner_cc = new CellCollection();
    }
    this(Collection cb){
        if(!_inner_cc.empty())
            table.add_box(this);
    }
    bool require_create_in(const Cell c){
        if(table.is_vacant(c))
        {
            _inner_cc.create_in(c);
            table.add_box(this);
            return true;
        }
        return false;
    }
    bool require_move(const Direct to){
        debug(move){
            writeln("ContentCollection::move start");
        }
        if(table.try_move(this,to))
        {
            _inner_cc.move(to);
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
    bool expand(const Direct to,int width=1){
        if(table.try_expand(this,to,width))
        {
            _inner_cc.expand(to,width);
            return true;
        }else return false;
    }
    void remove(const Direct dir,int width =1){
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
    void set_id(int id){
        _content_id = id;
    }
    @property bool empty()const{
        return _inner_cc.empty();
    }
}

