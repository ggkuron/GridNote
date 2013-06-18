module util.color;

import std.string;
import std.array;
import std.algorithm;
import std.typecons;

struct Color{
    int r,g,b,a;
    string _name;
    // 指定なしで赤色なのは見落とし防止の為
    this(in int rr=255,in int gg=0,in int bb=0,in int aa=255){
        r = rr; g = gg; b = bb; a = aa;
    }
    this(string hexspec,in int alpha=255)
        in{
        assert(hexspec[0] == '#');
        assert(hexspec.length == 7);
        }
    body{
        auto r = from_hex(hexspec[1 .. 3]);
        auto g = from_hex(hexspec[3 .. 5]);
        auto b = from_hex(hexspec[5 .. 7]);
        this(r,g,b,alpha);
    }
    this(string color_name,string hexspec){
        this(hexspec);
        _name = color_name;
    }
    this(in Color color){
        this(color.r,color.g,color.b,color.a);
    }
    this(in Color color,in int alpha){
        this(color.r,color.g,color.b,alpha);
    }
    public string hex_str()const{
        return "#"~to_Hex(r)~to_Hex(g)~to_Hex(b);
    }
    string toString()const{
        if(!_name.empty())
            return _name;
        else
            return hex_str;
    }
    void change_alpha(in int aa)
        in{
        assert(aa < 256);
        assert(aa >= 0);
        }
    body{
        a = aa;
    }
    static pure bool valid_check(in int i){
        return (i>=0 && i<256);
    }
    invariant(){
        assert(valid_check(r));
        assert(valid_check(g));
        assert(valid_check(b));
        assert(valid_check(a));
    }
}

pure int from_hex(in char hc){
    switch(hc){
        case '0': .. case '9':
            return hc - '0';
        case 'a': .. case 'f':
            return hc - 'a' + 10;
        case 'A': .. case 'F':
            return hc - 'A' + 10;
        default: 
            assert(0);
    }
}
string to_hex(in int i){
    return std.string.format("%02x",i);
}
string to_Hex(in int i){
    return std.string.format("%02X",i);
}
pure int from_hex(string hexstr){
    int result;
    uint weight = 1;
    for(int i=1;i <= hexstr.length; ++i)
    {
        result += from_hex(hexstr[$-i]) * weight;
        weight *= 16;
    }
    return result;
}
unittest{
    assert(from_hex("a") == 10);
    assert(from_hex("f") == 15);
    assert(from_hex("A") == 10);
    assert(from_hex("F") == 15);
    assert(from_hex("FF") == 255);
    assert(from_hex("FFFF") == 65535);
    assert(from_hex("ff") == 255);
    assert(from_hex("20") == 32);
    assert(from_hex("10") == 16);
    assert("ff" == to_hex(255));
    assert("FF" == to_Hex(255));
}

Color brightness(in Color c,in int per){
    Tuple!(int,const int)[] rgb = [tuple(0,c.r),tuple(1,c.g),tuple(2,c.b)];
    double min_v = int.max;
    double max_v = 0;
    int min= -1,max = -1;
    foreach(k; rgb)
    {
        if(k[1] < min_v ){
            min_v = k[1];
            min = k[0];
        }
        if(k[1] > max_v ){
            max_v = k[1];
            max = k[0];
        }
    }
    const middle = 3 - max - min; 
    const double middle_v = (rgb[middle])[1];

    double[int] adjust;
    adjust[max] = (255.0/100.0) * per;
    adjust[middle] = adjust[max] / (max_v/middle_v);
    adjust[min] = adjust[middle] / (max_v/min_v); 
    import std.stdio;
    writeln(rgb);
    writeln(adjust);
    return Color(
            cast(int)(c.r + adjust[0]),
            cast(int)(c.g + adjust[1]),
            cast(int)(c.b + adjust[2]),
            c.a);
}
unittest{
    import std.stdio;
    Color orign = Color("#006400");
    auto bright = orign.brightness(20);
    writeln(orign.hex_str);
    writeln(bright.hex_str);
    assert(bright.hex_str == "#009700");
}


