//+------------------------------------------------------------------+
//|                                              ska_3ma_signals.mq5 |
//|                                                            b. v. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "b. v."
#property link      "https://github.com/buravlev129/MetaTrader5"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_plots   5

#property description "Интуитивный скальпинг. Сигналы по индикатору 3МА"
#property description "Интервалы для работы М15-M30-H1"

#property indicator_label1  "LongMA"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMediumBlue
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1

#property indicator_label2  "MiddleMA"
#property indicator_type2   DRAW_LINE
#property indicator_color2  clrDodgerBlue
#property indicator_style2  STYLE_SOLID
#property indicator_width2  1

#property indicator_label3  "ShortMA"
#property indicator_type3   DRAW_LINE
#property indicator_color3  clrLightSkyBlue
#property indicator_style3  STYLE_SOLID
#property indicator_width3  1

#property indicator_label4  "SignalUp"
#property indicator_type4   DRAW_ARROW
#property indicator_color4  clrLightGreen
#property indicator_style4  STYLE_SOLID
#property indicator_width4  1

#property indicator_label5  "SignalDown"
#property indicator_type5   DRAW_ARROW
#property indicator_color5  clrRed
#property indicator_style5  STYLE_SOLID
#property indicator_width5  1

#include "arrows.mqh"
#include "delta.mqh"
#include "deltastats.mqh"
#include "curves.mqh"
#include "logger.mqh"
#include "treema.mqh"
#include "confreader.mqh"
#include "candlestats.mqh"
#include "candles.mqh"



input ENUM_APPLIED_PRICE  appliedPrice    = PRICE_CLOSE; // Параметр цены
input ENUM_MA_METHOD      ma_method       = MODE_EMA;    // Тип МА
input int                 longMAPeriod    = 208;         // Длинная МА
input int                 middleMAPeriod  = 104;         // Средняя МА
input int                 shortMAPeriod   = 16;          // Короткая МА
input int                 magic_num       = 416;         // Магия

double         longMABuffer[];
double         middleMABuffer[];
double         shortMABuffer[];
double         arrowUpBuffer[];
double         arrowDownBuffer[];

int            longMAhandle    = 0;
int            middleMAhandle  = 0;
int            shortMAhandle   = 0;

const string   x_caption            = "SKA-3MA";
string         x_name               = "";
bool           is_working_timeframe = true;
bool           is_init_error        = true;
int            bars_calculated      = 0;
int            stats_calculation_range = 1500;
bool           candle_stats_calculated = false;
bool           line_stats_calculated   = false;
CDeltaStats    stats_short();
CDeltaStats    stats_middle();
CDeltaStats    stats_long();
CLogger        ma_logger("3ma_logger_001.log");
ConfigData     configData();



