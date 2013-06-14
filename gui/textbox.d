module gui.textbox;

import gui.tableview;
import gui.render_box;
import cell.textbox;
import cell.cell;
import cell.contentbox;
import cell.collection;
import cell.table;
import text.text;
import util.direct;
import util.color;
import std.array;
import std.string;
import std.typecons;
import std.stdio;

import gtk.IMContext;

import cairo.Context;
import cairo.FontOption;
import cairo.Surface;
import cairo.ImageSurface;

import gtkc.pangotypes;
import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;
import pango.PgAttribute;
import pango.PgAttributeList;

import shape.shape;

/+ memo
PgLayout::indexToPos で矩形範囲をとれる
PgLayout::xyToPos
PgLayout::getCursorPos

PgLayout::getLineReadonly(int line)
+/

/+
    Drawer for TextBOX(cell.textbox(wraper of Text))  
    Derived from BoxRenderer(gui.renderbox)
        package methods:
        final:
        Rect window_position(in CellContent);
        void render_grid(Context,in CellContent,in Color,int width);
        void render_fill(Context,in ContentBOX,in Color)
        void render_fill(Context,in ContentFlex,in Color)
        double[2] get_center(in ContentBOX)const;
        int get_gridSize()const;

+/

// 描くだけじゃなく描画域によってBOXを書き換えてしまう
// IMがPixelに反映する領域を他の部分(描画部分以外)から知り得ないから、
// 分離するのだとしてもここからたらい回しするほかないと思う
class RenderTextBOX : BoxRenderer{
private: 
    alias int Line;
    TextBOX _render_target; // renderが各BOXごとに呼ばれるので切り替わる
    TextBOX _im_target; // IM使ってるであろうcurrentBOX 
    int _im_target_id;

    // stored info to show table
    alias int BoxId;
    Rect[BoxId] _box_pos;
    PgLayout[BoxId] _layout;
    PgAttributeList[BoxId] _attrilst;
    PgAttributeList _im_attr;

    string[BoxId] _strings;
    int _currentline; // preedit のために保持
    string _preedit;

