//+------------------------------------------------------------------+
//|                                             CConfigReader class  |
//|                                                            B. V. |
//|                                                                  |
//+------------------------------------------------------------------+

class ConfigData
{
public:
    string    label;
    string    key;
    bool      is_found;
    double    v1;
    double    v2;

    ConfigData()
    {
        label = "";
        key = "";
        is_found = false;
    }
    ConfigData(string _label, string _key)
    {
        label = _label;
        key = _key;
        is_found = false;
    }
    ConfigData(const ConfigData &other):
        label(other.label), key(other.key), is_found(other.is_found), v1(other.v1), v2(other.v2) {}

    void AssignKey(string _label, string _key)
    {
        label = _label;
        key = _key;
    }

    void CopyData(const ConfigData &other)
    {
        is_found = other.is_found;
        v1 = other.v1;
        v2 = other.v2;
    }
};


class ConfigReader
{
private:
    string m_filename;
    int m_fileHandle;

public:
    ConfigReader(string filename = "config_data.cfg")
    {
        m_filename = filename;
    }

    ~ConfigReader()
    {
        if (m_fileHandle != INVALID_HANDLE)
        {
            FileClose(m_fileHandle);
        }
    }

    void Close()
    {
        if (m_fileHandle != INVALID_HANDLE)
        {
            FileClose(m_fileHandle);
            m_fileHandle = INVALID_HANDLE;
        }
    }

    ConfigData ReadData(string label, string key)
    {
        ConfigData dat(label, key);

        m_fileHandle = FileOpen(m_filename, FILE_READ | FILE_TXT | FILE_ANSI | FILE_SHARE_READ);        
        if (m_fileHandle == INVALID_HANDLE)
        {
            Print("Error code ", GetLastError()); 
            Print("Ошибка: Не удалось открыть файл с данными ", m_filename);
            ResetLastError();
            return dat;
        }

        bool foundLabel = false;
        bool foundKey = false;
        double value1 = 0.0;
        double value2 = 0.0;
        
        while (!FileIsEnding(m_fileHandle))
        {
            string line = FileReadString(m_fileHandle);
            StringTrimLeft(line);
            StringTrimRight(line);
    
            if (line == label)
            {
                foundLabel = true;
                continue;
            }
            
            if (foundLabel && !foundKey)
            {
                if (line == "---")
                    break;

                string parts[];
                int count = StringSplit(line, ';', parts);
                
                if (count >= 3 && parts[0] == key)
                {
                    dat.is_found = true;
                    dat.v1 = StringToDouble(parts[1]);
                    dat.v2 = StringToDouble(parts[2]);
                    break;
                }
            }
        }        
        return dat;
    }

};
