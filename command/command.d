module command.command;

import std.array;

import manip;
import env;
import misc.direct;
import gdk.Keysyms; // Keysyms
import gdk.Event;
import gtk.Widget;
import gui.gui;
import gtkc.gdktypes;  // ModifierType
import gtk.IMMulticontext;
debug(cmd) import std.stdio;

// すべての実行可能な操作
// 直通。TODO:各機構との調停を挟む
interface COMMAND{
    void execute();
}
private import stdlib = core.stdc.stdlib : exit;

COMMAND cmd_template(alias func_body)(InputInterpreter i,ManipTable m,PageView p){
    return new CMD!(func_body)(i,m,p);
}
class CMD(alias func_body) : COMMAND{
    private:
    ManipTable manip_table;
    PageView view;
    InputInterpreter interpreter;
    public:
    this(InputInterpreter i,ManipTable m,PageView p){
        interpreter = i;
        manip_table = m;
        view = p;
    }
    final void execute(){
        mixin (func_body);
    }
}

enum InputState{normal,edit,select};
class InputInterpreter{

    ManipTable manip;
    PageView view;
    IMMulticontext imm;

    uint[] keyState;
    uint ModState;
    bool im_driven;

    COMMAND move_box_r;
    COMMAND move_box_l;
    COMMAND move_box_u;
    COMMAND move_box_d;
    COMMAND move_focus_l;
    COMMAND move_focus_r;

    COMMAND move_focus_d ;
    COMMAND move_focus_u ;
    COMMAND expand_select;
    COMMAND expand_select_r;
    COMMAND expand_select_l;
    COMMAND expand_select_d;
    COMMAND expand_select_u;
    COMMAND toggle_grid_show;
    COMMAND toggle_boxborder_show;

    COMMAND move_selected_r;
    COMMAND move_selected_l;
    COMMAND move_selected_u;
    COMMAND move_selected_d;
    COMMAND delete_selected;
    COMMAND manip_mode_normal;
    COMMAND mode_change_to_normal;
    COMMAND quit;

    COMMAND start_insert_normal_text;
    COMMAND start_select_mode;
    COMMAND text_backspace;
    COMMAND text_feed;
    COMMAND im_focusin;
    COMMAND im_focusout;

