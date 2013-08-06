module text.tag;

import text.text;
import std.string;
import std.conv;
import std.array;
import std.traits;
import std.typecons;
public import gtkc.pangotypes;
import util.color;

// alias PangoUnderline Underline;

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
    background_tag,
    font_size_tag,
    underline_tag,
};
alias TagType.font_desc_tag font_desc_tag;
alias TagType.font_family_tag font_family_tag;
alias TagType.foreground_tag foreground_tag;
alias TagType.background_tag background_tag;
alias TagType.font_size_tag font_size_tag;
alias TagType.underline_tag underline_tag;
alias TagType.face_tag face_tag;
alias TagType.style_tag style_tag;
alias TagType.weight_tag weight_tag;

struct ValuedTag(TagType t,V){
    TagType type = t;
    V value;
    private bool _set;
    void set(V val){
        value = val;
        _set = true;
    }
    bool is_set()const{
        return _set;
    }
}
alias ValuedTag!(foreground_tag,Color) Foreground;
alias ValuedTag!(background_tag,Color) Background;
alias ValuedTag!(font_size_tag,ubyte) FontSize;
alias ValuedTag!(underline_tag,PangoUnderline) Underline;
alias ValuedTag!(weight_tag,PangoWeight) Weight;
alias ValuedTag!(font_desc_tag,string) FontDesc;

struct SpanTag{
    private:
        string[TagType] _tags;
        bool[TagType] _tag_set_flg;

        Foreground _foreground;
        Background _background;
        FontSize _font_size;
        Underline _underline;
        Weight  _weight;
        FontDesc _font_desc;
    public:
        this(in Color fore){
            set_foreground(fore);
        }
        TagType[] tag_types()const{
            return _tags.keys;
        }
        bool is_set(in TagType tt)const{
            return (tt in _tag_set_flg) && _tag_set_flg[tt];
        }
        void set_font_desc(string desc){
            _font_desc.set(desc);
            _tag_set_flg[font_desc_tag] = true;
            _tags[font_desc_tag] = " font_desc="~'"'~desc~'"';
        }
        void set_foreground(in Color c){
            _foreground.set(c);
            _tag_set_flg[foreground_tag] = true;
            _tags[foreground_tag] = " foreground="~'"'~to!string(c)~'"';
        }
        void set_background(in Color c){
            _background.set(c);
            _tag_set_flg[background_tag] = true;
            _tags[background_tag] = " background="~'"'~to!string(c)~'"';
        }
        // correspond to Pango's font, not font_size
        void set_font_size(in ubyte s){
            _font_size.set(s);
            _tag_set_flg[font_size_tag] = true;
            _tags[font_size_tag] = " font="~to!string(s);
        }
        void set_underline(in PangoUnderline uc){
            _underline.set(uc);
            _tag_set_flg[underline_tag] = true;
            _tags[underline_tag] = " underline="~'"'~toLower(to!string(uc))~'"';
        }
        void set_weight(in PangoWeight wei){ 
            _weight.set(wei);
            _tag_set_flg[weight_tag] = true;
            _tags[weight_tag] = " weight="~'"'~toLower(to!string(wei))~'"';
        }
        string tagging(string content)const{
            return start_tag()~content~end_tag();
        }
        string start_tag()const{
            string start ="<";
            start = "<span";
            foreach(tag; EnumMembers!TagType)
                if(tag in _tags)
                start ~= _tags[tag];
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
                    set_foreground(Color(tag_str));
            }
        }
        string dat()const{
            string result;
            result ~= "(";
            foreach(tag_n; _tags.keys)
            {
                result ~= to!string(tag_n);
                if(tag_n == foreground_tag)
                    result ~= ":"~to!string(_foreground.value.hex_str());
                else if(tag_n == font_size_tag)
                    result ~= ":"~to!string(_font_size.value);
                result ~= ",";
            }

            result = result[0 .. $-1] ~")";
            return result;
        }
        // 包まなくても、使う側は存在してるかどうかだいたい知ってる..
        Tuple!(bool,const Color) foreground()const{
            return tuple(_foreground.is_set,_foreground.value);
        }
        Tuple!(bool,const Color) background()const{
            return tuple(_background.is_set,_background.value);
        }
        Tuple!(bool,const ubyte) font_size()const{
            return tuple(_font_size.is_set,_font_size.value);
        }
        Tuple!(bool,const PangoUnderline) underline()const{
            return tuple(_underline.is_set,_underline.value);
        }
        Tuple!(bool,const PangoWeight) weight()const{
            return tuple(_weight.is_set,_weight.value);
        }
        Tuple!(bool,string) font_desc()const{
            return tuple(_font_desc.is_set,_font_desc.value);
        }
    }

    // <span foreground="blue" font=24>Blue text</span>
    unittest{
        Color foreground = blue;
        ubyte font = 24;
        string content = "Blue text";
        PangoUnderline underline = PangoUnderline.NONE;
        SpanTag tag;
        tag.set_foreground(foreground);
        tag.set_font_size(font);
        tag.set_underline(underline);
        auto result = tag.tagging(content);
        import std.stdio;
        writeln(result);
        assert(result == `<span foreground="blue" font=24 underline="none">Blue text</span>`);
}