int OnInit()
{
   is_init_error = false;
   x_name = StringFormat("%s %i,%i,%i #%i", x_caption, shortMAPeriod, middleMAPeriod, longMAPeriod, magic_num);
   IndicatorSetString(INDICATOR_SHORTNAME, x_name);

   candle_stats_calculated = false;
   line_stats_calculated = false;

   PrintFormat("--- OnInit ---");
   PrintFormat("%s %s", _Symbol, EnumToString(_Period));
   PrintFormat("Bar count %d", iBars(_Symbol, _Period));
   PrintFormat("---");

   read_config_data();

   if (!is_working_timeframe)
      return INIT_SUCCEEDED;

   arrowUpCode = arrowUp1Code;
   arrowDownCode = arrowDown1Code;
   IndicatorSetInteger(INDICATOR_DIGITS, Digits());
   ArraySetAsSeries(longMABuffer, true);
   ArraySetAsSeries(middleMABuffer, true);
   ArraySetAsSeries(shortMABuffer, true);
   ArraySetAsSeries(arrowUpBuffer, true);
   ArraySetAsSeries(arrowDownBuffer, true);
   SetIndexBuffer(0, longMABuffer, INDICATOR_DATA);
   SetIndexBuffer(1, middleMABuffer, INDICATOR_DATA);
   SetIndexBuffer(2, shortMABuffer, INDICATOR_DATA);
   SetIndexBuffer(3, arrowUpBuffer, INDICATOR_DATA);
   SetIndexBuffer(4, arrowDownBuffer, INDICATOR_DATA);

   // PlotIndexSetInteger(0, PLOT_LINE_COLOR, longMAColor);
   // PlotIndexSetInteger(1, PLOT_LINE_COLOR, middleMAColor);
   // PlotIndexSetInteger(2, PLOT_LINE_COLOR, shortMAColor);
   PlotIndexSetInteger(3, PLOT_ARROW, arrowUpCode);
   PlotIndexSetInteger(4, PLOT_ARROW, arrowDownCode);
   PlotIndexSetInteger(3, PLOT_ARROW_SHIFT, arrowShift);
   PlotIndexSetInteger(4, PLOT_ARROW_SHIFT, -arrowShift);
   PlotIndexSetDouble(3, PLOT_EMPTY_VALUE, EMPTY_VALUE);
   PlotIndexSetDouble(4, PLOT_EMPTY_VALUE, EMPTY_VALUE);

   longMAhandle   = iMA(_Symbol, _Period, longMAPeriod, 0, ma_method, appliedPrice);
   middleMAhandle = iMA(_Symbol, _Period, middleMAPeriod, 0, ma_method, appliedPrice);
   shortMAhandle  = iMA(_Symbol, _Period, shortMAPeriod, 0, ma_method, appliedPrice);

   if(longMAhandle == INVALID_HANDLE || middleMAhandle == INVALID_HANDLE || shortMAhandle == INVALID_HANDLE)
   {
      PrintFormat("Не удалось создать хэндл индикатора iMA, код ошибки %d", GetLastError());
      is_init_error = true;
      return(INIT_FAILED);
   }

   return (INIT_SUCCEEDED);
}


