module misc.direct;

enum Direct{ left,right,up,down };
enum UpDown:Direct{ up=Direct.up,down=Direct.down };
enum LeftRight:Direct{ left=Direct.left,right=Direct.right };
alias UpDown.up up;
alias UpDown.down down;
alias LeftRight.left left;
alias LeftRight.right right;

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
