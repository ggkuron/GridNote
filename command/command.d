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
class CMD{
    ManipTable manip_table;
    alias manip_table this;
    PageView view;
    this(ManipTable m,PageView view){
        manip_table = m;
        this.view = view;
    }
    abstract void execute(){}
}

import command.op;
mixin op_atom; // difinition of CMD instance 

enum InputState{normal,insert,select};
class InputInterpreter{

     CMD move_box_r; 
     CMD move_box_l; 
     CMD move_box_u; 
     CMD move_box_d; 
     CMD move_focus_l;
     CMD move_focus_r;
     CMD move_focus_d;
     CMD move_focus_u;
     CMD expand_select;
     CMD expand_select_l;
     CMD expand_select_r;
     CMD expand_select_d;
     CMD expand_select_u;
     CMD mode_change;
     CMD manip_mode_normal;
     CMD mode_change_to_normal;
     CMD quit;
     CMD render_window;
     CMD start_select_mode;
     CMD start_insert_normal_text; 

    ManipTable manip;
    PageView view;
    IMMulticontext imm;

    uint[] keyState;
    uint ModState;
    bool im_driven;

    this(ManipTable m,PageView pv){
        manip = m;
        view = pv;
        imm = new IMMulticontext();
        imm.setClientWindow(view.getParentWindow());

        move_box_r = new MOVE_BOX_R(manip,view); 
        move_box_l = new MOVE_BOX_L(manip,view); 
        move_box_u = new MOVE_BOX_U(manip,view);                   
        move_box_d = new MOVE_BOX_D(manip,view); 
        move_focus_l = new MOVE_FOCUS_L(manip,view);
        move_focus_r = new MOVE_FOCUS_R(manip,view);
        move_focus_d = new MOVE_FOCUS_D(manip,view);
        move_focus_u = new MOVE_FOCUS_U(manip,view);
        expand_select = new EXPAND_SELECT(manip,view);
        expand_select_l = new EXPAND_SELECT_L(manip,view);
        expand_select_r = new EXPAND_SELECT_R(manip,view);
        expand_select_d = new EXPAND_SELECT_D(manip,view);
        expand_select_u = new EXPAND_SELECT_U(manip,view);
        mode_change = new MODE_CHANGE(manip,view);
        manip_mode_normal = new MANIP_MODE_NORMAL(manip,view);
        mode_change_to_normal = new MODE_CHANGE_TO_NORMAL(manip,view);
        quit = new QUIT(manip,view);
        start_select_mode = new START_SELECT_MODE(manip,view);
        start_insert_normal_text = new START_INSERT_NORMAL_TEXT(manip,view);
    }
    public bool key_to_cmd(Event event, Widget widget)
        in{
        assert(event.key() !is null);
        }
    body{
        imm.focusIn();
        auto ev = event.key();

        immutable preserve_length = 3;
        keyState.length = preserve_length;
        im_driven = cast(bool)imm.filterKeypress(ev);
        keyState ~= ev.keyval;
        debug(cmd) writeln("key is ",ev.keyval);
        debug(cmd) writeln("mod is ",ev.state);
        debug(cmd) writefln("str is %s",ev.string);
        ModState = ev.state;

        if(keyState.length > preserve_length)
            keyState = keyState[$-preserve_length .. $];

        writeln(keyState);
        interpret();
        execute();
        view.queueDraw();
        return true;
    }
    CMD[] command_queue;
    void add_to_queue(CMD[] cmds ...){
        foreach(cmd; cmds)
        {
            command_queue ~= cmd;
        }
    }
    private void interpret(){
        import std.stdio;
        if(keyState[$-1] == GdkKeysyms.GDK_Escape) add_to_queue (mode_change_to_normal);
 
        final switch (input_state)
        {
            case InputState.normal:
                if(ModState == ModifierType.CONTROL_MASK)
                {
                    input_state = InputState.select;
                    if(keyState[$-1] == MOVE_L_KEY){ add_to_queue (start_select_mode, move_focus_l,expand_select/*_l*/); }else
                    if(keyState[$-1] == MOVE_R_KEY){ add_to_queue (start_select_mode, move_focus_r,expand_select/*_r*/); }else
                    if(keyState[$-1] == MOVE_U_KEY){ add_to_queue (start_select_mode, move_focus_u,expand_select/*_u*/); }else
                    if(keyState[$-1] == MOVE_D_KEY){ add_to_queue (start_select_mode, move_focus_d,expand_select/*_d*/); }
                }
                else
                {
                    if(keyState[$-1] == INSERT_KEY) add_to_queue (start_insert_normal_text); else

                    if(keyState[$-1] == MOVE_L_KEY) add_to_queue (move_focus_l); else
                    if(keyState[$-1] == MOVE_R_KEY) add_to_queue (move_focus_r); else 
                    if(keyState[$-1] == MOVE_U_KEY) add_to_queue (move_focus_u); else
                    if(keyState[$-1] == MOVE_D_KEY) add_to_queue (move_focus_d);
                }
                break;
            case InputState.insert:
                if(im_driven) 
                return;
            case InputState.select:
                // if(keyState[$-1] == EXIT_KEY) command_queue ~= quit;
                if(manip.mode == focus_mode.select)
                {
                    if(ModState == ModifierType.CONTROL_MASK)
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
        in{ assert(input_state != InputState.insert); } 
    body{
        input_state = InputState.insert;
        // SDL_StartTextInput();
    }
    void input_end()
        in{ assert(input_state == InputState.insert); }
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
