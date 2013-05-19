module manip;

import util.direct;
import cell.textbox;
import cell.cell;
import cell.table;
import cell.select;
import cell.contentbox;
import command.command;
import gui.pageview;
debug(manip) import std.stdio;

enum focus_mode{ normal,select,edit }

// 全てのCMDに対して
// 全てのCMDを実行するためのハブ
// 操作は細分化しているのに、それをCMDで全部捌いているのが問題だと思ったならそうすべき
// 複合的な操作は現在思いつかないのでこのままにする
// このコメントを消そうとするときに考える

// Table に関する操作
   // ここからCellBOXに対する操作も行う
   // 表示位置の移動ってここでやってしまおうか
   // 指示棒をここがもってるから
final class ManipTable{
private:
    BoxTable focused_table;
    CellContent maniped_box;
    PageView _pv;
    string box_type;

    ManipTextBOX manip_textbox;
public:
    focus_mode mode;
    // Selectはここで持つべきか否か
    SelectBOX select;
    this(BoxTable table,PageView p)
        out{
        assert(focused_table);
        assert(manip_textbox);
        assert(select);
        }
    body{
        focused_table = table;
        select = new SelectBOX(focused_table);

        manip_textbox = new ManipTextBOX(this);
        _pv =  p;
    }
    void move_focus(Direct dir){
        auto focus = select.focus();
        const max_view = _pv.get_view_max();
        if((!focus.column && dir == Direct.left)
        || (!focus.row && dir == Direct.up)
        || (focus.column >= max_view.column && dir==Direct.right )
        || (focus.row >= max_view.row && dir==Direct.down ))
        {
            import std.stdio;
            debug(manip) writeln("focus ",focus);
            debug(manip) writeln("max ",max_view);

            _pv.move_view(dir.reverse);
            select.move(dir);
        }
        else
            select.move(dir);
        debug(manip) writefln("focus: %s",select.focus);
    }
    CellContent get_target(){
        return maniped_box;
    }
    void start_select()
        in{
        assert(mode != focus_mode.select);
        }
        out{
        assert(mode == focus_mode.select);
        }
    body{
        mode = focus_mode.select;
        select.set_pivot();
    }
    @property auto targetbox(){
        switch(box_type){
            case "cell.textbox.TextBOX":
                return cast(TextBOX)maniped_box;
            default:
                return null;
        }
    }
    // 端点にfocusがあればexpand, そうでなくてもfocusは動く
    void expand_if_on_edge(Direct dir){
        if(select.is_on_edge(dir))
        {
            expand_select(dir);
        }
        move_focus(dir);
    }
    void expand_to_focus()
        in{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
        out{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
    body{
        select.expand_to_focus();
    }
    void expand_select(Direct dir)
        in{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
        out{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
    body{
        select.expand(dir);
    }
    void grab_selectbox(){
        auto target = focused_table.get_content(select.focus);
        box_type = target[0];
        maniped_box = target[1];
    }
    void move_selected(Direct to)
        in{
        assert(mode==focus_mode.normal);
        }
        out{
        assert(mode==focus_mode.normal);
        }
    body{
        auto target = focused_table.get_content(select.focus)[1];
        if(target is null) return;
        else{
            if(target.top_left.row == 0 && to == Direct.up)
            {
                // focused_table.shift(Cell(1,0));
                _pv.move_view(to);
                target.require_move(to);
            }
            else if(target.top_left.column == 0 && to == Direct.left)
            {
                // focused_table.shift(Cell(0,1));
                _pv.move_view(to);
                target.require_move(to);
            }
            else if(target.bottom_right.row == _pv.get_view_max().row && to == Direct.down)
            {
                _pv.move_view(to);
                target.require_move(to);
            }
            else if(target.bottom_right.column == _pv.get_view_max().column && to==Direct.right)
            {
                _pv.move_view(to);
                target.require_move(to);
            }
            else if(target.require_move(to))
                move_focus(to);
        }
    }
    void delete_selected()
        in{
        assert(mode==focus_mode.normal);
        }
        out{
        assert(mode==focus_mode.normal);
        }
    body{
        auto target = focused_table.get_content(select.focus);
        if(target[1] is null) return;
        else{
            target[1].remove_from_table();
        }
    }
    void return_to_normal_mode()
        in{
        assert(mode==focus_mode.select || mode==focus_mode.edit);
        }
        out{
        assert(mode == focus_mode.normal);
        }
    body{
        debug(manip) writeln("return to normal start");
        mode = focus_mode.normal;
        if(maniped_box !is null)
        {   // maniped_box.is_to_spoil == false なら削除されない
            focused_table.try_remove(maniped_box);
        }
        select.clear();
        debug(manip) writeln("returned");
    }
    void start_insert_normal_text(){
        debug(manip) writeln("start_insert_normal_text");
        mode = focus_mode.edit;
        if(focused_table.has(select.focus)) return;
        auto tb = select.create_TextBOX();

        maniped_box = tb;
        debug(manip) writeln("type in: ",tb.toString());
        box_type = tb.toString();

        debug(manip) writeln("end");
    }
    void im_commit_to_box(string str){
        debug(manip) writeln("send to box start with :",str);
        if(mode!=focus_mode.edit) return;
        manip_textbox.with_commit(str,targetbox);
    }
    void backspace(){
        debug(manip) writeln("back space start");
        switch(box_type){
            case "cell.textbox.TextBOX":
                manip_textbox.backspace(cast(TextBOX)maniped_box);
                return;
            default:
                break;
        }
    }
    void text_feed(){
        if(box_type == "cell.textbox.TextBOX")
        manip_textbox.feed(cast(TextBOX)maniped_box);
    }
    void edit_textbox(){
        if(box_type != "cell.textbox.TextBOX") return;
        mode = focus_mode.edit;
    }
}

import gtk.IMMulticontext;
import gtk.IMContext;

final class ManipTextBOX {
    ManipTable manip_table;
    IMMulticontext imm;
    this(ManipTable mt){
        manip_table = mt;
    }
    void move_caret(TextBOX box, Direct dir){
        final switch(dir){
            case Direct.right:
                box.move_caretR(); return;
                break;
            case Direct.left:
                box.move_caretL(); return;
                break;
            case Direct.up:
                box.move_caretU(); return;
                break;
            case Direct.down:
                box.move_caretD(); return;
                break;
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
