module util.color;

import std.string;
import std.array;

struct Color{
    int r,g,b,a;
    string _name;
    // 指定なしで赤色なのは見落とし防止の為
    this(int rr=255,int gg=0,int bb=0,int aa=255){
        r = rr; g = gg; b = bb; a = aa;
    }
    this(string hexspec,int alpha=255)
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
    this(Color color){
        this(color.r,color.g,color.b,color.a);
    }
    this(Color color,int alpha){
        this(color.r,color.g,color.b,alpha);
    }
    private string color_string()const{
        return "#"~to_Hex(r)~to_Hex(g)~to_Hex(b);
    }
    string toString()const{
        if(!_name.empty())
            return _name;
        else
            return color_string;
    }
    void change_alpha(int aa)
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
    return std.string.format("%x",i);
}
string to_Hex(in int i){
    return std.string.format("%X",i);
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
    assert(from_hex("ff") == 255);
    assert(from_hex("20") == 32);
    assert(from_hex("10") == 16);
    assert("ff" == to_hex(255));
    assert("FF" == to_Hex(255));
}

import cairo.Context;
void set_color(Context cr,in Color c)
{
    cr.setSourceRgba(cast(double)c.r/255,
                     cast(double)c.g/255,
                     cast(double)c.b/255,
                     cast(double)c.a/255);
}

