module misc.direct;

enum Direct{ left,right,up,down };
Direct reverse(Direct dir){
    final switch(dir){
        case Direct.left: return right;
        case Direct.right: return left;
        case Direct.up: return down;
        case Direct.down: return up;
    }
    assert(0);
}

