module command.command;

import std.array;

import manip;
import env;
import util.direct;
import gdk.Keysyms; // Keysyms
import gdk.Event;
import gtk.Widget;
import gui.pageview;
// import gtkc.gdktypes;  // ModifierType
import gtk.IMMulticontext;
import command.keycombine;
debug(cmd) import std.stdio;
private import stdlib = core.stdc.stdlib : exit;

// すべての実行可能な操作
// 直通。TODO:各機構との調停を挟む
// COMMANDの粒度を細くして、組み合わせて使う方向で
abstract class COMMAND{
private:
    const(KeyCombine)[] keys;
public:
    void execute();
    final void regester_key(in KeyCombine ckc){
        keys ~= ckc;
    }
    final bool is_regestered(in KeyCombine kc)const{
        foreach(k; keys)
            if(k == kc)
                return true;
        return false;
    }
    final void clear(){
        keys.clear();
    }
}

interface AtomCMD{
    void execute();
}

COMMAND cmd_template(alias func_body)(InputInterpreter i,ManipTable m,PageView p){
    return new CMD!(func_body)(i,m,p);
}
class CMD(alias func_body) : COMMAND, AtomCMD{
private:
    ManipTable manip;
    PageView view;
    InputInterpreter inp;
    KeyCombine[] kb;
public:
    this(InputInterpreter i,ManipTable m,PageView p){
        inp = i;
        manip = m;
        view = p;
    }
    final void execute(){
        mixin (func_body);
    }
}
class combined_COMMAND : COMMAND{
// private:
    AtomCMD[] commands;
    this(COMMAND[] cmds...){
        foreach(cmd; cmds)
        {
            auto casted = cast(AtomCMD)cmd;
            debug(cmd) writeln("composed ",cmd);
            commands ~= casted;
            assert(casted);
        }
        debug(cmd){
            foreach(cmd; commands)
            {
                assert(cmd !is null);
            }
        }
    }
    final void execute(){
        foreach(cmd; commands)
        {
            debug(cmd) writeln("exec: ",cmd);
            cmd.execute();
        }
    }
}

enum InputState{normal,edit,select};
final class InputInterpreter{
immutable preserve_length = 1;
private:
    InputState _input_state = InputState.normal;
    ManipTable manip;
    PageView view;
    IMMulticontext imm;

    uint[] keyState;
    uint modState;
    bool im_driven;
    COMMAND[KeyCombine][InputState] command_table;

    COMMAND move_focus_l;
    COMMAND move_focus_r;
    COMMAND move_focus_d;
    COMMAND move_focus_u;
    COMMAND expand_select_pivot;
    COMMAND toggle_grid_show;
    COMMAND toggle_boxborder_show;

    COMMAND grab_target;
    COMMAND move_selected_r;
    COMMAND move_selected_l;
    COMMAND move_selected_u;
    COMMAND move_selected_d;
    COMMAND delete_selected;
    COMMAND manip_undo;
    COMMAND manip_mode_normal;
    COMMAND manip_mode_edit;
    COMMAND manip_mode_select;
    COMMAND input_mode_normal;
    COMMAND input_mode_select;
    COMMAND input_mode_edit;
    COMMAND mode_normal;
    COMMAND mode_edit;
    COMMAND mode_select;
    COMMAND quit;

    COMMAND create_TextBOX;
    COMMAND text_backspace;
    COMMAND text_feed;
    COMMAND im_focus_in;
    COMMAND im_focus_out;
    COMMAND text_edit;

    // combined_COMMAND
    COMMAND edit_to_normal_state; 
    COMMAND normal_start_edit_text;
    COMMAND normal_edit_textbox;

