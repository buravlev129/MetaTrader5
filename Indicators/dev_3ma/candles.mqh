//+------------------------------------------------------------------+
//|                                                   Class candles  |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+

#include "candlestats.mqh"
#include "candleinfo.mqh"


// Представляет свечу на графике
class CCandle
{
public:
    datetime          time;
    double            open;
    double            high;
    double            low;
    double            close;
    
    double            body;           // Размер тела свечи
    double            size;           // Полный размер High-Low в пунктах
    double            size_a;         // Полный размер High-Low
    double            lower_shadow;
    double            upper_shadow;

    bool              is_bullish;
    bool              is_bearish;
    bool              is_neutral;

    // is_green/is_red  отличается от is_bullish/is_bearish.
    // Например, красное эскимо будет is_bullish, но для некоторых расчетов нужно знать реальный цвет свечи
    bool              is_green;
    bool              is_red;

    bool              is_small_body;

    CandleDims        dimensions;     // размеры свечи определяются по size (не по body)
    CandleFigure      figure;
    string            s_dimensions;
    string            s_figure;
    string            s_direction;
    string            s_time;

    CCandle(void)
    {
    }
    CCandle(datetime _time, double _open, double _high, double _low, double _close)
    {
        time = _time;
        s_time = TimeToString(time);
        open = _open;
        high = _high;
        low = _low;
        close = _close;
        body = MathAbs(open - close) / _Point;
        size = (high - low) / _Point;
        size_a = (high - low);
        
        is_neutral = true;
        is_bullish = (close - open > 0);
        is_bearish = !is_bullish;
        is_green = is_bullish;
        is_red = is_bearish;

        is_small_body = false;

        if (is_bullish)
        {
            upper_shadow = (high - close) / _Point;
            lower_shadow = (open - low) / _Point;
        }
        else
        {
            upper_shadow = (high - open) / _Point;
            lower_shadow = (close - low) / _Point;
        }

        s_dimensions = "";
        s_figure = "";
        s_direction = "";
    }

    string ToString()
    {
        return StringFormat("%s %s %s %s", s_time, s_dimensions, s_figure, s_direction);
    }

    // Обработка параметров свечи в соответствии с переданной свечной статистикой
    void PrepareCandleDimensions(CCandleRanges &ranges)
    {
        dimensions = CandleDims::Undefined;

        if (size <= ranges.tiny_size)
            dimensions = CandleDims::Tiny;
        else if (size <= ranges.small_size)
            dimensions = CandleDims::Small;
        else if (size <= ranges.normal_size)
            dimensions = CandleDims::Normal;
        else if (size <= ranges.large_size)
            dimensions = CandleDims::Large;
        else
            dimensions = CandleDims::Huge;

        is_small_body = (body <= ranges.small_body);
        s_dimensions = EnumToString(dimensions);
    }

