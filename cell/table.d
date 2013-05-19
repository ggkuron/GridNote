module cell.table;

import cell.cell;
import cell.rangecell;
// import cell.rangebox;
import cell.collection;
import cell.contentbox;
import cell.contentflex;
import std.typecons;
import util.direct;
import util.array;
import util.range;
import cell.contentbox;
import cell.collection;

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
    KEY[Cell] keys;
    KEY[RangeCell] box_keys; // ContentBOXだけcacheしとく
    Cell[][Direct][KEY] box_edges;

    int _content_counter;
    void set_id(CellContent c){
        if(_content_counter == int.max)
        {   // throw exception
            assert(0);
        }
        // 0は欠番にしておく
        c.set_id(++_content_counter);
    }
    bool cell_forward(ref Cell start,const Cell end){
        if(start.column == end.column)
        {
            if(start.row == end.row)
            {
                return false;
            }
            else 
            {
                start.column = 0;
                ++start.row;
            }
        }else ++start.column;
        return true;
    }
package:
    Tuple!(string,CellContent)[] get_contents(Cell start,Cell end){
         
        Tuple!(string,CellContent)[] result;
        auto keys = ranged_keys(start,end);
        debug(table) writeln("ranged keys are ",keys);
        foreach(k; keys)
        {
            if(k==0) continue;
            assert(k in type_table);
            assert(k in content_table);
            result ~=tuple(type_table[k],content_table[k]);
        }
        return result;
    }
    int[] ranged_keys(Cell start,const Cell end)const{
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

    // CellContentからの要求でのみ行う操作
    // ContentBOXは形状RangeBOXを
    // ContentFlexは形状Cell[]をTableに保存するので
    // 形状操作はContentBOXに向かって発行されるが
    // ContentBOXは要求をTableに回す
        // Tableに向かって操作を要求してもいいが、
        // 操作には対象がまず存在するので、
        // 対象に向かって要求した方がわかりやすいかと
public:
    final void remove_content_edge(CellContent box,const Direct dir,const int width=1){
        int w = width;
        while(w--)
        {
            auto edge = box.edge_line[dir];
            foreach(c; edge)
            {
                // assert(c in keys); // <- 1マスCellが引っかかる
                keys.remove(c);
            }
            box.remove(dir);
        }
        // if(box.empty()) throw exception
    }
    final bool try_expand(ContentBOX cb,const Direct to,const int width=1)
        in{
        assert(cb.id in content_table);
        }
    body{
        if(to == Direct.left && cb.min_col==0
        || to == Direct.up && cb.min_row == 0)
            return false;
        debug(move) writeln("expand box start");
        immutable id = cb.id();
        int w = width;
        debug(move) writeln("edge ",edge);
        if(cb.empty()) return false;
        Cell[] added_cells;
        while(w--)
        {
            auto edge = cb.edge_forward_cells(to);
            foreach(c; edge) // just check
            {
                if(c in keys)
                { 
                    debug(move) writeln("not expanded");
                    return false;
                }
                added_cells ~= c;
            }
        }
        foreach(c; added_cells)
        {
            keys[c] = id;
        }

        cb.expand(to,width);
        debug(table) writeln("expanded");
        return true;
    }
    final bool try_expand(ContentFlex cf,const Direct to,int width=1){
        debug(move) writeln("expand box start");
        immutable id = cf.id();
        debug(move) writeln("edge ",edge);
        Cell[] tobe_expanded;
        if(cf.empty()) return false;
        while(width--)
        foreach(c; cf.edge_line[to]) // just check
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

        cf.expand(to,width);

        debug(table) writeln("expanded");
        return true;
    }
 
    // 移動できたらtrue そうでなければfalse
    // boxの整形は呼び出し側の責任
    final bool try_move(T:CellContent)(T cb,const Direct to,const int width=1){
        immutable id = cb.id();
        int w = width;
        if(try_expand(cb,to,w))
        {
            while(w--)
            {
                foreach(c; cb.edge_line[reverse(to)])
                    keys.remove(c);
            }
            cb.remove(to.reverse,width);
            return true;
        }else
            return false;
    }
    final bool try_remove(CellContent u)
    body{
        if(!u.is_to_spoil()) return false;

        auto content_cells = u.get_cells();
        immutable box_id = u.id();
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
        import cell.textbox;
        auto table = new BoxTable();
        auto cb = new TextBOX(table,Cell(0,0),5,5);
        cb.move(Direct.up);
        // 何もしない
        assert(cb.top_left == Cell(0,0));
        assert(cb.numof_col == 5);
        assert(cb.numof_row == 5);
        assert(cb.bottom_right == Cell(4,4));
        assert(cb.min_row == 0);
        assert(cb.min_col == 0);
        assert(cb.max_row == 4);
        assert(cb.max_col == 4);

        cb = new TextBOX(table,Cell(0,0),5,5);
        cb.remove(Direct.up);
        debug(table) writeln(cb.top_left);
        assert(cb.top_left == Cell(1,0));
        assert(cb.numof_col == 5);
        assert(cb.numof_row == 4);
        debug(table) writeln("num_row:",cb.numof_row);
        debug(table) writeln("row:",cb.grab_range().row.get());
        debug(table) writeln("col:",cb.grab_range().col.get());
        assert(cb.bottom_right == Cell(4,4));
        debug(table) writeln("min_row:",cb.min_row);
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
 
public:
    bool is_hold(Cell c){
        foreach(cb ; content_table.values)
            if(cb.is_hold(c)) return true;
        if(c in keys)
            return true;
        return false;
    }
    int[] get_boxkeys_first_by_row(const Cell start,const Cell end){
        Cell c = start;
        int[int] dupled_result;
        foreach(range,bkey; box_keys)
        {
            if(range.is_hold(c))
                dupled_result[bkey] = bkey;
            if(!cell_forward(c,end)) 
                return dupled_result.values;
        }
        assert(dupled_result.values.empty());
        return dupled_result.values; //empty;
    }
    int[] get_boxkeys_first_by_col(const Cell start,const Cell end){
        Cell c = start;
        int[int] dupled_result;
        foreach(range,bkey; box_keys)
        {
            if(range.is_hold(c))
                dupled_result[bkey] = bkey;
            if(!cell_forward(c,end)) 
                return dupled_result.values;
        }
        assert(dupled_result.values.empty());
        return dupled_result.values; //empty;
    }
    // Table全体を返す。これは保存時に使うつもり
    Tuple!(string,CellContent) get_content(int key)
        in{
        assert(keys.values.is_in(key));
        assert(key in content_table);
        }
    body{
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
    final void add_collection(T:ContentFlex)(T u)
        in{
        assert(u.table == this);
        assert(cast(ContentCollection)u !is null); // 静的に書き換えたい
        assert(!u.get_box().empty);
        }
    body{
        debug(move) writeln("add_box start");

        set_id(u);
        immutable box_id = u.id();
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
    final bool try_create_in(T:ContentBOX)(T u,const Cell c)
        in{
        }
    body{
        if(c in keys || has(c)) return false;
        if(!u.id()) set_id(u);
        immutable box_id = u.id();

        keys[c] = box_id;
        type_table[box_id] = u.toString;
        box_keys[u.grab_range()] = box_id;
        foreach(i; Direct.min .. Direct.max+1)
        {
            box_edges[box_id][cast(Direct)i] ~= c;
        }

        content_table[box_id] = u;
        u.create_in(c);
        return true;
    }
    final bool try_create_in(T:ContentFlex)(T u,const Cell c)
        in{
        }
    body{
        if(c in keys || has(c)) return false;
        if(!u.id()) set_id(u);
        immutable box_id = u.id();

        keys[c] = box_id;
        type_table[box_id] = u.toString;
        content_table[box_id] = u;
        foreach(i; Direct.min .. Direct.max+1)
        {
            box_edges[box_id][cast(Direct)i] ~= c;
        }

        u.create_in(c);
        return true;
    }

    final void add_box(T:ContentBOX)(T u)
        in{
        assert(u.table == this);
        assert(u !is null);
        assert(cast(ContentBOX)u !is null); // 静的に書き換えたい
        assert(!u.get_box().empty);
        }
        out{
        assert(u.id in content_table);
        assert(u.id in type_table);
        assert(u.id in box_keys);
        }
    body{
        debug(move) writeln("add_box start");
        if(!u.id()) set_id(u);
        immutable box_id = u.id();
        auto box = u.get_box();
        foreach(r; box[0].get())
        foreach(c; box[1].get())
        {
            keys[Cell(r,c)] = box_id;
        }
        box_keys[u.get_range()] = box_id;
        type_table[box_id] = u.toString;
        collection_table[box_id] = u;

        debug(table)
        {
            foreach(edge; box_edges)
                assert(edge.empty());
        }

        box_edges[Direct.right] ~= u.all_in_col[u.max_col];
        box_edges[Direct.left] ~= u.all_in_col[u.min_col];
        box_edges[Direct.up] ~= u.all_in_row[u.min_row];
        box_edges[Direct.down] ~= u.all_in_row[u.max_row];

        debug(table){
            writeln("type: ",u.toString);
            writeln("table key(box_id): ",box_id);
            writeln("boxes are: ",u.get_box());
        }
    }
    final void add_box(T:Collection)(T u)
            in{
            assert(u !is null);
            assert(!u.empty);
            }
    body{
        debug(move) writeln("add_box start");

        if(!u.id()) set_id(u);
        immutable box_id = u.id();
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
        }
    }
    // 1Cellだけの情報が欲しいとき。入っていなくてもとりあえず欲しい時。
    Tuple!(string,CellContent) get_content(const Cell c){
        int key;
        debug(move) if(c !in keys) writeln("this cell is empty, no content return");
        if(c !in keys)
            return tuple("none",content_table[0]);
        else
            key = keys[c];
        assert(key in content_table);
        return get_content(key);
    }
    // 見た目的な正方向にだけしかshiftできない
    // table上の全てのcontentのキーと実体を動かす
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
            content.move(o);
        }
        debug(refer) writeln("shift end");
    }
    void shift(in Direct dir)
        in{
        assert(dir.is_positive);
        }
    body{
        if(dir == Direct.right)
            shift(Cell(0,1));
        else // if(dir == Direct.down)
            shift(Cell(1,0));
    }
    final void clear(){
        keys.clear();
        type_table.clear();
        content_table.clear();
    }
    final bool is_vacant(const Cell c)const{
        return cast(bool)(c !in keys);
    }
    final bool has(const Cell c)const{
        return cast(bool)(c in keys);
    }
    @property bool empty()const{
        return keys.keys.empty();
    }
}


