//+------------------------------------------------------------------+
//|                                                     Class Curve  |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+

#include "delta.mqh"
#include "lineinfo.mqh"


// CCurve представляет набор точек индикатора
class CCurve
{
private:
    int           index;    
public:
    string        name;
    int           count;

    int           code;
    LineMovement  movement;
    LinePattern   pattern;

    double        value;
    CDelta        deltas[];
    string        s_time;
    string        s_pattern;
    string        s_movement;

    CCurve::CCurve(string _name)
    {
        name = _name;
        index = count = -1;
        code = 0;
        value = 0.0;
        s_time = "";
        s_pattern = "";
        s_movement = "";
    };

    CCurve::CCurve(string _name, int _count)
    {
        name = _name;
        index = -1;
        count = _count;
        code = 0;
        value = 0.0;
        s_time = "";
        s_pattern = "";
        s_movement = "";
        ArrayResize(deltas, count);
    };
                    
    int Add(const CDelta &dx)
    {
        index++;
        deltas[index] = dx;
        return index;
    };

    int Add(int i, int j, double vi, double vj, datetime time=0)
    {
        index++;
        CDelta d(i, j, vi, vj
                , CDelta::CalculateDelta(vi, vj) 
                , time);
        deltas[index] = d;
        return index;
    }

    void ResetArray()
    {
        if (ArraySize(deltas) != count)
            ArrayResize(deltas, count);
    }


    // Считывает данные из индикаторного буфера и вычистяет дельты для дальнейшего анализа
    int PopulateDeltas(const datetime &time[], const double &lineBuffer[], const int index0, const int _count)
    {
        index = -1;
        count = _count;
        ResetArray();

        int k = index0;
        for(int i = 0; i < count; i++)
        {
            Add(k, k+1, lineBuffer[k], lineBuffer[k+1], time[k]);
            k++;
        }

        s_time = TimeToString(deltas[0].time);
        value = deltas[0].vi;

        //PrintFormat("PopulateDeltas index0=%d %s", index0, s_time);
        return ArraySize(deltas);
    }

    LineInfo consolidate_pair(const LineInfo &di, const LineInfo &dj)
    {
        LineInfo t();
        t.pattern = di.pattern;
        t.movement = di.movement;
        if (di.pattern == LinePattern::Reversal)
            return t;

        if (dj.movement == LineMovement::Flat)
        {
            if (di.movement != LineMovement::Flat)
                t.pattern = LinePattern::Acceleration;
            else
                t.pattern = LinePattern::Nothing;
        }
        else
        {
            if (dj.movement == di.movement)
                t.pattern = LinePattern::Continuation;
            else
            {
                if (di.movement == LineMovement::Flat) // здесь какая-то ошибка? Deceleration не работает
                    t.pattern = LinePattern::Deceleration;
                else
                    t.pattern = LinePattern::Reversal;
            }
        }
        return t;
    }


