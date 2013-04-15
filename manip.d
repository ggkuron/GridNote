module manip;

import derelict.sdl2.sdl;

import misc.direct;
import cell.textbox;
import cell.cell;
import command.command;
import gui.gui;

enum focus_mode{ normal,select,edit }
class ManipTable{
    SDL_Event* event; 
    TableBOX focused_table;
    ContentBOX focused_box;
    Window window;
    InputInterpreter key_interpreter;

    ManipTextBOX manip_textbox;

    focus_mode mode;
    SelectBOX select;
    this(Window w,TableBOX table,InputInterpreter ki,SDL_Event* ev)
        out{
        assert(focused_table);
        assert(window);
        assert(key_interpreter);
        assert(manip_textbox);
        assert(select);
        }
    body{
        // 最終的にはwindow はもちたくない // 優先順位的怠惰さ // またの名をToDo
        focused_table = table;
        select = new SelectBOX(focused_table,Cell(3,3));
        window = w; // 消し去りたい
        key_interpreter = ki;
        event = ev;

        manip_textbox = new ManipTextBOX(this);
    }
    this(ManipTable mt){
        window = mt.window;
        focused_table = mt.focused_table;
        select = mt.select;
    }
    void redraw(){ // 操作後の書き直し // 消し去りたい
        window.Redraw(); // 
        import std.stdio;
        writeln("redraw");
    }
    void delete_from_select(Cell c){
        select.remove(c);
    }
    void delete_focus_from_select(){
        select.remove(select.focus);
    }
    void move_focus(Direct dir){
        move_own(select.focus,dir);
    }
    CellBOX fucus_to_box(){
        return focused_table.cells[select.focus];
    }
    void start_select(){
        mode = focus_mode.select;
        select.add(select.focus);
    }
    // 端点にfocusがあればexpand, そうでなくてもfocusは動く
    final void expand_if_on_edge(Direct dir){
        if(select.is_on_edge(select.focus,dir))
            side_expand_select(dir);
        move_focus(dir);
    }
    void side_expand_select(Direct dir)
        in{ assert(mode == focus_mode.select);
        }out{
            assert(mode == focus_mode.select);
    }body{
            select.expand(dir);
    }
    void single_expand_select(Direct dir)
        in{ assert(mode == focus_mode.select);
        }out{
            assert(mode == focus_mode.select);
            // assert(focus == focus);
    }body{
            auto adjacent = select.focus; // Cell は struct . focusは変わらない
            move_own(adjacent,dir);
            select.add(adjacent); // 
    }
    void delete_from_select(){
        select.remove(select.focus);
    }
    void return_to_normal_mode()
        in{
            assert(mode == focus_mode.select);
        }out{
            assert(mode == focus_mode.normal);
    }body{
        select.clear();
        mode = focus_mode.normal;
    }
    // void add_to_table(CellBOX box){
    //     foreach(c; select.cells.keys)
    //         focused_table.add(c,box);
    // }
    private TextBOX create_text_box(){
        auto tb = new TextBOX(focused_table,select.cells.keys);
        // add_to_table(tb);
        // import std.stdio;
        // writeln("table.select:",focused_table.cells);
        return tb;
    }
    void start_insert_normal_text(){
        // select.clear();
        select.add(select.focus);
        auto tb = create_text_box();
        manip_textbox.start_input(tb);
    }
}

class ManipCellBOX{
    void reconcider_my_shape(){
    }
}
class ManipTextBOX {
    ManipTable manip_table;
    this(ManipTable mt){
        manip_table = mt;
    }
    void move_caret(TextBOX box, Direct dir){
        final switch(dir){
            case Direct.right:
                box.move_caretR(); return;
            case Direct.left:
                box.move_caretL(); return;
            case Direct.up:
                box.move_caretU(); return;
            case Direct.down:
                box.move_caretD(); return;
        }
        assert(0);
    }
    void start_input(TextBOX box){
        // move the focus on the table 
        //  to acoord with caret positon
        import std.stdio;
        // SDL_SetTextInputRect(&tmp);
        bool done;
        bool first_flg = true;
        SDL_Event event;
        SDL_WaitEvent(&event);
        SDL_StartTextInput();

        while(!done)
        {
            SDL_WaitEvent(&event);
            switch(event.type)
            {
                case SDL_TEXTINPUT: // non IME text-input
                    if(first_flg){ 
                    //     // 切り替え入力を食う 
                        first_flg = false;
                        box.insert_char(event.text.text);
                    }else{
                        box.insert_char(event.text.text);
                        box.expand(Direct.right);
                        box.move_caretR();
                        manip_table.expand_if_on_edge(Direct.right);
                    }
                    if(event.text.text[0] == 'q') SDL_Quit();
                    break;
                case SDL_TEXTEDITING:   // composition is changed or started
                    writeln("in editing");
                    box.composition = event.edit.text;
                    box.set_caret(event.edit.start);
                    manip_table.redraw();
                    // selection_len = event.edit.length;
                    break;
                default:
                    writeln("which i am without concern");
                    break;
            }
            manip_table.redraw();
        }
        return;
    }
}