int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   if (!is_working_timeframe || is_init_error)
      return rates_total;

   int values_to_copy = 0;
   int calculated = BarsCalculated(shortMAhandle);
   if(calculated <= 0)
   {
      PrintFormat("BarsCalculated() returned %d, error code %d", calculated, GetLastError());
      return(0);
   }
   if(prev_calculated == 0 || calculated != bars_calculated || rates_total > prev_calculated+1)
   {
      if(calculated > rates_total)
         values_to_copy = rates_total;
      else
         values_to_copy = calculated;
   }
   else
   {
      values_to_copy = (rates_total - prev_calculated) + 1;
   }

   if (!FillArrayFromBuffer(longMABuffer, 0, longMAhandle, values_to_copy))
      return(0);
   if (!FillArrayFromBuffer(middleMABuffer, 0, middleMAhandle, values_to_copy))
      return(0);
   if (!FillArrayFromBuffer(shortMABuffer, 0, shortMAhandle, values_to_copy))
      return(0);

   int limit = prev_calculated - 1;
   if(prev_calculated == 0)
      limit = 2;

   if (prev_calculated == rates_total)
      return(rates_total);

   ArraySetAsSeries(time, true);
   ArraySetAsSeries(open, true);
   ArraySetAsSeries(high, true);
   ArraySetAsSeries(low, true);
   ArraySetAsSeries(close, true);
   ArraySetAsSeries(arrowUpBuffer, true);
   ArraySetAsSeries(arrowDownBuffer, true);

   PrintFormat("prev_calculated=%d rates_total=%d",prev_calculated, rates_total);
   //calculate_candle_stats(rates_total, time, open, high, low, close);
   calculate_line_stats(rates_total, time);

   datetime time_1 = D'2020.10.26 00:00'; //D'2025.02.17 00:00';
   datetime time_2 = D'2020.01.01 00:00';
   int index_1 = 1;
   time_1 = time[index_1];

   //int index_1 = iBarShift(_Symbol, _Period, time_1);
   int index_2 = iBarShift(_Symbol, _Period, time_2);
   int count = index_2 - index_1 + 1;
   PrintFormat("Processing");
   PrintFormat("  index1=%d, %s -- index2=%d, %s  count=%d", index_1, TimeToString(time_1), index_2, TimeToString(time_2), count);

   CCurve u_sht("ShortMA");
   CCurve u_mid("MiddleMA");
   CCurve u_lng("LongMA");

   for(int i = 0; i < rates_total; i++)
   {
      arrowUpBuffer[i] = EMPTY_VALUE;
      arrowDownBuffer[i] = EMPTY_VALUE;
   }

   // CCandle::PrintCandle(_Symbol, _Period, D'2024.10.21 08:00');
   // CCandle::PrintCandle(_Symbol, _Period, D'2024.10.21 10:00');

   // это будет загружаться из конфига и может меняться для разных валютных пар и таймфреймов
   CDeltaRanges range_short(0.06, 0.3, 1.5, 2.6);
   CDeltaRanges range_middle(0.09, 0.3, 1.5, 2.6);
   CDeltaRanges range_long(0.15, 0.3, 1.5, 2.6);
   range_short.CalculateThresholds(stats_short.mean);
   range_middle.CalculateThresholds(stats_middle.mean);
   range_long.CalculateThresholds(stats_long.mean);

   // 96	200	360	640	800

   CCandleRanges candle_range(2500, 300, 500, 1000, 2000);    // D1
   // CCandleRanges candle_range(1300, 110, 350, 650, 1100);  // H1
   // CCandleRanges candle_range(1500, 110, 320, 830, 1400);  // H3
   candle_range.PrintRanges();

   CTreeMA treeMA();

   if (index_1 > 0 && index_2 > index_1)
   {
      int k = index_1;
      ma_logger.Write("Логирование данных ShortMA");

      for(int i = 0; i < count; i++)
      {
         CCandle candles[];
         CCandle::CollectCandles(candles, time, open, high, low, close, k, treeMA.count);
         CCandle::EvaluateCandleParams(candle_range, candles);

         u_sht.PopulateDeltas(time, shortMABuffer, k, treeMA.count);
         u_mid.PopulateDeltas(time, middleMABuffer, k, treeMA.count);
         u_lng.PopulateDeltas(time, longMABuffer, k, treeMA.count);

         u_sht.AnalyseMovement(stats_short, range_short);
         u_mid.AnalyseMovement(stats_middle, range_middle);
         u_lng.AnalyseMovement(stats_long, range_long);

         arrowUpBuffer[k] = EMPTY_VALUE;
         arrowDownBuffer[k] = EMPTY_VALUE;

         CCandle c0 = candles[0];
         if (c0.figure == CandleFigure::Eskimo)
         {
            PrintFormat("%s %.0f %.0f", c0.ToString(), c0.size, c0.body);
            if (c0.is_bullish)
               arrowUpBuffer[k] = low[k];
            else if (c0.is_bearish)
               arrowDownBuffer[k] = high[k];
            // else
            //    arrowUpBuffer[k] = low[k];
         }



         //ma_logger.Write(StringFormat("%.1f %d %s %s", u_sht.deltas[0].delta, u_sht.code, u_sht.s_pattern, u_sht.s_movement));
         // short cross = CCurve::CheckIntersection(u_sht, u_mid);

         // if (u_sht.IsUptrend() && CCurve::CheckHigher(u_sht, u_mid, 1))
         // {
         //    arrowUpBuffer[k] = shortMABuffer[k];
         // }
         // else if (u_sht.IsDowntrend() && CCurve::CheckLower(u_sht, u_mid, 1))
         // {
         //    arrowDownBuffer[k] = shortMABuffer[k];
         // }

         // if (cross != 0)
         // {
         //    if (u_sht.IsUptrend())
         //       arrowUpBuffer[k] = shortMABuffer[k];
         //    else
         //       arrowDownBuffer[k] = shortMABuffer[k];
         //    PrintFormat("%s", u_sht.ToString());
         // }

         if (u_sht.IsUptrend())
         {
            // arrowUpBuffer[k] = shortMABuffer[k];
            // PrintFormat("%s", u_sht.ToString());
            // if (u_sht.IsReversal())
            //    arrowUpBuffer[k] = shortMABuffer[k];
            // if (u_sht.IsDeceleration())
            // {
            //    PrintFormat("%s", u_sht.ToString());
            //    arrowUpBuffer[k] = shortMABuffer[k];
            // }

         }
         else if (u_sht.IsDowntrend())
         {
            // PrintFormat("%s", u_sht.ToString());
            // arrowDownBuffer[k] = shortMABuffer[k];
            // if (u_sht.IsReversal())
            //    arrowDownBuffer[k] = shortMABuffer[k];
            // if (u_sht.IsDeceleration())
            // {
            //    PrintFormat("%s", u_sht.ToString());
            //    arrowDownBuffer[k] = shortMABuffer[k];
            // }
         }


         // Signal s = treeMA.analyse(k, u_sht, u_mid, u_lng);
         // if (s.value > 0)
         // {
         //    Print(s.text);
         //    // if (s.is_bullish)
         //    // {
         //    //    arrowUpBuffer[k] = low[k];
         //    // }
         //    // else if (s.is_bearish)
         //    // {
         //    //    arrowDownBuffer[k] = high[k];
         //    // }
         // }

         k++;
      }
   }

   return(rates_total);
}



