module command.op;

import env;
import manip;
import command.command;
import TextView;
import gui.gui;

import std.stdio;

private import stdlib = core.stdc.stdlib : exit;

mixin template ctor(){
    this(ManipTable t,PageView view){ super(t,view); }
}

mixin template op_atom()
{
    InputState input_state = InputState.normal;
    class MOVE_BOX_R : CMD
    {
        mixin ctor;
        void execute(){
            manip_table.focused_box.move(Direct.right);
        }
    }
    class MOVE_BOX_L : CMD
    {
        mixin ctor;
        void execute(){
            manip_table.focused_box.move(Direct.left);
        }
    }
    class MOVE_BOX_U : CMD
    {
        mixin ctor;
        void execute(){
            manip_table.focused_box.move(Direct.up);
        }
    }
    class MOVE_BOX_D : CMD
    {
        mixin ctor;
        void execute(){
            manip_table.focused_box.move(Direct.down);
        }
    }
    // text box
    class START_INSERT_NORMAL_TEXT : CMD
    {
        mixin ctor;
        void execute(){
            manip_table.start_insert_normal_text();
        }
    }
    class MODE_CHANGE :CMD
    {
        mixin ctor;
        void execute(){
            if(input_state == InputState.normal)
                input_state = InputState.insert;
            else input_state = InputState.normal;
        }
    }
    class MODE_CHANGE_TO_NORMAL :CMD
    {
        mixin ctor;
        void execute(){
            input_state = InputState.normal;
        }
    }
    class MOVE_FOCUS_L:CMD
    {
        mixin ctor;
        void execute(){
            manip_table.move_focus(Direct.left);
        }
    }
    class MOVE_FOCUS_R:CMD
    { 
        mixin ctor;
        void execute(){
            manip_table.move_focus(Direct.right);
        }
    }
    class MOVE_FOCUS_U:CMD
    {   
        mixin ctor;
        void execute(){
            manip_table.move_focus(Direct.up);
        }
    }
    class MOVE_FOCUS_D:CMD
    {   
        mixin ctor;
        void execute(){
            manip_table.move_focus(Direct.down);
        }
    }
    class START_SELECT_MODE:CMD
    {
        mixin ctor;
        void execute(){
            manip_table.start_select();
        }
    }
    class EXPAND_SELECT:CMD
    {
        mixin ctor;
        void execute(){
            manip_table.expand_to_focus();
        }
    }
    class EXPAND_SELECT_D:CMD
    {   
        mixin ctor;
        void execute(){
            manip_table.expand_if_on_edge(Direct.down);
        }
    }
    class EXPAND_SELECT_L:CMD
    {   
        mixin ctor;
        void execute(){
            manip_table.expand_if_on_edge(Direct.left);
        }
    }
    class EXPAND_SELECT_R:CMD
    {   
        mixin ctor;
        void execute(){
            manip_table.expand_if_on_edge(Direct.right);
        }
    }
    class EXPAND_SELECT_U:CMD
    {   
        mixin ctor;
        void execute(){
            manip_table.expand_if_on_edge(Direct.up);
        }
    }
    class QUIT:CMD
    {   
        mixin ctor;
        void execute(){
            stdlib.exit(0);
        }
    }
    class ZOOM_IN_GRID:CMD
    {
        mixin ctor;
        void execute(){
            ++(view.gridSpace);
        }
    }
    class ZOOM_OUT_GRID:CMD
    {
        mixin ctor;
        void execute(){
            --(view.gridSpace);
        }
    }
    class MANIP_MODE_NORMAL:CMD
    {
        mixin ctor;
        void execute(){
            manip_table.return_to_normal_mode();
        }
    }
}
