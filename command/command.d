module command.command;

import derelict.sdl2.sdl;
import userview;
import env;
import misc.direct;
import command.command_op;
import gui.gui;

class Command
{
    Slite slite;
    this(Slite s){
        slite = s;
    }
    abstract void execute(){}
}

// from command/command_op 
mixin operations;

enum InputState{normal,insert};
class KeyInterpreter{
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
        if(keyState[SDL_SCANCODE_ESCAPE]) slite.CMD_MODE_CHANGE_TO_NORMAL.execute();

        final switch (input_state)
        {
            case InputState.normal:
                switch (ModState){
                    case KMOD_LCTRL:
                        if(keyState[MOVE_L_KEY]) slite.CMD_MOVE_FOCUS_L.execute();
                        if(keyState[MOVE_R_KEY]) slite.CMD_MOVE_FOCUS_R.execute();
                        if(keyState[MOVE_U_KEY]) slite.CMD_MOVE_FOCUS_U.execute();
                        if(keyState[MOVE_D_KEY]) slite.CMD_MOVE_FOCUS_D.execute();
                        if(keyState[EXIT_KEY]) slite.CMD_QUIT.execute();
                        break;
                    default:
                        break;
                }
                break;
            case InputState.insert:
        }
        return null;
    }
    public:
    Command DoIt(){
        updateKeyState();
        return issueCommand();
    }
}

class Slite{
    KeyInterpreter cmd_interpreter;
    UserPageView user_view;
    CellTable focused_table;
    GUIManager gui;
    
    this(){
        cmd_interpreter = new KeyInterpreter(this);
        user_view = new UserPageView();
        focused_table = user_view.focused_table;
        gui = new GUIManager(user_view);
        // もっといい方法があるに違いない
        CMD_MOVE_BOX_L = new MOVE_BOX_L(this);
        CMD_MOVE_BOX_R = new MOVE_BOX_R(this);
        CMD_MOVE_BOX_D = new MOVE_BOX_D(this);
        CMD_MOVE_BOX_U = new MOVE_BOX_U(this);
        CMD_MOVE_FOCUS_L = new MOVE_FOCUS_L(this);
        CMD_MOVE_FOCUS_R = new MOVE_FOCUS_R(this);
        CMD_MOVE_FOCUS_D = new MOVE_FOCUS_D(this);
        CMD_MOVE_FOCUS_U = new MOVE_FOCUS_U(this);

        CMD_MODE_CHANGE = new MODE_CHANGE(this);
        CMD_INSERT_TEXT = new INSERT_TEXT(this);
        CMD_MODE_CHANGE_TO_NORMAL = new MODE_CHANGE_TO_NORMAL(this);
        CMD_QUIT = new QUIT(this);
    }
    void work(){
        cmd_interpreter.DoIt();
        gui.draw();
    }

    Command CMD_MOVE_BOX_R; 
    Command CMD_MOVE_BOX_L; 
    Command CMD_MOVE_BOX_U; 
    Command CMD_MOVE_BOX_D; 
    Command CMD_MOVE_FOCUS_L;
    Command CMD_MOVE_FOCUS_R;
    Command CMD_MOVE_FOCUS_D;
    Command CMD_MOVE_FOCUS_U;
    Command CMD_MODE_CHANGE;
    Command CMD_INSERT_TEXT;
    Command CMD_MODE_CHANGE_TO_NORMAL;
    Command CMD_QUIT;
}
