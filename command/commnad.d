module commnad;

import misc.direct;

interface Command
{
    execute();
}

// move box
class MOVE_BOX_R : Command
{
    execute(){
        target.move(Direct.right);
    }
}
class MOVE_BOX_L : Command
{
    execute(){
        target.move(Direct.left);
    }
}
class MOVE_BOX_U : Command
{
    execute(){
        target.move(Direct.up);
    }
}
class MOVE_BOX_D : Command
{
    execute(){
        target.move(Direct.down);
    }
}

// text box
class INSERT_TEXT : Command
{
    execute(){

        auto casted = cast(TextBOX)target;
        assert(casted !is null);
        // if(casted is null) throw new Exception("target is not TextBOX");
        casted.
    }
}

class MODE_CHANGE :Command
{
    execute(){
    }
}


