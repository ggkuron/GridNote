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
    final void register_key(in KeyCombine ckc){
        keys ~= ckc;
    }
    final bool is_registered(in KeyCombine kc)const{
        foreach(k; keys)
        {
            if(k == kc)
                return true;
        }
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
    final override void execute(){
        mixin (func_body);
    }
}
final class combined_COMMAND : COMMAND,AtomCMD{
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
    override void execute(){
        foreach(cmd; commands)
        {
            debug(cmd) writeln("exec: ",cmd);
            cmd.execute();
        }
    }
}

/+
    TODO
    状態遷移でコマンドが
    埋まってきてしまったので
    分離する
+/

enum InputState{Normal,Edit,CellSelect,ColorSelect};
final class InputInterpreter{
immutable preserve_length = 1;
public:
//  内部使用

//  ユーザー入力に対する
    COMMAND zoom_in;
    COMMAND zoom_out;

    COMMAND move_focus_l;
    COMMAND move_focus_r;
    COMMAND move_focus_d;
    COMMAND move_focus_u;
    COMMAND expand_select_pivot_R;
    COMMAND expand_select_pivot_L;
    COMMAND expand_select_pivot_D;
    COMMAND expand_select_pivot_U;
    COMMAND toggle_grid_show;
    COMMAND toggle_boxborder_show;

    COMMAND grab_target;
    COMMAND move_selected_r;
    COMMAND move_selected_l;
    COMMAND move_selected_u;
    COMMAND move_selected_d;
    COMMAND delete_selected;
    COMMAND delete_selected_area;
    COMMAND manip_undo;
    COMMAND manip_mode_normal;
    COMMAND manip_mode_edit;
    COMMAND manip_mode_select;
    COMMAND manip_mode_point;
    COMMAND input_mode_normal;
    COMMAND input_mode_select;
    COMMAND input_mode_edit;
    COMMAND input_mode_color;
    COMMAND mode_normal;
    COMMAND mode_edit;
    COMMAND mode_select;
    COMMAND quit;

    COMMAND color_select_L;
    COMMAND color_select_R;
    COMMAND color_select_U;
    COMMAND color_select_D;

    COMMAND create_TextBOX;
    COMMAND text_backspace;
    COMMAND text_feed;
    COMMAND im_focus_in;
    COMMAND im_focus_out;
    COMMAND text_edit;
    COMMAND open_imagefile;
    COMMAND create_circle;

    // combined_COMMAND
    COMMAND edit_to_normal_state; 
    COMMAND normal_start_edit_text;
    COMMAND normal_edit_textbox;
    COMMAND mode_edit_from_color_select;
    COMMAND mode_cell_select_from_color_select;
private:
    InputState _input_state = InputState.Normal;
    ManipTable _manip;
    PageView view;
    IMMulticontext imm;

    uint[] keyState;
    uint modState;
    bool im_driven;
    COMMAND[KeyCombine][InputState] command_table;

