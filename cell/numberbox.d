module cell.numberbox;

import cell.cell;
import cell.table;
import cell.contentbox;
public import text.text;
import text.tag;
import std.string;
import std.utf;
import std.conv;
import std.stdio;
import std.ascii;
import std.exception;
import glib.SimpleXML;
import util.direct;
import shape.shape;
debug(cell) import std.stdio;

import pango.PgCairo;
import pango.PgLayout;
import pango.PgFontDescription;
import pango.PgAttribute;
import pango.PgAttributeList;
import cell.textbox;

// Text自体をTableに取り付けるためにBOX領域を管理する
final class NumberBOX : TextBOX{  
    public:
        this(BoxTable table,string family,string style,in Color back,in Color fore){ 
            super(table,family,style,back,fore,true);
        }
        this(BoxTable table,string[] dat){
            super(table,dat);
        }        
        override bool require_create_in(in Cell c){
            return _table.try_create_in!(NumberBOX)(this,c);
        }
        override void insert(in string s){
            foreach(dchar c; s)
            {
                if(!c.isHexDigit)
                    return;
                else 
                    _text.insert(c);
            }
        }
        override void append(in string s){
            int feed_cnt;
            foreach(dchar c; s)
            {
                if(!c.isHexDigit)
                    return;
                else 
                    _text.append(c);
            }
            _text.caret_move_forward(s.length - feed_cnt);
        }
        // override true join(){}
        // 現状caretは改行時のみの使用になってる
        override string dat(in Cell offset=Cell(0,0)){
            return super.dat(offset,"NumberBOX");
        }
}
