//+------------------------------------------------------------------+
//|                                            Tree MA Test Strategy |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+

#include "delta.mqh"
#include "curves.mqh"
#include "candles.mqh"
#include "candleinfo.mqh"
#include "signal.mqh"




// Тестовая стратегия 3МА
class CTreeMA
{
public:
    int   count;

    CTreeMA::CTreeMA()
    {
        count = 6; // Количество свечей, которое анализирует данный алгоритм
    };


    CSignal analyse(const CCandle &candleArray[], const int k, CCurve &u_sht, CCurve &u_mid, CCurve &u_long)
    {
        // Нулевой элемент здесь главный. Сигнал всегда определяется для нулевого элемента

        CCandle c0 = candleArray[0];
        CSignal s(k, c0.s_time);

        bool filterShtMidPosition = true;
        bool checkTrend=true;

        CSignal x = Check_Bounce_Sht_Trend_Reversal(candleArray, k, u_sht, u_mid, u_long, filterShtMidPosition, checkTrend);
        if (x.IsSignal())
            return x;
        
        return s;
    }


    // Отскок от линии ShortМА по тренду
    CSignal Check_Bounce_Sht_Trend_Reversal(const CCandle &candleArray[], const int k, CCurve &u_sht, CCurve &u_mid, CCurve &u_long
                                           , const bool checkShtMidPosition=false
                                           , const bool checkTrend=true
                                           , const int sig_no=1
                                        )
    {
        // Нулевой элемент здесь главный. Сигнал всегда определяется для нулевого элемента
        // ---
        // Сигнал: отскок от линии МА по тренду
        // Свечи: разворотные - Eskimo, Hammer, Dragonfly
        // Фильтры:
        //  - checkShtMidPosition проверить, чтобы ShortMA была выше или ниже MiddMA
        //  - checkTrend проверять наличие тренда
        // 

        CCandle c0 = candleArray[0];
        CSignal s(k, c0.s_time);

        if (c0.IsSmall()
            // && (c0.figure == CandleFigure::Eskimo || c0.figure == CandleFigure::Hammer || c0.figure == CandleFigure::Dragonfly
            //     || c0.figure == CandleFigure::SpinBar || c0.figure == CandleFigure::Stump || c0.figure == CandleFigure::Brick)
           )
        {
            s.SetBullishOrBearish(c0.is_bullish, c0.is_bearish);
            int bounce =  CandleBounceFromLine(c0, u_sht);
            if (c0.is_green)
            {
                s.value = 1;
                s.SetBullish();
            }
            else if (c0.is_red)
            {
                s.value = 1;
                s.SetBearish();
            }
            // if (bounce == 1)
            // {
            //     s.value = 1;
            //     s.code = 182828;
            //     s.SetBullish();
            //     // if (checkShtMidPosition && !CCurve::CheckHigher(u_sht, u_mid, count))
            //     //     s.value = 0;
            //     // if (checkTrend && !u_sht.IsUptrendOrFlat())
            //     //     s.value = 0;
            // }
            // else if (bounce == 2)
            // {
            //     s.value = 1;
            //     s.code = 182828;
            //     s.SetBearish();
            //     // if (checkShtMidPosition && !CCurve::CheckLower(u_sht, u_mid, count))
            //     //     s.value = 0;
            //     // if (checkTrend && !u_sht.IsDowntrendOrFlat())
            //     //     s.value = 0;
            // }
        }

        // s.text = StringFormat("%s %.1f %.1f  %d %s %s", s.s_time, c0.size, c0.body, s.code, c0.s_figure, c0.s_direction);
        s.text = StringFormat("%s %.1f %.1f %.4f  sht=%.1f No %d %s %s (%d)", s.s_time, c0.high, c0.low, c0.size_a, u_sht.value, s.code, c0.s_figure, c0.s_direction, sig_no);
        return s;
    }


    int CandleBounceFromLine(CCandle &c0, CCurve &line)
    {
        double size_a_koff = (c0.IsTiny() || c0.IsSmall()) ? 0.22 : 0.15;
        double cx = c0.is_red ? c0.open : c0.close;
        double low_x = c0.low - (c0.size_a * size_a_koff);
        double high_x = c0.high + (c0.size_a * size_a_koff);

        if (low_x < line.value && cx > line.value)
        {
            if (c0.is_bullish)
            {
                if (c0.IsSmallBody() || c0.IsReversal())
                    return 1; // goes up

                if (c0.is_red && c0.close > line.value)
                    return 1; // goes up
                if (c0.is_green && c0.open > line.value)
                    return 1; // goes up
            }
            if (c0.is_bearish && c0.IsSmallBody())
                return 1; // goes down
        }
        else if (high_x > line.value && cx < line.value)
        {
            if (c0.is_bearish)
                return 2; // goes down
            if (c0.is_bullish && c0.IsSmallBody())
                return 2; // goes up
        }
        
        return 0;
    }


};

