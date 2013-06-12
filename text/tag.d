module text.tag;

import text.text;
import std.string;
import std.conv;
import std.array;
public import gtkc.pangotypes;
import util.color;

alias PangoUnderline Underline;

/+ refer from gtkc.pangotypes
public enum PangoUnderline
{
	NONE,
	SINGLE,
	DOUBLE,
	LOW,
	ERROR
}
+/

struct SpanTag{
private:
    string[TagType] _tags;
    enum TagType{
      font_desc_tag,
      font_family_tag,
      face_tag,
      style_tag,
      weight_tag,
      foreground_tag,
      font_size_tag,
      underline_tag
    };
    alias TagType.font_desc_tag font_desc_tag;
    alias TagType.font_family_tag font_family_tag;
    alias TagType.foreground_tag foreground_tag;
    alias TagType.font_size_tag font_size_tag;
    alias TagType.underline_tag underline_tag;
public:
    void font_desc(string desc){
        _tags[font_desc_tag] = " font_desc="~'"'~desc~'"';
    }
    void foreground(in Color c){
        _tags[foreground_tag] = " foreground="~'"'~to!string(c)~'"';
    }
    // correspond to Pango's font, not font_size
    void font_size(in ubyte s){
        _tags[font_size_tag] = " font="~to!string(s);
    }
    void underline(in Underline uc){
        _tags[underline_tag] = " underline="~'"'~toLower(to!string(uc))~'"';
    }
    string tagging(string content)const{
        return start_tag()~content~end_tag();
    }
    string start_tag()const{
        string start ="<";
        start = "<span";
        foreach(tag; _tags)
            start ~= tag;
        start ~= ">";
        return start;
    }
    string end_tag()const{
        return "</span>";
    }
    @property empty()const{
        return _tags.values.empty;
    }
}

// <span foreground="blue" font=24>Blue text</span>
unittest{
    Color foreground = blue;
    ubyte font = 24;
    string content = "Blue text";
    Underline underline = Underline.NONE;
    SpanTag tag;
    tag.foreground(foreground);
    tag.font_size(font);
    tag.underline(underline);
    auto result = tag.tagging(content);
    import std.stdio;
    writeln(result);
    assert(result == `<span foreground="blue" font=24 underline="none">Blue text</span>`);
}

