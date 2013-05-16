module cell.table;

import cell.cell;
import cell.collection;
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
    alias Tuple!(RowRange,ColRange) BoxRange;

    ContentBOX[KEY] box_table;
    ContentCollection[KEY] collection_table;
    string[KEY] type_table;

    BoxRange[KEY] box_range; 
    Cell[][KEY] collection;

    KEY[Cell] collection_keys;
    KEY[BoxRange] box_keys;

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
    bool is_in(Cell c){
        foreach(br; box_table.values)
            if(br.is_in(c)) return true;
        if(c in collection_keys)
            return true;
        return false;
    }
    int get_boxkey_first_by_row(Cell c)const{
        foreach(k,bk; box_keys.keys)
        {
            if(bk[0].is_in(c))
                if(bk[1].is_in(c))
                    return k;
            else return 0;
        }
    }
    int get_boxkey_first_by_col(Cell c)const{
        foreach(k,bk; box_keys.keys)
        {
            if(bk[1].is_in(c))
                if(bk[0].is_in(c))
                    return k;
            else return 0;
        }
    }
    BoxRange get_boxrange(int key){
        assert(key in box_body);
        return box_range[key];
    }
    Cell[] get_collection(int key){
        assert(key in collection_body);
        return collection[key];
    }
    Tuple!(string,CellStructure) get_content(int key){
        assert(key in keys.values);
        if(key in box_table)
            return tuple(type_table[key],box_table[key]);
        else if(key in collection_table)
            return tuple(type_table[key],collection_table[key]);
        else assert(0);
    }
    this(){
        box_table[0] = null;
        type_table[0] = "none";
        collection_table[0] = null;
    }
    this(BoxTable r){
        box_table = r.box_table;
        type_table = r.type_table;
        keys = r.keys;
        this();
    }
    invariant(){
        assert(box_table[0] is null);
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
        box_table[box_id] = u;

        assert(box_id in box_table);
        assert(box_id in type_table);
        debug(table){
            writeln("type: ",u.toString);
            writeln("table key(box_id): ",box_id);
            writeln("boxes are: ",u.get_box());
        }
    }
    final bool try_create_in(T)(T u,Cell c)
        in{
        assert(u.table == this);
        assert(cast(ContentBOX)u !is null); // 静的に書き換えたい
        }
    body{
        if(c in keys) return false;

        if(!u.id()) set_id(u);
        auto box_id = u.id();
        type_table[box_id] = u.toString;
        // keys[c] = box_id;
        auto range = u.get_range();
        box_keys[range] = box_id;
        box_range[box_id] = range;
        box_table[box_id] = u;
        return true;
    }
    final void add_box(T)(T u)
        in{
        assert(u.table == this);
        assert(u !is null);
        assert(cast(ContentBOX)u !is null); // 静的に書き換えたい
        assert(!u.get_box().empty);
        }
    body{
        debug(move) writeln("add_box start");

        set_id(u);
        auto box_id = u.box_id();
        auto box = u.get_box();
        foreach(r; box[0].get())
        foreach(c; box[1].get())
        {
            keys[Cell(r,c)] = box_id;
        }
        type_table[box_id] = u.toString;
        collection_table[box_id] = u;

        assert(box_id in box_table);
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
            return tuple("none",box_table[0]);
        else
            key = keys[c];
        if(key !in box_table) assert(0);
        return get_content(key);
    }
    Tuple!(string,ContentBOX) get_box(const Cell c){
        int key;
        debug(move) if(c !in keys) writeln("this cell is empty, no content return");
        if(c !in keys)
            return tuple("none",box_table[0]);
        else
            key = keys[c];
        if(key !in box_table) assert(0);
        return tuple(type_table[key],box_table[key]);
    }
    Tuple!(string,ContentCollection) get_collection(const Cell c){
        int key;
        debug(move) if(c !in keys) writeln("this cell is empty, no content return");
        if(c !in keys)
            return tuple("none",box_table[0]);
        else
            key = keys[c];
        if(key !in collection_table) assert(0);
        return tuple(type_table[key],box_table[key]);
    }
    final void remove_content_edge(ContentBOX box,const Direct dir){
        auto edge = box.edge_line[dir];
        foreach(c; edge)
        {
            // assert(c in keys); // <- 1マスCellが引っかかる
            keys.remove(c);
        }
        // if(box.empty()) throw exception
    }
    // Tableに登録されたBOXは、自身の変形が可能か
    // Tableに尋ねる。そのためのmethod。prefix: 
    //      分ける必要のある要件があったら統一して分離させる
    final bool try_expand(ContentBOX box,const Direct to,int width){
        debug(move) writeln("expand box start");
        auto id = box.box_id();
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
        if(id !in box_table)
            box_table[id] = box;

        debug(table) writeln("expanded");
        return true;
    }
    final bool try_expand(ContentCollection cc,const Direct to,int width){
        debug(move) writeln("expand box start");
        auto id = cc.id();
        auto edge = cc.edge_line[to];
        debug(move) writeln("edge ",edge);
        Cell[] tobe_expanded;
        if(box.empty()) return false;
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
        if(id !in box_table)
            box_table[id] = box;

        debug(table) writeln("expanded");
        return true;
    }
    // 移動できたらtrue そうでなければfalse
    // boxの整形は呼び出し側の責任
    final bool try_move(ContentCollection cc,const Direct to,int width){
            if(try_expand(cc,to,width))
            {
                while(width--)
                {
                    foreach(c; cc.edge_line[reverse(to)])
                        keys.remove(c);
                }
                return true;
            }else
                return false;
    }
    final bool try_remove(ContentBOX u)
        in{
        assert(u.table == this);
        }
    body{
        if(!u.is_to_spoil()) return false;

        auto content_cells = u.get_box();
        auto box_id = u.box_id();
        debug(cell) writefln("keys are:%s",keys);
        debug(cell) writefln("boxes are:%s",content_cells);
        foreach(c; content_cells)
        {
             assert(c in keys);
             keys.remove(c);
        }
        box_table.remove(box_id);
        type_table.remove(box_id);

        assert(keys.keys.empty || !keys.values.is_in(box_id));
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
            assert(id in box_table);
            new_key[c+o] = id;
        }
        keys = new_key;
        foreach(content; box_table)
        {
            if(content is null
                    || content.empty()) continue; // box_table[0]
            debug(refer) writeln("null test through");
            debug(refer) writefln("o: %s\n ",o);
            content.move(o);
        }
        debug(refer) writeln("shift end");
    }
    final void clear(){
        keys.clear();
        type_table.clear();
        box_table.clear();
    }
    final bool is_vacant(Cell c)const{
        return cast(bool)(c !in keys);
    }
    final bool has(Cell c)const{
        return cast(bool)(c in keys);
    }
    @property int content_id()const{
        return _content_id;
    }

}

abstract class ContentCollection : CellCollection{
private:
    BoxTable table;
    alias CellBOX.create_in create_in;
    alias CellBOX.expand expand;
    alias CellBOX.move move;
    int _content_id;
protected:
    invariant(){
        assert(table !is null);
    }
public:
    this(BoxTable attach, ContentCollection taken)
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
    this(ContentCollection cb){
        super(cb);
        if(!box.empty())
            table.add_box(this);
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
            writeln("ContentCollection::move start");
        }
        if(table.try_move(this,to))
        {
            CellBOX.move(to);
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
        if(table.try_expand(this,to))
        {
            super.expand(to);
            return true;
        }else return false;
    }
    void require_remove(const Direct dir){
        table.remove_content_edge(this,dir);
        super.remove(dir);
    }
    void remove_from_table(){
        spoiled = true;
        auto result = table.try_remove(this);
        assert(result);
    }
    // 削除対象かいなか
    private bool spoiled;
    bool is_to_spoil(){
        debug(cell) writeln(spoiled, box.empty());
        return spoiled || box.empty();
    };
    int id()const{ return _content_id; }
    void set_id(int id){
        if(id_counter == int.max){
            // throw exception
            assert(0);
        }
        _content_id = id;
    }
}

