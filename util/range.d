module util.range;

class Range{
private:
    int _min;
    int _max;  // 
    bool _empty=true;

    void check_overrun(){
        if(_min > _max)
        {
            _empty = true;
            _min = int.init;
            _max = int.init;
        }
    }
public:
    this(int min=-1,int max=-1)
    {
        _min = min;
        _max = max;
        _empty = false;
    }

    void set(int s,int e){
        _min = s;
        _max = e;
    }
    int opCmp(const int rhs)const{
        if(rhs < _min) return -1;
        else if(rhs > _max ) return 1;
        else if(is_in(rhs)) return 0;
        assert(0);
    }
    bool add(int a)
        in{
        assert(!_empty);
        }
    body{
        if(a < this) 
        {
            _min = a;
            return true;
        }
        if(a > this)
        {
            _max = a;
            return true;
        }
        return false;
    }
    void pop_front(int n=1){
        _max += n;
    }
    void pop_back(int n=1){
        if(!_min) return;
        _min -= n;
    }
    void move_front(int n=1){
        _min += n;
        _max += n;
    }
    void move_back(int n=1){
        if(!_min) return;
        _min -= n;
        _max -= n;
    }
    void remove_front(int n=1){
        _max -= n;
        check_overrun();
    }
    void remove_back(int n=1){
        _min += n;
        check_overrun();
    }
    @property int length()const{
        return _max - _min + 1;
    }
    @property bool is_in(int v)const{
        return _min <= v && v <= _max;
    }
    int[] get()const{ 
        // min == max の時にその値を返す
        int[] result = [min];
        foreach(int i; _min+1 .. _max+1)
        {
            result ~= i;
        }
        return result;
    }
    @property int min()const{
        return _min;
    }
    @property int max()const{
        return _max;
    }
    @property bool empty()const{
        return _empty;
    }
    void clear(){
        _min = -1;
        _max = -1;
        _empty = false;
    }
}
