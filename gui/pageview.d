module gui.pageview;

import gui.tableview;
import gui.guideview;
import std.string;
import std.array;
import env;
import cell.cell;
import cell.table;
import cell.contentbox;
import cell.imagebox;
import cell.refer;
import cell.textbox;
import text.text;
import manip;
import util.direct;
import std.algorithm;
import gui.textbox;
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
    GtkAllocation holding; // この2つの表すのは同じもの
    Rect holding_area;  // 内部処理はこちらを使う

    ManipTable manip_table; // tableに対する操作: 操作に伴う状態を読み取り描画する必要がある
    BoxTable table;    // 描画すべき対象: 
    ReferTable in_view;    // table にattachされた 表示領域
    Menu menu;

    InputInterpreter interpreter;
    // RenderImage render_image;
    RenderTextBOX render_text;
    IMMulticontext imm;

    GuideView guide_view;

    ubyte renderdLineWidth = 2;
    ubyte selectedLineWidth = 2;
    ubyte manipLineWidth = 2;
    Color grid_color = Color(48,48,48,96);
    Color selected_cell_border_color = Color("#00e4e4",128);
    Color normal_focus_color = Color(cyan,128);
    Color selected_focus_color = Color(cyan,168);
    Color manip_box_color = Color(darkorange,128);

    bool grid_show_flg = true;
    Lines grid;
    LinesDrawer drw_grid;
    int gridSpace =32; // □の1辺長
    ubyte grid_width = 1;

    bool on_key_press(Event ev,Widget w){
        return interpreter.key_to_cmd(ev,w);
    }
    bool on_key_release(Event ev,Widget w){
        return cast(bool)imm.filterKeypress(ev.key());
    }
    bool onButtonPress(Event event, Widget widget)
    {
        if ( event.type == EventType.BUTTON_PRESS )
        {
            GdkEventButton* buttonEvent = event.button;

            if ( buttonEvent.button == 3)
            {
                menu.showAll();
                menu.popup(buttonEvent.button, buttonEvent.time);
                return true;
            }
        }
        return false;
    }
    void commit(string str,IMContext imc){
        if(interpreter.state == InputState.edit)
        {
            manip_table.im_commit_to_box(str);
            queueDraw();
        }
    }
    void preedit_changed(IMContext imc){
        if(interpreter.state == InputState.edit)
        {
            auto inputted_box = manip_table.get_target();
            render_text.prepare_preedit(imm,cast(TextBOX)inputted_box);
            // レイアウトのことは投げる
            // IMContextごと
            queueDraw();
            // DrawにいれてPreeditを描く必要がある
        }
    }
    // ascii mode に切り替わったことを期待してみるようなところ
    // IMContextの実装依存がどの程度なのか
    void preedit_end(IMContext imc){
        if(interpreter.state == InputState.edit)
        {
        }
    }
    void preedit_start(IMContext imc){
    }
    bool retrieve_surrounding(IMContext imc){
        auto surround = render_text.get_surrounding();
        imc.setSurrounding(surround[0],surround[1]);
        return true;
    }
    bool focus_in(Event ev,Widget w){
        imm.focusIn();
        return true;
    }
    bool focus_out(Event ev,Widget w){
        imm.focusOut();
        return true;
    }
    void realize(Widget w){
        imm.setClientWindow(getParentWindow());
    }
    void unrealize(Widget w){
        imm.setClientWindow(null);
    }
    void set_holding_area()
        in{
        assert(holding_area);
        }
        out{
        assert(holding_area.w > 0);
        assert(holding_area.h > 0);
        }
    body{
        getAllocation(holding);
        holding_area.set_by(holding);
    }
    void set_view_size(){
        in_view.set_range(in_view.offset,
                cast(int)(holding_area.w/gridSpace),
                cast(int)(holding_area.h/gridSpace));
    }
    Rect back;
    RectDrawer backdrw;
    void backDesign(Context cr){
        back = new Rect(0,0,holding_area.w,holding_area.h);
        back.set_color(orange);
        backdrw = new RectDrawer(back);

        backdrw.clip(cr);
    }
    bool show_contents_border = true;
    void renderTable(Context cr){
        debug(gui) writeln("@@@@ render table start @@@@");
        if(in_view.empty) return;

        foreach(tb; in_view.get_textBoxes())
        {
            debug(gui) writeln("render textbox");
                if(show_contents_border)
                {
                    render_text.render_fill(cr,tb,Color(linen,96));
                    render_text.render_grid(cr,tb,Color(gold,128),1);
                }
                    render(cr,tb);
        }
        foreach(ib; in_view.get_imageBoxes())
        {
            debug(gui) writeln("render textbox");
                if(show_contents_border)
                {
                    render_text.render_grid(cr,ib,Color(gold,128),1);
                }
                    ib.set_rect();
                    ib.fill(cr,orange);

        }

        render_text.render_grid(cr,manip_table.get_target(),manip_box_color,manipLineWidth);

        debug(gui) writeln("#### render table end ####");
    }
    // renderするだけじゃなく描画域によってCellのサイズを修正する
    // Pangoしか知り得ないことを迂回して教えるよりはいいかと
    // BoxSizeの修正くらいならいいだろう
            // BoxSize修正のためのInterfaceをCMDに晒したほうがいい
    void render(Context cr,TextBOX b){
        render_text.render(cr,b);
    }
    
    bool draw_callback(Context cr,Widget widget){
        debug(gui) writeln("draw callback");
        backDesign(cr);
        if(grid_show_flg) renderGrid(cr);
        renderTable(cr);
        renderSelection(cr);
        renderFocus(cr);
        cr.resetClip(); // end of rendering
        debug(gui) writeln("end");
        return true;
    }
    void setGrid(){
        grid = new Lines();
        grid.set_color(grid_color);
        grid.set_width(grid_width);
        for(double y = 0; y < holding_area.h ; y += gridSpace)
        {
            auto start = new Point(0,y);
            auto end = new Point(holding_area.w,y);
            grid.add_line(new Line(start,end,grid_width));
        }
        for(double x = 0 ; x < holding_area.w ; x += gridSpace)
        {
            auto start = new Point(x,0);
            auto end = new Point(x, holding_area.h);
            grid.add_line(new Line(start,end,grid_width));
        }
        drw_grid = new LinesDrawer(grid);
    }
    void renderGrid(Context cr){
        drw_grid.stroke(cr);
    }
    void renderFocus(Context cr){
        // 現在は境界色を変えてるだけだけど
        // 考えられる他の可能性のために
        // e.g. cell内部色を変えるとか（透過させるとか
        final switch(manip_table.mode)
        {
            case focus_mode.normal:
                FillCell(cr,manip_table.select.focus,normal_focus_color); 
                break;
            case focus_mode.select:
                FillCell(cr,manip_table.select.focus,selected_focus_color); 
                break;
            case focus_mode.edit:
                // FillCell(cr,manip_table.select.focus,selected_focus_color); 
                // Text編集中,IMに任せるため
                break;
        }
    }
    void renderSelection(Context cr){
        FillGrids(cr,manip_table.select.get_cells(),
                selected_cell_border_color);
    }
    void when_sizeallocate(GdkRectangle* n,Widget w){
        set_holding_area();
        set_view_size();
        setGrid();
    }
