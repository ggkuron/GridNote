module cell.table;

import cell.cell;
import std.typecons;
import util.direct;
import util.array;

debug(cell) import std.stdio;
debug(move) import std.stdio;
debug(table) import std.stdio;
debug(refer) import std.stdio;

class BoxTable{
private:
    ContentBOX[int] content_table;
    string[int] type_table;
    int[Cell] keys;
protected:
public:
    auto refer_content_table(){
        return content_table;
    }
    auto refer_type_table(){
        return type_table;
    }
    auto refer_keys()const{
        return keys;
    }
    auto get_content(int key){
        // 継承先はこのTableのkeyを知れるのでcheckはあまく
        // 特定のContent idを指定しては呼び出さないだろうと仮定しているということ
        assert(keys.values.is_in(key));
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
    // content_box[0] にはnullが入っているが
    // 他のkeyにはnullは入らない
    final void add_box(T)(T u)
        in{
        assert(u.table == this);
        assert(u !is null);
        assert(cast(ContentBOX)u !is null); // 静的に書き換えたい
        assert(!u.get_box().empty);
        }
    body{
        debug(move) writeln("add_box start");

        auto box_id = u.box_id();
        auto box = u.get_box();
        foreach(r; box[0].get())
        foreach(c; box[1].get())
        {
            keys[Cell(r,c)] = box_id;
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
    Tuple!(string,ContentBOX) get_content(const Cell c){
        int key;
        debug(move) if(c !in keys) writeln("this cell is empty, no content return");
        if(c !in keys)
            return tuple("none",content_table[0]);
        else
            key = keys[c];
        return tuple(type_table[key],content_table[key]);
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
    // 可能なときには処理も行なってしまう
    //      分ける必要のある要件があったら統一して分離させる
    final bool tryto_expand(ContentBOX box,const Direct to){
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
        if(id !in content_table)
            content_table[id] = box;

        debug(table) writeln("expanded");
        return true;
    }
    // 移動できたらtrue そうでなければfalse
    // boxの整形は呼び出し側の責任
    final bool tryto_move(ContentBOX box,const Direct to){
        if(tryto_expand(box,to))
        {
            foreach(c; box.edge_line[reverse(to)])
                keys.remove(c);
            return true;
        }else
            return false;
    }
    final bool tryto_remove(ContentBOX u)
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
        content_table.remove(box_id);
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
            content.move(o);
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
}

abstract class ContentBOX : CellBOX{
private:
    BoxTable table;
protected:
    invariant(){
        assert(table !is null);
    }
public:
    this(BoxTable attach, ContentBOX taken)
        out{
        assert(table !is null);
        }
    body{
        table = attach;
        super(taken);
    }
    this(BoxTable attach)
        out{
        assert(table !is null);
        }
    body{
        table = attach;
    }
    this(ContentBOX cb){
        super(cb);
        if(!box.empty())
            table.add_box(this);
    }
    alias CellBOX.create_in create_in;
    alias CellBOX.expand expand;
    alias CellBOX.move move;

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
            writeln("ContentBOX::move start");
        }
        if(table.tryto_move(this,to))
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
        assert(cb.top_left == Cell(3,3));
        assert(cb.bottom_right == Cell(3,4));
        cb.move(Direct.right);
        assert(cb.top_left == Cell(3,4));
        assert(cb.bottom_right == Cell(3,5));
        cb.move(Direct.up);
        assert(cb.top_left == Cell(2,4));
        assert(cb.bottom_right == Cell(2,5));
        debug(cell) writeln("#### TableBOX unittest end ####");
    }
    // 実行できたかどうかは知りたい
    bool require_expand(const Direct to){
        if(table.tryto_expand(this,to))
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
        auto result = table.tryto_remove(this);
        assert(result);
    }
    // 削除対象かいなか
    private bool spoiled;
    bool is_to_spoil(){
        debug(cell) writeln(spoiled, box.empty());
        return spoiled || box.empty();
    };
}


