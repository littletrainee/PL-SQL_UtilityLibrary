CREATE OR REPLACE PACKAGE UTL_PATH AS
 --*--------------------------------------------------------------------------------------------------------------------
 -- Package Name: UTL_PATH
 -- Author: Littletrainee
 -- Version: 1.0
 -- Description: Path-related package.
 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION GET_FILE_NAME(P_FILE_FULL_NAME IN VARCHAR2) RETURN VARCHAR2;
 -- Description:
 --     Extracts the file name (including the extension) from a full file path.

 -- Parameters:
 --     P_FILE_FULL_NAME (VARCHAR2): The full file path。

 -- Return Value:
 --     VARCHAR2: The extracted file name. If the input is NULL, returns NULL.

 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION GET_DIRECTORY_NAME(P_FILE_FULL_NAME IN VARCHAR2) RETURN VARCHAR2;
 -- Description:
 --     Extracts the directory name (excluding the file name) from a full file path.

 -- Parameters:
 --     P_FILE_FULL_NAME (VARCHAR2): The full file path。

 -- Return Value:
 --     VARCHAR2: The extracted directory name. If the input is NULL or the path contains no directory part, returns NULL.

 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION GET_FILE_NAME_NO_EXTENSION(P_FILE_FULL_NAME IN VARCHAR2) RETURN VARCHAR2;
 -- Description:
 --     Extracts the file name without the extension from a full file path.

 -- Parameters:
 --     P_FILE_FULL_NAME (VARCHAR2): The full file path。

 -- Return Value:
 --     VARCHAR2: The extracted file name without the extension. If the input is NULL, returns NULL.

 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION CHECK_FILE_EXISTS(P_FILE_FULL_NAME IN VARCHAR2) RETURN INTEGER;
 -- Description:
 --     Checks whether the specified file exists.

 -- Parameters:
 --     P_FILE_FULL_NAME (VARCHAR2): The full file path.

 -- Return Value:
 --     INTEGER: Returns 1 if the file exists; otherwise, returns 0.

 --*--------------------------------------------------------------------------------------------------------------------
    FUNCTION CHECK_DIRECTORY_EXIST(P_DIRECTORY_FULL_NAME IN VARCHAR2) RETURN INTEGER;
 -- Description:
 --     Checks whether the specified directory exists.

 -- Parameters:
 --     P_DIRECTORY_FULL_NAME (VARCHAR2): The full directory path.

 -- Return Value:
 --     INTEGER: Returns 1 if the directory exists; otherwise, returns 0.

END UTL_PATH;