public:
    this(GuideView guide,Cell start_offset = Cell(0,0))
        out{
        assert(table);
        assert(in_view);
        assert(render_text);
        // assert(render_image);
        assert(select);
        assert(select_drwer);
        }
    body{ 
        void init_selecter(){
            select = new Rect(0,0,gridSpace,gridSpace);
            select_drwer = new RectDrawer(select);
        }
        void set_view_offset(){
            // TODO: set start_offset 
        }

        setProperty("can-focus",1);

        imm = new IMMulticontext();
        menu = new Menu();
        table = new BoxTable();
        manip_table = new ManipTable(table,this);
        interpreter = new InputInterpreter(manip_table,this,imm);
        holding_area = new Rect(0,0,200,200);

        in_view = new ReferTable(table,start_offset,1,1);
        guide_view = guide;

        addOnKeyPress(&interpreter.key_to_cmd);
        addOnFocusIn(&focus_in);
        addOnFocusOut(&focus_out);
        addOnRealize(&realize);
        addOnUnrealize(&unrealize);

        init_selecter();
        setGrid();
        render_text = new RenderTextBOX(this);
        // render_image = new RenderImage(this);

        addOnDraw(&draw_callback);
        addOnButtonPress(&onButtonPress);
        addOnSizeAllocate(&when_sizeallocate);
        imm.addOnCommit(&commit);
        imm.addOnPreeditChanged(&preedit_changed);
        imm.addOnPreeditStart(&preedit_start);
        imm.addOnPreeditEnd(&preedit_end);
        imm.addOnRetrieveSurrounding(&retrieve_surrounding);

        menu.append( new ImageMenuItem(StockID.CUT, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.COPY, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.PASTE, cast(AccelGroup)null) );
        menu.append( new ImageMenuItem(StockID.DELETE, cast(AccelGroup)null) );
        imm.appendMenuitems(menu);

        menu.attachToWidget(this, null);

        showAll();
    }
    void move_view(in Direct dir){
        in_view.move_area(dir);
    }
    void zoom_in(){
        ++gridSpace;
    }
    void zoom_out(){
        if(gridSpace)  --gridSpace;
    }
    void toggle_grid_show(){
        grid_show_flg = !grid_show_flg;
    }
    void toggle_boxborder_show(){
        show_contents_border = !show_contents_border;
    }
    Rect select;
    RectDrawer select_drwer;
    double get_x(in Cell c)const{ return (c.column - in_view.offset.column) * gridSpace ; }
    double get_y(in Cell c)const{ return (c.row - in_view.offset.row) * gridSpace ; }

   // アクセサ
public:
    ReferTable get_view(){
        return in_view;
    }
    int get_gridSize()const{
        return gridSpace;
    }
    const(Rect) get_holdingArea()const{
        return holding_area;
    }
    Cell get_view_max()const{
        return in_view.max_cell();
    }
    Cell get_view_min()const{
        return in_view.min_cell();
    }
}

