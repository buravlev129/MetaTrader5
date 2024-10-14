//+------------------------------------------------------------------+
//|                                         collect_trading_data.mq5 |
//|                                                            b. v. |
//|                                                                  |
//+------------------------------------------------------------------+

#property copyright "b. v."
#property version   "1.00"
#property description "Скрипт собирает информацию по закрытым позициям в указанном окне."
#property description "Данные собираются с объектов Trandline, у которых в названии"
#property description "указана подстрока 'autotrade #'"
#property script_show_inputs

input bool     Trandlines=true;             // Используются трендовые линии
input string   Name="autotrade #";          // Подстрока в названии объекта
input group    "Сохранение данных";
input string   Filename="trading-data.txt"; // Имя файла


void OnStart()
{
    string file_name = Filename;

    Print("Сохранение данных по сделкам с графика в текстовый файл");
    PrintFormat("Имя файла: %s", file_name);

    int file_handle = FileOpen(file_name, FILE_WRITE|FILE_TXT|FILE_ANSI, (short)9, CP_UTF8);
    if(file_handle == INVALID_HANDLE)
    {
      Print("Ошибка открытия файла для записи: ", GetLastError());
      return;
    }

    int total_objects = ObjectsTotal(0, 0, -1);
    int substr_len = StringLen(Name);
    bool caption_added = false;

    for(int i = total_objects - 1; i >= 0; i--)
    {
        string object_name = ObjectName(0, i);

        if(StringSubstr(object_name, 0, substr_len) == Name)
        {
            ENUM_OBJECT object_type = (ENUM_OBJECT)ObjectGetInteger(0, object_name, OBJPROP_TYPE);

            if(object_type == OBJ_TREND)
            {
                string text = ObjectGetString(0, object_name, OBJPROP_TEXT);
                double price0 = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 0);
                double price1 = ObjectGetDouble(0, object_name, OBJPROP_PRICE, 1);
                long t0 = ObjectGetInteger(0, object_name, OBJPROP_TIME, 0);
                long t1 = ObjectGetInteger(0, object_name, OBJPROP_TIME, 1);

                if (!caption_added)
                {
                    string caption = "Symbol|| time0|| price0|| time1|| price1|| object_name|| text";
                    FileWriteString(file_handle, caption + "\r\n");
                    caption_added = true;
                }

                string line = StringFormat("%s|| %s|| %s|| %s|| %s|| %s|| %s", _Symbol
                                            , TimeToString(t0), DoubleToString(price0)
                                            , TimeToString(t1), DoubleToString(price1)
                                            , object_name
                                            , text);
                Print(line);
                FileWriteString(file_handle, line + "\r\n");
            }
        }
    }

    FileClose(file_handle);
    Print("Ок.");
}
