//+------------------------------------------------------------------+
//|                                               Class CandleStats  |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+



// Определяет диапазоны в % для различных размеров свечей
class CCandleRanges
{
public:

    // Размеры свечи определяются по size (не по body)
    // tiny  - крошечные свечки
    // large - большие свечи. Если размер свечи превышает large_size, такие свечи игнорируются
    // Все размеры задаются в пунктах.

    double      max_value;
    double      tiny_size;
    double      small_size;
    double      normal_size;
    double      large_size;
    double      small_body;

    CCandleRanges(void)
    {
        max_value = 0.0;
        tiny_size = 0.0;
        small_size = 0.0;
        normal_size = 0.0;
        large_size = 0.0;
        small_body = 0.0;
    }
    CCandleRanges(const CCandleRanges& other)
    {
        max_value = other.max_value;
        tiny_size = other.tiny_size;
        small_size = other.small_size;
        normal_size = other.normal_size;
        large_size = other.large_size;
        small_body = other.small_body;
    }
    CCandleRanges(double _max_value, double _tiny_size, double _small_size, double _normal_size, double _large_size, double _small_body)
    {
        max_value = _max_value;
        tiny_size = _tiny_size;
        small_size = _small_size;
        normal_size = _normal_size;
        large_size = _large_size;
        small_body = _small_body;
    }

    void PrintRanges()
    {
        PrintFormat("=== CCandleRanges ===");
        PrintFormat("Max Size: %.0f", max_value);
        PrintFormat("tiny   = %.1f", tiny_size);
        PrintFormat("small  = %.1f", small_size);
        PrintFormat("normal = %.1f", normal_size);
        PrintFormat("large  = %.1f", large_size);
        PrintFormat("small_b  = %.1f", small_body);
        PrintFormat("----");
    }


};