import cairo.Context;
void set_color(Context cr,in Color c)
{
    cr.setSourceRgba(cast(double)c.r/255,
                     cast(double)c.g/255,
                     cast(double)c.b/255,
                     cast(double)c.a/255);
}
// Color get_by_name(string color_name){
//     return mixin color_name;
// }

static immutable maroon = Color("maroon","#800000");
static immutable darkred = Color("darkred","#8b0000");
static immutable brown = Color("brown","#a52a2a");
static immutable firebrick = Color("firebrick","#b22222");
static immutable rosybrown = Color("rosybrown","#bc8f8f");
static immutable indianred = Color("indianred","#cd5c5c");
static immutable lightcoral = Color("lightcoral","#f08080");
static immutable red = Color("red","#ff0000");
static immutable snow = Color("snow","#fffafa");
static immutable salmon = Color("salmon","#fa8072");
static immutable mistyrose = Color("mistyrose","#ffe4e1");
static immutable tomato = Color("tomato","#ff6347");
static immutable darksalmon = Color("darksalmon","#e9967a");
static immutable orangered = Color("orangered","#ff4500");
static immutable coral = Color("coral","#ff7f50");
static immutable lightsalmon = Color("lightsalmon","#ffa07a");
static immutable sienna = Color("sienna","#a0522d");
static immutable seashell = Color("seashell","#fff5ee");
static immutable saddlebrown = Color("saddlebrown","#8b4513");
static immutable chocolate = Color("chocolate","#d2691e");
static immutable sandybrown = Color("sandybrown","#f4a460");
static immutable peachpuff = Color("peachpuff","#ffdab9");
static immutable peru = Color("peru","#cd853f");
static immutable linen = Color("linen","#faf0e6");
static immutable darkorange = Color("darkorange","#ff8c00");
static immutable bisque = Color("bisque","#ffe4c4");
static immutable tan = Color("tan","#d2b48c");
static immutable burlywood = Color("burlywood","#deb887");
static immutable antiquewhite = Color("antiquewhite","#faebd7");
static immutable navajowhite = Color("navajowhite","#ffdead");
static immutable blanchedalmond = Color("blanchedalmond","#ffebcd");
static immutable moccasin = Color("moccasin","#ffe4b5");
static immutable papayawhip = Color("papayawhip","#ffefd5");
static immutable wheat = Color("wheat","#f5deb3");
static immutable oldlace = Color("oldlace","#fdf5e6");
static immutable orange = Color("orange","#ffa500");
static immutable floralwhite = Color("floralwhite","#fffaf0");
static immutable darkgoldenrod = Color("darkgoldenrod","#b8860b");
static immutable goldenrod = Color("goldenrod","#daa520");
static immutable cornsilk = Color("cornsilk","#fff8dc");
static immutable gold = Color("gold","#ffd700");
static immutable palegoldenrod = Color("palegoldenrod","#eee8aa");
static immutable khaki = Color("khaki","#f0e68c");
static immutable lemonchiffon = Color("lemonchiffon","#fffacd");
static immutable darkkhaki = Color("darkkhaki","#bdb76b");
static immutable olive = Color("olive","#808000");
static immutable beige = Color("beige","#f5f5dc");
static immutable lightgoldenrodyellow = Color("lightgoldenrodyellow","#fafad2");
static immutable ivory = Color("ivory","#fffff0");
static immutable lightyellow = Color("lightyellow","#ffffe0");
static immutable yellow = Color("yellow","#ffff00");
static immutable olivedrab = Color("olivedrab","#6b8e23");
static immutable yellowgreen = Color("yellowgreen","#9acd32");
static immutable darkolivegreen = Color("darkolivegreen","#556b2f");
static immutable greenyellow = Color("greenyellow","#adff2f");
static immutable lawngreen = Color("lawngreen","#7cfc00");
static immutable chartreuse = Color("chartreuse","#7fff00");
static immutable darkgreen = Color("darkgreen","#006400");
static immutable green = Color("green","#008000");
static immutable lime = Color("lime","#00ff00");
static immutable forestgreen = Color("forestgreen","#228b22");
static immutable limegreen = Color("limegreen","#32cd32");
static immutable darkseagreen = Color("darkseagreen","#8fbc8f");
static immutable lightgreen = Color("lightgreen","#90ee90");
static immutable palegreen = Color("palegreen","#98fb98");
static immutable honeydew = Color("honeydew","#f0fff0");
static immutable seagreen = Color("seagreen","#2e8b57");
static immutable mediumseagreen = Color("mediumseagreen","#3cb371");
static immutable springgreen = Color("springgreen","#00ff7f");
static immutable mintcream = Color("mintcream","#f5fffa");
static immutable mediumspringgreen = Color("mediumspringgreen","#00fa9a");
static immutable mediumaquamarine = Color("mediumaquamarine","#66cdaa");
static immutable aquamarine = Color("aquamarine","#7fffd4");
static immutable turquoise = Color("turquoise","#40e0e0");
static immutable lightseagreen = Color("lightseagreen","#20b2aa");
static immutable mediumtourquoise = Color("mediumtourquoise","#48d1cc");
static immutable teal = Color("teal","#008080");
static immutable darkcyan = Color("darkcyan","#008b8b");
static immutable cyan = Color("cyan","#00ffff");
static immutable aqua = Color("aqua","#00ffff");
static immutable darkslategray = Color("darkslategray","#2f4f4f");
static immutable paleturquoise = Color("paleturquoise","#afeeee");
static immutable lightcyan = Color("lightcyan","#e0ffff");
static immutable azure = Color("azure","#f0ffff");
static immutable darkturquoise = Color("darkturquoise","#00ced1");
static immutable cadetblue = Color("cadetblue","#5f9ea0");
static immutable powderblue = Color("powderblue","#b0e0e6");
static immutable deepskyblue = Color("deepskyblue","#00bfff");
static immutable lightblue = Color("lightblue","#add8e6");
static immutable skyblue = Color("skyblue","#87ceeb");
static immutable lightskyblue = Color("lightskyblue","#87cefa");
static immutable steelblue = Color("steelblue","#4682b4");
static immutable aliceblue = Color("aliceblue","#f0f8ff");
static immutable dodgerblue = Color("dodgerblue","#1e90ff");
static immutable slategray = Color("slategray","#708090");
static immutable lightslategray = Color("lightslategray","#778899");
static immutable lightsteelblue = Color("lightsteelblue","#b0c4de");
static immutable cornflowerblue = Color("cornflowerblue","#6495ed");
static immutable royalblue = Color("royalblue","#4169e1");
static immutable blue = Color("blue","#0000ff");
static immutable mediumblue = Color("mediumblue","#0000cd");
static immutable darkblue = Color("darkblue","#00008b");
static immutable navy = Color("navy","#000080");
static immutable midnightbule = Color("midnightbule","#101070");
static immutable lavender = Color("lavender","#e6e6fa");
static immutable ghostwhite = Color("ghostwhite","#f8f8ff");
static immutable darkslateblue = Color("darkslateblue","#483d8b");
static immutable slateblue = Color("slateblue","#6a5acd");
static immutable mediumslateblue = Color("mediumslateblue","#7b68ee");
static immutable mediumpurple = Color("mediumpurple","#9370db");
static immutable blueviolet = Color("blueviolet","#8a2be2");
static immutable indigo = Color("indigo","#4b0082");
static immutable darkorchid = Color("darkorchid","#9932cc");
static immutable darkviolet = Color("darkviolet","#9400d3");
static immutable mediumorchid = Color("mediumorchid","#ba55d3");
static immutable purple = Color("purple","#800080");
static immutable darkmagenta = Color("darkmagenta","#8b008b");
static immutable thistle = Color("thistle","#d8bfd8");
static immutable plum = Color("plum","#dda0dd");
static immutable violet = Color("violet","#ee82ee");
static immutable magenta = Color("magenta","#ff00ff");
static immutable fuchsia = Color("fuchsia","#ff00ff");
static immutable orchid = Color("orchid","#da70d6");
static immutable mediumvoiletred = Color("mediumvoiletred","#c71585");
static immutable deeppink = Color("deeppink","#ff1493");
static immutable hotpink = Color("hotpink","#ff69b4");
static immutable palevioletred = Color("palevioletred","#db7093");
static immutable lavenderblush = Color("lavenderblush","#fff0f5");
static immutable crimson = Color("crimson","#dc143c");
static immutable pink = Color("pink","#ffc0cb");
static immutable lightpink = Color("lightpink","#ffb6c1");
static immutable black = Color("black","#000000");
static immutable dimgray = Color("dimgray","#696969");
static immutable gray = Color("gray","#808080");
static immutable darkgray = Color("darkgray","#a9a9a9");
static immutable silver = Color("silver","#c0c0c0");
static immutable lightgray = Color("lightgray","#d3d3d3");
static immutable gainsboro = Color("gainsboro","#dcdcdc");
static immutable whitesmoke = Color("whitesmoke","#f5f5f5");
static immutable white = Color("white","#ffffff");


