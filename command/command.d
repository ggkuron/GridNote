module command.command;

import std.array;

import manip;
import env;
import util.direct;
import util.color;
import gdk.Keysyms; // Keysyms
import gdk.Event;
import gtk.Widget;
import gui.pageview;
import gtkc.gdktypes;  // ModifierType
import gtk.IMMulticontext;
import command.keycombine;
debug(cmd) import std.stdio;
private import stdlib = core.stdc.stdlib : exit;

// すべての実行可能な操作
// 直通。TODO:各機構との調停を挟む
//      Keycombinedから操作対象を判別して（一段 ここ
//      操作自体は捜査対象ごとの操作オブジェクトにKeycombinedを受け渡し（二段
//      実行（三段
//    のほうが柔軟性ある
// Text操作をしているとして、いまやりたいのが入力か入力位置の移動なのかをここで管理したくない
// Text操作の状態はManipTextに管理させるべき
// 少なくともカーソル移動キーは汎用的に使えるべきで、そのための状態を持つ責任はどこかには生じる

abstract class COMMAND{
    private:
        bool[KeyCombine] _table;
    public:
        void execute();
    final:
        void register_key(in KeyCombine ckc,bool invert = false){
            _table[ckc] = invert;
        }
        bool is_registered(in KeyCombine kc)const{
            foreach(k; _table)
            {
                if(kc !in _table)
                    return _table[kc];
            }
            return !_table[kc];
        }
        void clear(){
            _table.clear();
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
                assert(casted); // だいたい宣言順見なおして
            }
            debug(cmd){
                foreach(cmd; commands)
                {
                    assert(cmd !is null);
                }
            }
        }
        final override void execute(){
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

    //  ユーザー入力に対すして発動するfunction直通
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
        COMMAND input_mode_before;
        COMMAND mode_normal;
        COMMAND mode_edit;
        COMMAND mode_select;
        COMMAND quit;

        COMMAND color_select_L;
        COMMAND color_select_R;
        COMMAND color_select_U;
        COMMAND color_select_D;

        COMMAND create_TextBOX;
        COMMAND create_CodeBOX;
        COMMAND text_move_caretL;
        COMMAND text_move_caretR;
        COMMAND text_move_caretU;
        COMMAND text_move_caretD;
        COMMAND table_page_ejectD;
        COMMAND table_page_ejectU;
        COMMAND text_backspace;
        COMMAND text_deletechar;
        COMMAND text_feed;
        COMMAND text_join;
        COMMAND im_focus_in;
        COMMAND im_focus_out;
        COMMAND text_edit;
        COMMAND open_imagefile;
        COMMAND create_circle;
        COMMAND choose_open_file;
        COMMAND choose_save_file;
        COMMAND save;
        COMMAND restore;
        COMMAND save_to_file;
        COMMAND restore_from_file;
        COMMAND insert_tab;

        // combined_COMMAND
        COMMAND edit_to_normal_state; 
        COMMAND normal_start_edit_text;
        COMMAND normal_start_edit_text_mono;
        COMMAND normal_edit_textbox;
        // COMMAND mode_edit_from_color_select;
        // COMMAND mode_cell_select_from_color_select;
        COMMAND change_color_L;
        COMMAND change_color_R;
        COMMAND change_color_U;
        COMMAND change_color_D;
        COMMAND toggle_transparent;
    private:
        InputState _input_state = InputState.Normal;
        ManipTable _manip;
        PageView _view;
        IMMulticontext _imm;

        uint[] keyState;
        uint modState;
        bool _im_driven;
        COMMAND[KeyCombine][InputState] _command_table;

        void register_key(COMMAND cmd, in InputState state, in KeyCombine ckc,bool invert= false){
            cmd.register_key(ckc,invert);
            // 重複してはいけない
            import std.stdio;
            writeln("regist ",cmd);
            writeln("state ",state);
            writefln("kc %s \n",ckc);

            // 同一のキーバインドを許さない
            if(!_command_table.keys.empty 
                && state in _command_table 
                && !_command_table[state].keys.empty 
                && ckc in _command_table[state] // <- KeyConfig実装するときにException飛ばす,もしくは上書きするためにtableから現在のKeyCombineを消して
                && _command_table[state][ckc].is_registered(ckc))
                throw new Exception("alredy used this keycombined");
            _command_table[state][ckc] = cmd;
        }
        void control_input(){
            debug(cmd) writeln(keyState);
            parse_input();
            execute();
            _view.queueDraw();
        }
        // 状態遷移前の状態でCMDを登録する必要
        // preserve_length == 3でとりあえず決め打ちしてるの直す
        //  key_to_cmd の内側に統合しても良いのでは
        void parse_input(){

            KeyCombine input;
            if(modState)
                // この生成方法はKeyCombine::opEqualsに依る。
                input = KeyCombine([cast(ModifierType)modState],keyState);
            else
                input = KeyCombine(keyState);
            
            if(_input_state in _command_table  // 上段は
                    && input in _command_table[_input_state])
            {
                debug(cmd) writeln("parsed: ",input);
                keyState.clear();
                add_to_queue(_command_table[_input_state][input]);
            }else if(!modState)
                keyState.clear();

            debug(cmd) writeln("INVALID ");
        }
    public:
        this(ManipTable m,PageView pv,IMMulticontext im){
            _manip = m;
            _imm = im;
            _view = pv;

            zoom_in = cmd_template!("view.zoom_in();")(this,_manip,_view);
            zoom_out = cmd_template!("view.zoom_out();")(this,_manip,_view);
            register_key(zoom_in,InputState.Normal,default_ZOOM_IN);
            register_key(zoom_out,InputState.Normal,default_ZOOM_OUT);

            insert_tab = cmd_template!(`manip.commit_to_box("\t");`)(this,_manip,_view);
            register_key(insert_tab,InputState.Edit,tab_key);

            move_focus_l = cmd_template!("manip.move_focus(left);")(this,_manip,_view);
            move_focus_r = cmd_template!("manip.move_focus(right);")(this,_manip,_view);
            move_focus_d = cmd_template!("manip.move_focus(down);")(this,_manip,_view);
            move_focus_u = cmd_template!("manip.move_focus(up);")(this,_manip,_view);
            register_key(move_focus_l,InputState.Normal,default_MOVE_FOCUS_L);
            register_key(move_focus_r,InputState.Normal,default_MOVE_FOCUS_R);
            register_key(move_focus_u,InputState.Normal,default_MOVE_FOCUS_U);
            register_key(move_focus_d,InputState.Normal,default_MOVE_FOCUS_D);

            expand_select_pivot_R = cmd_template!("manip.expand_to_focus(right);")(this,_manip,_view);
            register_key(expand_select_pivot_R,InputState.Normal,default_SELECT_PIVOT_R);
            register_key(expand_select_pivot_R,InputState.CellSelect,default_SELECT_PIVOT_R);
            expand_select_pivot_U = cmd_template!("manip.expand_to_focus(up);")(this,_manip,_view);
            register_key(expand_select_pivot_U,InputState.CellSelect,default_SELECT_PIVOT_U);
            register_key(expand_select_pivot_U,InputState.Normal,default_SELECT_PIVOT_U);
            expand_select_pivot_L = cmd_template!("manip.expand_to_focus(left);")(this,_manip,_view);
            register_key(expand_select_pivot_L,InputState.Normal,default_SELECT_PIVOT_L);
            register_key(expand_select_pivot_L,InputState.CellSelect,default_SELECT_PIVOT_L);
            expand_select_pivot_D = cmd_template!("manip.expand_to_focus(down);")(this,_manip,_view);
            register_key(expand_select_pivot_D,InputState.Normal,default_SELECT_PIVOT_D);
            register_key(expand_select_pivot_D,InputState.CellSelect,default_SELECT_PIVOT_D);
            delete_selected_area = cmd_template!("manip.delete_selected_area();")(this,_manip,_view);
            register_key(delete_selected_area,InputState.CellSelect,default_BOX_DELETE);

            toggle_grid_show = cmd_template!("view.toggle_grid_show();")(this,_manip,_view);
            register_key(toggle_grid_show,InputState.Normal,default_TOGGLE_GRID_RENDER);
            toggle_boxborder_show = cmd_template!("view.toggle_boxborder_show();")(this,_manip,_view);
            register_key(toggle_boxborder_show,InputState.Normal,default_TOGGLE_BOX_BORDER_RENDER);

            manip_undo = cmd_template!("manip.undo();")(this,_manip,_view);
            register_key(manip_undo,InputState.Edit,default_UNDO);
            delete_selected = cmd_template!("manip.delete_selected();")(this,_manip,_view);
            register_key(delete_selected,InputState.Normal,default_BOX_DELETE);

            move_selected_r = cmd_template!("manip.move_selected(right);")(this,_manip,_view);
            move_selected_l = cmd_template!("manip.move_selected(left);")(this,_manip,_view);
            move_selected_u = cmd_template!("manip.move_selected(up);")(this,_manip,_view);
            move_selected_d = cmd_template!("manip.move_selected(down);")(this,_manip,_view);
            register_key(move_selected_r,InputState.Normal,default_MOVE_BOX_R);
            register_key(move_selected_l,InputState.Normal,default_MOVE_BOX_L);
            register_key(move_selected_u,InputState.Normal,default_MOVE_BOX_U);
            register_key(move_selected_d,InputState.Normal,default_MOVE_BOX_D);

            create_TextBOX = cmd_template!("manip.create_TextBOX();")(this,_manip,_view);
            create_CodeBOX = cmd_template!(`manip.create_CodeBOX();`)(this,_manip,_view);
            im_focus_out = cmd_template!("inp.im_focusOut();")(this,_manip,_view);
            create_circle = cmd_template!("manip.create_RectBOX();")(this,_manip,_view);
            register_key(create_circle,InputState.Normal,default_ImageOpen);
            register_key(create_circle,InputState.Edit,default_ImageOpen);

            table_page_ejectD = cmd_template!("manip.page_eject(down);")(this,_manip,_view);
            table_page_ejectU = cmd_template!("manip.page_eject(up);")(this,_manip,_view);
            // table_page_ejectL = cmd_template!("manip.page_eject(left);")(this,_manip,_view);
            // table_page_ejectR = cmd_template!("manip.page_eject(right);")(this,_manip,_view);
            register_key(table_page_ejectD,InputState.Normal,default_PAGE_D);
            register_key(table_page_ejectU,InputState.Normal,default_PAGE_U);

            // 内部使用
            // mode遷移はもっと包んだ方が良さそう
            input_mode_edit = cmd_template!("inp.change_mode_edit();")(this,_manip,_view);
            input_mode_normal = cmd_template!("inp.change_mode_normal();")(this,_manip,_view);
            input_mode_select = cmd_template!("inp.change_mode_select();")(this,_manip,_view);
            input_mode_color = cmd_template!("inp.change_mode_color();")(this,_manip,_view);
            register_key(input_mode_color,InputState.Normal,default_MODE_COLOR);
            register_key(input_mode_color,InputState.Edit,default_MODE_COLOR);
            // register_key(input_mode_color,InputState.CellSelect,default_MODE_COLOR);

            manip_mode_normal = cmd_template!("manip.change_mode_normal();")(this,_manip,_view);
            manip_mode_select = cmd_template!("manip.change_mode_select();")(this,_manip,_view);
            manip_mode_edit = cmd_template!("manip.change_mode_edit();")(this,_manip,_view);
            manip_mode_point = cmd_template!("manip.change_mode_point();")(this,_manip,_view);
            register_key(manip_mode_point,InputState.Normal,default_Point);

            color_select_L = cmd_template!("manip.select_color(left);")(this,_manip,_view); 
            color_select_R = cmd_template!("manip.select_color(right);")(this,_manip,_view);
            color_select_U = cmd_template!("manip.select_color(up);")(this,_manip,_view);
            color_select_D = cmd_template!("manip.select_color(down);")(this,_manip,_view);

            quit = cmd_template!("stdlib.exit(0);")(this,_manip,_view);
            grab_target = cmd_template!("manip.grab_selectbox();")(this,_manip,_view);

            text_move_caretL = cmd_template!("manip.move_caret(left);")(this,_manip,_view);
            text_move_caretR = cmd_template!("manip.move_caret(right);")(this,_manip,_view);
            text_move_caretU = cmd_template!("manip.move_caret(up);")(this,_manip,_view);
            text_move_caretD = cmd_template!("manip.move_caret(down);")(this,_manip,_view);
            text_join = cmd_template!("manip.join();")(this,_manip,_view);
            register_key(text_join,InputState.Normal,default_JOIN);
            register_key(text_move_caretL,InputState.Edit,default_MOVE_BOX_L);
            register_key(text_move_caretR,InputState.Edit,default_MOVE_BOX_R);
            register_key(text_move_caretU,InputState.Edit,default_MOVE_BOX_U);
            register_key(text_move_caretD,InputState.Edit,default_MOVE_BOX_D);
            text_backspace = cmd_template!("manip.backspace();")(this,_manip,_view);
            text_deletechar = cmd_template!("manip.delete_char();")(this,_manip,_view);
            register_key(text_deletechar,InputState.Edit,default_EDIT_DELETE);
            register_key(text_backspace,InputState.Edit,backspace);
            text_feed = cmd_template!("manip.text_feed();")(this,_manip,_view);
            register_key(text_feed,InputState.Edit,return_key);
            text_edit = cmd_template!("manip.edit_textbox();")(this,_manip,_view);
            im_focus_in = cmd_template!("inp.im_focusIn();")(this,_manip,_view);

            save = cmd_template!("manip.preserve();")(this,_manip,_view);
            restore = cmd_template!("manip.restore();")(this,_manip,_view);
            choose_open_file = cmd_template!("manip.choose_open_file();")(this,_manip,_view);
            choose_save_file = cmd_template!("manip.choose_save_file();")(this,_manip,_view);
            save_to_file = new combined_COMMAND(choose_save_file,save);
            restore_from_file = new combined_COMMAND(choose_open_file,restore);
            register_key(save_to_file,InputState.Normal,default_SAVE_NEW);
            register_key(save,InputState.Normal,default_SAVE);
            register_key(restore_from_file,InputState.Normal,default_RESTORE_FILE);
            register_key(restore,InputState.Normal,default_RESTORE);

            // combined_COMMAND
            normal_edit_textbox = new combined_COMMAND(grab_target,text_edit);
            register_key(normal_edit_textbox,InputState.Normal,default_EDIT);
            normal_start_edit_text = new combined_COMMAND(input_mode_edit,create_TextBOX,im_focus_in);
            normal_start_edit_text_mono = new combined_COMMAND(input_mode_edit,create_CodeBOX,im_focus_in);
            register_key(normal_start_edit_text,InputState.Normal,default_INSERT);
            register_key(normal_start_edit_text_mono,InputState.Normal,default_mono_insert);

            input_mode_before = cmd_template!("inp.change_mode_before();")(this,_manip,_view);
            mode_normal = new combined_COMMAND(input_mode_normal,manip_mode_normal);
            mode_edit = new combined_COMMAND(input_mode_edit,manip_mode_edit);
            mode_select = new combined_COMMAND(input_mode_select,manip_mode_select);
            register_key(mode_normal,InputState.Normal,escape_key);
            register_key(mode_normal,InputState.Edit,escape_key);
            register_key(mode_normal,InputState.Normal,alt_escape);
            register_key(mode_normal,InputState.Edit,alt_escape);
            // mode_edit_from_color_select = new combined_COMMAND(input_mode_edit);
            // mode_cell_select_from_color_select = new combined_COMMAND(input_mode_select,manip_mode_select);
            // register_key(mode_edit_from_color_select,InputState.ColorSelect,escape_key);
            // register_key(mode_edit_from_color_select,InputState.ColorSelect,alt_escape);
            // register_key(mode_cell_select_from_color_select,InputState.CellSelect,escape_key);
            // register_key(mode_cell_select_from_color_select,InputState.CellSelect,alt_escape);

            // open_imagefile = cmd_template!("manip.select_file();")(this,manip,_view);
            // register_key(open_imagefile,InputState.Normal,default_ImageOpen);
            change_color_L = new combined_COMMAND(input_mode_color,color_select_L,input_mode_before);
            change_color_R = new combined_COMMAND(input_mode_color,color_select_R,input_mode_before);
            change_color_U = new combined_COMMAND(input_mode_color,color_select_U,input_mode_before);
            change_color_D = new combined_COMMAND(input_mode_color,color_select_D,input_mode_before);

            register_key(change_color_L,InputState.Normal,default_CMOVE_L);
            register_key(change_color_R,InputState.Normal,default_CMOVE_R);
            register_key(change_color_U,InputState.Normal,default_CMOVE_U);
            register_key(change_color_D,InputState.Normal,default_CMOVE_D);
            register_key(change_color_L,InputState.Edit,default_CMOVE_L);
            register_key(change_color_R,InputState.Edit,default_CMOVE_R);
            register_key(change_color_U,InputState.Edit,default_CMOVE_U);
            register_key(change_color_D,InputState.Edit,default_CMOVE_D);

            toggle_transparent = cmd_template!("view.parent_window.toggle_opacity();")(this,_manip,_view);
            register_key(toggle_transparent,InputState.Edit,default_toggle_transparent);
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
                    _im_driven = cast(bool)_imm.filterKeypress(ev);
                    debug(cmd) writeln(_im_driven);
                    if(_im_driven) return true;
                    break;
                case InputState.Normal:
                case InputState.CellSelect:
                case InputState.ColorSelect:
                    im_focusOut();
                    break;
            }
            keyState ~= ev.keyval;
            modState = ev.state;
            if(keyState.length > preserve_length)
                keyState = keyState[$-preserve_length .. $];
            control_input();

            // debug(cmd) writeln(keyState);
            return true;
        }
        COMMAND[] command_queue;
        void add_to_queue(COMMAND[] cmds ...){
            foreach(cmd; cmds)
            {
                command_queue ~= cmd;
            }
        }
    public:
        private InputState _state_memento = InputState.Normal;
        private void _add_in_memento(in InputState bis){
            // 格納数増やせるように一応
            import std.stdio;
            // writeln(_input_state);
            _state_memento = bis;
            writeln(_input_state);
        }
        bool is_enable_to_edit()const{
            return _input_state == InputState.Edit
                && _manip.mode == FocusMode.edit;
        }
        void change_mode_before(){
            import std.stdio;
            _input_state = _state_memento;
            if(_im_driven) 
                im_focusIn();
            writeln(_input_state);
        }
        void change_mode_normal(){
            final switch(_input_state){
                case InputState.Normal:
                    im_focusOut();
                    break;
                case InputState.CellSelect:
                    _add_in_memento(_input_state);
                    _input_state = InputState.Normal;
                    im_focusOut();
                    break;
                case InputState.ColorSelect:
                    _add_in_memento(_input_state);
                    break;
                case InputState.Edit:
                    keyState.clear();
                    im_focusOut();
                    _add_in_memento(_input_state);
                    _input_state = InputState.Normal;
                    break;
            }
        }
        void change_mode_edit(){
            final switch(_input_state){
                case InputState.Normal:
                case InputState.CellSelect:
                    _add_in_memento(_input_state);
                case InputState.ColorSelect:
                    _input_state = InputState.Edit;
                    im_focusIn();
                    add_to_queue( manip_mode_edit );
                    break;
                case InputState.Edit:
                    im_focusIn();
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
                    im_focusOut();
                    _add_in_memento(_input_state);
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
                    // _imm.focusOut(); // _im_drivenを維持
                    _add_in_memento(_input_state);
                    _input_state = InputState.ColorSelect;
                    break;
            }
        }
        void im_focusIn(){
            _im_driven = true;
            _imm.focusIn();
        }
        void im_focusOut(){
            _im_driven = false;
            _imm.focusOut();
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
        bool is_using_im()const{
            return _im_driven;
        }
}
