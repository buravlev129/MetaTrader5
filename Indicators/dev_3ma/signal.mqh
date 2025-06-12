//+------------------------------------------------------------------+
//|                                                    CSignal class |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+


// Представляет сигнал для открытия/закрытия чего-нибудь
class CSignal
{
public:    
    bool    is_bullish;
    bool    is_bearish;
    int     index;
    int     code;
    int     value;
    string  text;
    string  s_time;


    CSignal(void)
    {
        is_bullish = false;
        is_bearish = false;
        index = 0;
        code = 0;
        value = 0;
        text = "";
        s_time = "";
    }
    CSignal(const int _index, const string _time)
    {
        index = _index;
        s_time = _time;

        is_bullish = false;
        is_bearish = false;
        code = 0;
        value = 0;
        text = "";
    }

    CSignal(const CSignal &other)
    {
        is_bullish = other.is_bullish;
        is_bearish = other.is_bearish;
        index = other.index;
        code = other.code;
        value = other.value;
        text = other.text;
        s_time = other.s_time;
    }


    void Consolidate(const CSignal &x)
    {
        is_bullish = x.is_bullish;
        is_bearish = x.is_bearish;
        index = x.index;
        code = x.code;
        value = x.value;
        text = x.text;
        s_time = x.s_time;
    }


    void SetBearish()
    {
        is_bearish = true;
        is_bullish = !is_bearish;
    }
    void SetBullish()
    {
        is_bullish = true;
        is_bearish= !is_bullish;
    }
    void SetBullishOrBearish(bool _is_bullish, bool _is_bearish)
    {
        is_bullish = _is_bullish;
        is_bearish = _is_bearish;
    }

    bool IsSignal()
    {
        return value > 0;
    }

};

