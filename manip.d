module manip;

import misc.direct;
import cell.textbox;
import cell.cell;
import command.command;
import gui.gui;
debug(manip) import std.stdio;

enum focus_mode{ normal,select,edit }

// 全てのCMDに対して
// 全てのCMDを実行するためのハブ
// 操作は細分化しているのに、それをCMDで全部捌いているのが問題だと思ったならそうすべき
// 複合的な操作は現在思いつかないのでこのままにする
// このコメントを消そうとするときに考える
// どうしたかはcommit messageに書くべきだと思われる


// Table に関する操作
   // ここからCellBOXに対する操作も行う
   // その責任は分離すべき
final class ManipTable{
private:
    BoxTable focused_table;
    ContentBOX maniped_box;
    string box_type;

    ManipTextBOX manip_textbox;

public:
    focus_mode mode;
    SelectBOX select;
    this(BoxTable table)
        out{
        assert(focused_table);
        assert(manip_textbox);
        assert(select);
        }
    body{
        focused_table = table;
        select = new SelectBOX(focused_table);

        manip_textbox = new ManipTextBOX(this);
    }
    void move_focus(Direct dir){
        import std.stdio;
        select.move(dir);
        debug(manip) writefln("focus: %s",select.focus);
    }
    ContentBOX get_target(){
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
    void select_clear(){
        select.clear();
    }
    @property auto targetbox(){
        switch(box_type){
            case "cell.textbox.TextBOX":
                return cast(TextBOX)maniped_box;
            default:
                assert(0);
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
    void move_selected(Direct to)
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
            target[1].move(to);
            select.move(to);
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
        if(maniped_box !is null && maniped_box.is_to_spoil)
        {
            focused_table.remove(maniped_box);
            debug(manip) writeln("REMOVED empty box from table");
        }
        select.clear();
        debug(manip) writeln("returned");
    }
    void start_insert_normal_text(){
        debug(manip) writeln("start_insert_normal_text");
        mode = focus_mode.edit;
        auto tb = select.create_TextBOX();

        maniped_box = tb;
        focused_table.add_box!(TextBOX)(tb);
        debug(manip) writeln("type in: ",tb.toString());
        box_type = tb.toString();

        debug(manip) writeln("end");
    }
    void im_commit_to_box(string str){
        debug(manip) writeln("send to box start with :",str);
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