// Вычисление статистики для линий МА за указанный период
void calculate_line_stats(const int rates_total, const datetime &time[])
{
   if (!line_stats_calculated)
   {
      line_stats_calculated = true;
      PrintFormat("--- Calculate Line Stats ---");
      int range = (rates_total > stats_calculation_range)? stats_calculation_range : rates_total - 1;
      datetime t0 = time[0];
      datetime t1 = time[range];
      PrintFormat(" range=%d  %s - %s", range, TimeToString(t0), TimeToString(t1));

      stats_short = CDelta::GetDeltaStats(time, shortMABuffer, 0, range);
      stats_middle = CDelta::GetDeltaStats(time, middleMABuffer, 0, range);
      stats_long = CDelta::GetDeltaStats(time, longMABuffer, 0, range);

      PrintFormat(" ShortMA:  max_d=%f at %s  mean=%f mean_p=%f", stats_short.max_value, TimeToString(stats_short.max_time), stats_short.mean, stats_short.mean_p);
      PrintFormat(" MiddleMA: max_d=%f at %s  mean=%f mean_p=%f", stats_middle.max_value, TimeToString(stats_middle.max_time), stats_middle.mean, stats_middle.mean_p);
      PrintFormat(" LongMA:   max_d=%f at %s  mean=%f mean_p=%f", stats_long.max_value, TimeToString(stats_long.max_time), stats_long.mean, stats_long.mean_p);
      PrintFormat("---");
   }
}


bool FillArrayFromBuffer(double &values[],   // indicator buffer of Moving Average values
                         int shift,          // shift
                         int ind_handle,     // handle of the iMA indicator
                         int amount          // number of copied values
                        )
{
   ResetLastError();

   if(CopyBuffer(ind_handle, 0, -shift, amount, values) < 0)
   {
      PrintFormat("Failed to copy data from the iMA indicator, error code %d",GetLastError());
      return(false);
   }

   return(true);
}


void OnDeinit(const int reason) 
{
   if(longMAhandle != INVALID_HANDLE)
      IndicatorRelease(longMAhandle);
   if(middleMAhandle != INVALID_HANDLE)
      IndicatorRelease(middleMAhandle);
   if(shortMAhandle != INVALID_HANDLE)
      IndicatorRelease(shortMAhandle);
   
   ma_logger.Close();
   // if (treeRivers != NULL)
   // {
   //    delete treeRivers;
   //    treeRivers = NULL;      
   // }
   Comment("");
}


void read_config_data()
{
   string symbol_currency_base   = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_BASE); 
   string symbol_currency_profit = SymbolInfoString(Symbol(), SYMBOL_CURRENCY_PROFIT); 

   string symbol = StringFormat("%s%s", symbol_currency_base, symbol_currency_profit);
   string period = EnumToString(_Period);
   int pos = StringFind(period, "PERIOD_"); 
   if (pos >= 0)
      period = StringSubstr(period, StringLen("PERIOD_"), -1);

   configData.AssignKey(symbol, period);
   PrintFormat("Reading config data for %s %s", configData.label, configData.key);

   ConfigReader configReader("candle_stats.ini");
   ConfigData def_dat = configReader.ReadData("DEFAULTS", period);

   ConfigData dat = configReader.ReadData(symbol, period);
   if (dat.is_found)
   {
      configData.CopyData(dat);
      PrintFormat("found: %.3f %.3f", configData.v1, configData.v2);
   }
   else
   {
      PrintFormat("Key not found %s %s", configData.label, configData.key);
      configData.CopyData(def_dat);
      configData.v1 = def_dat.v1;
      configData.v2 = def_dat.v2;
      PrintFormat("default values: %.3f %.3f", configData.v1, configData.v2);
   }

   configReader.Close();
   PrintFormat("---");
}

