//+------------------------------------------------------------------+
//|                                       drop_Autotrade_objects.mq5 |
//|                                                            b. v. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+

#property copyright "b. v."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Скрипт удаляет из окна графика стрелки и линии,"
#property description "которые ставит MetaTrader при открытии и закрытии позиции"
#property script_show_inputs

//--- input parameters
input bool     TradeArrows=true;    // Стрелки открытия и закрытия позиции
input bool     Trandlines=true;     // Трендовые линии
input string   Name="autotrade #";  // Название объекта (подстрока)

void OnStart()
  {
   int total_objects = ObjectsTotal(0, 0, -1);
   int substr_len = StringLen(Name);

   for(int i = total_objects - 1; i >= 0; i--)
     {
      string object_name = ObjectName(0, i);

      if(StringSubstr(object_name, 0, substr_len) == Name)
        {
         ENUM_OBJECT object_type = (ENUM_OBJECT)ObjectGetInteger(0, object_name, OBJPROP_TYPE);

         if((TradeArrows && (object_type == OBJ_ARROW_SELL || object_type == OBJ_ARROW_BUY)) || (Trandlines && object_type == OBJ_TREND))
           {
            Print("delete: ", object_name, EnumToString(object_type));
            ObjectDelete(0, object_name);
           }
        }
     }
  }
