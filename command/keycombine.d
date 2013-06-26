module command.keycombine;

import gdk.Keysyms;
import gtkc.gdktypes;

alias uint KeySym;
struct KeyCombine{
    const(KeySym)[] keys;
    ubyte mod;
    this(in KeySym[] k...){
        keys = k;
    }
    this(ModifierType[] m,in KeySym[] k...){
        foreach(mm; m)
            mod |= mm;
        keys = k;
    }
    bool opEquals(const KeyCombine kc)const{
        return (mod == kc.mod) && (keys == kc.keys);
    }
    int opCmp(ref const KeyCombine rhs)const{
        return cast(int)(toHash() - rhs.toHash());
    }
    const hash_t toHash()
    { 
        hash_t hash;
        foreach (k; keys)
            hash += (hash * 255) + k + mod*13;
        return hash;
    }
}                            
unittest{
    assert(default_MOVE_FOCUS_L == default_MOVE_FOCUS_L);
    // writeln(default_MOVE_FOCUS_L);
    // writeln(default_MOVE_BOX_L);
    // writefln("%d",ModifierType.SHIFT_MASK);
    assert(default_MOVE_FOCUS_L != default_MOVE_BOX_L);
    assert(default_MOVE_FOCUS_L.toHash() != default_MOVE_BOX_L.toHash());

    assert(default_MOVE_FOCUS_L == KeyCombine([104]));
}

// wrap
immutable backspace = KeyCombine(GdkKeysyms.GDK_BackSpace);
immutable delete_key = KeyCombine(GdkKeysyms.GDK_Delete);
immutable return_key = KeyCombine(GdkKeysyms.GDK_Return);
immutable shift_key = KeyCombine(GdkKeysyms.GDK_Shift_L);
immutable control_key = KeyCombine(GdkKeysyms.GDK_Control_L);
immutable tab_key = KeyCombine(GdkKeysyms.GDK_Tab);
immutable escape_key = KeyCombine(GdkKeysyms.GDK_Escape);
immutable alt_escape = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_bracketleft]);

// table 上に登録しない値として
immutable INVALID = KeyCombine();

immutable default_ZOOM_IN = KeyCombine(GdkKeysyms.GDK_1);
immutable default_ZOOM_OUT = KeyCombine(GdkKeysyms.GDK_2);

immutable default_EXIT = KeyCombine(GdkKeysyms.GDK_w);
immutable default_DELETE = KeyCombine(GdkKeysyms.GDK_x);
immutable default_EDIT_DELETE = KeyCombine([ModifierType.CONTROL_MASK],GdkKeysyms.GDK_x);
immutable default_INSERT = KeyCombine(GdkKeysyms.GDK_i);
immutable default_EDIT = KeyCombine(GdkKeysyms.GDK_e);

immutable default_MOVE_FOCUS_L = KeyCombine(GdkKeysyms.GDK_h);
immutable default_MOVE_FOCUS_R = KeyCombine(GdkKeysyms.GDK_l);
immutable default_MOVE_FOCUS_U = KeyCombine(GdkKeysyms.GDK_k);
immutable default_MOVE_FOCUS_D = KeyCombine(GdkKeysyms.GDK_j);

immutable default_MOVE_BOX_L = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_h]);
immutable default_MOVE_BOX_R = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_l]);
immutable default_MOVE_BOX_U = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_k]);
immutable default_MOVE_BOX_D = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_j]);

immutable default_SELECT_PIVOT_L = KeyCombine([ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_H]);
immutable default_SELECT_PIVOT_R = KeyCombine([ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_L]);
immutable default_SELECT_PIVOT_D = KeyCombine([ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_J]);
immutable default_SELECT_PIVOT_U = KeyCombine([ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_K]);

immutable default_TOGGLE_GRID_RENDER = KeyCombine(GdkKeysyms.GDK_0);
immutable default_TOGGLE_BOX_BORDER_RENDER = KeyCombine(GdkKeysyms.GDK_9);

immutable default_UNDO = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_z]);
immutable default_REDO = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_r]);
immutable default_BOX_DELETE = KeyCombine([ModifierType.CONTROL_MASK,ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_X]);

immutable default_MODE_NORMAL = KeyCombine(GdkKeysyms.GDK_Escape);
// immutable default_start_insert = KeyCombine(GdkKeysyms.GDK_i);
immutable default_mono_insert = KeyCombine(GdkKeysyms.GDK_m);

immutable default_ImageOpen= KeyCombine([ModifierType.SHIFT_MASK],GdkKeysyms.GDK_I);
immutable default_Point= KeyCombine(GdkKeysyms.GDK_p);

immutable default_MODE_COLOR = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_c]);
// CLEARに当たる操作
immutable default_RESTORE = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_0]);
immutable default_RESTORE_FILE = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_o]);
immutable default_SAVE = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_s]);
immutable default_SAVE_NEW = KeyCombine([ModifierType.CONTROL_MASK,ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_S]);
immutable default_heading1 = KeyCombine([GdkKeysyms.GDK_numbersign]);
immutable default_heading2 = KeyCombine([GdkKeysyms.GDK_numbersign,GdkKeysyms.GDK_numbersign]);
immutable default_heading3 = KeyCombine([GdkKeysyms.GDK_numbersign,GdkKeysyms.GDK_numbersign,GdkKeysyms.GDK_numbersign]);

immutable default_CMOVE_L = KeyCombine([ModifierType.CONTROL_MASK,ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_H]);
immutable default_CMOVE_R = KeyCombine([ModifierType.CONTROL_MASK,ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_L]);
immutable default_CMOVE_U = KeyCombine([ModifierType.CONTROL_MASK,ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_K]);
immutable default_CMOVE_D = KeyCombine([ModifierType.CONTROL_MASK,ModifierType.SHIFT_MASK],[GdkKeysyms.GDK_J]);

immutable default_PAGE_D = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_f]);
immutable default_PAGE_U = KeyCombine([ModifierType.CONTROL_MASK],[GdkKeysyms.GDK_b]);

immutable default_JOIN = KeyCombine([ModifierType.SHIFT_MASK],GdkKeysyms.GDK_U);
