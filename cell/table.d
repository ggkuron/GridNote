module cell.table;

import cell.cell;
import cell.rangecell;
import cell.collection;
import cell.contentbox;
import cell.contentflex;
public import cell.textbox;
public import cell.imagebox;
import std.typecons;
import std.traits;
import util.direct;
import util.array;
import util.span;
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

    alias Span RowSpan;
    alias Span ColSpan;
    int _grid_size;

    CellContent[KEY] _content_table;
    TextBOX[KEY] _text_table;
    ImageBOX[KEY] _image_table;
    string[KEY] _type_table;
    KEY[Cell] _keys;
    KEY[RangeCell] _box_keys; // ContentBOXだけcacheしとく
    Cell[][Direct][KEY] _box_edges;

    int _content_counter;
    void set_id(CellContent c){
        if(_content_counter == int.max)
        {   // throw exception
            assert(0);
        }
        // 0は欠番にしておく
        c.set_id(++_content_counter);
    }
    bool cell_forward(ref Cell start,in Cell end){
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
    // 矩形的に取り出す
    int[] ranged_keys(in Cell start,in Cell end)const{
        int[int] ranged_keys;
        Cell itr = start;
        auto max_range = end;
        while(1)
        {
            if(itr in _keys)
            {
                auto cells_key = _keys[itr];
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
    // ContentBOXは形状SpanBOXを
    // ContentFlexは形状Cell[]をTableに保存するので
    // 形状操作はContentBOXに向かって発行されるが
    // ContentBOXは要求をTableに回す
        // Tableに向かって操作を要求してもいいが、
        // 操作には対象がまず存在するので、
        // 対象に向かって要求した方がわかりやすいかと思ったから
        // どうなるか
public:
    final void remove_content_edge(CellContent box,in Direct dir,in int width=1){
        int w = width;
        while(w--)
        {
            auto edge = box.edge_line[dir];
            foreach(c; edge)
            {
                // assert(c in _keys); // <- 1マスCellが引っかかる
                _keys.remove(c);
            }
            box.remove(dir);
        }
        // if(box.empty()) throw exception?
    }
    final bool try_expand(ContentBOX cb,in Direct to,in int width=1)
        in{
        assert(cb.id in _content_table);
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
                if(c in _keys)
                { 
                    debug(move) writeln("not expanded");
                    return false;
                }
                added_cells ~= c;
            }
        }
        foreach(c; added_cells)
        {
            _keys[c] = id;
        }

        cb.expand(to,width);
        debug(table) writeln("expanded");
        return true;
    }
    final bool try_expand(ContentFlex cf,in Direct to,int width=1){
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
            if(the_cell in _keys)
            { 
                debug(move) writeln("not expanded");
                return false;
            }
        }
        foreach(c; tobe_expanded)
        {
            _keys[c] = id;
        }

        cf.expand(to,width);

        debug(table) writeln("expanded");
        return true;
    }
 
    // 移動できたらtrue そうでなければfalse
    // boxの整形もTableが行う。呼び出し元は成功したとき整形されている。
    final bool try_move(T:CellContent)(T cb,in Direct to,in int width=1){
        immutable id = cb.id();
        int w = width;
        if(try_expand(cb,to,w))
        {
            while(w--)
            {
                foreach(c; cb.edge_line[reverse(to)])
                    _keys.remove(c);
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
        debug(table) writefln("keys are:%s",_keys);
        debug(table) writefln("boxes are:%s",content_cells);
        foreach(c; content_cells)
        {
             _keys.remove(c);
        }
        _content_table.remove(box_id);
        _type_table.remove(box_id);

        // assert(keys.keys.empty || !keys.values.is_in(box_id));
        return true;
    }
    unittest{
        import cell.textbox;
        auto table = new BoxTable();
        auto cb = new TextBOX(table,Cell(0,0),5,5);
        cb.move(Direct.up);
        // 何もしない
        assert(cb.top_left == Cell(0,0));
        import std.stdio;
        writeln(cb.numof_col);
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
    // Table全体を返す。
    Tuple!(string,CellContent)[] get_all_contents(){
         
        Tuple!(string,CellContent)[] result;
        foreach(k; _keys)
        {
            if(k==0) continue;
            assert(k in _type_table);
            assert(k in _content_table);
            result ~=tuple(_type_table[k],_content_table[k]);
        }
        return result;
    }
    Tuple!(string,CellContent)[] get_contents(in Cell start,in Cell end){
         
        Tuple!(string,CellContent)[] result;
        auto _keys = ranged_keys(start,end);
        debug(table) writeln("ranged _keys are ",_keys);
        foreach(k; _keys)
        {
            if(k==0) continue;
            assert(k in _type_table);
            assert(k in _content_table);
            result ~=tuple(_type_table[k],_content_table[k]);
        }
        return result;
    }
    TextBOX[] get_textBoxes(){
        return _text_table.values;
    }
    ImageBOX[] get_imageBoxes(){
        return _image_table.values;
    }
    TextBOX[] get_textBoxes(in Cell s,in Cell e){
        auto _keys = ranged_keys(s,e);
        TextBOX[] result;
        foreach(k; _keys)
            if(k in _text_table)
            result ~= _text_table[k];
        return result;
    }
    ImageBOX[] get_imageBoxes(in Cell s,in Cell e){
        auto _keys = ranged_keys(s,e);
        ImageBOX[] result;
        foreach(k; _keys)
            if(k in _image_table)
            result ~= _image_table[k];
        return result;
    }

    bool is_hold(in Cell c){
        foreach(cb ; _content_table.values)
            if(cb.is_hold(c)) return true;
        if(c in _keys)
            return true;
        return false;
    }
    int[] get_boxkeys_first_by_row(in Cell start,in Cell end){
        Cell c = start;
        int[int] dupled_result;
        foreach(range,bkey; _box_keys)
        {
            if(range.is_hold(c))
                dupled_result[bkey] = bkey;
            if(!cell_forward(c,end)) 
                return dupled_result.values;
        }
        assert(dupled_result.values.empty());
        return dupled_result.values; //empty;
    }
    int[] get_boxkeys_first_by_col(in Cell start,in Cell end){
        Cell c = start;
        int[int] dupled_result;
        foreach(range,bkey; _box_keys)
        {
            if(range.is_hold(c))
                dupled_result[bkey] = bkey;
            if(!cell_forward(c,end)) 
                return dupled_result.values;
        }
        assert(dupled_result.values.empty());
        return dupled_result.values; //empty;
    }
    Tuple!(string,CellContent) get_content(in int key)
        in{
        assert(_keys.values.is_in(key));
        assert(key in _content_table);
        }
    body{
        return tuple(_type_table[key],_content_table[key]);
    }
    this(){ // 実際には使われてはいけないかもしれない
        _content_table[0] = null;
        _type_table[0] = "none";
    }
    this(in int gridS){
        _grid_size = gridS;
        _content_table[0] = null;
        _type_table[0] = "none";
    }
    this(BoxTable r,in int gridS){
        _content_table = r._content_table;
        _type_table = r._type_table;
        _keys = r._keys;
        this(gridS);
    }
    invariant(){
        assert(_content_table[0] is null);
        assert(_type_table[0] == "none");
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
            _keys[c] = box_id;
        }
        _type_table[box_id] = u.toString;
        _content_table[box_id] = u;

        assert(box_id in _content_table);
        assert(box_id in _type_table);
        debug(table){
            writeln("type: ",u.toString);
            writeln("table key(box_id): ",box_id);
            writeln("boxes are: ",u.get_box());
        }
    }
    final bool try_create_in(T:ContentBOX)(T u,in Cell c)
    body{
        if(has(c)) return false;
        if(!u.is_registered()) set_id(u);
        immutable box_id = u.id();

        _keys[c] = box_id;
        _type_table[box_id] = u.toString;
        _box_keys[u.grab_range()] = box_id;
        foreach(dir; EnumMembers!Direct)
        {
            _box_edges[box_id][dir] ~= c;
        }

        _content_table[box_id] = u;
        static if(is(T == TextBOX)) _text_table[box_id] = u;
        else 
        static if(is(T == ImageBOX)) _image_table[box_id] = u;
        u.create_in(c);
        writeln("table:",_content_table.values);
        writeln("text:",_text_table.values);
        writeln("image:",_image_table.values);

        return true;
    }

    final bool try_create_in(T:ContentFlex)(T u,in Cell c)
    body{
        if(has(c)) return false;
        if(!u.id) set_id(u);
        immutable box_id = u.id();

        _keys[c] = box_id;
        _type_table[box_id] = u.toString;
        _content_table[box_id] = u;
        foreach(dir; EnumMembers!Direct)
        {
            _box_edges[box_id][dir] ~= c;
        }
        u.create_in(c);
        import std.stdio;
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
        assert(u.id in _content_table);
        assert(u.id in _type_table);
        assert(u.id in _box_keys);
        }
    body{
        debug(move) writeln("add_box start");
        if(!u.id()) set_id(u);
        immutable box_id = u.id();
        auto box = u.get_box();
        foreach(r; box[0].get())
        foreach(c; box[1].get())
        {
            _keys[Cell(r,c)] = box_id;
        }
        _box_keys[u.get_range()] = box_id;
        _type_table[box_id] = u.toString;
        collection_table[box_id] = u;

        debug(table)
        {
            foreach(edge; _box_edges)
                assert(edge.empty());
        }
        _box_edges[Direct.right] ~= u.all_in_col[u.max_col];
        _box_edges[Direct.left] ~= u.all_in_col[u.min_col];
        _box_edges[Direct.up] ~= u.all_in_row[u.min_row];
        _box_edges[Direct.down] ~= u.all_in_row[u.max_row];

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
            _keys[c] = box_id;
        }
        _type_table[box_id] = u.toString;
        _content_table[box_id] = u;

        assert(box_id in _content_table);
        assert(box_id in _type_table);
        debug(table){
            writeln("type: ",u.toString);
            writeln("table key(box_id): ",box_id);
        }
    }
    // 1Cellだけの情報が欲しいとき。入っていなくてもとりあえず欲しい時。
    Tuple!(string,CellContent) get_content(in Cell c){
        int key;
        debug(move) if(c !in _keys) writeln("this cell is empty, no content return");
        if(c !in _keys)
            return tuple("none",_content_table[0]);
        else
            key = _keys[c];
        assert(key in _content_table);
        return get_content(key);
    }
    // 見た目的な正方向にだけしかshiftできない
    // table上の全てのcontentのキーと実体を動かす
   final void shift(in Cell o){
        debug(refer) writeln("shift start");
        int[Cell] new_key;
        foreach(c,id; _keys)
        {
            assert(id in _content_table);
            new_key[c+o] = id;
        }
        _keys = new_key;
        foreach(content; _content_table)
        {
            if(content is null
                    || content.empty()) continue; // _content_table[0]
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
        _keys.clear();
        _type_table.clear();
        _content_table.clear();
    }
    final bool is_vacant(in Cell c)const{
        return cast(bool)(c !in _keys);
    }
    final bool has(in Cell c)const{
        return cast(bool)(c in _keys);
    }
    @property bool empty()const{
        return _keys.keys.empty();
    }
    @property int grid_size()const{
        return _grid_size;
    }
    // RangeCellのopCmpの設計がされてない
    // @property Cell max_cell()const{
    //     if(_box_keys.keys.empty) return Cell(0,0);
    //     return _box_keys.keys.sort[$].bottom_right;
    // }
}


