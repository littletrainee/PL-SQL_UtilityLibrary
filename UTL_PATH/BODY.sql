CREATE OR REPLACE PACKAGE BODY UTL_PATH 
IS
 --*--------------------------------------------------------------------------------------------------------------------
 --*--------------------------------------------- PRIVATE FUNCTION ------------------------------------------------------
 --*--------------------------------------------------------------------------------------------------------------------

 --*--------------------------------------------- GET LAST SLASH POSITION ----------------------------------------------
    FUNCTION GET_LAST_SLASH_POSITION(P_FILE_FULL_NAME VARCHAR2) RETURN NUMBER
    IS
    BEGIN
        RETURN GREATEST(NVL(INSTR(P_FILE_FULL_NAME, '/', -1), 0), NVL(INSTR(P_FILE_FULL_NAME, '\', -1), 0));
    END;

 --*--------------------------------------------------------------------------------------------------------------------
 --*--------------------------------------------- IMPLEMENTATION -------------------------------------------------------
 --*--------------------------------------------------------------------------------------------------------------------

 --*--------------------------------------------- GET FILE NAME --------------------------------------------------------
    FUNCTION GET_FILE_NAME (P_FILE_FULL_NAME IN VARCHAR2) RETURN VARCHAR2 
    IS
    BEGIN
        IF P_FILE_FULL_NAME IS NULL THEN
            RETURN NULL;
        END IF;
        
        DECLARE
            V_LAST_SLASH NUMBER(4,0) := GET_LAST_SLASH_POSITION(P_FILE_FULL_NAME);
        BEGIN
            IF V_LAST_SLASH > 0 THEN
                RETURN SUBSTR(P_FILE_FULL_NAME, V_LAST_SLASH + 1);
            ELSE
                RETURN P_FILE_FULL_NAME;
            END IF;
        END;
    END;

 --*--------------------------------------------- GET DIRECTORY NAME ---------------------------------------------------
    FUNCTION GET_DIRECTORY_NAME (P_FILE_FULL_NAME IN VARCHAR2)RETURN VARCHAR2 
    IS
    BEGIN
        IF P_FILE_FULL_NAME IS NULL THEN
            RETURN NULL;
        END IF;
        
        DECLARE
            V_LAST_SLASH NUMBER(4,0) := GET_LAST_SLASH_POSITION(P_FILE_FULL_NAME);
        BEGIN
            IF V_LAST_SLASH = 0 THEN
                RETURN NULL; --* 沒有目錄部分
            END IF;
            RETURN SUBSTR(P_FILE_FULL_NAME, 1, V_LAST_SLASH - 1);
        END;
    END;

 --*--------------------------------------------- GET FILE NAME NO EXTENSION -------------------------------------------
    FUNCTION GET_FILE_NAME_NO_EXTENSION(P_FILE_FULL_NAME IN VARCHAR2) RETURN VARCHAR2 
    IS
    BEGIN
        IF P_FILE_FULL_NAME IS NULL THEN
            RETURN NULL;
        END IF;
        
        DECLARE
            V_FILE_NAME VARCHAR2(4000) := GET_FILE_NAME(P_FILE_FULL_NAME);
        BEGIN
            IF V_FILE_NAME IS NULL THEN
                RETURN NULL;
            END IF;

            DECLARE 
                V_DOT_POSITION NUMBER(4,0) := INSTR(V_FILE_NAME, '.', -1);
            BEGIN
                IF V_DOT_POSITION = 0 THEN
                    RETURN V_FILE_NAME; 
                END IF;
                RETURN SUBSTR(V_FILE_NAME, 1, V_DOT_POSITION - 1);
            END;
        END;
    END;

 --*--------------------------------------------- CHECK FILE EXISTS ----------------------------------------------------
    FUNCTION CHECK_FILE_EXISTS(P_FILE_FULL_NAME IN VARCHAR2) RETURN INTEGER
    IS
        V_IS_EXIST INTEGER;
        PROCEDURE DISPOSE_DIRECTORY
        IS 
            V_EXIST NUMBER;
        BEGIN
            SELECT COUNT(*) 
              INTO V_EXIST
              FROM ALL_DIRECTORIES
             WHERE DIRECTORY_NAME = 'TARGET_PATH';
            IF V_EXIST > 0 THEN
                EXECUTE IMMEDIATE('DROP DIRECTORY TARGET_PATH');
            END IF;
        END;
    BEGIN
        EXECUTE IMMEDIATE('CREATE OR REPLACE DIRECTORY TARGET_PATH AS '''|| GET_DIRECTORY_NAME(P_FILE_FULL_NAME) ||'\''');
        V_IS_EXIST := DBMS_LOB.FILEEXISTS(BFILENAME('TARGET_PATH', GET_FILE_NAME(P_FILE_FULL_NAME)));
        DISPOSE_DIRECTORY;
        RETURN V_IS_EXIST;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
            DISPOSE_DIRECTORY;
    END;
    
 --*--------------------------------------------- CHECK DIRECTORY EXISTS -----------------------------------------------
    FUNCTION CHECK_DIRECTORY_EXIST(P_DIRECTORY_FULL_NAME IN VARCHAR2) RETURN INTEGER
    IS 
    BEGIN
        RETURN CHECK_FILE_EXISTS(P_DIRECTORY_FULL_NAME || '\.');
    END;

END UTL_PATH;