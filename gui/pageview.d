module gui.pageview;

import gui.tableview;
import gui.guideview;
import gui.textbox;
import gui.window;
import std.string;
import std.array;
import std.algorithm;
import util.direct;
import cell.cell;
import cell.table;
import cell.contentbox;
import cell.imagebox;
import cell.refer;
import cell.textbox;
import manip;
import shape.shape;
import shape.drawer;
import command.command;

import gtk.Box;
import gtkc.gdktypes;
import gtk.Widget;
import gtk.IMContext;

import gtk.EventBox;
import gtk.ImageMenuItem;
import gtk.AccelGroup;
import gtk.IMMulticontext;
import gdk.Event;

import gtk.DrawingArea;
import gtk.Menu;
import cairo.Surface;
import cairo.Context;
debug(gui) import std.stdio;

// 入力領域
final class PageView : DrawingArea,TableView{
private:
    GtkAllocation _holding; // この2つの表すのは同じもの
    Rect _holding_area;  // 内部処理はこちらを使う

    ManipTable _manip_table; // tableに対する操作: 操作に伴う状態を読み取り描画する必要がある
    BoxTable _table;    // 描画すべき対象: 
    ReferTable _in_view;    // table にattachされた 表示領域
    Menu _menu;

    InputInterpreter _interpreter;
    RenderTextBOX _render_text;
    IMMulticontext _imm;

    GuideView _guide_view;

    ubyte _manipLineWidth = 2;
    Color _grid_color = Color(48,48,48,96);
    Color _selected_cell_border_color = Color("#00e4e4",128);
    Color _normal_focus_color = Color(cyan,128);
    Color _selected_focus_color = Color(cyan,168);
    Color _manip_box_color = Color(darkorange,128);

    bool _grid_show_flg = true;
    LinesBOX _grids;

    int _gridSpace =24; // □の1辺長
    ubyte _grid_width = 1;

    bool _on_key_press(Event ev,Widget w){
        return _interpreter.key_to_cmd(ev,w);
    }
    bool _on_key_release(Event ev,Widget w){
        return cast(bool)_imm.filterKeypress(ev.key());
    }
    bool _onButtonPress(Event event, Widget widget)
    {
        if(event.type == EventType.BUTTON_PRESS )
        {
            GdkEventButton* buttonEvent = event.button;

            if(buttonEvent.button == 3)
            {
                _menu.showAll();
                _menu.popup(buttonEvent.button, buttonEvent.time);
                return true;
            }
        }
        return false;
    }
    void _when_commit(string str,IMContext imc){
        if(_interpreter.is_enable_to_edit())
        {
            _manip_table.im_commit_to_box(str);
            queueDraw();
        }
    }
    void _when_preedit_changed(IMContext imc){
        if(_interpreter.is_enable_to_edit())
        {
            auto inputted_box = cast(TextBOX)_manip_table.get_target();
            assert(inputted_box !is null);
            _render_text.prepare_preedit(_imm,inputted_box);
            // レイアウトのことは投げる
            // IMContextごと
            queueDraw();
            // Preeditを描かせるため必要
        }
    }
    // ascii mode に切り替わったことを期待してみるようなところ
    void _when_preedit_end(IMContext imc){
        if(_interpreter.state == InputState.Edit)
        {
        }
    }
    void _when_preedit_start(IMContext imc){
    }
    bool _when_retrieve_surrounding(IMContext imc){
        auto surround = _render_text.get_surrounding();
        imc.setSurrounding(surround[0],surround[1]);
        return true;
    }
    import std.stdio;
    bool _focus_in(Event ev,Widget w){
        // if(_interpreter.is_using_im)
        _interpreter.im_focusIn();
        return true;
    }
    // private bool _last_im_state;
    bool _focus_out(Event ev,Widget w){
        if(!_interpreter.is_using_im)
            _interpreter.im_focusOut();
        return true;
    }
    void _when_realize(Widget w){
        _imm.setClientWindow(getParentWindow());
        _interpreter.im_focusIn();
    }
    void _when_unrealize(Widget w){
        _imm.focusOut();
        // _imm.reset();
        _imm.setClientWindow(null);
    }
    void _set_holding_area()
        in{
        assert(_holding_area);
        }
        out{
        assert(_holding_area.w > 0);
        assert(_holding_area.h > 0);
        }
    body{
        getAllocation(_holding);
        _holding_area.set_by(_holding);
    }
    void _set_view_size(){
        _in_view.set_range(_in_view.offset,
                cast(int)(_holding_area.w/_gridSpace),
                cast(int)(_holding_area.h/_gridSpace));
    }
    // void backDesign(Context cr){
    // }
    bool _show_contents_border = true;
    void _renderTable(Context cr,bool modify= false){
        if(_in_view.empty) return;
        auto manip_t = _manip_table.get_target();

        if(manip_t)
        {
            _render_text.stroke(cr,manip_t,_manip_box_color,_manipLineWidth);
        }

        foreach(tb; _in_view.get_textBoxes())
        {
            if(_show_contents_border)
            {
                _render_text.fill(cr,tb,tb.box_color);
                _render_text.stroke(cr,tb,Color(gold,128),1);
            }
            _render(cr,tb,(manip_t !is tb)||modify);
        }
        foreach(ib; _in_view.get_imageBoxes())
        {
            if(_show_contents_border)
            {
                _render_text.stroke(cr,ib,Color(gold,128),1);
            }
            ib.fill(cr);
        }

    }
    // renderするだけじゃなく描画域によってCellのサイズを修正する
    // Pangoしか知り得ないことを迂回して教えるよりはいいかと
    //      迂回してでも責任の分離はしておくべきやも
    // BoxSizeの修正くらいならいいだろう
            // BoxSize修正のためのInterfaceをCMDに晒したほうがいい
    void _render(Context cr,TextBOX b,bool focused = false){
        _render_text.render(cr,b,focused);
    }
    
