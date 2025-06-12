//+------------------------------------------------------------------+
//|                                             Line Info constants  |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+


// Направление движения
enum LineMovement
{
    Flat           = 0,
    UpTrend        = 1,
    DownTrend      = 2
};


// Патерн движения
enum LinePattern
{
    Nothing        = 0,
    Deceleration   = 1,
    Continuation   = 2,
    Acceleration   = 3,
    Bounce         = 4,
    Reversal       = 5
};

// Информация о движении линии индикатора
struct LineInfo
{
    int            code;
    LineMovement   movement;
    LinePattern    pattern;
};


