module command.command;

import std.array;
import derelict.sdl2.sdl;

import manip;
import env;
import misc.direct;
import slite;

class Command{
    Slite slite;
    this(Slite s){
        slite = s;
    }
    abstract void execute(){}
}

import command.command_op;
mixin operations;

enum InputState{normal,insert};
class InputInterpreter{
    Command CMD_MOVE_BOX_R; 
    Command CMD_MOVE_BOX_L; 
    Command CMD_MOVE_BOX_U; 
    Command CMD_MOVE_BOX_D; 
    Command CMD_MOVE_FOCUS_L;
    Command CMD_MOVE_FOCUS_R;
    Command CMD_MOVE_FOCUS_D;
    Command CMD_MOVE_FOCUS_U;
    Command CMD_EXPAND_SELECT_L;
    Command CMD_EXPAND_SELECT_R;
    Command CMD_EXPAND_SELECT_D;
    Command CMD_EXPAND_SELECT_U;
    Command CMD_MODE_CHANGE;
    //  Command CMD_INSERT_TEXT;
    Command CMD_MANIP_MODE_NORMAL;
    Command CMD_MODE_CHANGE_TO_NORMAL;
    Command CMD_QUIT;
    Command CMD_RENDER_WINDOW;
    Command CMD_START_SELECT_MODE;
    Command CMD_DELETE_FOCUS_FROM_SELECT;
    Command CMD_START_INSERT_NORMAL_TEXT; 

    ubyte* keyState;
    SDL_Keymod ModState;
    Slite slite;

    this(Slite s){
        slite = s;
        CMD_MOVE_BOX_R = new MOVE_BOX_R(slite); 
        CMD_MOVE_BOX_L = new MOVE_BOX_L(slite); 
        CMD_MOVE_BOX_U = new MOVE_BOX_U(slite);                   
        CMD_MOVE_BOX_D = new MOVE_BOX_D(slite); 
        CMD_MOVE_FOCUS_L = new MOVE_FOCUS_L(slite);
        CMD_MOVE_FOCUS_R = new MOVE_FOCUS_R(slite);
        CMD_MOVE_FOCUS_D = new MOVE_FOCUS_D(slite);
        CMD_MOVE_FOCUS_U = new MOVE_FOCUS_U(slite);
        CMD_EXPAND_SELECT_L = new EXPAND_SELECT_L(slite);
        CMD_EXPAND_SELECT_R = new EXPAND_SELECT_R(slite);
        CMD_EXPAND_SELECT_D = new EXPAND_SELECT_D(slite);
        CMD_EXPAND_SELECT_U = new EXPAND_SELECT_U(slite);
        CMD_MODE_CHANGE = new MODE_CHANGE(slite);
        CMD_MANIP_MODE_NORMAL = new MANIP_MODE_NORMAL(slite);
        // CMD_INSERT_TEXT = new INSERT_TEXT(slite);
        CMD_MODE_CHANGE_TO_NORMAL = new MODE_CHANGE_TO_NORMAL(slite);
        CMD_QUIT = new QUIT(slite);
        CMD_RENDER_WINDOW = new RENDER_WINDOW(slite);
        CMD_START_SELECT_MODE = new START_SELECT_MODE(slite);
        CMD_DELETE_FOCUS_FROM_SELECT = new DELETE_FOCUS_FROM_SELECT(slite);
        CMD_START_INSERT_NORMAL_TEXT = new START_INSERT_NORMAL_TEXT(slite);
    }
    void updateKeyState(){
        keyState = SDL_GetKeyboardState(null);
        ModState = SDL_GetModState();
    }
    Command[] command_queue;
    void add_to_queue(Command[] cmds ...){
        foreach(cmd; cmds)
        {
            command_queue ~= cmd;
        }
    }
    InputState input_state;
    private void issue(){
        if(keyState[SDL_SCANCODE_ESCAPE]) add_to_queue (CMD_MODE_CHANGE_TO_NORMAL);

        final switch (input_state)
        {
            case InputState.normal:
                switch (ModState){
                    case KMOD_LCTRL:
                        if(keyState[EXIT_KEY]) command_queue ~= CMD_QUIT;
                        if(slite.manip_table.mode == focus_mode.select)
                        {
                            if(keyState[MOVE_L_KEY]){ add_to_queue (CMD_EXPAND_SELECT_L); }
                            if(keyState[MOVE_R_KEY]){ add_to_queue (CMD_EXPAND_SELECT_R); }
                            if(keyState[MOVE_U_KEY]){ add_to_queue (CMD_EXPAND_SELECT_U); }
                            if(keyState[MOVE_D_KEY]){ add_to_queue (CMD_EXPAND_SELECT_D); }
                            if(keyState[DELETE_KEY]){ add_to_queue (CMD_DELETE_FOCUS_FROM_SELECT); }
                            // コマンド生成のキーが入力に混じらないためにDelay
                            // 優先順位を実装するか　DelayをCMDにするか -- Delay をCMD化したところで旨みはない
                                        
                            if(keyState[SDL_SCANCODE_ESCAPE]) add_to_queue (CMD_MANIP_MODE_NORMAL);
                        }else{
                            if(keyState[MOVE_L_KEY]){ add_to_queue (CMD_START_SELECT_MODE, CMD_EXPAND_SELECT_L); }
                            if(keyState[MOVE_R_KEY]){ add_to_queue (CMD_START_SELECT_MODE, CMD_EXPAND_SELECT_R); }
                            if(keyState[MOVE_U_KEY]){ add_to_queue (CMD_START_SELECT_MODE, CMD_EXPAND_SELECT_U); }
                            if(keyState[MOVE_D_KEY]){ add_to_queue (CMD_START_SELECT_MODE, CMD_EXPAND_SELECT_D); }
                        }
                        return;
                    default:
                        if(keyState[MOVE_L_KEY]) add_to_queue (CMD_MOVE_FOCUS_L);
                        if(keyState[MOVE_R_KEY]) add_to_queue (CMD_MOVE_FOCUS_R);
                        if(keyState[MOVE_U_KEY]) add_to_queue (CMD_MOVE_FOCUS_U);
                        if(keyState[MOVE_D_KEY]) add_to_queue (CMD_MOVE_FOCUS_D);
                        if(keyState[INSERT_KEY]){ SDL_Delay(200); add_to_queue (CMD_MODE_CHANGE,CMD_START_INSERT_NORMAL_TEXT); }
                        return ;
                }
            case InputState.insert:
                return;
        }
        return;
    }
    void input_start()
        in{ assert(input_state != InputState.insert); } 
    body{
        input_state = InputState.insert;
        SDL_StartTextInput();
    }
    void input_end()
        in{ assert(input_state == InputState.insert); }
    body{
        input_state = InputState.normal;
        SDL_StopTextInput();
    }
    ubyte* get_keys()
        in{ assert(input_state == InputState.insert); }
    body{
        return keyState;
    }
    SDL_Keymod get_mod()
        in{ assert(input_state == InputState.insert); }
    body{
        return ModState;
    }
    public:
    void execute(){
        updateKeyState(); // keyState updated
        issue();
        
        if(!command_queue.empty){
            foreach(cmd; command_queue)
                cmd.execute();
            command_queue.clear();
            CMD_RENDER_WINDOW.execute();
        }
    }
}
