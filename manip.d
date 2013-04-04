module manip;

import derelict.sdl2.sdl;

import misc.direct;
import cell.textbox;
import cell.cell;
import gui.gui;

enum focus_mode{ normal,select,edit }
class ManipTable{
    CellBOX focused_table;
    CellBOX focused_box;
    Window window;

    ManipTextBOX manip_text;

    focus_mode mode;
    Cell focus;
    CellBOX select;
    this(Window w,CellBOX table){
        focused_table = table;
        focus = Cell(3,3); 
        select = new CellBOX(CellBOX.selecter_id,focused_table,Cell(0,0));
        window = w;

        manip_text = new ManipTextBOX(this);
    }
    this(ManipTable mt){
        window = mt.window;
        focused_table = mt.focused_table;
        focus = mt.focus;
        select = mt.select;
    }
    void redraw(){ // 操作後の書き直し
        window.Redraw();
        import std.stdio;
        writeln("redraw");
    }
        
    void delete_from_select(Cell c){
        select.remove(c);
    }
    void delete_focus_from_select(){
        select.remove(focus);
    }
    void move_focus(Direct dir){
        move_cell(focus,dir);
    }
    CellBOX fucus_to_box(){
        return focused_table.cells[focus];
    }
    void start_select(){
        mode = focus_mode.select;
        select.add(focus);
    }
    void expand_if_on_edge(Direct dir){
        if(select.is_on_edge(focus,dir))
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
            assert(focus == focus);
        }body{
            auto adjacent = focus; // Cell は struct . focusは変わらない
            move_cell(adjacent,dir);
            select.add(adjacent); // 
    }
    void delete_from_select(){
        select.remove(focus);
    }
    void return_to_normal_mode()
    in{
        assert(mode == focus_mode.select);
    }out{
        assert(mode == focus_mode.normal);
    }body{
        select.clear();
        select = new CellBOX(CellBOX.selecter_id);
        mode = focus_mode.normal;
    }
    void add_to_table(CellBOX box){
        foreach(c; select.cells.keys)
            focused_table.add(c,box);
    }
    void create_text_box(){
        auto tb = new TextBOX(select);
        add_to_table(tb);
        manip_text.start_input(tb);
    }
}

class ManipCellBOX{
    void reconcider_my_shape(){
    }
}
class ManipTextBOX : ManipTable{
    this(ManipTable mt){
        super(mt);
    }
    void move_cursor(TextBOX box, Direct dir){
        final switch(dir){
            case Direct.right:
                box.move_cursorR(); return;
            case Direct.left:
                box.move_cursorL(); return;
            case Direct.up:
                box.move_cursorU(); return;
            case Direct.down:
                box.move_cursorD(); return;
        }
        assert(0);
    }
    void start_input(TextBOX box){
        import std.stdio;
        SDL_Event event;
        SDL_Rect tmp = SDL_Rect(20,20,300,400);
        SDL_SetTextInputRect(&tmp);
        SDL_StartTextInput();
        bool done;
        while(!done)
        {
            if(SDL_PollEvent(&event))
            {
                switch(event.type)
                {
                    case SDL_TEXTINPUT: // non IME text-input
                        box.insert_char(event.text.text[0]);
                        if(event.text.text[0] == 'q') SDL_Quit();
                        break;
                    case SDL_TEXTEDITING:   // composition is changed or started
                        writeln("in editing");
                        box.composition = event.edit.text;
                        box.set_cursor(event.edit.start);
                        redraw();
                        // selection_len = event.edit.length;
                        break;
                    default:
                        writeln("which i am without concern");
                        break;
                }
                redraw();
            }
        }
        return;
    }
}