immutable maroon = Color("maroon","#800000");
immutable darkred = Color("darkred","#8b0000");
immutable brown = Color("brown","#a52a2a");
immutable firebrick = Color("firebrick","#b22222");
immutable rosybrown = Color("rosybrown","#bc8f8f");
immutable indianred = Color("indianred","#cd5c5c");
immutable lightcoral = Color("lightcoral","#f08080");
immutable red = Color("red","#ff0000");
immutable snow = Color("snow","#fffafa");
immutable salmon = Color("salmon","#fa8072");
immutable mistyrose = Color("mistyrose","#ffe4e1");
immutable tomato = Color("tomato","#ff6347");
immutable darksalmon = Color("darksalmon","#e9967a");
immutable orangered = Color("orangered","#ff4500");
immutable coral = Color("coral","#ff7f50");
immutable lightsalmon = Color("lightsalmon","#ffa07a");
immutable sienna = Color("sienna","#a0522d");
immutable seashell = Color("seashell","#fff5ee");
immutable saddlebrown = Color("saddlebrown","#8b4513");
immutable chocolate = Color("chocolate","#d2691e");
immutable sandybrown = Color("sandybrown","#f4a460");
immutable peachpuff = Color("peachpuff","#ffdab9");
immutable peru = Color("peru","#cd853f");
immutable linen = Color("linen","#faf0e6");
immutable darkorange = Color("darkorange","#ff8c00");
immutable bisque = Color("bisque","#ffe4c4");
immutable tan = Color("tan","#d2b48c");
immutable burlywood = Color("burlywood","#deb887");
immutable antiquewhite = Color("antiquewhite","#faebd7");
immutable navajowhite = Color("navajowhite","#ffdead");
immutable blanchedalmond = Color("blanchedalmond","#ffebcd");
immutable moccasin = Color("moccasin","#ffe4b5");
immutable papayawhip = Color("papayawhip","#ffefd5");
immutable wheat = Color("wheat","#f5deb3");
immutable oldlace = Color("oldlace","#fdf5e6");
immutable orange = Color("orange","#ffa500");
immutable floralwhite = Color("floralwhite","#fffaf0");
immutable darkgoldenrod = Color("darkgoldenrod","#b8860b");
immutable goldenrod = Color("goldenrod","#daa520");
immutable cornsilk = Color("cornsilk","#fff8dc");
immutable gold = Color("gold","#ffd700");
immutable palegoldenrod = Color("palegoldenrod","#eee8aa");
immutable khaki = Color("khaki","#f0e68c");
immutable lemonchiffon = Color("lemonchiffon","#fffacd");
immutable darkkhaki = Color("darkkhaki","#bdb76b");
immutable olive = Color("olive","#808000");
immutable beige = Color("beige","#f5f5dc");
immutable lightgoldenrodyellow = Color("lightgoldenrodyellow","#fafad2");
immutable ivory = Color("ivory","#fffff0");
immutable lightyellow = Color("lightyellow","#ffffe0");
immutable yellow = Color("yellow","#ffff00");
immutable olivedrab = Color("olivedrab","#6b8e23");
immutable yellowgreen = Color("yellowgreen","#9acd32");
immutable darkolivegreen = Color("darkolivegreen","#556b2f");
immutable greenyellow = Color("greenyellow","#adff2f");
immutable lawngreen = Color("lawngreen","#7cfc00");
immutable chartreuse = Color("chartreuse","#7fff00");
immutable darkgreen = Color("darkgreen","#006400");
immutable green = Color("green","#008000");
immutable lime = Color("lime","#00ff00");
immutable forestgreen = Color("forestgreen","#228b22");
immutable limegreen = Color("limegreen","#32cd32");
immutable darkseagreen = Color("darkseagreen","#8fbc8f");
immutable lightgreen = Color("lightgreen","#90ee90");
immutable palegreen = Color("palegreen","#98fb98");
immutable honeydew = Color("honeydew","#f0fff0");
immutable seagreen = Color("seagreen","#2e8b57");
immutable mediumseagreen = Color("mediumseagreen","#3cb371");
immutable springgreen = Color("springgreen","#00ff7f");
immutable mintcream = Color("mintcream","#f5fffa");
immutable mediumspringgreen = Color("mediumspringgreen","#00fa9a");
immutable mediumaqumarine = Color("mediumaqumarine","#66cdaa");
immutable aquamarine = Color("aquamarine","#7fffd4");
immutable turquoise = Color("turquoise","#40e0e0");
immutable lightseagreen = Color("lightseagreen","#20b2aa");
immutable mediumtourquoise = Color("mediumtourquoise","#48d1cc");
immutable teal = Color("teal","#008080");
immutable darkcyan = Color("darkcyan","#008b8b");
immutable cyan = Color("cyan","#00ffff");
immutable aqua = Color("aqua","#00ffff");
immutable darkslategray = Color("darkslategray","#2f4f4f");
immutable paleturquoise = Color("paleturquoise","#afeeee");
immutable lightcyan = Color("lightcyan","#e0ffff");
immutable azure = Color("azure","#f0ffff");
immutable darkturquoise = Color("darkturquoise","#00ced1");
immutable cadetblue = Color("cadetblue","#5f9ea0");
immutable powderblue = Color("powderblue","#b0e0e6");
immutable deepskyblue = Color("deepskyblue","#00bfff");
immutable lightblue = Color("lightblue","#add8e6");
immutable skyblue = Color("skyblue","#87ceeb");
immutable lightskyblue = Color("lightskyblue","#87cefa");
immutable steelblue = Color("steelblue","#4682b4");
immutable aliceblue = Color("aliceblue","#f0f8ff");
immutable dodgerblue = Color("dodgerblue","#1e90ff");
immutable slategray = Color("slategray","#708090");
immutable lightslategray = Color("lightslategray","#778899");
immutable lightsteelblue = Color("lightsteelblue","#b0c4de");
immutable cornflowerblue = Color("cornflowerblue","#6495ed");
immutable royalblue = Color("royalblue","#4169e1");
immutable blue = Color("blue","#0000ff");
immutable mediumblue = Color("mediumblue","#0000cd");
immutable darkblue = Color("darkblue","#00008b");
immutable navy = Color("navy","#000080");
immutable midnightbule = Color("midnightbule","#101070");
immutable lavender = Color("lavender","#e6e6fa");
immutable ghostwhite = Color("ghostwhite","#f8f8ff");
immutable darkslateblue = Color("darkslateblue","#483d8b");
immutable slateblue = Color("slateblue","#6a5acd");
immutable mediumslateblue = Color("mediumslateblue","#7b68ee");
immutable mediumpurple = Color("mediumpurple","#9370db");
immutable blueviolet = Color("blueviolet","#8a2be2");
immutable indigo = Color("indigo","#4b0082");
immutable darkorchid = Color("darkorchid","#9932cc");
immutable darkviolet = Color("darkviolet","#9400d3");
immutable mediumorchid = Color("mediumorchid","#ba55d3");
immutable purple = Color("purple","#800080");
immutable darkmagenta = Color("darkmagenta","#8b008b");
immutable thistle = Color("thistle","#d8bfd8");
immutable plum = Color("plum","#dda0dd");
immutable violet = Color("violet","#ee82ee");
immutable magenta = Color("magenta","#ff00ff");
immutable fuchsia = Color("fuchsia","#ff00ff");
immutable orchid = Color("orchid","#da70d6");
immutable mediumvoiletred = Color("mediumvoiletred","#c71585");
immutable deeppink = Color("deeppink","#ff1493");
immutable hotpink = Color("hotpink","#ff69b4");
immutable palevioletred = Color("palevioletred","#db7093");
immutable lavenderblush = Color("lavenderblush","#fff0f5");
immutable crimson = Color("crimson","#dc143c");
immutable pink = Color("pink","#ffc0cb");
immutable lightpink = Color("lightpink","#ffb6c1");
immutable black = Color("black","#000000");
immutable dimgray = Color("dimgray","#696969");
immutable gray = Color("gray","#808080");
immutable darkgray = Color("darkgray","#a9a9a9");
immutable silver = Color("silver","#c0c0c0");
immutable lightgray = Color("lightgray","#d3d3d3");
immutable gainsboro = Color("gainsboro","#dcdcdc");
immutable whitesmoke = Color("whitesmoke","#f5f5f5");
immutable white = Color("white","#ffffff");


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
mediumaqumarine, 
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
