//+------------------------------------------------------------------+
//|                                                   CLogger class  |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+


class CLogger
{
private:
    string m_filename;
    int m_fileHandle;

public:
    CLogger(string filename = "log.txt")
    {
        m_filename = filename;
        m_fileHandle = FileOpen(m_filename, FILE_READ | FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_SHARE_READ | FILE_SHARE_WRITE);        
        if (m_fileHandle == INVALID_HANDLE)
        {
            Print("Error code ", GetLastError()); 
            Print("Ошибка: Не удалось открыть файл логов ", m_filename);
            ResetLastError();
        }
    }

    ~CLogger()
    {
        if (m_fileHandle != INVALID_HANDLE)
        {
            FileClose(m_fileHandle);
        }
    }

    void Write(string text)
    {
        if (m_fileHandle != INVALID_HANDLE)
        {
            string timestamp = TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS);
            string logEntry = StringFormat("[%s] %s", timestamp, text);
    
            // FileSeek(m_fileHandle, 0, SEEK_END);
            if (FileWrite(m_fileHandle, logEntry) <= 0)
            {
                Print("Error code ", GetLastError()); 
                Print("Ошибка: Не удалось записать в файл логов.");
                ResetLastError();
            }
        }
    }

    void Close()
    {
        Print("Закрытие логгера"); 
        if (m_fileHandle != INVALID_HANDLE)
        {
            FileClose(m_fileHandle);
            m_fileHandle = INVALID_HANDLE;
        }
    }
};