    bool _draw_callback(Context cr,Widget widget){
        // backDesign(cr);
        if(_grid_show_flg) _renderGrid(cr);
        _renderTable(cr);
        _renderSelection(cr);
        _renderFocus(cr);
        cr.resetClip(); // end of rendering
        return true;
    }
    void _setGrid(){
        Line[] lines;
        for(double y = 0; y < _holding_area.h; y += _gridSpace)
        {
            auto start = new Point(0,y);
            auto end = new Point(_holding_area.w,y);
            lines ~= new Line(start,end,_grid_width);
        }
        for(double x = 0; x < _holding_area.w; x += _gridSpace)
        {
            auto start = new Point(x,0);
            auto end = new Point(x, _holding_area.h);
            lines ~= new Line(start,end,_grid_width);
        }
        _grids = new LinesBOX(_table,this);

        _grids.set_drawer(lines,_grid_width);
        _grids.set_color(_grid_color);
    }
    void _renderGrid(Context cr){
        _grids.stroke(cr);
    }
    void _renderFocus(Context cr){
        // 現在は境界色を変えてるだけだけど
        // 考えられる他の可能性のために
        // e.g. cell内部色を変えるとか（透過させるとか
        final switch(_manip_table.mode)
        {
            case FocusMode.normal:
                FillCell(cr,_manip_table.select.focus,_normal_focus_color); 
                break;
            case FocusMode.select:
                FillCell(cr,_manip_table.select.focus,_selected_focus_color); 
                break;
            case FocusMode.edit:
                // FillCell(cr,_manip_table.select.focus,_selected_focus_color); 
                // Text編集中,IMに任せるため
                // editモード細分化する?
                break;
            case FocusMode.point:
                PointCell(cr,_manip_table.select.focus,green);
                break;
        }
    }
    void _renderSelection(Context cr){
        FillGrids(cr,_manip_table.select.get_cells(),_selected_cell_border_color);
    }
    void _when_sizeallocate(GdkRectangle* n,Widget w){
        _size_allocate();
    }
    void _size_allocate(){
        _set_holding_area();
        _set_view_size();
        _setGrid();
        _table.set_gridsize(_gridSpace);
    }
    // ConfigFileから読むようにしたい
    void _init_color_select(){
        _manip_table.select_color(dimgray);
        _guide_view.add_color(dimgray);
        _guide_view.add_color(darkorange);
        _guide_view.add_color(violet);
        _guide_view.add_color(plum);
        _guide_view.add_color(cadetblue);
        _guide_view.add_color(black);
        _guide_view.add_color(cyan);
        _guide_view.add_color(firebrick);
        _guide_view.add_color(peachpuff);
        _guide_view.add_color(mediumaquamarine);
        _guide_view.add_color(gold);
        _guide_view.add_color(linen);
        _guide_view.add_color(darkgoldenrod);
        _guide_view.add_color(lemonchiffon);
        _guide_view.add_color(forestgreen);
        _guide_view.display_color();
    }
public:
    Window _main_window;
    this(Window w,GuideView guide,Cell start_offset = Cell(0,0))
        out{
        assert(_table);
        assert(_in_view);
        assert(_render_text);
        assert(_guide_view);
        }
    body{ 
        _main_window = w;
        void set_view_offset(){
            // TODO: set start_offset 
        }
        setProperty("can-focus",1);

        _imm = new IMMulticontext();
        _menu = new Menu();
        _table = new BoxTable(_gridSpace);
        _manip_table = new ManipTable(_table,this);
        _interpreter = new InputInterpreter(_manip_table,this,_imm);
        _holding_area = new Rect(0,0,200,200);

        _in_view = new ReferTable(_table,start_offset,1,1);
        _guide_view = guide;
        _init_color_select();

        addOnKeyPress(&_interpreter.key_to_cmd);
        addOnFocusIn(&_focus_in);
        addOnFocusOut(&_focus_out);
        addOnRealize(&_when_realize);
        addOnUnrealize(&_when_unrealize);

        _setGrid();
        _render_text = new RenderTextBOX(this);

        addOnDraw(&_draw_callback);
        addOnButtonPress(&_onButtonPress);
        addOnSizeAllocate(&_when_sizeallocate);
        _imm.addOnCommit(&_when_commit);
        _imm.addOnPreeditChanged(&_when_preedit_changed);
        _imm.addOnPreeditStart(&_when_preedit_start);
        _imm.addOnPreeditEnd(&_when_preedit_end);
        _imm.addOnRetrieveSurrounding(&_when_retrieve_surrounding);

        _menu.append( new ImageMenuItem(StockID.CUT, cast(AccelGroup)null) );
        _menu.append( new ImageMenuItem(StockID.COPY, cast(AccelGroup)null) );
        _menu.append( new ImageMenuItem(StockID.PASTE, cast(AccelGroup)null) );
        _menu.append( new ImageMenuItem(StockID.DELETE, cast(AccelGroup)null) );
        _imm.appendMenuitems(_menu);

        _menu.attachToWidget(this, null);

        showAll();
    }
    void move_view(in Direct dir){
        _in_view.move_area(dir);
    }
    void zoom_in(){
        _gridSpace *= 1.15;
        _size_allocate();
        queueDraw();
    }
    void zoom_out(){
        if(_gridSpace<15) return;
        _gridSpace /= 1.15;
        _size_allocate();
        queueDraw();
    }
    void IM_FocusOut(){
        _imm.focusOut();
    }
    void toggle_grid_show(){
        _grid_show_flg = !_grid_show_flg;
    }
    void toggle_boxborder_show(){
        _show_contents_border = !_show_contents_border;
    }
    double get_x(in Cell c)const{ return (c.column - _in_view.offset.column) * _gridSpace ; }
    double get_y(in Cell c)const{ return (c.row - _in_view.offset.row) * _gridSpace ; }

   // アクセサ
    ReferTable get_view(){
        return _in_view;
    }
    int get_gridSize()const{
        return _gridSpace;
    }
    const(Rect) get_holdingArea()const{
        return _holding_area;
    }
    Cell get_view_max()const{
        return _in_view.max_cell();
    }
    Cell get_view_min()const{
        return _in_view.min_cell();
    }
    // アクセサにする意味ないかもしれません
    @property GuideView guide_view(){
        return _guide_view;
    }
    void set_msg(string msg){
        _guide_view.set_msg(msg);
    }
}

