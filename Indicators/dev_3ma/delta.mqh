//+------------------------------------------------------------------+
//|                                                     Class Delta  |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+


#include "lineinfo.mqh"
#include "deltastats.mqh"



// Представляет дельту (расстояние) между двумя точками индикаторной линии
class CDelta
{
public:
    int           i;
    int           j;
    double        vi;
    double        vj;
    double        delta;   // delta in points
    datetime      time;

    LineMovement  movement;

    CDelta(const CDelta& other):
        i(other.i), j(other.j), vi(other.vi), vj(other.vj), delta(other.delta),
        time(other.time), 
        movement(other.movement) {}

    CDelta(void): i(-1), j(-1), vi(0), vj(0), delta(0), time(0),
        movement(0) {}

    CDelta(int _i, int _j, double _vi, double _vj, double _delta=0, datetime _time=0)
    {
        i=_i;
        j=_j;
        vi=_vi;
        vj=_vj;
        delta=_delta;
        time = _time;
    };


    LineInfo GetLineInfo()
    {
        LineInfo t();
        t.movement = movement;
        return t;
    }

    bool IsUp() const
    {
        return movement == LineMovement::UpTrend;
    }
    bool IsDown() const
    {
        return movement == LineMovement::DownTrend;
    }
    bool IsFlat() const
    {
        return movement == LineMovement::Flat;
    }


    void AnalyseMovement(const CDeltaStats &stats, const CDeltaRanges &range)
    {
        if (delta < range.flat_threshold)
            movement = LineMovement::Flat;
        else
            movement = (vi > vj)? LineMovement::UpTrend : LineMovement::DownTrend;
    }


    string to_str()
    {
        return StringFormat("Delta %s %d-%d vi=%f vj=%f del=%.1f  %s", TimeToString(time), i, j, vi, vj, delta, EnumToString(movement));
    }

    
    static double CalculateDelta(double vi, double vj)
    {
        double d = fabs(vi - vj) / _Point;
        return d;
    }

    // Возвращает статистические параметры дельт индикаторной линии за указанный период
    static CDeltaStats GetDeltaStats(const datetime &time[], const double &lineBuffer[], const int start, const int count)
    {
        CDeltaStats st();
        int finish = start + count;
        int length = ArraySize(lineBuffer);
        if (start >= length || finish > length || start >= finish)
            return st;

        double data[];
        ArrayResize(data, count);

        int k = 0;
        int i;
        for (int j = start+1; j < finish; j++)
        {
            i = j - 1;
            data[k] = CDelta::CalculateDelta(lineBuffer[i], lineBuffer[j]);
            if (data[k] > st.max_value)
            {
                st.max_value = data[k];
                st.max_time = time[k];
            }
            k++;
        }

        PrintFormat("Max delta: %s - %.0f", TimeToString(st.max_time), st.max_value);

        double data_p[];
        ArrayResize(data_p, count);
        for(int i = 0; i < count; i++)
        {
            data_p[i] = data[i] / st.max_value * 100;
        }

        double tresh_10 = 0.3 * st.max_value;
        double tresh_90 = 0.8 * st.max_value;

        st.mean = CDelta::CalculateMean(data, tresh_10, tresh_90);
        PrintFormat("mean tresholds: %.2f - %.2f mean=%.2f", tresh_10, tresh_90, st.mean);
        
        return st;
    }

    // Функция для вычисления средней для массива
    static double CalculateMean(const double &data[], double thres1, double thres2)
    {
        double sum = 0;
        int size = ArraySize(data);
        int count = 0;
        for(int i = 0; i < size; i++)
        {
            if (data[i] < thres1 || data[i] > thres2)
               continue;

            count++;
            sum += data[i];
        }
        return (count > 0)? sum / count : 0.0;
    }    

    static double CalculateMean(const double &data[])
    {
        double sum = 0;
        int size = ArraySize(data);
        int count = 0;
        for(int i = 0; i < size; i++)
        {
            count++;
            sum += data[i];
        }
        return (count > 0)? sum / count : 0.0;
    }    

};




