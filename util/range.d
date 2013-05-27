module util.range;
debug(range) import std.stdio;

struct Range{
private:
    int _min = -1;
    int _max = -1;  // 
    bool _empty=true;

    void check_overrun(){
        if(!empty)
        _min = _min<0? 0:_min;
    }
public:
    void set(in int s,in int e)
        in{
        assert(s >= 0);
        assert(e >= 0);
        assert(s <= e);
        }
    body{
        _min = s;
        _max = e;
        _empty = false;
    }
    int opCmp(in int i)const{
        if(_max < i || empty) return -1;
        else if(_min > i ) return 1;
        else if(is_hold(i)) return 0;
        assert(0);
    }
    bool opEquals(in int rhs)const{
        return is_hold(rhs);
    }
    bool add(in int a){
        bool did_it;
        if(_min == -1 || a < _min) 
        {
            _min = a;
            did_it = true;
        }
        if(_max == -1 || a > _max)
        {
            _max = a;
            did_it = true;
        }

        if(empty)
            _empty = false;
        if(did_it)
            return true;
        else 
            return false;
    }
    void pop_front(in int n=1)
        in{
        assert(!empty);
        }
    body{
        _max += n;
    }
    void pop_back(in int n=1)
        in{
        assert(!empty);
        }
    body{
        _min -= n;
        check_overrun();
    }
    void move_front(in int n=1)
        in{
        assert(!empty);
        }
    body{
        _min += n;
        _max += n;
    }
    void move_back(in int n=1)
        in{
        assert(!empty);
        }
    body{
        if(!_min) return;
        _min -= n;
        _max -= n;
        check_overrun();
    }
    void remove_front(in int n=1)
        in{
        assert(!empty);
        }
    body{
        _max -= n;
        check_overrun();
    }
    void remove_back(in int n=1)
        in{
        assert(!empty);
        }
    body{
        _min += n;
        check_overrun();
    }
    @property int length()const{
        return _max - _min + 1;
    }
    // operator == と等価
    @property bool is_hold(in int v)const{
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
        _empty = true;
    }
}
unittest{
    Range r; // = new Range();
    assert(r.empty);
    assert(r < 1);
    assert(r < 5);
    assert(r < 0);
    r.set(3,8);
    assert(!r.empty);
    assert(r > 1);
    assert(8 == r);
    assert(r.is_hold(8));
    assert(3 == r);
    assert(r.is_hold(3));
    assert(r.max == 8);
    assert(r != 9);
    debug(range) writeln(r.opCmp(9));
    assert(r < 9);
    r.add(10);
    debug(range) writeln(r.get());
    assert(r > 2);
    assert(9 == r);
    assert(r.is_hold(9));
    assert(10 == r);
    assert(r.is_hold(10));
    assert(11 > r);
    r.add(2);
    assert(2 == r);
    assert(1 < r);
    assert(3 == r);
    r.set(5,10);
    assert(4 < r);
    assert(5 == r);
    assert(10 == r);
    assert(11 > r);
    assert(r.get().length == 6);
    r.pop_back();
    debug(range) writeln(r.get());
    assert(r.min == 4);
    assert(r.max == 10);
    assert(r.get().length == 7);
    r.pop_front();
    assert(r.min == 4);
    assert(r.max == 11);
    assert(r.get().length == 8);
    r.move_front();
    assert(r.min == 5);
    assert(r.max == 12);
    assert(r.get().length == 8);
    r.move_back();
    assert(r.min == 4);
    assert(r.max == 11);
    assert(r.get().length == 8);
    r.remove_front();
    assert(r.min == 4);
    assert(r.max == 10);
    assert(r.get().length == 7);
    r.remove_back();
    assert(r.min == 5);
    assert(r.max == 10);
    assert(r.get().length == 6);
    assert(r.length == 6);
    r.clear();
    assert(r.empty);
    r.add(5);
    debug(range) writeln(r.get());
    assert(5 == r);
    assert(r.is_hold(5));
    assert(4 < r);
    assert(6 > r);
    r.pop_front(3);
    assert(6 == r);
    assert(7 == r);
    assert(8 == r);
    assert(5 == r);
    assert(4 < r);
    assert(9 > r);
    r.pop_back(2);
    assert(4 == r);
    assert(3 == r);
    assert(2 < r);
    assert(9 > r);
    assert(r.length == 6);
    r.move_front(2);
    assert(9 == r);
    assert(10 == r);
    assert(11 > r);
    assert(5 == r);
    assert(4 < r);
    assert(r.length == 6);
    r.remove_front(3);
    assert(11 > r);
    assert(10 > r);
    assert(9 > r);
    assert(8 > r);
    assert(7 == r);
    assert(5 == r);
    assert(r.length == 3);
    r.remove_back(3);
    r.clear();
    r.add(5);
    debug(range) writeln(r.min <= r.max);
    r.pop_back(10);
    debug(range) writeln(r.min <= r.max);
    debug(range) writeln(r.get());
    assert(r.length == 6);
    assert(r.min == 0);
    r.remove_back(5);
    assert(r.min == 5);
    assert(4 < r.min);
}