    // Определение свечной конфигурации
    void DetermineCandleFigure()
    {
        // https://en.wikipedia.org/wiki/Candlestick_pattern
        // https://bcs-express.ru/novosti-i-analitika/2017472037-50-osnovnykh-kombinatsii-iaponskikh-svechei-opredeliaemsia-s-trendami
        // https://fxtrendo.com/ru/blog/363/%D0%A7%D1%82%D0%BE-%D1%82%D0%B0%D0%BA%D0%BE%D0%B5-%D1%81%D0%B2%D0%B5%D1%87%D0%B0?

        double dodji_size_koff = 0.06;
        double hummer_size_koff = 0.2;
        double eskimo_size_koff = 0.5;
        double brick_size_koff = 0.65;
        double body_size_ratio = body / size;

        double short_shadow = (upper_shadow < lower_shadow) ? upper_shadow : lower_shadow;
        double long_shadow = (upper_shadow > lower_shadow) ? upper_shadow : lower_shadow;
        double shadows_size = upper_shadow + lower_shadow;
        double shadows_ratio = short_shadow / shadows_size;

        SetNeutral();
        figure = CandleFigure::Undefined;
        if (open > close)
            SetBearish();
        else
            SetBullish();
        
        if (body_size_ratio <= dodji_size_koff)
        {
            if (shadows_ratio > 0.4)
                figure = CandleFigure::Dodji;
            else if (shadows_ratio < 0.2)
            {
                figure = CandleFigure::Dragonfly;
                AssignBullishBearishByShadows();
            }
            else
            {
                figure = CandleFigure::SpinBar;
                AssignBullishBearishByShadows();
            }
        }
        else if (body_size_ratio <= hummer_size_koff)
        {
            if (shadows_ratio < 0.3)
                figure = CandleFigure::Hammer;
            else
                figure = CandleFigure::SpinBar;

            AssignBullishBearishByShadows();
        }
        else if (body_size_ratio <= eskimo_size_koff)
        {
            if (shadows_ratio < 0.25)
            {
                if (long_shadow >= body)
                {
                    figure = CandleFigure::Eskimo;
                    AssignBullishBearishByShadows();
                }
                else
                {
                    figure = CandleFigure::Eskimo;
                    AssignBullishBearishByOpenClose();
                }
            }
            else
            {
                figure = CandleFigure::SpinBar;
                AssignBullishBearishByOpenClose();
            }
        }
        else
        {
            if (body_size_ratio > brick_size_koff)
            {
                if (IsNormal() || IsLarge() || IsHuge())
                    figure = CandleFigure::Baton;
                else
                    figure = CandleFigure::Brick;
            }
            else
                figure = CandleFigure::Stump;

            //figure = CandleFigure::YyyBar;
            //figure = CandleFigure::XxxBar;
            AssignBullishBearishByOpenClose();
        }

        s_figure = EnumToString(figure);
        //s_figure = StringFormat("%s %.4f", EnumToString(figure), body_size_ratio);
    }

    void SetNeutral()
    {
        is_neutral = true;
        is_bearish = is_bullish = false;
        s_direction = "neutral";
    }
    void SetBearish()
    {
        is_neutral = false;
        is_bearish = true;
        is_bullish = !is_bearish;
        s_direction = "bearish";
    }
    void SetBullish()
    {
        is_neutral = false;
        is_bullish = true;
        is_bearish= !is_bullish;
        s_direction = "bullish";
    }

    void AssignBullishBearishByShadows()
    {
        if (upper_shadow > lower_shadow)
            SetBearish();
        else
            SetBullish();
    }

    void AssignBullishBearishByOpenClose()
    {
        if (open > close)
            SetBearish();
        else
            SetBullish();
    }


    bool IsStop()
    {
        if ((IsTiny() || IsSmall()) && IsSmallBody())
            return true;
        return false;
    }

    bool IsReversal()
    {
        return (figure == CandleFigure::Eskimo || figure == CandleFigure::Hammer || figure == CandleFigure::Dragonfly);
    }

    bool IsSmallBody()
    {
        return is_small_body;
    }

    bool IsTiny()
    {
        return dimensions == CandleDims::Tiny;
    }
    bool IsSmall()
    {
        return dimensions == CandleDims::Small;
    }
    bool IsNormal()
    {
        return dimensions == CandleDims::Normal;
    }
    bool IsLarge()
    {
        return dimensions == CandleDims::Large;
    }
    bool IsHuge()
    {
        return dimensions == CandleDims::Huge;
    }


    // Определение параметров свечей на основе переданной статистики
    static void EvaluateCandleParams(CCandleRanges &ranges, CCandle &candleArray[])
    {
        int count = ArraySize(candleArray);
        for (int i = 0; i < count; i++)
        {
            candleArray[i].PrepareCandleDimensions(ranges);
            candleArray[i].DetermineCandleFigure();
        }
    }


    // Собрает массив свечек за указанный период
    static int CollectCandles(CCandle &candleArray[], const datetime &time[], const double &open[], const double &high[]
                               , const double &low[], const double &close[], const int index0, const int count)
    {
        ArrayResize(candleArray, count);
        int k = index0;
        int arraySize = ArraySize(close);
        for(int i = 0; i < count; i++)
        {
            if (k >= arraySize)
                break;
            CCandle c_1(time[k], open[k], high[k], low[k], close[k]);
            candleArray[i] = c_1;
            k++;
        }
        return ArraySize(candleArray);
    }
    
    
};
