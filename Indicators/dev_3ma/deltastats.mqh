//+------------------------------------------------------------------+
//|                                                Class DeltaStats  |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+


// Определяет диапазоны в % для флета, слабого и нормального движения и т.д.
class CDeltaRanges
{
public:
    double      koff_flat;     // Очень слабое движение, флет
    double      koff_weak;     // Слабое движение, возможное начало тренда
    double      koff_normal;   // Нормальное движение по тренду
    double      koff_large;    // Большое движение по тренду. Если значение больше large, то нужно переждать
    double      flat_threshold;
    double      weak_threshold;
    double      normal_threshold;
    double      large_threshold;

    CDeltaRanges(void)
    {
        koff_flat = 0.1;
        koff_weak = 0.5;
        koff_normal = 2.0;
        koff_large = 3.0;
        flat_threshold = 0.0;
        weak_threshold = 0.0;
        normal_threshold = 0.0;
        large_threshold = 0.0;
    }
    CDeltaRanges(const CDeltaRanges& other)
    {
        koff_flat = other.koff_flat;
        koff_weak = other.koff_weak;
        koff_normal = other.koff_normal;
        koff_large = other.koff_large;
        flat_threshold = other.flat_threshold;
        weak_threshold = other.weak_threshold;
        normal_threshold = other.normal_threshold;
        large_threshold = other.large_threshold;
    }
    CDeltaRanges(double _koff_flat, double _koff_weak, double _koff_normal, double _koff_large)
    {
        koff_flat = _koff_flat;
        koff_weak = _koff_weak;
        koff_normal = _koff_normal;
        koff_large = _koff_large;
    }

    void CalculateThresholds(double mean)
    {
        flat_threshold = mean * koff_flat;
        weak_threshold = mean * koff_weak;
        normal_threshold = mean * koff_normal;
        large_threshold = mean * koff_large;

        PrintFormat("mean=%f thresholds: %.1f  %.1f  %.1f  %.1f", mean, flat_threshold, weak_threshold, normal_threshold, large_threshold);
    }

};


// Представляет статистику по дельте индикаторной линии
class CDeltaStats
{
public:
    double      mean;
    double      mean_p;
    double      stddev;
    double      max_value;
    datetime    max_time;
    CDeltaStats(void)
    {
        mean = mean_p = stddev = max_value = 0.0;
        max_time = 0;
    }
    CDeltaStats(const CDeltaStats& other)
    {
        mean = other.mean;
        mean_p = other.mean_p;
        stddev = other.stddev;
        max_value = other.max_value;
        max_time = other.max_time;
    }
    CDeltaStats(double _mean, double _mean_p, double _stddev, double _max_value, datetime _max_time)
    {
        mean = _mean;
        mean_p = _mean_p;
        stddev = _stddev;
        max_value = _max_value;
        max_time = _max_time;
    }

};