    // Rectを取得して入れてる.その取得元のx,yは_box_posを使って設定されてる
    // Rectで保持するとその依存関係がわかりにくくなりそう
    // 根本的には、LayoutLineでPixelWidth取るのがめんどくさそうなの直せばいい
    int[BoxId][Line] _width;
    int[BoxId] _height;
    // 一応保持しとく
    PangoRectangle[Line] _logicRect;
    PangoRectangle _caretRect;
    int _gridSize;
public:
    this(TableView tv){
        super(tv);
    }
    void render(Context cr,TextBOX box){
        debug(gui) writeln("@@@@ render textbox start @@@@");

        // get info and update class holded info
        if(box.empty()) return;
        immutable box_id = box.id();
        _gridSize = get_gridSize();
        _box_pos[box_id] = context_position(box); // gui.render_box::get_position
        _box_pos[box_id].y += _gridSize;
        _currentline = box.getText().current_line();
        const numof_lines = box.getText().numof_lines();
            
        void register_check(TextBOX box)
        {
            debug(gui) writeln("checkBOX start");
            if(box_id !in _box_pos)
                _box_pos[box_id] = Rect.init;
            if(box_id !in _attrilst)
                _attrilst[box_id] = PgAttributeList.init;
            if(box_id !in _width)
                _width[box_id] = null;
            if(box_id !in _strings)
                _strings[box_id] = string.init;
            if(_render_target != box)
            {
                _render_target = box;
                _layout[box_id] = PgCairo.createLayout(cr);
            }
            foreach(l; 0 .. box.numof_lines)
                _logicRect[l] = PangoRectangle.init;
            debug(gui) writeln("end");
        }

        register_check(box);
        string markup_str = box.markup_string();
        import std.stdio;
        writeln(markup_str);
        if(markup_str)
        {
            const markup_len = cast(int)markup_str.length;
            PgAttribute.parseMarkup(markup_str,markup_len,0,_attrilst[box_id],_strings[box_id],null);
            _layout[box_id].setMarkup(markup_str,markup_len);
            _layout[box_id].indexToPos(box.get_caret,&_caretRect);
            auto caret = new Rect(_caretRect);
            writeln(box.get_caret);
            writeln(_caretRect);
            caret.set_color(red);
            fill(cr,caret);
        }
        for(int line; line < box.numof_lines; ++line )
        {
            auto line_layout = _layout[box_id].getLineReadonly(line);
            int newIndex,newTraing;

            const lines_y = _box_pos[box_id].y + _gridSize * line;
            cr.moveTo(_box_pos[box_id].x,lines_y);
            PgCairo.showLayoutLine(cr,line_layout);

            // get real ocupied width and height
            // render_preedit より前に取得する必要がある
            line_layout.getPixelExtents(null,&_logicRect[line]);
            _width[box_id][line] = _logicRect[line].width;
            _height[box_id] = _logicRect[line].height;
        }

        void render_preedit()
        {   // 固定化されているBOXならここを通らなくていい
            debug(gui) writeln("render preedit start");
            if(_im_target_id !in _width || _currentline !in _width[_im_target_id])   
                _width[_im_target_id][_currentline] = 0;

            auto layout = PgCairo.createLayout(cr);
            layout.setAttributes(_im_attr);
            layout.setFontDescription(_im_target.font_desc());
            layout.setText(_preedit);

            cr.set_color(box.current_foreground);
            cr.moveTo(_box_pos[_im_target_id].x + _width[_im_target_id][_currentline],
                      _box_pos[_im_target_id].y + _currentline * _gridSize - _im_target.current_fontsize() - 5);
            PgCairo.updateLayout(cr,layout);
            PgCairo.showLayout(cr,layout);

            debug(text) writeln("preedit text ",_preedit);
            set_preeditting(false);
            debug(gui) writeln("#### render textbox end ####");
        }
        void  modify_boxsize()
        {   /+
              描画された領域のサイズでBOXを変形させる
              フォントの大きさを順守するため
              1Cell1Charモードならここは通るな通すな

              他に何通りかの挙動が考えられる
                 1行目の横幅で自動改行
                 自動expnad <= 下の実装
                 横に圧縮して無理やり入れる
                 Cellごと縮小して無理やり入れる
              
              確定された(固定化された)BOX はこの処理を通したくない
              TODO 確定されたBOXの定義
            +/
            if(box_id !in _width) return;

            do
            {
                const cells_snap = box.get_cells();
                const box_width = _gridSize * box.numof_col();
                debug(gui) writefln("box width %d",box_width);

                const calced_width = _width[box_id].values.sort[$-1];

                // expand後の box_widthで揺らがないように調整必要
                // 次のループではbox_widthの大きさは変わってる
                if(calced_width > box_width)
                    box.require_expand(Direct.right); 
                else
                if(calced_width < box_width-_gridSize)
                {
                    box.require_remove(Direct.right);
                }
                // 整形後と前が揺らがず一致したら終了
                if(cells_snap == box.get_cells())
                    break;

            } while(1);
        }
        if(is_preediting() && _im_target_id == box_id)
            render_preedit();
        if(!_render_target.empty)
            modify_boxsize();
        debug(gui) writeln("text render end");
    }
    public void prepare_preedit(IMContext imc,TextBOX box)
        out{
        assert(_im_target_id == box.id);
        }
    body{
        debug(text) writeln("prepare_preedit start");
        _im_target = box;
        immutable box_id = _im_target.id();
        _im_target_id = box_id;
        _gridSize = get_gridSize();

        auto box_pos = window_position(box);
        auto im_rect = cast(cairo_rectangle_int_t)_logicRect[_currentline];
        im_rect.x += box_pos.x;
        im_rect.y += box_pos.y + _gridSize * (_currentline + 1);

        int cursor_pos;
        imc.setCursorLocation(im_rect);
        imc.getPreeditString(_preedit,_im_attr,cursor_pos);
        _im_attr.insert(PgAttribute.fontDescNew(_im_target.font_desc));
        _im_target.set_cursor_pos(cursor_pos);

        set_preeditting(true);
        debug(text) writeln("end");
    }
    public void retrieve_surrouding(IMContext imc){
    }
    private bool _preeditting;
    private bool is_preediting(){
        return _preeditting;
    }
    private void set_preeditting(in bool b){
        _preeditting = b;
    }
    public Tuple!(string,int) get_surrounding(){
        debug(gui) writeln("get surrounding start");
        // _im_target.set_cursor_pos(_im_target.getText.caret().column);
        writeln("cursor_pos: ",_im_target.cursor_pos); 
        return tuple(_strings[_im_target_id],_im_target.cursor_pos);
        debug(gui) writeln("end");
    }
}
 
