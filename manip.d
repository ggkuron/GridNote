module manip;

import util.direct;
import util.color;
import cell.textbox;
import cell.cell;
import cell.table;
import cell.select;
import cell.contentbox;
import command.command;
import gui.pageview;

import gtk.IMMulticontext;
import gtk.IMContext;
import gtk.FileChooserDialog;

import std.array;
import std.stdio;
import std.string;

enum FocusMode{ normal,select,edit,point }

// Tableに対する操作
// CMDは指示を投げるだけってことをやるかってこと
// このコメントを消そうとするときに考える

// Table に関する操作
   // ここからCellBOXに対する操作も行う
   // 表示位置の移動ってここでやってしまおうか
   // 指示棒をここがもってるから
   // 指示棒自体はCell::SelectBOX
// 
final class ManipTable{
    private:
        BoxTable  _focused_table;
        CellContent _maniped_box;
        CellContent[] _old_state;
        PageView  _pv;
        SelectBOX _select;
        FocusMode _mode;

        Color  _selected_color;
        string _box_type;
        TextController _manip_textbox;
    public:
        this(BoxTable table,PageView p)
            out{
            assert(_focused_table);
            assert(_manip_textbox);
            assert(_select);
            assert(_pv);
            }
        body{
            _focused_table = table;
            _select = new SelectBOX(_focused_table);

            _manip_textbox = new TextController();
            _pv =  p;
        }
        void move_focus(in Direct dir){
            immutable focus = _select.focus();
            immutable max_view = _pv.get_view_max();
            immutable min_view = _pv.get_view_min();
            if((focus.column <= min_view.column && dir == left)
            || (focus.row <= min_view.row && dir == up)
            || (focus.column >= max_view.column && dir==right )
            || (focus.row >= max_view.row && dir==down ))
            {
                debug(manip) writeln("focus ",focus);
                debug(manip) writeln("max ",max_view);

                _pv.move_view(dir);
                _select.move(dir);
            }
            else
                _select.move(dir);
            debug(manip) writefln("focus: %s",_select.focus);
        }
        void change_mode_select()
            in{
            assert(_mode != FocusMode.select);
            }
            out{
            assert(_mode == FocusMode.select);
            }
        body{
            _mode = FocusMode.select;
            _select.set_pivot();
        }
        auto targetbox(){
            switch(_box_type){
                case "cell.textbox.TextBOX":
                    return cast(TextBOX)_maniped_box;
                case "cell.textbox.CodeBOX":
                    return cast(CodeBOX)_maniped_box;
                default:
                    return null;
            }
            assert(0);
        }
        // 端点にfocusがあればexpand, そうでなくてもfocusは動く
        void expand_if_on_edge(in Direct dir){
            if(_select.is_on_edge(dir))
                expand_select(dir);

            move_focus(dir);
        }
        // moveとCMD単位で分離したかったが、
        // 初回の切り分けが複雑になるのでこうなった
        // 必要ならexpand_to_focus(no args)書いてそれをCMD化すればいい
        void expand_to_focus(in Direct dir)
            out{
            assert(_mode==FocusMode.select || _mode==FocusMode.edit);
            }
        body{
            if(_mode == FocusMode.normal)
                change_mode_select();

            move_focus(dir);
            _select.expand_to_focus();
        }
        void expand_select(in Direct dir)
            in{
            assert(_mode==FocusMode.select || _mode==FocusMode.edit);
            }
            out{
            assert(_mode==FocusMode.select || _mode==FocusMode.edit);
            }
        body{
            _mode = FocusMode.select;
            _select.expand(dir);
        }
        void delete_selected_area(){
            const select_min = _select.top_left;
            const select_max = _select.bottom_right;
            auto selected = _focused_table.get_contents(select_min,select_max);
            foreach(box; selected)
                box[1].remove_from_table();
        }
        auto grab_selectbox(){
            auto target = _focused_table.get_content(_select.focus);
            _box_type = target[0];
            _maniped_box = target[1];

            return _maniped_box;
        }
        void move_selected(in Direct to){
            auto target = _focused_table.get_content(_select.focus)[1];
            immutable view_min = _pv.get_view_min();
            immutable view_max = _pv.get_view_max();
            if(target is null) return;
            else{
                if(target.top_left.row <= view_min.row && to == up)
                {   // viewを動かしたあとそれに合わせるためにmoveする
                    // このrequire_moveは必ず通る
                    _pv.move_view(to);
                    target.require_move(to);
                        move_focus(to);
                    if(!view_min.row)
                        _select.move(to.reverse);
                }
                else if(target.top_left.column <= view_min.column && to == left)
                {
                    _pv.move_view(to);
                    target.require_move(to);
                        move_focus(to);
                    if(!view_min.column)
                         _select.move(to.reverse);
                }
                else if(target.bottom_right.row >= view_max.row && to == down)
                {   // 
                    _pv.move_view(to);
                    if(target.require_move(to))
                        move_focus(to);
                }
                else if(target.bottom_right.column >= view_max.column && to==right)
                {
                    _pv.move_view(to);
                    if(target.require_move(to))
                        move_focus(to);
                }
                else if(target.require_move(to)
                     ||(target.top_left.column == view_min.column && to == left)
                     ||(target.top_left.row == view_min.row && to == up))
                   _select.move(to);
            }
        }
        void delete_selected(){
            auto target = _focused_table.get_content(_select.focus);
            if(target[1] is null)
                return;
            else
                target[1].remove_from_table();
        }
        void change_mode_normal()
            out{
            assert(_mode == FocusMode.normal);
            }
        body{
            debug(manip) writeln("return to normal start");
            _mode = FocusMode.normal;
            if(_maniped_box !is null) {   // _maniped_box.is_to_spoil == false なら削除されない
                _focused_table.try_remove(_maniped_box);
            }
            _select.selection_clear();
            debug(manip) writeln("returned");
        }
        void change_mode_point(){
            change_mode_normal();
            _mode = FocusMode.point;
        }
        void change_mode_edit()
            out{
            assert(_mode == FocusMode.edit);
            }
        body{
            _mode = FocusMode.edit;
        }
        void create_TextBOX(){
            string family="Sans"; // このパラメータは設定ファイルから読めるようにする
            string style="Normal"; // 設定を読み出すのはここで、読む機能は別のところに。
            const Color fore=black;
            const Color back=linen;

            _mode = FocusMode.edit;
            if(_focused_table.has(_select.focus)) return;
            auto tb = new TextBOX(_focused_table,family,style,back,fore);
            if(!tb.require_create_in(_select.focus))
            {
                tb.clear();
                return;
            }

            tb.set_box_default_color(_selected_color);

            _maniped_box = tb;
            _box_type = tb.toString();
            debug(manip) writeln("type in: ",tb.toString());
        }
        void create_CodeBOX(){
            string family="Monospace"; // このパラメータは設定ファイルから読めるようにする
            string style="Normal"; // 設定を読み出すのはここで、読む機能は別のところに。
            const Color fore=white;
            const Color back=Color(48,48,48,210);

            _mode = FocusMode.edit;
            if(_focused_table.has(_select.focus)) return;
            // auto tb = _select.create_CodeBOX(family,style,back,fore);
            auto cb = new CodeBOX(_focused_table,family,style,back,fore);
            if(!cb.require_create_in(_select.focus))
            {
                cb.clear();
                return;
            }

            _maniped_box = cb;
            _box_type = cb.toString();
            debug(manip) writeln("type in: ",cb.toString());
        }
        void select_color(in Direct dir){
            _pv.guide_view.select_color(dir);
            _selected_color = get_selectedColor();
            _set_color();
        }
        private void _set_color(){
            if(_mode == FocusMode.normal)
                if(grab_selectbox())
                    _maniped_box.set_color(_selected_color);
            if(_mode == FocusMode.edit)
                if(auto tb = cast(TextBOX)(_maniped_box))
                    tb.set_foreground_color(_selected_color);
        }
        void select_color(in Color c){
            _selected_color = c;
            _pv.guide_view.display_color(c);
        }
        const(Color) get_selectedColor(){
            return _pv.guide_view.get_selectedColor();
        }
        void create_CircleBOX(){
            _mode = FocusMode.edit;
            if(_focused_table.has(_select.focus)) return;
            auto ib = _select.create_CircleCell(_selected_color,_pv);

            _maniped_box = ib;
            _box_type = ib.toString();
        }
        void page_eject(in Direct dir){
            const size = _pv.get_holdingSize();
            int travel;
            if(dir.is_horizontal)
                travel = size.column;
            else
                travel = size.row;
            _select.move(dir,travel);

            foreach(i; 0 .. travel)
                _pv.move_view(dir);
        }
        void create_RectBOX(){
            _mode = FocusMode.edit;
            if(_focused_table.has(_select.focus)) return;
            auto ib = _select.create_RectCell(_selected_color,_pv);

            _maniped_box = ib;
            _box_type = ib.toString();
        }
        void commit_to_box(string str){
            debug(manip) writeln("send to box start with :",str);
            if(_mode!=FocusMode.edit)
            {   // こんな状態になってるのがおかしいわけで
                assert(0);
                _pv.IM_FocusOut();
                return;
            }
            switch(_box_type){
               case "cell.textbox.TextBOX":
               case "cell.textbox.CodeBOX":
                   targetbox.input(str);
                   return;
               default:
                   return;
            }
        }
        void backspace(){
            _old_state ~= _maniped_box;
            switch(_box_type){
                case "cell.textbox.TextBOX":
                case "cell.textbox.CodeBOX":
                    _manip_textbox.backspace(targetbox);
                    return;
                default:
                    return;
            }
        }
        void text_feed(){
            if(auto tb = cast(TextBOX)_maniped_box) {
                // _old_state ~= new TextBOX(_focused_table,tb);
                if(_manip_textbox.feed(tb))
                    move_focus(down);
            }
        }
        void edit_textbox(){
            if(auto tb = cast(TextBOX)_maniped_box) 
                _old_state ~= _maniped_box;
        }
        void move_caret(in Direct dir){
            if(auto tb = cast(TextBOX)_maniped_box) 
                if(tb.move_caret(dir) && dir.is_vertical())
                    move_focus(dir);
        }
        void delete_char(){
             if(auto tb = cast(TextBOX)_maniped_box) 
                 tb.delete_char();
        }
        void join(){
             if(auto tb = cast(TextBOX)_maniped_box)
                 tb.join();
        }
        void undo(){
            if(!_old_state.empty())
                _maniped_box = _old_state[$-1];
        }
        import gtk.FileChooserDialog;
        import gtk.Window;
        private FileChooserDialog _file_chooser;
        private string _opened_file;
        string choose_save_file(){
            string file_name;
            // if(!_file_chooser)
            {
                string[] a;
                ResponseType[] r;
                a ~= "Save on!";
                a ~= "Cancel";
                r ~= ResponseType.ACCEPT;
                r ~= ResponseType.CANCEL;
                scope win = new Window("saving");
                _file_chooser = new FileChooserDialog("File Selection", win, FileChooserAction.SAVE,a,r);
            }
            _file_chooser.setFileChooserAction(FileChooserAction.SAVE);
            auto response = _file_chooser.run();
            if(response == ResponseType.ACCEPT )
            {
                _opened_file = file_name = _file_chooser.getFilename();
            }else
                _opened_file = "";
            _file_chooser.hide();
            return file_name;
        }
        bool preserve(string file_name = ""){
            if(_opened_file) 
                file_name = _opened_file;
            else 
                file_name = choose_save_file();

            if(!file_name || file_name.empty) 
                file_name = "tmp.dat";

            auto file = std.stdio.File(file_name,"w");
            if(!file.isOpen()) return false;
            auto all_ibs = _focused_table.get_imageBoxes();
            auto all_txt = _focused_table.get_textBoxes();
            auto all_code = _focused_table.get_codeBoxes();
            const offset = Cell(_focused_table.edge(up),_focused_table.edge(left));
            writeln(offset);
            foreach(ib; all_ibs)
            {
                if(auto rect = cast(RectBOX)ib)
                    file.write(rect.dat(offset));
            }
            foreach(tb; all_txt)
            {
                if(!tb.text_empty())
                    file.write(tb.dat(offset));
            }
            foreach(cb; all_code)
            {
                if(!cb.text_empty())
                    file.write(cb.dat(offset));
            }
            return true;
        }
        string choose_open_file(){
            string file_name;
            // if(!_file_chooser)
            {
                string[] a;
                ResponseType[] r;
                a ~= "Open!";
                a ~= "Cancel";
                r ~= ResponseType.ACCEPT;
                r ~= ResponseType.CANCEL;
                scope win = new Window("restore");
                _file_chooser = new FileChooserDialog("File Selection", win, FileChooserAction.OPEN,a,r);
            }
            auto response = _file_chooser.run();
            if( response == ResponseType.ACCEPT )
                _opened_file = file_name = _file_chooser.getFilename();
            _file_chooser.hide();
            return file_name;
        }
        void restore(){
            string file_name;
            if(_opened_file)
                file_name = _opened_file;
            else 
                file_name = choose_open_file();
            if(file_name.empty) return;

            _focused_table.clear();
            auto file = std.stdio.File(file_name,"r");

            string[][int] line_buf;
            int i;
            foreach(string l; lines(file))
            {   
                if(l[0] == '[')
                    ++i;
                line_buf[i-1] ~= l;
            }
            foreach(l; line_buf.values)
            {
                writeln(l);
                auto box_type = split(chomp(l[1])," * ");
                switch(box_type[0]){
                    case "RectBOX":
                        auto rb = new RectBOX(_focused_table,_pv,l);
                        rb.set_color(Color(box_type[1]));
                        break;
                    case "TextBOX":
                        auto tb = new TextBOX(_focused_table,l);
                        tb.set_color(Color(box_type[1]));
                        break;
                    case "CodeBOX":
                        auto tb = new CodeBOX(_focused_table,l,Color(box_type[1]));
                        // tb.set_color(Color(box_type[1]));
                        break;
                    default:
                        break;
                }
            }

            _maniped_box = null;
            _pv.queueDraw();
        }
        const(SelectBOX) select()const{
            return _select;
        }
        FocusMode mode()const{
            return _mode;
        }
        // このclassの役割って..?
        final class TextController {
            this(){
            }
            void backspace(TextBOX box){
                if(!box.backspace()) // 行始でfalse
                    move_focus(up);
            }
            void backspace(CodeBOX box){
                if(!box.backspace())
                    move_focus(up);
            }
            bool feed(TextBOX box){
                return box.expand_with_text_feed();
            }
            void set_foreground_color(TextBOX box,in Color c){
                box.set_foreground_color(c);
            }
            void set_color(TextBOX box,in Color c){
                box.set_foreground_color(c);
            }
            void move_caret(TextBOX box,in Direct dir){
                box.move_caret(dir);
            }
        }
}