immutable Color[140] AllColors = 
[
maroon,
darkred,
brown,
firebrick,
rosybrown,
indianred,
lightcoral,
red,
snow,
salmon,
mistyrose,
tomato, 
darksalmon, 
orangered, 
coral, 
lightsalmon,
sienna,
seashell, 
saddlebrown, 
chocolate, 
sandybrown, 
peachpuff, 
peru, 
linen, 
darkorange, 
bisque, 
tan, 
burlywood, 
antiquewhite, 
navajowhite, 
blanchedalmond, 
moccasin, 
papayawhip, 
wheat, 
oldlace, 
orange , 
floralwhite, 
darkgoldenrod, 
goldenrod, 
cornsilk, 
gold, 
palegoldenrod, 
khaki, 
lemonchiffon, 
darkkhaki, 
olive, 
beige, 
lightgoldenrodyellow, 
ivory, 
lightyellow, 
yellow , 
olivedrab, 
yellowgreen, 
darkolivegreen, 
greenyellow, 
lawngreen, 
chartreuse, 
darkgreen, 
green, 
lime, 
forestgreen, 
limegreen, 
darkseagreen, 
lightgreen, 
palegreen, 
honeydew, 
seagreen, 
mediumseagreen, 
springgreen, 
mintcream, 
mediumspringgreen, 
mediumaquamarine, 
aquamarine, 
turquoise, 
lightseagreen, 
mediumtourquoise, 
teal, 
darkcyan, 
cyan, 
aqua, 
darkslategray, 
paleturquoise, 
lightcyan, 
azure, 
darkturquoise, 
cadetblue, 
powderblue, 
deepskyblue, 
lightblue, 
skyblue, 
lightskyblue, 
steelblue, 
aliceblue, 
dodgerblue, 
slategray, 
lightslategray, 
lightsteelblue, 
cornflowerblue, 
royalblue, 
blue, 
mediumblue, 
darkblue, 
navy, 
midnightbule, 
lavender, 
ghostwhite, 
darkslateblue, 
slateblue, 
mediumslateblue, 
mediumpurple, 
blueviolet, 
indigo, 
darkorchid, 
darkviolet, 
mediumorchid, 
purple, 
darkmagenta, 
thistle, 
plum, 
violet, 
magenta, 
fuchsia, 
orchid, 
mediumvoiletred, 
deeppink, 
hotpink, 
palevioletred, 
lavenderblush, 
crimson, 
pink, 
lightpink, 
black, 
dimgray, 
gray, 
darkgray, 
silver, 
lightgray, 
gainsboro, 
whitesmoke, 
white ];
