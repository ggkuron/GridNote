module slite;

import command.command;
import userview;
import env;
enum InputState{normal,incert};
import slite;
import misc.direct;

class Command
{
    Slite slite;
    this(Slite s){
        slite = s;
    }
    abstract void execute(){}
}
// move box
class MOVE_BOX_R : Command
{
    void execute(){
        slite.user_view.focused_box.move(Direct.right);
    }
}
class MOVE_BOX_L : Command
{
    void execute(){
        slite.user_view.focused_box.move(Direct.left);
    }
}
class MOVE_BOX_U : Command
{
    void execute(){
        slite.user_view.focused_box.move(Direct.up);
    }
}
class MOVE_BOX_D : Command
{
    void execute(){
        slite.user_view.focused_box.move(Direct.down);
    }
}

// text box
class INSERT_TEXT : Command
{
    void execute(){

    }
}

class MODE_CHANGE :Command
{
    void execute(){
        auto state = slite.cmd_interpreter.input_state;
        state == InputState.normal?state = InputState.insert:state = InputState.normal;
    }
}

class MODE_CHANGE_TO_NORMAL :Command
{
    void execute(){
        slite.cmd_interpreter.input_state = InputState.normal;
    }
}
class MOVE_FOCUS_L:Command
{
    void execute(){
        slite.user_view.move_focus(Direct.left);
    }
}
class MOVE_FOCUS_R:Command
{ 
    void execute(){
        slite.user_view.move_focus(Direct.right);
    }

}
class MOVE_FOCUS_U:Command
{   
    void execute(){
        slite.user_view.move_focus(Direct.up);
    }

}
class MOVE_FOCUS_D:Command
{   
    void execute(){
        slite.user_view.move_focus(Direct.down);
    }
}
class CommandInterpreter{
    private:
    Slite slite;
    InputState input_state;
    ubyte* keyState;
    SDL_Keymod ModState;
    this(Slite s){
        slite = s;
    }
    void updateKeyState(){
        SDL_PumpEvents();
        keyState = SDL_GetKeyboardState(null);
        ModState = SDL_GetModState();
    }
    Command issueCommand(){
        if(keyState[SDL_SCANCODE_ESCAPE]){}

        final switch (input_state)
        {
            case InputState.normal:
                switch (ModState){
                    case KMOD_LCTRL:
                        if(keyState[MOVE_L_KEY]) slite.CMD_;
                        if(keyState[MOVE_R_KEY]) slite.CMD_;
                        if(keyState[MOVE_U_KEY]) slite.CMD_;
                        if(keyState[MOVE_D_KEY]) slite.CMD_;
                        break;
                }
                break;
            case InputState.insert:
        }

        return null;
    }
    public:
    Command interpret(){
        updateKeyState();
        return issueCommand();
    }
}

class Slite{
    CommandInterpreter cmd_interpreter;
    UserPageView user_view;
    CellTable focused_table;
    
    this(){
        cmd_interpreter = new CommandInterpreter(this);
        user_view = new UserPageView();
        focused_table = user_view.focused_table;
    }

    private void command_exec(Command cmd){
        cmd.execute();
    }
    void interpreted_exec(){
        auto cmd = cmd_interpreter.interpret();
        command_exec(cmd);
    }
    static auto CMD_MOVE_BOX_R = MOVE_BOX_R(this);
    static auto CMD_MOVE_BOX_L = MOVE_BOX_L(this);
    static auto CMD_MOVE_BOX_U = MOVE_BOX_U(this);
    static auto CMD_MOVE_BOX_D = MOVE_BOX_D(this);
    static auto CMD_MODE_CHANGE = MODE_CHANGE(this);
    static auto CMD_INSERT_TEXT = INSERT_TEXT(this);
    static auto CMD_MODE_CHANGE_TO_NORMAL = MODE_CHANGE_TO_NORMAL(this);

}
