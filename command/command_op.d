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
    class START_INSERT_NORMAL_TEXT : Command
    {
        mixin super_ctor;
        void execute(){
            // slite.manip_table.(); // CREATE_TEXTBOX
            slite.manip_table.start_insert_normal_text();
        }
    }
    class MODE_CHANGE :Command
    {
        mixin super_ctor;
        void execute(){
            if(slite.interpreter.input_state == InputState.normal)
                slite.interpreter.input_state = InputState.insert;
            else slite.interpreter.input_state = InputState.normal;
        }
    }
    class MODE_CHANGE_TO_NORMAL :Command
    {
        mixin super_ctor;
        void execute(){
            slite.interpreter.input_state = InputState.normal;
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
            slite.manip_table.expand_if_on_edge(Direct.down);
            SDL_Delay(210);
        }
    }
    class EXPAND_SELECT_L:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.expand_if_on_edge(Direct.left);
            SDL_Delay(210);
        }
    }
    class EXPAND_SELECT_R:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.expand_if_on_edge(Direct.right);
            SDL_Delay(210);
        }
    }
    class EXPAND_SELECT_U:Command
    {   
        mixin super_ctor;
        void execute(){
            slite.manip_table.expand_if_on_edge(Direct.up);
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
            ++(slite.page_view.gridSpace);
        }
    }
    class ZOOM_OUT_GRID:Command
    {
        mixin super_ctor;
        void execute(){
            --(slite.page_view.gridSpace);
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
