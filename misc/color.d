module misc.color;

struct Color{
    int r,g,b,a;
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
    this(Color color){
        this(color.r,color.g,color.b,color.a);
    }
    this(Color color,int alpha){
        this(color.r,color.g,color.b,alpha);
    }

    void change_alpha(int aa)
        in{
        assert(aa<256);
        assert(aa>=0);
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
    assert(from_hex("20") == 32);
    assert(from_hex("10") == 16);
}

// 140 Color 
// 1色足りない気がする…
immutable maroon  = Color("#800000");
immutable darkred = Color("#8b0000");
immutable brown   = Color("#a52a2a");
immutable firebrick = Color("#b22222");
immutable rosybrown = Color("#bc8f8f");
immutable indianred = Color("#cd5c5c");
immutable lightcoral = Color("#f08080");
immutable red     = Color("#ff0000");
immutable snow = Color("#fffafa");
immutable salmon = Color("#fa8072");
immutable mistyrose = Color("#ffe4e1");
immutable tomato = Color("#ff6347");
immutable darksalmon = Color("#e9967a");
immutable orangered = Color("#ff4500");
immutable coral = Color("#ff7f50");
immutable lightsalmon = Color("#ffa07a");
immutable sienna = Color("#a0522d");
immutable seashell = Color("#fff5ee");
immutable saddlebrown = Color("#8b4513");
immutable chocolate = Color("#d2691e");
immutable sandybrown = Color("#f4a460");
immutable peachpuff = Color("#ffdab9");
immutable peru = Color("#cd853f");
immutable linen = Color("#faf0e6");
immutable darkorenge = Color("#ff8c00");
immutable bisque = Color("#ffe4c4");
immutable tan = Color("#d2b48c");
immutable burlywood = Color("#deb887");
immutable antiquewhite = Color("#faebd7");
immutable navajowhite = Color("#ffdead");
immutable blanchedalmond = Color("#ffebcd");
immutable moccasin = Color("#ffe4b5");
immutable papayawhip = Color("#ffefd5");
immutable wheat = Color("#f5deb3");
immutable oldlace = Color("#fdf5e6");
immutable orenge  = Color("#ffa500");
immutable floralwhite = Color("#fffaf0");
immutable darkgoldenrod = Color("#b8860b");
immutable goldenrod = Color("#daa520");
immutable cornsilk = Color("#fff8dc");
immutable gold = Color("#ffd700");
immutable palegoldenrod = Color("#eee8aa");
immutable khaki = Color("#f0e68c");
immutable lemonchiffon = Color("#fffacd");
immutable darkkhaki = Color("#bdb76b");
immutable olive = Color("#808000");
immutable beige = Color("#f5f5dc");
immutable lightgoldenrodyellow = Color("#fafad2");
immutable ivory = Color("#fffff0");
immutable lightyellow = Color("#ffffe0");
immutable yellow  = Color("#ffff00");
immutable olivedrab = Color("#6b8e23");
immutable yellowgreen = Color("#9acd32");
immutable darkolivegreen = Color("#556b2f");
immutable greenyellow = Color("#adff2f");
immutable lawngreen = Color("#7cfc00");
immutable chartreuse = Color("#7fff00");
immutable darkgreen = Color("#006400");
immutable green = Color("#008000");
immutable lime = Color("#00ff00");
immutable forestgreen = Color("#228b22");
immutable limegreen = Color("#32cd32");
immutable darkseagreen = Color("#8fbc8f");
immutable lightgreen = Color("#90ee90");
immutable palegreen = Color("#98fb98");
immutable honeydew = Color("#f0fff0");
immutable seagreen = Color("#2e8b57");
immutable mediumseagreen = Color("#3cb371");
immutable springgreen = Color("#00ff7f");
immutable mintcream = Color("#f5fffa");
immutable mediumspringgreen = Color("#00fa9a");
immutable mediumaqumarine = Color("#66cdaa");
immutable aquamarine = Color("#7fffd4");
immutable turquoise = Color("#40e0e0");
immutable lightseagreen = Color("#20b2aa");
immutable mediumtourquoise = Color("#48d1cc");
immutable teal = Color("#008080");
immutable darkcyan = Color("#008b8b");
immutable cyan = Color("#00ffff");
immutable aqua = Color("#00ffff");
immutable darkslategray = Color("#2f4f4f");
immutable paleturquoise = Color("#afeeee");
immutable lightcyan = Color("#e0ffff");
immutable azure = Color("#f0ffff");
immutable darkturquoise = Color("#00ced1");
immutable cadetblue = Color("#5f9ea0");
immutable powderblue = Color("#b0e0e6");
immutable deepskyblue = Color("#00bfff");
immutable lightblue = Color("#add8e6");
immutable skyblue = Color("#87ceeb");
immutable lightskyblue = Color("#87cefa");
immutable steelblue = Color("#4682b4");
immutable aliceblue = Color("#f0f8ff");
immutable dodgerblue = Color("#1e90ff");
immutable slategray = Color("#708090");
immutable lightslategray = Color("#778899");
immutable lightsteelblue = Color("#b0c4de");
immutable cornflowerblue = Color("#6495ed");
immutable royalblue = Color("#4169e1");
immutable blue = Color("#0000ff");
immutable mediumblue = Color("#0000cd");
immutable darkblue = Color("#00008b");
immutable navy = Color("#000080");
immutable midnightbule = Color("#101070");
immutable lavender = Color("#e6e6fa");
immutable ghostwhite = Color("#f8f8ff");
immutable darkslateblue = Color("#483d8b");
immutable slateblue = Color("#6a5acd");
immutable mediumslateblue = Color("#7b68ee");
immutable mediumpurple = Color("#9370db");
immutable blueviolet = Color("#8a2be2");
immutable indigo = Color("#4b0082");
immutable darkorchid = Color("#9932cc");
immutable darkviolet = Color("#9400d3");
immutable mediumorchid = Color("#ba55d3");
immutable purple = Color("#800080");
immutable darkmagenta = Color("#8b008b");
immutable thistle = Color("#d8bfd8");
immutable plum = Color("#dda0dd");
immutable voilet = Color("#ee82ee");
immutable magenta = Color("#ff00ff");
immutable fuchsia = Color("#ff00ff");
immutable orchid = Color("#da70d6");
immutable mediumvoiletred = Color("#c71585");
immutable deeppink = Color("#ff1493");
immutable hotpink = Color("#ff69b4");
immutable palevioletred = Color("#db7093");
immutable lavenderblush = Color("#fff0f5");
immutable crimson = Color("#dc143c");
immutable pink = Color("#ffc0cb");
immutable lightpink = Color("#ffb6c1");
immutable black   = Color("#000000");
immutable dimgray = Color("#696969");
immutable gray = Color("#808080");
immutable darkgray = Color("#a9a9a9");
immutable silver = Color("#c0c0c0");
immutable lightgray = Color("#d3d3d3");
immutable gainsboro = Color("#dcdcdc");
immutable whitesmoke = Color("#f5f5f5");
immutable white   = Color("#ffffff");
