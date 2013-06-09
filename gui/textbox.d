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
    // PgFontDescription[BoxId] _desc;
    PgAttributeList[BoxId] _attrilst;
    PgAttributeList _im_attr;

    string[BoxId] _strings;

    int _currentline; // preedit のために保持
    string _preedit;

    ubyte[BoxId] _fontsize;
    // BOXは矩形なのでべつにlineごとに持たなくていい
    int[BoxId] _width,_height;
    Color[BoxId] _foreground;
    int _gridSize;
public:
    this(TableView tv)
    body{
        super(tv);
    }
    // 描くだけじゃなく描画域によってBOXを書き換える
    void render(Context cr,TextBOX box){
        debug(gui) writeln("@@@@ render textbox start @@@@");

        // get info and update class holded info
        if(box.empty()) return;
        immutable box_id = box.id();
        _gridSize = get_gridSize();
        _box_pos[box_id] = get_position(box); // gui.render_box::get_position
        _box_pos[box_id].y += _gridSize;
        // _fontsize[box_id] = cast(ubyte)_gridSize; // box.font_size;    //  !!TextBOXで変更できるように 
        _foreground[box_id] = box.default_foreground;             //  !!なったら変更 
        _currentline = box.getText().current_line();
        const numof_lines = box.getText().numof_lines();
            
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

            do{
                const cells_snap = box.get_cells();
                const box_width = _gridSize * box.numof_col();
                debug(gui) writefln("box width %d",box_width);

                const calced_width = _width[box_id];
                // const max_width = sorted_width[$-1];

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

            }while(true);
        }
        void render_preedit()
        {
            debug(gui) writeln("render preedit start");
            // 固定化されているBOXならここを通らなくていい

            if(_im_target_id !in _width)   
                _width[_im_target_id] = 0;

            // _im_attr.insert(PgAttribute.fontDescNew(box.font_desc()));
            _layout[_im_target_id].setAttributes(_im_attr);
            _layout[_im_target_id].setFontDescription(box.font_desc());
            _layout[_im_target_id].setText(_preedit);

            // いろのせっていいるよ
            // 初回のpreeditのため(だけ)に必要
            cr.moveTo(_box_pos[_im_target_id].x + _width[_im_target_id],
                      _box_pos[_im_target_id].y + _currentline-1*_gridSize );
            PgCairo.updateLayout(cr,_layout[_im_target_id]);
            PgCairo.showLayout(cr,_layout[_im_target_id]);

            debug(text) writeln("preedit text ",_preedit);
            set_preeditting(false);
            debug(gui) writeln("#### render textbox end ####");
        }
        void register_check(TextBOX box)
        {
            debug(gui) writeln("checkBOX start");
            if(box_id !in _box_pos)
                _box_pos[box_id] = Rect.init;
            if(box_id !in _attrilst)
                _attrilst[box_id] = PgAttributeList.init;
            if(box_id !in _width)
                _width[box_id] = 0;
            if(box_id !in _strings)
                _strings[box_id] = string.init;
            if(_render_target != box){

                _render_target = box;
                _layout[box_id] = PgCairo.createLayout(cr);
                // desc とかmarkupparce
            }
            debug(gui) writeln("end");
        }

        register_check(box);
        string markup_str = box.markup_string();
        import std.stdio;
        writeln(markup_str);
        if(markup_str)
        {
            writeln("b line start");
            int markup_len = cast(int)markup_str.length;
            PgAttribute.parseMarkup(markup_str,markup_len,0,_attrilst[box_id],_strings[box_id],null);
            _layout[box_id].setMarkup(markup_str,markup_len);

            writeln("b line start");
        }
        for(int line; line < box.numof_lines; ++line )
        {
            // Readonly 使うべき
            auto line_layout = _layout[box_id].getLine(line);
            int newIndex,newTraing;

            writeln("write position: ",_box_pos[box_id].x," ",_box_pos[box_id].y);

            auto lines_y = _box_pos[box_id].y + _gridSize * line;
            cr.moveTo(_box_pos[box_id].x,lines_y);
            PgCairo.showLayoutLine(cr,line_layout);

            // get real ocupied width and height
            // render_preedit より前に取得する必要がある
            _width[box_id] = int.init;
            _height[box_id] = int.init;
        }
        _layout[box_id].getPixelSize(_width[box_id],_height[box_id]);

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

        auto pos = get_window_position(box);
        auto cursorL = pos.get_struct!(Rectangle)();// Rectangle(_im_target.
        int cursor_pos;
        imc.setCursorLocation(cursorL);
        imc.getPreeditString(_preedit,_im_attr,cursor_pos);
        _im_attr.insert(PgAttribute.fontDescNew(box.font_desc));
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
 
