module misc.direct;

enum Direct{ left,right,up,down };
Direct reverse(Direct dir){
    final switch(dir){
        case Direct.left: return Direct.right;
        case Direct.right: return Direct.left;
        case Direct.up: return Direct.down;
        case Direct.down: return Direct.up;
    }
    assert(0);
}

