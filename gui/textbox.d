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
import pango.PgAttributeList;

import shape.shape;

class RenderTextBOX : BoxRenderer{
private: 
    alias int Line;
    TextBOX _render_target; // renderが各BOXごとに呼ばれるので切り替わる
    TextBOX _im_target; // IM使ってるであろうcurrentBOX 
    int _im_target_id;

    // stored info to show table
    alias int BoxId;
    Rect[BoxId] _box_pos;
    PgLayout[Line][BoxId] _layout;
    PgFontDescription[BoxId] _desc;
    PgAttributeList[BoxId] _attrilst;

    string[Line][BoxId] _strings;

    int _currentline; // preedit のために保持
    string _preedit;

    ubyte[BoxId] _fontsize;
    int[int][BoxId] _width,_height;
    Color[BoxId] _fontcolor;
    int _gridSize;
public:
    this(TableView tv)
    body{
        super(tv);
    }
    // 描くだけじゃなく描画域によってBOXを書き換える
    void render(Context cr,TextBOX box){
        debug(gui) writeln("@@@@ render textbox start @@@@");
        // get info and update class holded one
        if(box.empty()) return;
        auto box_id = box.id();
        _gridSize = get_gridSize();
        _box_pos[box_id] = get_position(box); // gui.render_box::get_position
        _box_pos[box_id].y += _gridSize/3;
        _fontsize[box_id] = box.font_size;    //  !!TextBOXで変更できるように 
        _fontcolor[box_id] = box.font_color;             //  !!なったら変更 
        auto numof_lines = box.getText().numof_lines();
        _currentline = box.getText().current_line();
            
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
                auto pre_box = box.get_cells();

                auto box_width = _gridSize * box.numof_col();
                debug(gui) writefln("box width %d",box_width);

                auto sorted_width = _width[box_id].values.sort;
                auto max_width = sorted_width[$-1];
                // auto min_width = sorted_width[0];

                // expand後の box_widthで揺らがないように調整必要
                // 次のループではbox_widthの大きさは変わってる
                if(max_width > box_width)
                    box.require_expand(Direct.right); 
                else
                if(max_width < box_width-_gridSize)
                {
                    box.require_remove(Direct.right);
                }
                // 整形後と前が揺らがず一致したら終了
                if(pre_box == box.get_cells())
                    break;

            }while(true);
        }
        void render_preedit()
        {
            debug(gui) writeln("render preedit start");
            // if(_currentline !in _layout)  <- 改行後現れなくなる
            // 固定化されているBOXならここを通らなくていい
            _layout[_im_target_id][_currentline] = PgCairo.createLayout(cr); // 
            _layout[_im_target_id][_currentline].setFontDescription(_desc[_im_target_id]);

            if(_im_target_id !in _width || _currentline !in _width[_im_target_id])   
                _width[_im_target_id][_currentline] = 0;

            _layout[_im_target_id][_currentline].setAttributes(_attrilst[_im_target_id]);
            _layout[_im_target_id][_currentline].setText(_preedit);

            cr.set_color(_fontcolor[box_id]);  // 初回のpreeditのため(だけ)に必要
            cr.moveTo(_box_pos[_im_target_id].x + _width[_im_target_id][_currentline],
                      _box_pos[_im_target_id].y + _currentline*_gridSize );
            PgCairo.updateLayout(cr,_layout[_im_target_id][_currentline]);
            PgCairo.showLayout(cr,_layout[_im_target_id][_currentline]);

            debug(text) writeln("preedit text ",_preedit);
            set_preeditting(false);
            debug(gui) writeln("#### render textbox end ####");
        }
        void checkBOX(TextBOX box)
        {
            debug(gui) writeln("checkBOX start");
            if(_render_target != box){

                _desc[box_id] = PgFontDescription.fromString(box.get_fontname~_fontsize[box_id]);
                _render_target = box;

                _layout[box_id][0] = PgCairo.createLayout(cr);
                _layout[box_id][0].setFontDescription(_desc[box_id]);

                cr.set_color(_fontcolor[box_id]);
            }
            debug(gui) writeln("end");
        }
        
        checkBOX(box);
        _strings[box_id] = box.getText().strings;
        debug(text) writeln("strings are ",_strings[box_id]);

        foreach(line,one_line; _strings[box_id])
        {
            if(one_line.empty) continue;
            // if(line !in _layout) <- IMのpreedit位置が最初の位置にも反映されてしまう
            int newIndex,newTraing;
            _layout[box_id][line] = PgCairo.createLayout(cr);
            _layout[box_id][line].setFontDescription(_desc[box_id]);

            debug(gui) writeln("write position: ",_box_pos[box_id].x," ",_box_pos[box_id].y);
            cr.set_color(_fontcolor[box_id]);

            auto lines_y = _box_pos[box_id].y + _gridSize * line;
            cr.moveTo(_box_pos[box_id].x,lines_y);
            _layout[box_id][line].setText(one_line);
            PgCairo.updateLayout(cr,_layout[box_id][line]);
            PgCairo.showLayout(cr,_layout[box_id][line]);

            // get real ocupied width and height
            // render_preedit より前に取得する必要がある
            _layout[box_id][line].getPixelSize(_width[box_id][line],_height[box_id][line]);
            debug(gui) writefln("_layout width %d",_width[box_id][line]);

            debug(gui) writefln("wt %s",one_line);
        }

        if(is_preediting() && _im_target_id == box_id)
            render_preedit();
        if(!_strings[box_id].keys.empty)
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
        immutable id = _im_target.id();
        _im_target_id = id;

        auto pos = get_window_position(box);
        auto cursorL = pos.get_struct!(Rectangle)();// Rectangle(_im_target.
        int cursor_pos;
        imc.setCursorLocation(cursorL);
        imc.getPreeditString(_preedit,_attrilst[id],cursor_pos);
        _render_target.set_cursor_pos(cursor_pos);

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
    public auto get_surrounding(){
        debug(gui) writeln("get surrounding start");
        // _im_target.cursor_pos = _im_target.getText.caret().column;
        writeln("cursor_pos: ",_im_target.cursor_pos); 
        return tuple(_strings[_im_target_id][_currentline],_im_target.cursor_pos);
        debug(gui) writeln("end");
    }
}
 
