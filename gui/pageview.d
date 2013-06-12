module gui.pageview;

import gui.tableview;
import gui.guideview;
import gui.textbox;
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
import text.text;
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

    ubyte renderdLineWidth = 2;
    ubyte selectedLineWidth = 2;
    ubyte manipLineWidth = 2;
    Color _grid_color = Color(48,48,48,96);
    Color selected_cell_border_color = Color("#00e4e4",128);
    Color normal_focus_color = Color(cyan,128);
    Color selected_focus_color = Color(cyan,168);
    Color manip_box_color = Color(darkorange,128);

    bool _grid_show_flg = true;
    LinesBOX _grids;

    int _gridSpace =32; // □の1辺長
    ubyte _grid_width = 1;

    bool on_key_press(Event ev,Widget w){
        return _interpreter.key_to_cmd(ev,w);
    }
    bool on_key_release(Event ev,Widget w){
        return cast(bool)_imm.filterKeypress(ev.key());
    }
    bool onButtonPress(Event event, Widget widget)
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
    void commit(string str,IMContext imc){
        if(_interpreter.can_edit())
        {
            _manip_table.im_commit_to_box(str);
            queueDraw();
        }
    }
    void preedit_changed(IMContext imc){
        if(_interpreter.can_edit())
        {
            auto inputted_box = cast(TextBOX)_manip_table.get_target();
            assert(inputted_box !is null);
            _render_text.prepare_preedit(_imm,inputted_box);
            // レイアウトのことは投げる
            // IMContextごと
            queueDraw();
            // Preeditを描かせる必要がある
        }
    }
    // ascii mode に切り替わったことを期待してみるようなところ
    void preedit_end(IMContext imc){
        if(_interpreter.state == InputState.Edit)
        {
        }
    }
    void preedit_start(IMContext imc){
    }
    bool retrieve_surrounding(IMContext imc){
        auto surround = _render_text.get_surrounding();
        imc.setSurrounding(surround[0],surround[1]);
        return true;
    }
    bool focus_in(Event ev,Widget w){
        _imm.focusIn();
        return true;
    }
    bool focus_out(Event ev,Widget w){
        _imm.focusOut();
        return true;
    }
    void realize(Widget w){
        _imm.setClientWindow(getParentWindow());
        _imm.focusOut();
    }
    void unrealize(Widget w){
        _imm.setClientWindow(null);
    }
    void set_holding_area()
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
    void set_view_size(){
        _in_view.set_range(_in_view.offset,
                cast(int)(_holding_area.w/_gridSpace),
                cast(int)(_holding_area.h/_gridSpace));
    }
    // void backDesign(Context cr){
    // }
    bool _show_contents_border = true;
    void renderTable(Context cr){
        debug(gui) writeln("@@@@ render table start @@@@");
        if(_in_view.empty) return;

        foreach(tb; _in_view.get_textBoxes())
        {
            debug(gui) writeln("render textbox");
            if(_show_contents_border)
            {
                _render_text.fill(cr,tb,Color(linen,96));
                _render_text.stroke(cr,tb,Color(gold,128),1);
            }
            render(cr,tb);
        }
        foreach(ib; _in_view.get_imageBoxes())
        {
            debug(gui) writeln("render textbox");
            if(_show_contents_border)
            {
                _render_text.stroke(cr,ib,Color(gold,128),1);
            }
            ib.fill(cr);
        }

        _render_text.stroke(cr,_manip_table.get_target(),manip_box_color,manipLineWidth);

        debug(gui) writeln("#### render table end ####");
    }
    // renderするだけじゃなく描画域によってCellのサイズを修正する
    // Pangoしか知り得ないことを迂回して教えるよりはいいかと
    // BoxSizeの修正くらいならいいだろう
            // BoxSize修正のためのInterfaceをCMDに晒したほうがいい
    void render(Context cr,TextBOX b){
        _render_text.render(cr,b);
    }
    
    bool draw_callback(Context cr,Widget widget){
        debug(gui) writeln("draw callback");
        // backDesign(cr);
        if(_grid_show_flg) renderGrid(cr);
        renderTable(cr);
        renderSelection(cr);
        renderFocus(cr);
        cr.resetClip(); // end of rendering
        debug(gui) writeln("end");
        return true;
    }
    void setGrid(){
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
    void renderGrid(Context cr){
        _grids.stroke(cr);
    }
    void renderFocus(Context cr){
        // 現在は境界色を変えてるだけだけど
        // 考えられる他の可能性のために
        // e.g. cell内部色を変えるとか（透過させるとか
        final switch(_manip_table.mode)
        {
            case FocusMode.normal:
                FillCell(cr,_manip_table.select.focus,normal_focus_color); 
                break;
            case FocusMode.select:
                FillCell(cr,_manip_table.select.focus,selected_focus_color); 
                break;
            case FocusMode.edit:
                // FillCell(cr,_manip_table.select.focus,selected_focus_color); 
                // Text編集中,IMに任せるため
                // editモード細分化する?
                break;
            case FocusMode.point:
                PointCell(cr,_manip_table.select.focus,green);
                break;
        }
    }
    void renderSelection(Context cr){
        FillGrids(cr,_manip_table.select.get_cells(),
                selected_cell_border_color);
    }
    void when_sizeallocate(GdkRectangle* n,Widget w){
        set_holding_area();
        set_view_size();
        setGrid();
    }
public:
    // ConfigFileから読むようにしたい
    void init_color_select(){
        _manip_table.select_color(black);
        _guide_view.add_color(black);
        _guide_view.add_color(darkorange);
        _guide_view.add_color(violet);
        _guide_view.add_color(plum);
        _guide_view.add_color(cadetblue);
        _guide_view.add_color(cyan);
        _guide_view.add_color(firebrick);
        _guide_view.add_color(peachpuff);
        _guide_view.add_color(mediumaquamarine);
        _guide_view.add_color(dimgray);
        _guide_view.add_color(gold);
        _guide_view.add_color(linen);
        _guide_view.add_color(darkgoldenrod);
        _guide_view.add_color(lemonchiffon);
        _guide_view.add_color(forestgreen);
        _guide_view.display_color();
    }
    this(GuideView guide,Cell start_offset = Cell(0,0))
        out{
        assert(_table);
        assert(_in_view);
        assert(_render_text);
        assert(_guide_view);
        }
    body{ 
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
        init_color_select();

        addOnKeyPress(&_interpreter.key_to_cmd);
        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        addOnRealize(&realize);
        addOnUnrealize(&unrealize);

        setGrid();
        _render_text = new RenderTextBOX(this);

        addOnDraw(&draw_callback);
        addOnButtonPress(&onButtonPress);
        addOnSizeAllocate(&when_sizeallocate);
        _imm.addOnCommit(&commit);
        _imm.addOnPreeditChanged(&preedit_changed);
        _imm.addOnPreeditStart(&preedit_start);
        _imm.addOnPreeditEnd(&preedit_end);
        _imm.addOnRetrieveSurrounding(&retrieve_surrounding);

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
        ++_gridSpace;
        setGrid();
        _table.set_gridsize(_gridSpace);
        queueDraw();
    }
    void zoom_out(){
        if(_gridSpace>15)  --_gridSpace;
        setGrid();
        _table.set_gridsize(_gridSpace);
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
public:
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
}

