module command.command_op;

import derelict.sdl2.sdl;
import env;

mixin template super_ctor(){
    this(Slite s){ super(s); }
}

mixin template operations()
{
    class MOVE_BOX_R : Command
    {
        mixin super_ctor;
        void execute(){
            slite.manip_table.focused_box.move(Direct.right);
        }
    }
    class MOVE_BOX_L : Command
    {
        mixin super_ctor;
        void execute(){
            slite.manip_table.focused_box.move(Direct.left);
        }
    }
    class MOVE_BOX_U : Command
    {
        mixin super_ctor;
        void execute(){
            slite.manip_table.focused_box.move(Direct.up);
        }
    }
    class MOVE_BOX_D : Command
    {
        mixin super_ctor;
        void execute(){
            slite.manip_table.focused_box.move(Direct.down);
        }
    }
    // text box
    class INSERT_TEXT : Command
    {
        mixin super_ctor;
        void execute(){
        }
    }
    class MODE_CHANGE :Command
    {
        mixin super_ctor;
        void execute(){
            if(slite.cmd_interpreter.input_state == InputState.normal)
                slite.cmd_interpreter.input_state = InputState.insert;
            else slite.cmd_interpreter.input_state = InputState.normal;
        }
    }
    class MODE_CHANGE_TO_NORMAL :Command
    {
        mixin super_ctor;
        void execute(){
            slite.cmd_interpreter.input_state = InputState.normal;
        }
    }
    class MOVE_FOCUS_L:Command
    {
        mixin super_ctor;
        void execute(){
            slite.manip_table.move_focus(Direct.left);
            SDL_Delay(210);
        }
    }
    class MOVE_FOCUS_R:Command
    { 
        mixin super_ctor;
        void execute(){
            slite.manip_table.move_focus(Direct.right);
            SDL_Delay(210);
        }
    }
    class MOVE_FOCUS_U:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.move_focus(Direct.up);
            SDL_Delay(210);
        }
    }
    class MOVE_FOCUS_D:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.move_focus(Direct.down);
            SDL_Delay(210);
        }
    }
    class START_SELECT_MODE:Command
    {
        mixin super_ctor;
        void execute(){
            slite.manip_table.start_select();
        }
    }
    class EXPAND_SELECT_D:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.expand_select(Direct.down);
            SDL_Delay(210);
        }
    }
    class EXPAND_SELECT_L:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.expand_select(Direct.left);
            SDL_Delay(210);
        }
    }
    class EXPAND_SELECT_R:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.expand_select(Direct.right);
            SDL_Delay(210);
        }
    }
    class EXPAND_SELECT_U:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.expand_select(Direct.up);
            SDL_Delay(210);
        }
    }
    class DELETE_FOCUS_FROM_SELECT:Command
    {
        mixin super_ctor;
        void execute(){
            slite.manip_table.delete_focus_from_select();
        }
    }
    class QUIT:Command
    {   
        mixin super_ctor;
        void execute(){
                import init;
            Quit();
        }
    }
    class ZOOM_IN_GRID:Command
    {
        mixin super_ctor;
        void execute(){
            ++gridSpace;
        }
    }
    class ZOOM_OUT_GRID:Command
    {
        mixin super_ctor;
        void execute(){
            --gridSpace;
        }
    }
    class RENDER_WINDOW:Command
    {
        mixin super_ctor;
        void execute(){
            slite.mainWindow.Redraw();
        }
    }
    class MANIP_MODE_NORMAL:Command
    {
        mixin super_ctor;
        void execute(){
            slite.manip_table.return_to_normal_mode();
        }
    }
}
