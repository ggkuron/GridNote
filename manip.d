module manip;

import util.direct;
import util.color;
import cell.textbox;
import cell.cell;
import cell.table;
import cell.select;
import cell.contentbox;
import command.command;
import gui.pageview;

import gtk.FileChooserDialog;

import std.array;
debug(manip) import std.stdio;

enum focus_mode{ normal,select,edit }

// Tableに対する操作
// 操作は細分化しているのに、それをCMDで全部捌いているのが問題だと思ったならそうすべき
// 複合的な操作は現在思いつかないのでこのままにする
// CMDは指示を投げるだけってことをやるかってこと
// このコメントを消そうとするときに考える

// Table に関する操作
   // ここからCellBOXに対する操作も行う
   // 表示位置の移動ってここでやってしまおうか
   // 指示棒をここがもってるから
final class ManipTable{
private:
    BoxTable _focused_table;
    CellContent _maniped_box;
    CellContent[] _old_state;
    PageView _pv;
    SelectBOX _select;
    focus_mode _mode;

    Color _selected_color;
    string _box_type;
    ManipTextBOX _manip_textbox;
public:
    this(BoxTable table,PageView p)
        out{
        assert(_focused_table);
        assert(_manip_textbox);
        assert(_select);
        }
    body{
        _focused_table = table;
        _select = new SelectBOX(_focused_table);

        _manip_textbox = new ManipTextBOX(this);
        _pv =  p;
    }
    void move_focus(in Direct dir){
        immutable focus = _select.focus();
        immutable max_view = _pv.get_view_max();
        immutable min_view = _pv.get_view_min();
        if((focus.column <= min_view.column && dir == Direct.left)
        || (focus.row <= min_view.row && dir == Direct.up)
        || (focus.column >= max_view.column && dir==Direct.right )
        || (focus.row >= max_view.row && dir==Direct.down ))
        {
            debug(manip) writeln("focus ",focus);
            debug(manip) writeln("max ",max_view);

            _pv.move_view(dir);
            _select.move(dir);
        }
        else
            _select.move(dir);
        debug(manip) writefln("focus: %s",_select.focus);
    }
    CellContent get_target(){
        return _maniped_box;
    }
    void change_mode_select()
        in{
        assert(_mode != focus_mode.select);
        }
        out{
        assert(_mode == focus_mode.select);
        }
    body{
        _mode = focus_mode.select;
        _select.set_pivot();
    }
    @property auto targetbox(){
        switch(_box_type){
            case "cell.textbox.TextBOX":
                return cast(TextBOX)_maniped_box;
            default:
                return null;
        }
    }
    // 端点にfocusがあればexpand, そうでなくてもfocusは動く
    void expand_if_on_edge(Direct dir){
        if(_select.is_on_edge(dir))
        {
            expand_select(dir);
        }
        move_focus(dir);
    }
    // moveとCMD単位で分離したかったが、
    // 初回の切り分けが複雑になるのでこうなった
    // 必要ならexpand_to_focus()書いてそれをCMD化すればいい
    void expand_to_focus(in Direct dir)
        out{
        assert(_mode==focus_mode.select || _mode==focus_mode.edit);
        }
    body{
        if(_mode == focus_mode.normal)
        {
            change_mode_select();
        }
        move_focus(dir);
        _select.expand_to_focus();
    }
    void expand_select(Direct dir)
        in{
        assert(_mode==focus_mode.select || _mode==focus_mode.edit);
        }
        out{
        assert(_mode==focus_mode.select || _mode==focus_mode.edit);
        }
    body{
        _mode = focus_mode.select;
        _select.expand(dir);
    }
    void delete_selected_area(){
        auto select_min = _select.top_left;
        auto select_max = _select.bottom_right;
        auto selected = _focused_table.get_contents(select_min,select_max);
        foreach(box; selected)
        {
            box[1].remove_from_table();
        }
    }
    void grab_selectbox(){
        auto target = _focused_table.get_content(_select.focus);
        _box_type = target[0];
        _maniped_box = target[1];
    }
    void move_selected(in Direct to)
    body{
        auto target = _focused_table.get_content(_select.focus)[1];
        immutable view_min = _pv.get_view_min();
        immutable view_max = _pv.get_view_max();
        if(target is null) return;
        else{
            if(target.top_left.row <= view_min.row && to == Direct.up)
            {   // viewを動かしたあとそれに合わせるためにmoveする
                // このrequire_moveは必ず通る
                _pv.move_view(to);
                target.require_move(to);
                    move_focus(to);
                if(!view_min.row)
                    _select.move(to.reverse);
            }
            else if(target.top_left.column <= view_min.column && to == Direct.left)
            {
                _pv.move_view(to);
                target.require_move(to);
                    move_focus(to);
                if(!view_min.column)
                     _select.move(to.reverse);
            }
            else if(target.bottom_right.row >= view_max.row && to == Direct.down)
            {   // 
                _pv.move_view(to);
                if(target.require_move(to))
                    move_focus(to);
            }
            else if(target.bottom_right.column >= view_max.column && to==Direct.right)
            {
                _pv.move_view(to);
                if(target.require_move(to))
                    move_focus(to);
            }
            else if(target.require_move(to)
                 || target.top_left.column == view_min.column && to == Direct.left
                 || target.top_left.row == view_min.row && to == Direct.up)
               _select.move(to);
        }
    }
    void delete_selected()
    body{
        auto target = _focused_table.get_content(_select.focus);
        if(target[1] is null) return;
        else{
            target[1].remove_from_table();
        }
    }
    void change_mode_normal()
        out{
        assert(_mode == focus_mode.normal);
        }
    body{
        debug(manip) writeln("return to normal start");
        _mode = focus_mode.normal;
        if(_maniped_box !is null)
        {   // _maniped_box.is_to_spoil == false なら削除されない
            _focused_table.try_remove(_maniped_box);
        }
        _select.selection_clear();
        debug(manip) writeln("returned");
    }
    void change_mode_edit()
        out{
        assert(_mode == focus_mode.edit);
        }
    body{
        _mode = focus_mode.edit;
    }
    void create_TextBOX(){
        debug(manip) writeln("start_insert_normal_text");
        _mode = focus_mode.edit;
        if(_focused_table.has(_select.focus)) return;
        auto tb = _select.create_TextBOX();

        _maniped_box = tb;
        debug(manip) writeln("type in: ",tb.toString());
        _box_type = tb.toString();

        debug(manip) writeln("end");
    }
//    void select_file(){
//        auto filechooserD = new FileChooserDialog(null);
//        filechooserD.run();
//        // filechooserD.getFile();
//        filechooserD.showAll();
//    }
    void select_color(in Color c){
        _selected_color = c;
    }
    Color get_SelectedColor()const{
        return _selected_color;
    }
    void create_CircleBOX(in Color c){
        debug(manip) writeln("@@@@ start create_ImageBOX @@@@");
        _mode = focus_mode.edit;
        if(_focused_table.has(_select.focus)) return;
        auto ib = _select.create_CircleCell(c,_pv);

        _maniped_box = ib;
        _box_type = ib.toString();
        debug(manip) writeln("#### end create_ImageBOX ####");
    }
    void create_RectBOX(in Color c){
        debug(manip) writeln("@@@@ start create_ImageBOX @@@@");
        _mode = focus_mode.edit;
        if(_focused_table.has(_select.focus)) return;
        auto ib = _select.create_RectCell(c,_pv);

        _maniped_box = ib;
        _box_type = ib.toString();
        debug(manip) writeln("#### end create_ImageBOX ####");
    }
    void im_commit_to_box(string str){
        debug(manip) writeln("send to box start with :",str);
        if(_mode!=focus_mode.edit) return;
        
        _old_state ~= _maniped_box;
        _manip_textbox.with_commit(str,targetbox);
    }
    void backspace(){
        debug(manip) writeln("back space start");
        _old_state ~= _maniped_box;
        switch(_box_type){
            case "cell.textbox.TextBOX":
                _manip_textbox.backspace(cast(TextBOX)_maniped_box);
                return;
            default:
                return;
        }
    }
    void text_feed(){
        auto tb = cast(TextBOX)_maniped_box;
        _old_state ~= new TextBOX(_focused_table,tb);
        if(_box_type == "cell.textbox.TextBOX")
        _manip_textbox.feed(tb);
    }
    void edit_textbox(){
        _old_state ~= _maniped_box;
        if(_box_type != "cell.textbox.TextBOX") return;
    }
    void undo(){
        if(!_old_state.empty())
        _maniped_box = _old_state[$-1];
    }
    // アクセサ
    const(SelectBOX) select()const{
        return _select;
    }
    focus_mode mode()const{
        return _mode;
    }
}

import gtk.IMMulticontext;
import gtk.IMContext;

final class ManipTextBOX {
    // ManipTable _manip_table;
    // IMMulticontext _imm;
    // 上2つ使ってないかもしれない
    // manip_table渡してしまったらどうして分離してるのかわからない
    this(ManipTable mt){
        //_manip_table = mt;
    }
    void move_caret(TextBOX box, Direct dir){
        final switch(dir){
            case Direct.right:
                box.move_caretR(); return;
                return;
            case Direct.left:
                box.move_caretL(); return;
                return;
            case Direct.up:
                box.move_caretU(); return;
                return;
            case Direct.down:
                box.move_caretD(); return;
                return;
        }
        assert(0);
    }
    void insert(TextBOX box,string str){
        debug(manip) writeln("text insert strat");
        box.insert(str);
        move_caret(box,Direct.right);
        debug(manip) writeln("end");
    }
    void with_commit(string str,TextBOX box){
        debug(manip) writeln("with commit text");
        insert(box,str);
    }
    void backspace(TextBOX box){
        box.backspace();
    }
    void feed(TextBOX box){
        box.move_caretD();
    }
}