    void register_key(COMMAND cmd, InputState state, in KeyCombine ckc){
        cmd.register_key(ckc);
        // 重複してはいけない
        import std.stdio;
        writeln("regist ",cmd);
        writeln("state ",state);
        writefln("kc %s \n",ckc);

        // 同一のキーバインドを許さない
        if(!command_table.keys.empty 
                && state in command_table 
                && !command_table[state].keys.empty 
                && ckc in command_table[state]) // <- KeyConfig実装するときにException飛ばす,もしくは上書きするためにtableから現在のKeyCombineを消して
            throw new Exception("alredy used this keycombined");
        command_table[state][ckc] = cmd;
    }
    void control_input(){
        debug(cmd) writeln(keyState);
        parse_input();
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
        _manip = m;
        imm = im;
        view = pv;

        // 内部使用
        // ユーザー入力
        zoom_in = cmd_template!("view.zoom_in();")(this,_manip,view);
        zoom_out = cmd_template!("view.zoom_out();")(this,_manip,view);
        register_key(zoom_in,InputState.Normal,default_ZOOM_IN);
        register_key(zoom_out,InputState.Normal,default_ZOOM_OUT);

        move_focus_l = cmd_template!("manip.move_focus(Direct.left);")(this,_manip,view);
        move_focus_r = cmd_template!("manip.move_focus(Direct.right);")(this,_manip,view);
        move_focus_d = cmd_template!("manip.move_focus(Direct.down);")(this,_manip,view);
        move_focus_u = cmd_template!("manip.move_focus(Direct.up);")(this,_manip,view);
        register_key(move_focus_l,InputState.Normal,default_MOVE_FOCUS_L);
        register_key(move_focus_r,InputState.Normal,default_MOVE_FOCUS_R);
        register_key(move_focus_u,InputState.Normal,default_MOVE_FOCUS_U);
        register_key(move_focus_d,InputState.Normal,default_MOVE_FOCUS_D);

        expand_select_pivot_R = cmd_template!("manip.expand_to_focus(Direct.right);")(this,_manip,view);
        register_key(expand_select_pivot_R,InputState.Normal,default_SELECT_PIVOT_R);
        register_key(expand_select_pivot_R,InputState.CellSelect,default_SELECT_PIVOT_R);
        expand_select_pivot_U = cmd_template!("manip.expand_to_focus(Direct.up);")(this,_manip,view);
        register_key(expand_select_pivot_U,InputState.CellSelect,default_SELECT_PIVOT_U);
        register_key(expand_select_pivot_U,InputState.Normal,default_SELECT_PIVOT_U);
        expand_select_pivot_L = cmd_template!("manip.expand_to_focus(Direct.left);")(this,_manip,view);
        register_key(expand_select_pivot_L,InputState.Normal,default_SELECT_PIVOT_L);
        register_key(expand_select_pivot_L,InputState.CellSelect,default_SELECT_PIVOT_L);
        expand_select_pivot_D = cmd_template!("manip.expand_to_focus(Direct.down);")(this,_manip,view);
        register_key(expand_select_pivot_D,InputState.Normal,default_SELECT_PIVOT_D);
        register_key(expand_select_pivot_D,InputState.CellSelect,default_SELECT_PIVOT_D);
        delete_selected_area = cmd_template!("manip.delete_selected_area();")(this,_manip,view);
        register_key(delete_selected_area,InputState.CellSelect,default_BOX_DELETE);

        toggle_grid_show = cmd_template!("view.toggle_grid_show();")(this,_manip,view);
        register_key(toggle_grid_show,InputState.Normal,default_TOGGLE_GRID_RENDER);
        toggle_boxborder_show = cmd_template!("view.toggle_boxborder_show();")(this,_manip,view);
        register_key(toggle_boxborder_show,InputState.Normal,default_TOGGLE_BOX_BORDER_RENDER);

        manip_undo = cmd_template!("manip.undo();")(this,_manip,view);
        register_key(manip_undo,InputState.Edit,default_UNDO);
        delete_selected = cmd_template!("manip.delete_selected();")(this,_manip,view);
        register_key(delete_selected,InputState.Normal,default_BOX_DELETE);

        move_selected_r = cmd_template!("manip.move_selected(Direct.right);")(this,_manip,view);
        move_selected_l = cmd_template!("manip.move_selected(Direct.left);")(this,_manip,view);
        move_selected_u = cmd_template!("manip.move_selected(Direct.up);")(this,_manip,view);
        move_selected_d = cmd_template!("manip.move_selected(Direct.down);")(this,_manip,view);
        register_key(move_selected_r,InputState.Normal,default_MOVE_BOX_R);
        register_key(move_selected_l,InputState.Normal,default_MOVE_BOX_L);
        register_key(move_selected_u,InputState.Normal,default_MOVE_BOX_U);
        register_key(move_selected_d,InputState.Normal,default_MOVE_BOX_D);

        create_TextBOX = cmd_template!("manip.create_TextBOX();")(this,_manip,view);
        im_focus_out = cmd_template!("inp.imm.focusOut();")(this,_manip,view);
        create_circle = cmd_template!("manip.create_RectBOX();")(this,_manip,view);
        register_key(create_circle,InputState.Normal,default_ImageOpen);
        register_key(create_circle,InputState.Edit,default_ImageOpen);

        // 内部使用
        // mode遷移はもっと包んだ方が良さそう
        // ModifierKeyとModeは括りつけない方がいいと確信した
        input_mode_edit = cmd_template!("inp.change_mode_edit();")(this,_manip,view);
        input_mode_normal = cmd_template!("inp.change_mode_normal();")(this,_manip,view);
        input_mode_select = cmd_template!("inp.change_mode_select();")(this,_manip,view);
        input_mode_color = cmd_template!("inp.change_mode_color();")(this,_manip,view);
        register_key(input_mode_color,InputState.Normal,default_MODE_COLOR);
        register_key(input_mode_color,InputState.Edit,default_MODE_COLOR);
        // register_key(input_mode_color,InputState.CellSelect,default_MODE_COLOR);

        manip_mode_normal = cmd_template!("manip.change_mode_normal();")(this,_manip,view);
        manip_mode_select = cmd_template!("manip.change_mode_select();")(this,_manip,view);
        manip_mode_edit = cmd_template!("manip.change_mode_edit();")(this,_manip,view);
        manip_mode_point = cmd_template!("manip.change_mode_point();")(this,_manip,view);
        register_key(manip_mode_point,InputState.Normal,default_Point);

        color_select_L = cmd_template!("manip.select_color(Direct.left);")(this,_manip,view); 
        color_select_R = cmd_template!("manip.select_color(Direct.right);")(this,_manip,view);
        color_select_U = cmd_template!("manip.select_color(Direct.up);")(this,_manip,view);
        color_select_D = cmd_template!("manip.select_color(Direct.down);")(this,_manip,view);
        register_key(color_select_L,InputState.ColorSelect,default_MOVE_FOCUS_L);
        register_key(color_select_R,InputState.ColorSelect,default_MOVE_FOCUS_R);
        register_key(color_select_U,InputState.ColorSelect,default_MOVE_FOCUS_U);
        register_key(color_select_D,InputState.ColorSelect,default_MOVE_FOCUS_D);

        quit = cmd_template!("stdlib.exit(0);")(this,_manip,view);
        grab_target = cmd_template!("manip.grab_selectbox();")(this,_manip,view);

        text_backspace = cmd_template!("manip.backspace();")(this,_manip,view);
        register_key(text_backspace,InputState.Edit,backspace);
        text_feed = cmd_template!("manip.text_feed();")(this,_manip,view);
        register_key(text_feed,InputState.Edit,return_key);
        text_edit = cmd_template!("manip.edit_textbox();")(this,_manip,view);
        im_focus_in = cmd_template!("inp.imm.focusIn();")(this,_manip,view);
        // combined_COMMAND

        normal_edit_textbox = new combined_COMMAND(grab_target,text_edit,im_focus_in);
        register_key(normal_edit_textbox,InputState.Normal,default_EDIT);
        normal_start_edit_text = new combined_COMMAND(input_mode_edit,create_TextBOX,im_focus_in);
        register_key(normal_start_edit_text,InputState.Normal,default_INSERT);

        mode_normal = new combined_COMMAND(input_mode_normal,manip_mode_normal);
        mode_edit = new combined_COMMAND(input_mode_edit,manip_mode_edit);
        mode_select = new combined_COMMAND(input_mode_select,manip_mode_select);
        register_key(mode_normal,InputState.Normal,escape_key);
        register_key(mode_normal,InputState.Edit,escape_key);
        register_key(mode_normal,InputState.Normal,alt_escape);
        register_key(mode_normal,InputState.Edit,alt_escape);
        mode_edit_from_color_select = new combined_COMMAND(input_mode_edit);
        mode_cell_select_from_color_select = new combined_COMMAND(input_mode_select,manip_mode_select);
        register_key(mode_edit_from_color_select,InputState.ColorSelect,escape_key);
        register_key(mode_edit_from_color_select,InputState.ColorSelect,alt_escape);
        register_key(mode_cell_select_from_color_select,InputState.CellSelect,escape_key);
        register_key(mode_cell_select_from_color_select,InputState.CellSelect,alt_escape);

        // open_imagefile = cmd_template!("manip.select_file();")(this,manip,view);
        // register_key(open_imagefile,InputState.Normal,default_ImageOpen);
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
            case InputState.Edit:
                im_driven = cast(bool)imm.filterKeypress(ev);
                debug(cmd) writeln(im_driven);
                if(im_driven) return true;
                break;
            case InputState.Normal:
            case InputState.CellSelect:
            case InputState.ColorSelect:
                if(im_driven) imm.focusOut();
                break; // ここで使われる値ではない
        }
        keyState ~= ev.keyval;
        modState = ev.state;
        if(keyState.length > preserve_length)
            keyState = keyState[$-preserve_length .. $];
        control_input();

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
    InputState _before_state;
public:
    bool can_edit()const{
        return _input_state == InputState.Edit
            && _manip.mode == FocusMode.edit;
    }
    void change_mode_normal(){
        final switch(_input_state){
            case InputState.Normal:
                imm.focusOut();
                break;
            case InputState.CellSelect:
                _input_state = InputState.Normal;
                imm.focusOut();
                break;
            case InputState.ColorSelect:
                if(_before_state == InputState.Edit)
                {
                    _input_state = InputState.Edit;
                    _before_state = InputState.Normal;
                }else
                {
                    _input_state = InputState.Normal;
                    imm.focusOut();
                }
                break;
            case InputState.Edit:
                keyState.clear();
                _input_state = InputState.Normal;
                imm.focusOut();
                break;
        }
    }
    void change_mode_edit(){
        final switch(_input_state){
           case InputState.Normal:
           case InputState.CellSelect:
            case InputState.ColorSelect:
                _input_state = InputState.Edit;
                // imm.focusIn();
                add_to_queue(
                    manip_mode_edit,im_focus_in
                    );
                break;
            case InputState.Edit:
                break;
        }
    }
    void change_mode_select(){
        final switch(_input_state){
            case InputState.CellSelect:
            case InputState.ColorSelect:
                break;
            case InputState.Normal:
            case InputState.Edit:
                imm.focusOut();
                _input_state = InputState.CellSelect;
                add_to_queue(
                manip_mode_select);
                break;
        }
    }
    void change_mode_color(){
        final switch(_input_state){
            case InputState.ColorSelect:
                break;
            case InputState.CellSelect:
            case InputState.Normal:
            case InputState.Edit:
                imm.focusOut();
                _input_state = InputState.ColorSelect;
                _before_state = InputState.Edit;
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
