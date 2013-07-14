module util.direct;

enum Direct{ left,right,up,down };
alias Direct.left left;
alias Direct.right right;
alias Direct.up up;
alias Direct.down down;

// 左右上下に特殊化
enum UpDown:Direct{ up=Direct.up,down=Direct.down };
enum LR:Direct{ left=Direct.left,right=Direct.right };
alias UpDown.up Up;
alias UpDown.down Down;
alias LR.left Left;
alias LR.right Right;

pure Direct reverse(in Direct dir){
    final switch(dir){
        case left: return right;
        case right: return left;
        case up: return down;
        case down: return up;
    }
    assert(0);
}

pure bool is_horizontal(in Direct dir){
    return dir == right || dir == left;
}
pure bool is_vertical(in Direct dir){
    return dir == up || dir == down;
}
pure bool is_negative(in Direct dir){
    return dir == left || dir == up;
}
pure bool is_positive(in Direct dir){
    return dir == right || dir == down;
}