    LineInfo consolidate_quadro(const CDelta &di, const CDelta &dj, const CDelta &dk, const CDelta &dm)
    {
        LineInfo t();
        t.pattern = LinePattern::Nothing;
        t.movement = di.movement;
        t.code = 0;

        if ((di.IsUp() && dj.IsUp() && dk.IsFlat() && dm.IsDown()) || (di.IsDown() && dj.IsDown() && dk.IsFlat() && dm.IsUp()))
        {
            t.pattern = LinePattern::Reversal;
            t.code = 401;
        }
        else if ((di.IsUp() && dj.IsFlat() && dk.IsFlat() && dm.IsDown()) || (di.IsDown() && dj.IsFlat() && dk.IsFlat() && dm.IsUp())
              || (di.IsUp() && dj.IsFlat() && dk.IsDown()) || (di.IsDown() && dj.IsFlat() && dk.IsUp())
            )
        {
            t.pattern = LinePattern::Reversal;
            t.code = 402;
        }
        else if ((di.IsUp() && dj.IsUp() && dk.IsDown()) || (di.IsDown() && dj.IsDown() && dk.IsUp()))
        {
            t.pattern = LinePattern::Reversal;
            t.code = 403;
        }
        else if ((di.IsUp() && dj.IsDown() && dk.IsDown()) || (di.IsDown() && dj.IsUp() && dk.IsUp()))
        {
            t.pattern = LinePattern::Reversal;
            t.code = 404;
        }
        else
        {
            if ((di.IsUp() && dj.IsUp() && dk.IsUp()) || (di.IsDown() && dj.IsDown() && dk.IsDown()))
            {
                t.pattern = LinePattern::Continuation;
                t.code = 101;
            }
            else if ((di.IsUp() && dj.IsFlat() && dk.IsUp()) || (di.IsDown() && dj.IsFlat() && dk.IsDown()))
            {
                t.pattern = LinePattern::Bounce;
                t.code = 201;
            }
            else if (((di.IsUp() && dj.IsDown() && dk.IsUp()) && di.vi > dk.vj) || ((di.IsDown() && dj.IsUp() && dk.IsDown()) && di.vi < dk.vj))
            {
                t.pattern = LinePattern::Bounce;
                t.code = 202;
            }
            else if ((di.IsUp() && dj.IsUp() && dk.IsFlat()) || (di.IsDown() && dj.IsDown() && dk.IsFlat()))
            {
                t.pattern = LinePattern::Acceleration;
                t.code = 301;
            }
            else if (((di.IsUp() && dj.IsFlat() && dk.IsFlat())) || (di.IsDown() && dj.IsFlat() && dk.IsFlat()))
            {
                t.pattern = LinePattern::Acceleration;
                t.code = 302;
            }
            else if ((di.IsFlat() && dj.IsUp() && dk.IsUp()) || (di.IsFlat() && dj.IsDown() && dk.IsDown()))
            {
                t.pattern = LinePattern::Deceleration;
                t.code = 501;
            }

        }
        return t;
    }

    void AnalyseMovement(const CDeltaStats &stats, const CDeltaRanges &range)
    {
        for (int i = 0; i < count; i++)
            deltas[i].AnalyseMovement(stats, range);

        LineInfo t0 = consolidate_quadro(deltas[0], deltas[1], deltas[2], deltas[3]);

        code = t0.code;
        pattern = t0.pattern;
        movement = t0.movement;
        s_pattern = EnumToString(pattern);
        s_movement = EnumToString(movement);
    }

    string ToString()
    {
        string bf = StringFormat("%s delta %.1f %d %s %s", s_time, deltas[0].delta, code, s_movement, s_pattern);
        return bf;
    }

    bool IsUptrendOrFlat()
    {
        return movement == LineMovement::Flat || movement == LineMovement::UpTrend;
    }
    bool IsUptrend()
    {
        return movement == LineMovement::UpTrend;
    }

    bool IsDowntrendOrFlat()
    {
        return movement == LineMovement::Flat || movement == LineMovement::DownTrend;
    }
    bool IsDowntrend()
    {
        return movement == LineMovement::DownTrend;
    }

    bool IsFlat()
    {
        return movement == LineMovement::Flat;
    }

    bool IsReversal()
    {
        return pattern == LinePattern::Reversal;
    }

    bool IsBounce()
    {
        return pattern == LinePattern::Bounce;
    }

    bool IsAcceleration()
    {
        return pattern == LinePattern::Acceleration;
    }

    bool IsDeceleration()
    {
        return pattern == LinePattern::Deceleration;
    }

    bool IsContinuation()
    {
        return pattern == LinePattern::Continuation;
    }


    // Проверяет, что curve1 во всех точках выше чем curve2
    static bool CheckHigher(const CCurve &curve1, const CCurve &curve2, const int count)
    {
        for(int i = 0; i < count; i++)
        {
            if (curve1.deltas[i].vi <= curve2.deltas[i].vi)
                return false;
        }
        return true;
    }

    // Проверяет, что curve1 во всех точках ниже чем curve2
    static bool CheckLower(const CCurve &curve1, const CCurve &curve2, const int count)
    {
        for(int i = 0; i < count; i++)
        {
            if (curve1.deltas[i].vi >= curve2.deltas[i].vi)
                return false;
        }
        return true;
    }

    // Проверяет пересечение линии curve1 с линией curve2
    static short CheckIntersection(const CCurve &curve1, const CCurve &curve2)
    {
        if (curve1.deltas[0].vi > curve2.deltas[0].vi && curve1.deltas[1].vi < curve2.deltas[1].vi)
            return 1;
        if (curve1.deltas[0].vi < curve2.deltas[0].vi && curve1.deltas[1].vi > curve2.deltas[1].vi)
            return -1;
        return 0;
    }
    

};


