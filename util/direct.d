module util.direct;

enum Direct{ left,right,up,down };
enum UpDown:Direct{ up=Direct.up,down=Direct.down };
enum LR:Direct{ left=Direct.left,right=Direct.right };
immutable UpDown up = UpDown.up;
immutable UpDown down = UpDown.down;
immutable LR left = LR.left;
immutable LR right =  LR.right;

pure Direct reverse(const Direct dir){
    final switch(dir){
        case Direct.left: return Direct.right;
        case Direct.right: return Direct.left;
        case Direct.up: return Direct.down;
        case Direct.down: return Direct.up;
    }
    assert(0);
}

pure bool is_horizontal(const Direct dir){
    return dir == Direct.right || dir == Direct.left;
}
pure bool is_vertical(const Direct dir){
    return dir == Direct.up || dir == Direct.down;
}
pure bool is_negative(const Direct dir){
    return dir == Direct.left || dir == Direct.up;
}
pure bool is_positive(const Direct dir){
    return dir == Direct.right || dir == Direct.down;
}