    void regester_key(COMMAND cmd, InputState state, KeyCombine ckc){
        cmd.regester_key(ckc);
        // 重複してはいけない
        debug(cmd) writeln("regest ",cmd);
        debug(cmd) writeln("state ",state);
        debug(cmd) writefln("kc %s \n",ckc);

        assert(command_table.keys.empty || state !in command_table 
                || command_table[state].keys.empty 
                || ckc !in command_table[state]); // <- KeyConfig実装するときにException飛ばす,もしくは上書きするためにtableから現在のKeyCombineを消して
        command_table[state][ckc] = cmd;
    }
    void control_input(){
        debug(cmd) writeln(keyState);
        parse_input();

        // debug(cmd) writefln("table is: \n%s",command_table);
        // debug(cmd) writeln("parsed ",kc);
        // interpret(kc);
        execute();
        view.queueDraw();
    }
    // 状態遷移前の状態でCMDを登録する必要
    // preserve_length == 3でとりあえず決め打ちしてるの直す
    //  key_to_cmd の内側に統合しても良いのでは
    void parse_input(){

        KeyCombine input;
        if(modState & ModifierType.CONTROL_MASK)
            input = KeyCombine(ModifierType.CONTROL_MASK,keyState);
        else if(modState & ModifierType.SHIFT_MASK)
            input = KeyCombine(keyState);
        else
            input = KeyCombine(keyState);
        debug(cmd) writeln("input: ",input);
        // debug(cmd) writeln("state: ",_input_state);
        // debug(cmd) writeln("state in: ",command_table[_input_state].keys);
        
        if(input in command_table[_input_state])
        {
            debug(cmd) writeln("parsed: ",input);
            keyState.clear();
            add_to_queue(command_table[_input_state][input]);
        }else if(!modState)
            keyState.clear();

        debug(cmd) writeln("INVALID ");
    }
public:
    this(ManipTable m,PageView pv,IMMulticontext im){
        manip = m;
        imm = im;
        view = pv;

        move_focus_l = cmd_template!("manip.move_focus(Direct.left);")(this,manip,view);
        move_focus_r = cmd_template!("manip.move_focus(Direct.right);")(this,manip,view);
        move_focus_d = cmd_template!("manip.move_focus(Direct.down);")(this,manip,view);
        move_focus_u = cmd_template!("manip.move_focus(Direct.up);")(this,manip,view);
        regester_key(move_focus_l,InputState.normal,default_MOVE_FOCUS_L);
        regester_key(move_focus_r,InputState.normal,default_MOVE_FOCUS_R);
        regester_key(move_focus_u,InputState.normal,default_MOVE_FOCUS_U);
        regester_key(move_focus_d,InputState.normal,default_MOVE_FOCUS_D);

        expand_select_pivot = cmd_template!("manip.expand_to_focus();")(this,manip,view);
        regester_key(expand_select_pivot,InputState.select,default_SELECT_PIVOT_L);
        regester_key(expand_select_pivot,InputState.select,default_SELECT_PIVOT_R);
        regester_key(expand_select_pivot,InputState.select,default_SELECT_PIVOT_U);
        regester_key(expand_select_pivot,InputState.select,default_SELECT_PIVOT_D);

        // expand_select_l = cmd_template!("manip.expand_if_on_edge(Direct.left);")(this,manip,view);
        // expand_select_r = cmd_template!("manip.expand_if_on_edge(Direct.right);")(this,manip,view);
        // expand_select_d = cmd_template!("manip.expand_if_on_edge(Direct.down);")(this,manip,view);
        // expand_select_u = cmd_template!("manip.expand_if_on_edge(Direct.up);")(this,manip,view);

        toggle_grid_show = cmd_template!("view.toggle_grid_show();")(this,manip,view);
        regester_key(toggle_grid_show,InputState.normal,default_TOGGLE_GRID_RENDER);
        regester_key(toggle_grid_show,InputState.edit,default_TOGGLE_GRID_RENDER);
        toggle_boxborder_show = cmd_template!("view.toggle_boxborder_show();")(this,manip,view);
        regester_key(toggle_boxborder_show,InputState.normal,default_TOGGLE_BOX_BORDER_RENDER);

        manip_undo = cmd_template!("manip.undo();")(this,manip,view);
        regester_key(manip_undo,InputState.edit,default_UNDO);
        delete_selected = cmd_template!("manip.delete_selected();")(this,manip,view);
        regester_key(delete_selected,InputState.normal,default_BOX_DELETE);

        move_selected_r = cmd_template!("manip.move_selected(Direct.right);")(this,manip,view);
        move_selected_l = cmd_template!("manip.move_selected(Direct.left);")(this,manip,view);
        move_selected_u = cmd_template!("manip.move_selected(Direct.up);")(this,manip,view);
        move_selected_d = cmd_template!("manip.move_selected(Direct.down);")(this,manip,view);
        regester_key(move_selected_r,InputState.normal,default_MOVE_BOX_R);
        regester_key(move_selected_l,InputState.normal,default_MOVE_BOX_L);
        regester_key(move_selected_u,InputState.normal,default_MOVE_BOX_U);
        regester_key(move_selected_d,InputState.normal,default_MOVE_BOX_D);

        create_TextBOX = cmd_template!("manip.create_TextBOX();")(this,manip,view);
        // regester_key(manip_start_insert_normal_text,InputState.normal,default_INSERT);
        im_focus_out = cmd_template!("inp.imm.focusOut();")(this,manip,view);

        // 内部使用
        // mode遷移はもっと包んだ方が良さそう
        // ModifierKeyとModeは括りつけない方がいいと確信した
        input_mode_edit = cmd_template!("inp.change_mode_edit();")(this,manip,view);
        input_mode_normal = cmd_template!("inp.change_mode_normal();")(this,manip,view);
        input_mode_select = cmd_template!("inp.change_mode_select();")(this,manip,view);
        // regester_key(mode_select,InputState.normal,control_key);
        manip_mode_normal = cmd_template!("manip.change_mode_normal();")(this,manip,view);
        manip_mode_select = cmd_template!("manip.change_mode_select();")(this,manip,view);
        manip_mode_edit = cmd_template!("manip.change_mode_edit();")(this,manip,view);
        // regester_key(manip_mode_normal,InputState.all,default_MODE_NORMAL);

        quit = cmd_template!("stdlib.exit(0);")(this,manip,view);
        grab_target = cmd_template!("manip.grab_selectbox();")(this,manip,view);

        text_backspace = cmd_template!("manip.backspace();")(this,manip,view);
        regester_key(text_backspace,InputState.edit,backspace);
        text_feed = cmd_template!("manip.text_feed();")(this,manip,view);
        regester_key(text_feed,InputState.edit,return_key);
        text_edit = cmd_template!("manip.edit_textbox();")(this,manip,view);
        im_focus_in = cmd_template!("inp.imm.focusIn();")(this,manip,view);
        // combined_COMMAND
        // 状態の遷移が含まれるものが多いので呼び出し元のprefix適当につけてる
        // KeyCombineに状態も包含してもいいかも
        //  名前が表すものではなくなるが

        // 状態遷移はInterpreterの関数内で閉じ込める。具体的にはchange_input_modeでやることにする
        // のでedit_to_normal_state は消して,書きなおすの
        // 明日はここから
        //  つまり、edit_to_normal_state と input_mode_normal を統合
        // regester_key(edit_to_normal_state,InputState.edit,default_EDIT_TO_NORMAL);
        normal_edit_textbox = new combined_COMMAND(grab_target,text_edit,im_focus_in);
        regester_key(normal_edit_textbox,InputState.normal,default_EDIT);
        normal_start_edit_text = new combined_COMMAND(input_mode_edit,create_TextBOX,im_focus_in);
        regester_key(normal_start_edit_text,InputState.normal,default_INSERT);

        mode_normal = new combined_COMMAND(input_mode_normal,manip_mode_normal);
        mode_edit = new combined_COMMAND(input_mode_edit,manip_mode_edit);
        mode_select = new combined_COMMAND(input_mode_select,manip_mode_select);
        regester_key(mode_normal,InputState.normal,escape_key);
        regester_key(mode_normal,InputState.select,escape_key);
        regester_key(mode_normal,InputState.edit,escape_key);
        regester_key(mode_normal,InputState.normal,alt_escape);
        regester_key(mode_normal,InputState.select,alt_escape);
        regester_key(mode_normal,InputState.edit,alt_escape);

    }
    bool key_to_cmd(Event event, Widget w)
        in{
        assert(event.key() !is null);
        }
    body{
        auto ev = event.key();
        debug(key){
            writeln("im_driven: ",im_driven);
            writeln("key is ",ev.keyval);
            writeln("mod is ",ev.state);
            writefln("str is %s",*(ev.string));
            writeln("input state ",_input_state);
        }
        final switch(_input_state){
            case InputState.edit:
                im_driven = cast(bool)imm.filterKeypress(ev);
                debug(cmd) writeln(im_driven);
                // if(im_driven) return true;
                // else fall through
            case InputState.normal:
            case InputState.select:
                keyState ~= ev.keyval;
                modState = ev.state;
                if(keyState.length > preserve_length)
                    keyState = keyState[$-preserve_length .. $];
                control_input();
                break; // ここで使われる値ではない
        }
        debug(cmd) writeln(keyState);
        return true;
    }
    COMMAND[] command_queue;
    void add_to_queue(COMMAND[] cmds ...){
        foreach(cmd; cmds)
        {
            command_queue ~= cmd;
        }
    }
    // void change_input_mode(InputState istate){
    //     _input_state = istate;
    // }

public:
    void change_mode_normal(){
        final switch(_input_state){
            case InputState.normal:
                imm.focusOut();
                break;
            case InputState.select:
                _input_state = InputState.normal;
                imm.focusOut();
                break;
            case InputState.edit:
                keyState.clear();
                _input_state = InputState.normal;
                imm.focusOut();
                break;
        }
    }
    void change_mode_edit(){
        final switch(_input_state){
           case InputState.normal:
           case InputState.select:
                _input_state = InputState.edit;
                add_to_queue(
                manip_mode_edit,im_focus_in);
                break;
            case InputState.edit:
                break;
        }
    }
    void change_mode_select(){
        final switch(_input_state){
            case InputState.select:
                break;
            case InputState.normal:
            case InputState.edit:
                _input_state = InputState.select;
                add_to_queue(
                manip_mode_select);
                break;
        }
    }
    void execute(){
        foreach(cmd; command_queue)
        {
            debug(cmd) writeln("try exec: ",cmd);
            cmd.execute();
        }
        command_queue.clear();
    }
    @property InputState state()const{
        return _input_state;
    }
}
