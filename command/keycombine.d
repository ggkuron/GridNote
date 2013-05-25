module command.keycombine;

import gdk.Keysyms;
import gtkc.gdktypes;

alias uint KeySym;
struct KeyCombine{
    const(KeySym)[] keys;
    ModifierType mod;
    bool use_mod;
    this(in KeySym[] k...){
        keys = k;
    }
    this(ModifierType m,in KeySym[] k...){
        use_mod = true;
        mod = m;
        keys = k;
    }
    bool opEquals(ref const KeyCombine kc)const{
        if(use_mod || kc.use_mod)
            return (mod & kc.mod) && (keys == kc.keys);
        else return keys == kc.keys;
    }
    int opCmp(ref const KeyCombine rhs)const{
        return cast(int)(toHash() - rhs.toHash());
    }
    const hash_t toHash()
    { 
        hash_t hash;
        foreach (k; keys)
        hash = (hash * 9) + k + mod*25;
        return hash;
    }

}                            
unittest{
    assert(default_MOVE_FOCUS_L == default_MOVE_FOCUS_L);
    assert(default_MOVE_FOCUS_L != default_MOVE_BOX_L);
    assert(default_MOVE_FOCUS_L.toHash() != default_MOVE_BOX_L.toHash());

    assert(default_MOVE_FOCUS_L == KeyCombine([104]));
}

// table 上に登録しない値として
immutable INVALID = KeyCombine();

immutable default_EXIT = KeyCombine(GdkKeysyms.GDK_w);
immutable default_DELETE = KeyCombine(GdkKeysyms.GDK_x);
immutable default_INSERT = KeyCombine(GdkKeysyms.GDK_i);
immutable default_EDIT = KeyCombine(GdkKeysyms.GDK_e);

immutable default_MOVE_FOCUS_L = KeyCombine(GdkKeysyms.GDK_h);
immutable default_MOVE_FOCUS_R = KeyCombine(GdkKeysyms.GDK_l);
immutable default_MOVE_FOCUS_U = KeyCombine(GdkKeysyms.GDK_k);
immutable default_MOVE_FOCUS_D = KeyCombine(GdkKeysyms.GDK_j);

immutable default_MOVE_BOX_L = KeyCombine(ModifierType.CONTROL_MASK,[GdkKeysyms.GDK_h]);
immutable default_MOVE_BOX_R = KeyCombine(ModifierType.CONTROL_MASK,[GdkKeysyms.GDK_l]);
immutable default_MOVE_BOX_U = KeyCombine(ModifierType.CONTROL_MASK,[GdkKeysyms.GDK_k]);
immutable default_MOVE_BOX_D = KeyCombine(ModifierType.CONTROL_MASK,[GdkKeysyms.GDK_j]);

immutable default_SELECT_PIVOT_L = KeyCombine([GdkKeysyms.GDK_H]);
immutable default_SELECT_PIVOT_R = KeyCombine([GdkKeysyms.GDK_L]);
immutable default_SELECT_PIVOT_D = KeyCombine([GdkKeysyms.GDK_J]);
immutable default_SELECT_PIVOT_U = KeyCombine([GdkKeysyms.GDK_K]);

immutable default_TOGGLE_GRID_RENDER = KeyCombine(GdkKeysyms.GDK_0);
immutable default_TOGGLE_BOX_BORDER_RENDER = KeyCombine(GdkKeysyms.GDK_9);

immutable default_UNDO = KeyCombine(ModifierType.CONTROL_MASK,[GdkKeysyms.GDK_z]);
immutable default_REDO = KeyCombine(ModifierType.CONTROL_MASK,[GdkKeysyms.GDK_r]);
immutable default_BOX_DELETE = KeyCombine(ModifierType.CONTROL_MASK,[GdkKeysyms.GDK_x]);

immutable default_MODE_NORMAL = KeyCombine(GdkKeysyms.GDK_Escape);
immutable default_start_insert = KeyCombine(GdkKeysyms.GDK_i);

immutable backspace = KeyCombine(GdkKeysyms.GDK_BackSpace);
immutable delete_key = KeyCombine(GdkKeysyms.GDK_Delete);
immutable return_key = KeyCombine(GdkKeysyms.GDK_Return);
immutable shift_key = KeyCombine(GdkKeysyms.GDK_Shift_L);
immutable control_key = KeyCombine(GdkKeysyms.GDK_Control_L);
immutable escape_key = KeyCombine(GdkKeysyms.GDK_Escape);
immutable alt_escape = KeyCombine(ModifierType.CONTROL_MASK,[GdkKeysyms.GDK_bracketleft]);

immutable default_ImageOpen= KeyCombine(GdkKeysyms.GDK_I);
