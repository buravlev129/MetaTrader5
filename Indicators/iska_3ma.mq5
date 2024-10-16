//+------------------------------------------------------------------+
//|                                                     iska_3ma.mq5 |
//|                                                            b. v. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "b. v."
#property link      "https://github.com/buravlev129/MetaTrader5"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 6
#property indicator_plots   6

#property description "Интуитивный скальпинг. Индикатор 3МА"
#property description "Основной интервал для получения сигналов М30 - Н1"
#property description "Интервалы для входа М5 - М15"

#property indicator_label1  "LongMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMediumBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

#property indicator_label2  "ShortMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

#property indicator_label3  "SignalMA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLimeGreen
#property indicator_style3  STYLE_SOLID
#property indicator_width3  2

#property indicator_label4  "LongMA-2"
#property indicator_label5  "ShortMA-2"
#property indicator_label6  "SignalMA-2"
#property indicator_width4  2
#property indicator_width5  2
#property indicator_width6  2
#property indicator_color4  clrDarkSlateBlue
#property indicator_color5  clrCornflowerBlue
#property indicator_color6  clrMediumSeaGreen


input string               timeframe1      = "--------"; // Параметры МА для минутных таймфреймов
input int                  signalMAPeriod1 = 16;         // Сигнальная МА
input int                  shortMAPeriod1  = 104;        // Короткая МА
input int                  longMAPeriod1   = 208;        // Длинная МА

input string               timeframe2      = "--------"; // Параметры МА для часовых таймфреймов
input int                  signalMAPeriod2 = 14;         // Сигнальная МА
input int                  shortMAPeriod2  = 26;         // Короткая МА
input int                  longMAPeriod2   = 52;         // Длинная МА

input string               other_params    = "--------"; // Другие параметры
input ENUM_APPLIED_PRICE   appliedPrice    = PRICE_CLOSE;// Значение цены
input ENUM_MA_METHOD       ma_method       = MODE_EMA;   // Тип МА
input int                  magic_num       = 36;         // Магия

//--- indicator buffers
double         longMABuffer[];
double         shortMABuffer[];
double         signalMABuffer[];
int            longMAhandle   = 0;
int            shortMAhandle  = 0;
int            signalMAhandle = 0;

int buf_0  = 0;
int buf_1  = 1;
int buf_2  = 2;
int plot_0 = 0;
int plot_1 = 1;
int plot_2 = 2;

string x_name = "";
const string x_caption = "ISKA-3MA";

bool is_working_timeframe = true;
int signalMAPeriod        = signalMAPeriod1;
int shortMAPeriod         = shortMAPeriod1;
int longMAPeriod          = longMAPeriod1;


int OnInit()
  {
    is_working_timeframe = IsSmallTimeframe() || IsMiddleTimeframe() || IsHighTimeframe();

    x_name = StringFormat("%s #%i Stopped!", x_caption, magic_num);

    if (IsSmallTimeframe())
    {
      signalMAPeriod = signalMAPeriod1;
      shortMAPeriod  = shortMAPeriod1;
      longMAPeriod   = longMAPeriod1;
      x_name = StringFormat("%s %i,%i,%i #%i", x_caption, signalMAPeriod, shortMAPeriod, longMAPeriod, magic_num);
      PlotIndexSetInteger(plot_0, PLOT_LINE_COLOR, indicator_color1);
      PlotIndexSetInteger(plot_1, PLOT_LINE_COLOR, indicator_color2);
      PlotIndexSetInteger(plot_2, PLOT_LINE_COLOR, indicator_color3);
    }
    if (IsMiddleTimeframe() || IsHighTimeframe())
    {
      signalMAPeriod = signalMAPeriod2;
      shortMAPeriod  = shortMAPeriod2;
      longMAPeriod   = longMAPeriod2;
      x_name = StringFormat("%s %i,%i,%i #%i", x_caption, signalMAPeriod, shortMAPeriod, longMAPeriod, magic_num);
      PlotIndexSetInteger(plot_0, PLOT_LINE_COLOR, indicator_color4);
      PlotIndexSetInteger(plot_1, PLOT_LINE_COLOR, indicator_color5);
      PlotIndexSetInteger(plot_2, PLOT_LINE_COLOR, indicator_color6);
    }

    IndicatorSetString(INDICATOR_SHORTNAME, x_name);

    if (!is_working_timeframe)
      return INIT_SUCCEEDED;

    SetIndexBuffer(buf_0, longMABuffer, INDICATOR_DATA);
    SetIndexBuffer(buf_1, shortMABuffer, INDICATOR_DATA);
    SetIndexBuffer(buf_2, signalMABuffer, INDICATOR_DATA);
    ArraySetAsSeries(longMABuffer, true);
    ArraySetAsSeries(shortMABuffer, true);
    ArraySetAsSeries(signalMABuffer, true);

    longMAhandle   = iMA(_Symbol, _Period, longMAPeriod, 0, ma_method, appliedPrice);
    shortMAhandle  = iMA(_Symbol, _Period, shortMAPeriod, 0, ma_method, appliedPrice);
    signalMAhandle = iMA(_Symbol, _Period, signalMAPeriod, 0, ma_method, appliedPrice);

    if(shortMAhandle == INVALID_HANDLE || longMAhandle == INVALID_HANDLE || signalMAhandle == INVALID_HANDLE)
    {
      PrintFormat("Не удалось создать хэндл индикатора iMA, код ошибки %d", GetLastError());
      return(INIT_FAILED);
    }

    return(INIT_SUCCEEDED);
  }


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const int begin,
                const double &price[])
  {
    if (!is_working_timeframe)
      return rates_total;

    //Print("--- OnCalculate ---");

    CopyBuffer(longMAhandle, 0, 0, rates_total, longMABuffer);
    ResetLastError();
    CopyBuffer(shortMAhandle, 0, 0, rates_total, shortMABuffer);
    ResetLastError();
    CopyBuffer(signalMAhandle, 0, 0, rates_total, signalMABuffer);
    ResetLastError();

   return(rates_total);
  }


void OnDeinit(const int reason) 
  { 
   if(longMAhandle != INVALID_HANDLE)
      IndicatorRelease(longMAhandle);
   if(shortMAhandle != INVALID_HANDLE)
      IndicatorRelease(shortMAhandle);
   if(signalMAhandle != INVALID_HANDLE)
      IndicatorRelease(signalMAhandle);
   Comment("");
  }


bool IsSmallTimeframe()
{
  if (_Period >= PERIOD_M1 && _Period < PERIOD_M30)
    return true;
  return false;
}
bool IsMiddleTimeframe()
{
  if (_Period >= PERIOD_M30 && _Period < PERIOD_H6)
    return true;
  return false;
}
bool IsHighTimeframe()
{
  if (_Period >= PERIOD_H6)
    return true;
  return false;
}

