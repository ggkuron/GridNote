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
import std.conv;

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
import pango.PgTabArray;

import shape.shape;

/+ memo

PgLayout::indexToPos で矩形範囲をとれる
PgLayout::xyToPos
PgLayout::getCursorPos

PgLayout::getLineReadonly(int line) getLineより高速
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

// 描くだけじゃなく描画域によってBOXを書き換えてしまってる
class RenderTextBOX : BoxRenderer{
private: 
    alias int Line;
    TextBOX _render_target; // renderが各BOXごとに呼ばれるので切り替わる
    TextBOX _im_target; // IM使ってるであろうcurrentBOX 
    int _im_target_id;

    alias int BoxId;
    Rect[BoxId] _box_pos;
    PgLayout[BoxId] _layout;
    PgAttributeList[BoxId] _attrilst;
    PgAttributeList _im_attr;
    
    IMContext _imc;
    bool _preeditting;
    bool is_preediting(){
        return _preeditting;
    }
    void set_preeditting(in bool b){
        _preeditting = b;
    }
    int _im_pos;

    string[BoxId] _strings;
    int _currentline; // preedit のために保持
    string _preedit;

    // Rectを取得して入れてる.その取得元のx,yは_box_posを使って設定されてる
    // Rectで保持するとその依存関係がわかりにくくなりそう
    // 根本的には、LayoutLineでPixelWidth取るのがめんどくさそうなのをどうにかすれば分離できてよさそう
    int[BoxId][Line] _width;
    int[BoxId] _height;
    // 一応保持してる
    Rect _caret_rect;
    PangoRectangle[Line] _logicRect;
    PangoRectangle _caretRect;
    int _gridSize;
public:
    this(TableView tv){
        super(tv);
        _caret_rect = new Rect();
    }
    alias renderT!(TextBOX) render;
    alias renderT!(CodeBOX) render;
    void renderT(TB:TextBOX)(Context cr, TB box, bool fixed = false){ // get info and update class held info
        immutable box_id = box.id();
        _gridSize = get_gridSize();
        _box_pos[box_id] = context_position(box); // gui.render_box::get_position
        _box_pos[box_id].y += _gridSize;
        _currentline = box.cursor_line();
        const numof_lines = box.numof_lines();
            
        void _register_check(TextBOX box)
        {
            if(box_id !in _box_pos)
                _box_pos[box_id] = Rect.init;
            if(box_id !in _attrilst)
                _attrilst[box_id] = PgAttributeList.init;
            if(box_id !in _width)
                _width[box_id] = null;
            if(box_id !in _strings)
                _strings[box_id] = string.init;
            if(_render_target != box)
                _render_target = box;
            if(box_id !in _layout)
                _layout[box_id] = PgCairo.createLayout(cr);
            foreach(l; 0 .. box.numof_lines)
                _logicRect[l] = PangoRectangle.init;
        }
        double lines_y(in int l){
            return _box_pos[box_id].y + _gridSize * l;
        }
        void _update_caret_rect(){
            if(!is_preediting) _im_pos = 0;
            assert(box_id == _im_target_id);
            _layout[box_id].indexToPos(box.get_caret,&_caretRect); // _layout[box_id].getCursorPos(box.get_caret,&_caretRect,null);
            _caret_rect.set_by(_caretRect);
            _caret_rect.x /= 1024;
            _caret_rect.x += _box_pos[box_id].x;
            _caret_rect.y = lines_y(_currentline) - _gridSize;
            _caret_rect.w /= 1024; // = _gridSize*3/4;
            _caret_rect.h = _gridSize;
            if(_caret_rect.w == 0) // 挿入位置に何もまだ入ってない状態
                _caret_rect.w = _gridSize/4;
        }
        void render_preedit() {   // 固定化されているBOXならここを通らなくていい
            if(_im_target_id !in _width || _currentline !in _width[_im_target_id])   
                _width[_im_target_id][_currentline] = 0;

            assert(box_id == _im_target_id);
            auto layout = PgCairo.createLayout(cr);
            layout.setAttributes(_im_attr);
            layout.setFontDescription(_im_target.font_desc());
            layout.setText(_preedit);

            _update_caret_rect();
            auto im_rect = _caret_rect.get_struct!(cairo_rectangle_int_t)();
            im_rect.x += _table_view.get_holdingArea.x;
            im_rect.height = _gridSize;
            _imc.setCursorLocation(im_rect);

            cr.set_color(box.current_foreground);
            cr.moveTo(_caret_rect.x,  // _box_pos[_im_target_id].x + _width[_im_target_id][_currentline],
                      _caret_rect.y); //_box_pos[_im_target_id].y + _currentline * _gridSize - _im_target.current_fontsize() - 5);
            PgCairo.updateLayout(cr,layout);
            PgCairo.showLayout(cr,layout);

            set_preeditting(false);
        }
        void  modify_boxsize() {   
            /+
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

            do {
                const cells_snap = box.get_cells();
                const box_width = _gridSize * box.numof_col();
                debug(gui) writefln("box width %d",box_width);

                const calced_width = _width[box_id].values.sort[$-1];

                // expand後の box_widthで揺らがないように調整必要
                // 次のループではbox_widthの大きさは変わってる
                if(calced_width > box_width)
                    box.require_expand(Direct.right); 
                else if(calced_width < box_width-_gridSize) {
                    box.require_remove(Direct.right);
                }
                // 整形後と前が揺らがず一致したら終了
                if(cells_snap == box.get_cells())
                    break;
            } while(1);
        }

        _register_check(box);
        // textを持っていなくてIM入力もしてないなら描画しない
        // BOX生成直後のチェック後のここまでの処理は必要
        if(box.text_empty() && !is_preediting)
            return;

        string markup_str;
        if(!fixed && is_preediting() && _im_target_id == box_id) {
            markup_str = box.markup_string(_preedit);
            render_preedit();
        } else
            markup_str = box.markup_string("");

        debug(gui) writeln(markup_str);
        if(markup_str) {
            const markup_len = cast(int)markup_str.length;
            PgAttribute.parseMarkup(markup_str,markup_len,0,_attrilst[box_id],_strings[box_id],null);
            _layout[box_id].setMarkup(markup_str,markup_len);

            if(!fixed) {    
                _im_target_id = box.id;
                _update_caret_rect();
                _caret_rect.set_color(Color(lime,128));
                fill(cr,_caret_rect);
            }
        }
        const box_lines = box.numof_lines;
        const layout_lines = _layout[box_id].getLineCount();

        for(int line; line < box_lines; ++line ) {
            auto line_layout = _layout[box_id].getLineReadonly(line);
            int newIndex,newTraing;

            const line_y = lines_y(line);
            cr.moveTo(_box_pos[box_id].x,line_y);
            PgCairo.showLayoutLine(cr,line_layout);

            assert(line in _logicRect);
            line_layout.getPixelExtents(null,&_logicRect[line]);
            _width[box_id][line] = _logicRect[line].width;
            _height[box_id] = _logicRect[line].height;
        }
        if(!fixed && !_render_target.empty)
            modify_boxsize();
    }
    void prepare_preedit(IMContext imc,TextBOX box)
        out{
        assert(_im_target_id == box.id);
        }
    body{
        _im_target = box;
        immutable box_id = _im_target.id();
        _im_target_id = box_id;
        _imc = imc;

        imc.getPreeditString(_preedit,_im_attr,_im_pos);
        _im_attr.insert(PgAttribute.fontDescNew(_im_target.font_desc));

        set_preeditting(true);
    }
    void retrieve_surrouding(IMContext imc){ }
    Tuple!(string,int) get_surrounding(){
        if(_im_target_id !in _strings)
            _strings[_im_target_id] = "";
        return tuple(_strings[_im_target_id],_im_target.cursor_pos);
    }
}
