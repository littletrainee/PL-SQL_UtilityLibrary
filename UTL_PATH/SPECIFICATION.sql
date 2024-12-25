CREATE OR REPLACE PACKAGE UTL_PATH AS
 --*--------------------------------------------------------------------------------------------------------------------
 -- 描述：路徑相關的包
 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION GET_FILE_NAME(P_FILE_FULL_NAME IN VARCHAR2) RETURN VARCHAR2;
 -- 描述：
 --     從完整的文件路徑中提取文件名稱（包括擴展名）。

 -- 參數：
 --     P_FILE_FULL_NAME (VARCHAR2): 完整的文件路徑。

 -- 返回值：
 --     VARCHAR2: 提取出的文件名稱。如果輸入為 NULL，則返回 NULL。

 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION GET_DIRECTORY_NAME(P_FILE_FULL_NAME IN VARCHAR2) RETURN VARCHAR2;
 -- 描述：
 --     從完整的文件路徑中提取目錄名稱（不包括文件名稱）。

 -- 參數：
 --     P_FILE_FULL_NAME (VARCHAR2): 完整的文件路徑。

 -- 返回值：
 --     VARCHAR2: 提取出的目錄名稱。如果輸入為 NULL 或路徑中不包含目錄部分，則返回 NULL。

 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION GET_FILE_NAME_NO_EXTENSION(P_FILE_FULL_NAME IN VARCHAR2) RETURN VARCHAR2;
 -- 描述：
 --     從完整的文件路徑中提取不帶擴展名的文件名稱。

 -- 參數：
 --     P_FILE_FULL_NAME (VARCHAR2): 完整的文件路徑

 -- 返回值：
 --     VARCHAR2: 提取出的不帶擴展名的文件名稱。如果輸入為 NULL，則返回 NULL。

 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION CHECK_FILE_EXISTS(P_FILE_FULL_NAME IN VARCHAR2) RETURN INTEGER;
 -- 描述：
 --     判斷指定的檔案是否存在。

 -- 參數：
 --     P_FILE_FULL_NAME (VARCHAR2): 完整的文件路徑。

 -- 返回值：
 --     INTEGER: 若存在返回 1 否則返回 0。

 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION CHECK_DIRECTORY_EXIST(P_DIRECTORY_FULL_NAME IN VARCHAR2) RETURN INTEGER;
 -- 描述：
 --     判斷指定的資料夾是否存在。

 -- 參數：
 --     P_DIRECTORY_FULL_NAME (VARCHAR2): 資料夾完整路徑。

 -- 返回值：
 --     INTEGER: 若存在返回 1 否則返回 0。

END UTL_PATH;