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
enum TagType{
  font_desc_tag,
  font_family_tag,
  face_tag,
  style_tag,
  weight_tag,
  foreground_tag,
  font_size_tag,
  underline_tag,
};
alias TagType.font_desc_tag font_desc_tag;
alias TagType.font_family_tag font_family_tag;
alias TagType.foreground_tag foreground_tag;
alias TagType.font_size_tag font_size_tag;
alias TagType.underline_tag underline_tag;
alias TagType.face_tag face_tag;
alias TagType.style_tag style_tag;
alias TagType.weight_tag weight_tag;

struct SpanTag{
private:
    string[TagType] _tags;
    Color _foreground;
    ubyte _font_size;
    Underline _underline;
    string _font_desc;
    PangoWeight _weight = PangoWeight.NORMAL;
public:
    TagType[] tag_types()const{
        return _tags.keys;
    }
    void font_desc(string desc){
        _font_desc = desc;
        _tags[font_desc_tag] = " font_desc="~'"'~desc~'"';
    }
    void foreground(in Color c){
        _foreground = c;
        _tags[foreground_tag] = " foreground="~'"'~to!string(c)~'"';
    }
    // correspond to Pango's font, not font_size
    void font_size(in ubyte s){
        _font_size = s;
        _tags[font_size_tag] = " font="~to!string(s);
    }
    void underline(in Underline uc){
        _underline = uc;
        _tags[underline_tag] = " underline="~'"'~toLower(to!string(uc))~'"';
    }
    void weight(in PangoWeight wei){ 
        _weight = wei;
        _tags[weight_tag] = " weight="~'"'~toLower(to!string(wei))~'"';
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
        string result;
        return result~"</span>";
    }
    @property empty()const{
        return _tags.values.empty;
    }
    this(string dat){
        import std.stdio;
        writeln(dat);
        dat = dat[1 .. $-1];
        auto tag_strs = split(dat,",");
        foreach(tag_str; tag_strs)
        {
            auto is_fore = munch(tag_str,"foreground_tag:");
            if(is_fore)
                foreground(Color(tag_str));
        }
    }
    string dat()const{
        string result;
        result ~= "(";
        foreach(tag_n; _tags.keys)
        {
            result ~= to!string(tag_n);
            if(tag_n == foreground_tag)
                result ~= ":"~to!string(_foreground.hex_str());
            else if(tag_n == font_size_tag)
                result ~= ":"~to!string(_font_size);
            result ~= ",";
        }

        result = result[0 .. $-1] ~")";
        return result;
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

