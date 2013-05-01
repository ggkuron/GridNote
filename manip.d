module manip;

import misc.direct;
import cell.textbox;
import cell.cell;
import command.command;
import gui.gui;
debug(manip) import std.stdio;

enum focus_mode{ normal,select,edit }

// 全てのCMDに対して
// 適切に捌く
// 全てのCMDを実行するためのハブ
// class Manipulater が存在してもいいかも
// 操作は細分化しているのに、それをCMDで全部捌いているのが問題だと思ったならそうすべき
// 複合的な操作は現在思いつかないのでこのままにする
// このコメントを消そうとするときに考えて欲しい

// Table に関する操作
   // ここからCellBOXに対する操作も行う
   // その責任は分離すべき
class ManipTable{
    BoxTable focused_table;
    ContentBOX focused_box;

    ManipTextBOX manip_textbox;

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
    // 端点にfocusがあればexpand, そうでなくてもfocusは動く
    final void expand_if_on_edge(Direct dir){
        if(select.is_on_edge(dir))
        {
            expand_select(dir);
        }
        move_focus(dir);
    }
    final void expand_to_focus()
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
    void return_to_normal_mode()
        in{
        assert(mode == focus_mode.select);
        }
        out{
        assert(mode == focus_mode.normal);
        }
    body{
        select.clear();
        mode = focus_mode.normal;
    }
    void start_insert_normal_text(){
        debug(manip) writeln("start_insert_normal_text");
        mode = focus_mode.edit;
        auto tb = select.create_TextBOX();
        manip_textbox.start_input(tb);
        debug(manip) writeln("end");
    }
}

import gtk.IMMulticontext;

class ManipTextBOX {
    ManipTable manip_table;
    IMMulticontext imm;
    this(ManipTable mt){
        manip_table = mt;
    }
    void move_caret(TextBOX box, Direct dir){
        final switch(dir){
            case Direct.right:
                box.move_caretR(); return;
            case Direct.left:
                box.move_caretL(); return;
            case Direct.up:
                box.move_caretU(); return;
            case Direct.down:
                box.move_caretD(); return;
        }
        assert(0);
    }
    void start_input(TextBOX box){
        // move the focus on the table 
        //  to acoord with caret positon

    }
}