    InputState input_state = InputState.normal;
    this(ManipTable m,PageView pv,IMMulticontext im){
        manip = m;
        imm = im;
        view = pv;

        move_box_r = cmd_template!("manip_table.get_target().move(Direct.right);")(this,manip,view);
        move_box_l = cmd_template!("manip_table.get_target().move(Direct.left);")(this,manip,view);
        move_box_u = cmd_template!("manip_table.get_target().move(Direct.up);")(this,manip,view);
        move_box_d = cmd_template!("manip_table.get_target().move(Direct.down);")(this,manip,view);
        move_focus_l = cmd_template!("manip_table.move_focus(Direct.left);")(this,manip,view);
        move_focus_r = cmd_template!("manip_table.move_focus(Direct.right);")(this,manip,view);

        move_focus_d = cmd_template!("manip_table.move_focus(Direct.down);")(this,manip,view);
        move_focus_u = cmd_template!("manip_table.move_focus(Direct.up);")(this,manip,view);
        expand_select = cmd_template!("manip_table.expand_to_focus();")(this,manip,view);
        expand_select_l = cmd_template!("manip_table.expand_if_on_edge(Direct.left);")(this,manip,view);
        expand_select_r = cmd_template!("manip_table.expand_if_on_edge(Direct.right);")(this,manip,view);
        expand_select_d = cmd_template!("manip_table.expand_if_on_edge(Direct.down);")(this,manip,view);
        expand_select_u = cmd_template!("manip_table.expand_if_on_edge(Direct.up);")(this,manip,view);
        toggle_grid_show = cmd_template!("view.toggle_grid_show();")(this,manip,view);
        toggle_boxborder_show = cmd_template!("view.toggle_boxborder_show();")(this,manip,view);

        move_selected_r = cmd_template!("manip_table.move_selected(Direct.right);")(this,manip,view);
        move_selected_l = cmd_template!("manip_table.move_selected(Direct.left);")(this,manip,view);
        move_selected_u = cmd_template!("manip_table.move_selected(Direct.up);")(this,manip,view);
        move_selected_d = cmd_template!("manip_table.move_selected(Direct.down);")(this,manip,view);
        delete_selected = cmd_template!("manip_table.delete_selected();")(this,manip,view);
        manip_mode_normal = cmd_template!("manip_table.return_to_normal_mode();")(this,manip,view);
        mode_change_to_normal = cmd_template!("interpreter.input_state = InputState.normal;")(this,manip,view);
        quit = cmd_template!("stdlib.exit(0);")(this,manip,view);

        start_insert_normal_text = cmd_template!("manip_table.start_insert_normal_text();")(this,manip,view);
        start_select_mode = cmd_template!("manip_table.start_select();")(this,manip,view);
        text_backspace = cmd_template!("manip_table.backspace();")(this,manip,view);
        text_feed = cmd_template!("manip_table.text_feed();")(this,manip,view);
        im_focusin = cmd_template!("interpreter.imm.focusIn();")(this,manip,view);
        im_focusout = cmd_template!("interpreter.imm.focusOut();")(this,manip,view);
    }
    public bool key_to_cmd(Event event, Widget w)
        in{
        assert(event.key() !is null);
        }
    body{
        auto ev = event.key();
        debug(cmd) writeln("im_driven: ",im_driven);
        debug(cmd) writeln("key is ",ev.keyval);
        debug(cmd) writeln("mod is ",ev.state);
        debug(cmd) writefln("str is %s",*(ev.string));
        debug(cmd) writeln(imm.getContextId());

        debug(cmd) writeln("input state ",input_state);
        // alias interpreter.input_state input_state;
        final switch(input_state){
            case InputState.edit:
                im_driven = cast(bool)imm.filterKeypress(ev);
                debug(cmd) writeln(im_driven);
                if(im_driven) return true;
                // else fall through
            case InputState.normal:
            case InputState.select:
                immutable preserve_length = 3;
                keyState ~= ev.keyval;
                ModState = ev.state;
                if(keyState.length > preserve_length)
                    keyState = keyState[$-preserve_length .. $];
                control_input();
                break;
        }

        debug(cmd) writeln(keyState);
        return true;
    }
    void control_input(){

        debug(cmd) writeln(keyState);
        interpret();
        execute();
        view.queueDraw();
    }
    COMMAND[] command_queue;
    void add_to_queue(COMMAND[] cmds ...){
        foreach(cmd; cmds)
        {
            command_queue ~= cmd;
        }
    }
    private void interpret(){
        import std.stdio;
        debug(cmd) writeln("input mode ",input_state);
        debug(cmd) writefln("%d",ModifierType.CONTROL_MASK);
 
        // 魔界化する前に
        // KeyConfigを
        // 連キーをKeyConfigに割り当てたい
        //    keyCheckをmethod化?
        //    1つの発行自体を個々のmethodに分離?
        final switch (input_state)
        {
            case InputState.normal:
                if(ModState & ModifierType.CONTROL_MASK)
                {
                    // input_state = InputState.select;
                    // if(keyState[$-1] == MOVE_L_KEY){ add_to_queue (start_select_mode, move_focus_l,expand_select/*_l*/); }else
                    // if(keyState[$-1] == MOVE_R_KEY){ add_to_queue (start_select_mode, move_focus_r,expand_select/*_r*/); }else
                    // if(keyState[$-1] == MOVE_U_KEY){ add_to_queue (start_select_mode, move_focus_u,expand_select/*_u*/); }else
                    // if(keyState[$-1] == MOVE_D_KEY){ add_to_queue (start_select_mode, move_focus_d,expand_select/*_d*/); }

                    if(keyState[$-1] == MOVE_L_KEY){ add_to_queue (move_selected_l); }else
                    if(keyState[$-1] == MOVE_R_KEY){ add_to_queue (move_selected_r); }else
                    if(keyState[$-1] == MOVE_U_KEY){ add_to_queue (move_selected_u); }else
                    if(keyState[$-1] == MOVE_D_KEY){ add_to_queue (move_selected_d); }else

                    if(keyState[$-1] == DELETE_KEY){ add_to_queue (delete_selected); }
                }
                else
                {
                    if(keyState[$-1] == INSERT_KEY)
                    {
                        add_to_queue (start_insert_normal_text,im_focusin);
                        input_state = InputState.edit;
                    }else

                    if(keyState[$-1] == MOVE_L_KEY) add_to_queue (move_focus_l); else
                    if(keyState[$-1] == MOVE_R_KEY) add_to_queue (move_focus_r); else 
                    if(keyState[$-1] == MOVE_U_KEY) add_to_queue (move_focus_u); else
                    if(keyState[$-1] == MOVE_D_KEY) add_to_queue (move_focus_d); else
                    if(keyState[$-1] == GdkKeysyms.GDK_0) add_to_queue (toggle_grid_show); else
                    if(keyState[$-1] == GdkKeysyms.GDK_9) add_to_queue (toggle_boxborder_show);
                }
                break;
            case InputState.edit:
                if(keyState[$-1] == GdkKeysyms.GDK_Escape)
                    add_to_queue (mode_change_to_normal,manip_mode_normal,im_focusout); else
                if(keyState[$-1] == GdkKeysyms.GDK_BackSpace)
                    add_to_queue (text_backspace); else
                if(keyState[$-1] == GdkKeysyms.GDK_Return)
                    add_to_queue (text_feed);
                if(im_driven) {
                }
                else{
                }
                return;
            case InputState.select:
                if(keyState[$-1] == GdkKeysyms.GDK_Escape) add_to_queue (mode_change_to_normal);
                // if(keyState[$-1] == EXIT_KEY) command_queue ~= quit;
                if(manip.mode == focus_mode.select)
                {
                    if(ModState & ModifierType.CONTROL_MASK)
                    {
                        if(keyState[$-1] == MOVE_L_KEY){ add_to_queue (move_focus_l,expand_select/*_l*/); }else
                        if(keyState[$-1] == MOVE_R_KEY){ add_to_queue (move_focus_r,expand_select/*_r*/); }else
                        if(keyState[$-1] == MOVE_U_KEY){ add_to_queue (move_focus_u,expand_select/*_u*/); }else
                        if(keyState[$-1] == MOVE_D_KEY){ add_to_queue (move_focus_d,expand_select/*_d*/); }
                    }
                    else
                    {
                        input_state = InputState.normal;
                        add_to_queue(manip_mode_normal);
                    }
                }
                else
                {
                }
                break;
        }
        return;
    }
    void input_start()
        in{
        assert(input_state != InputState.edit); 
        }
    body{
        input_state = InputState.edit;
        // SDL_StartTextInput();
    }
    void input_end()
        in{
        assert(input_state == InputState.edit); 
        }
    body{
        input_state = InputState.normal;
        // SDL_StopTextInput();
    }
    public:
    void execute(){
        if(!command_queue.empty){
            foreach(cmd; command_queue)
                cmd.execute();
            command_queue.clear();
        }
    }
}
