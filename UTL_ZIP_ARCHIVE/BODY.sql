CREATE OR REPLACE TYPE BODY UTL_ZIP_ARCHIVE IS
 --*--------------------------------------------------------------------------------------------------------------------
    CONSTRUCTOR FUNCTION UTL_ZIP_ARCHIVE(SELF IN OUT NOCOPY UTL_ZIP_ARCHIVE, P_FILE_FULL_NAME VARCHAR2) RETURN SELF AS RESULT
    IS 
    BEGIN
        SELF.FILE_FULL_NAME := P_FILE_FULL_NAME;
        --! CHECK TARGET FILE(P_FILE_NAME) IN ZIP FILE IS DIRECTORY/FOLDER
        IF SUBSTR(SELF.FILE_FULL_NAME, -1) IN ('/', '\') THEN  
            RAISE_APPLICATION_ERROR(-20002, 'The parameter [P_FILE_FULL_NAME] is directory/folder' || CHR(10)
                                         || 'Value:' || P_FILE_FULL_NAME);
        END IF;

        SELF.FILE_DIRECTORY_NAME := UTL_PATH.GET_DIRECTORY_NAME(SELF.FILE_FULL_NAME);
        --! CHECK dIRECTORY IS EXIST
        IF UTL_PATH.CHECK_DIRECTORY_EXIST(SELF.FILE_DIRECTORY_NAME) <> 1 THEN
            RAISE_APPLICATION_ERROR(-20001, 'The directory/folder of [P_FILE_FULL_NAME] is not exist please check directory/folder is exist.' || CHR(10)
                                         || 'Value: ' || P_FILE_FULL_NAME);
        END IF;

        SELF.FILE_NAME := UTL_PATH.GET_FILE_NAME(P_FILE_FULL_NAME);
        DBMS_LOB.CREATETEMPORARY(SELF.FILE_CONTENT, TRUE);

        IF UTL_PATH.CHECK_FILE_EXISTS(P_FILE_FULL_NAME) = 1 THEN
            DECLARE -- if zip file exist then load all bytes to memory
                V_FILE_LOB BFILE := BFILEnAME('TARGET_PATH', UTL_PATH.GET_FILE_NAME(P_FILE_FULL_NAME));
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
                EXECUTE IMMEDIATE('CREATE OR REPLACE DIRECTORY TARGET_PATH AS '''|| UTL_PATH.GET_DIRECTORY_NAME(P_FILE_FULL_NAME) ||'\''');
                BEGIN
                    DBMS_LOB.OPEN(V_FILE_LOB, DBMS_LOB.FILE_READONLY);
                    DBMS_LOB.LOADFROMFILE(SELF.FILE_CONTENT, V_FILE_LOB, DBMS_LOB.LOBMAXSIZE);
                    DBMS_LOB.CLOSE(V_FILE_LOB);
                    DISPOSE_DIRECTORY;
                EXCEPTION 
                    WHEN OTHERS THEN
                        IF DBMS_LOB.ISOPEN(V_FILE_LOB) = 1 THEN
                            DBMS_LOB.CLOSE(V_FILE_LOB);
                        END IF;
                        DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
                        DISPOSE_DIRECTORY;
                END;
            END;
        END IF;
        RETURN;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
    END;

 --*--------------------------------------------------------------------------------------------------------------------
    MEMBER PROCEDURE ADD_FILE(P_FILE_FULL_NAME VARCHAR2, P_COMPRESSED_FILE_FULL_NAME VARCHAR2 := NULL)
    IS
        V_FILE_BLOB BLOB;
    BEGIN
        DECLARE -- Read File Content
            V_FILE_LOB BFILE := BFILENAME('TARGET_PATH', UTL_PATH.GET_FILE_NAME(P_FILE_FULL_NAME));
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
            DECLARE
                V_BOOL BOOLEAN;
                V_FILE_LENGTH NUMBER;
                V_BLOCK_SIZE BINARY_INTEGER;
            BEGIN
                EXECUTE IMMEDIATE('CREATE OR REPLACE DIRECTORY TARGET_PATH AS ''' || UTL_PATH.GET_DIRECTORY_NAME(P_FILE_FULL_NAME) || '\''');
                UTL_FILE.FGETATTR('TARGET_PATH', UTL_PATH.GET_FILE_NAME(P_FILE_FULL_NAME), V_BOOL,V_FILE_LENGTH, V_BLOCK_SIZE);

                IF NOT V_BOOL THEN -- target file not exist
                    RAISE_APPLICATION_ERROR(-20001, P_FILE_FULL_NAME || ': File not exist, this file will pass.');
                ELSIF V_FILE_LENGTH = 0 THEN -- target file is empty
                    RAISE_APPLICATION_ERROR(-20001, P_FILE_FULL_NAME || ': File content is empty, this file will pass.');
                END IF;

                DBMS_LOB.OPEN(V_FILE_LOB, DBMS_LOB.FILE_READONLY);
                DBMS_LOB.CREATETEMPORARY(V_FILE_BLOB, TRUE);
                DBMS_LOB.LOADFROMFILE(V_FILE_BLOB, V_FILE_LOB, DBMS_LOB.LOBMAXSIZE);
                DBMS_LOB.CLOSE(V_FILE_LOB);
                DISPOSE_DIRECTORY;
            EXCEPTION 
                WHEN OTHERS THEN 
                    IF SQLCODE <> -20001 AND DBMS_LOB.ISOPEN(V_FILE_LOB) = 1 THEN
                        DBMS_LOB.CLOSE(V_FILE_LOB);
                    END IF;
                    DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
                    DISPOSE_DIRECTORY;
            END;
            IF V_FILE_BLOB IS NULL THEN
                RETURN;
            END IF;
        END;

        DECLARE
            V_FILE_LENGTH INTEGER := NVL(DBMS_LOB.GETLENGTH(V_FILE_BLOB), 0);
            V_TEMP_BLOB BLOB;
            V_TEMP_FILE_CONTENT_LENGTH INTEGER;
            V_CRC32 RAW(4) := HEXTORAW('00000000');
            V_COMPRESSED BOOLEAN := FALSE;
            V_COMPRESSED_FILE_FULL_NAME VARCHAR2(4000) := CASE 
                                                          WHEN P_COMPRESSED_FILE_FULL_NAME IS NULL THEN UTL_PATH.GET_FILE_NAME(P_FILE_FULL_NAME)
                                                          ELSE P_COMPRESSED_FILE_FULL_NAME
                                                          END;
            PROCEDURE DISPOSE_TEMP_LOB
            IS 
            BEGIN
                IF DBMS_LOB.ISTEMPORARY(V_TEMP_BLOB) = 1 THEN
                    DBMS_LOB.FREETEMPORARY(V_TEMP_BLOB);
                END IF;
            END;
        BEGIN
            IF V_FILE_LENGTH > 0 THEN
                V_TEMP_BLOB := UTL_COMPRESS.LZ_COMPRESS(V_FILE_BLOB);
                V_TEMP_FILE_CONTENT_LENGTH := DBMS_LOB.GETLENGTH(V_TEMP_BLOB) - 18;
                V_COMPRESSED := V_TEMP_FILE_CONTENT_LENGTH < V_FILE_LENGTH;
                V_CRC32 := DBMS_LOB.SUBSTR(V_TEMP_BLOB, 4, V_TEMP_FILE_CONTENT_LENGTH + 11);
            END IF;

            IF NOT V_COMPRESSED THEN
                V_TEMP_FILE_CONTENT_LENGTH := V_FILE_LENGTH;
                V_TEMP_BLOB := V_FILE_BLOB;
            END IF;

            DECLARE 
                V_FILE_NAME RAW(32767) := UTL_I18N.STRING_TO_RAW(V_COMPRESSED_FILE_FULL_NAME, 'AL32UTF8');

                V_FILE_LAST_MODIFY_TIME BINARY_INTEGER := TO_NUMBER(TO_CHAR(SYSDATE, 'SS')) / 2 
                                                        + TO_NUMBER(TO_CHAR(SYSDATE, 'MI')) * 32 
                                                        + TO_NUMBER(TO_CHAR(SYSDATE, 'HH24')) * 2048;

                V_FILE_LAST_MODIFY_DATE BINARY_INTEGER := TO_NUMBER(TO_CHAR(SYSDATE, 'DD')) 
                                                        + TO_NUMBER(TO_CHAR(SYSDATE, 'MM')) * 32 
                                                        + (TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')) - 1980) * 512;

                --! file name is ASCII Word if ascii then '0000' else '0008'
                V_FILE_NAME_ENCODING RAW(2) := CASE 
                                               WHEN V_FILE_NAME = UTL_I18N.STRING_TO_RAW(V_COMPRESSED_FILE_FULL_NAME, 'US8PC437') THEN HEXTORAW('0000') 
                                               ELSE HEXTORAW('0008')                                                                               
                                               END;
                --! compress type, deflate or no compress
                V_COMPRESS_TYPE RAW(2) := CASE 
                                          WHEN V_COMPRESSED THEN HEXTORAW('0800') 
                                          ELSE HEXTORAW('0000')                   
                                          END; 

                FUNCTION LITTLE_ENDIAN(P_BIG BINARY_INTEGER, P_BYTES PLS_INTEGER := 4) RETURN RAW
                IS
                    V_BIG BINARY_INTEGER := CASE WHEN P_BIG > 2147483647 
                                            THEN P_BIG - 4294967296 
                                            ELSE P_BIG 
                                            END;
                BEGIN
                    RETURN UTL_RAW.SUBSTR(UTL_RAW.CAST_FROM_BINARY_INTEGER(V_BIG, UTL_RAW.LITTLE_ENDIAN), 1, P_BYTES);
                END;
            BEGIN
                DBMS_LOB.APPEND(
                    SELF.FILE_CONTENT, 
                    UTL_RAW.CONCAT(
                        HEXTORAW('504B0304'),                                   -- Local file header signature
                        HEXTORAW('1400'),                                       -- version 2.0
                        V_FILE_NAME_ENCODING,                                   -- file name encoding
                        V_COMPRESS_TYPE,                                        -- compress type
                        LITTLE_ENDIAN(V_FILE_LAST_MODIFY_TIME, 2),              -- File last modification time
                        LITTLE_ENDIAN(V_FILE_LAST_MODIFY_DATE, 2),              -- File last modification date
                        V_CRC32,                                                -- CRC-32
                        LITTLE_ENDIAN(V_TEMP_FILE_CONTENT_LENGTH),              -- compressed size
                        LITTLE_ENDIAN(V_FILE_LENGTH),                           -- uncompressed size
                        LITTLE_ENDIAN(UTL_RAW.LENGTH(V_FILE_NAME), 2),          -- File name length
                        HEXTORAW('0000'),                                       -- Extra field length
                        V_FILE_NAME                                             -- File name
                    )
                );

                IF V_COMPRESSED THEN
                    DBMS_LOB.COPY(SELF.FILE_CONTENT, V_TEMP_BLOB, V_TEMP_FILE_CONTENT_LENGTH, DBMS_LOB.GETLENGTH(SELF.FILE_CONTENT) + 1, 11); -- compressed content
                ELSIF V_TEMP_FILE_CONTENT_LENGTH > 0 THEN
                    DBMS_LOB.COPY(SELF.FILE_CONTENT, V_TEMP_BLOB, V_TEMP_FILE_CONTENT_LENGTH, DBMS_LOB.GETLENGTH(SELF.FILE_CONTENT) + 1, 1); --  content
                END IF;

                DISPOSE_TEMP_LOB;
            EXCEPTION
                WHEN OTHERS THEN 
                    DISPOSE_TEMP_LOB;
            END;
        END;
    END;

 --*--------------------------------------------------------------------------------------------------------------------
    MEMBER FUNCTION GET_FILE_NAMES(P_ENCODING VARCHAR2 := NULL) RETURN VARCHAR2
    IS
        V_INDEX INTEGER := NVL(DBMS_LOB.GETLENGTH(SELF.FILE_CONTENT), 0) - 21;
    BEGIN
        --! CHECK ZIP FILE IS EXIST
        IF DBMS_LOB.GETLENGTH(SELF.FILE_CONTENT) = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Zip File is Not Exist');
        END IF;

        LOOP
            EXIT WHEN V_INDEX < 1 OR DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, 4, V_INDEX) = HEXTORAW('504B0506');
            V_INDEX := V_INDEX - 1;
        END LOOP;

        IF V_INDEX <= 0 THEN
            RETURN NULL;
        END IF;

        DECLARE
            V_HD_INDEX BINARY_INTEGER;
            V_FILE_LIST VARCHAR2(32767);

            FUNCTION BLOB_TO_BINARY_INTEGER(P_BLOB BLOB, P_LENGTH INTEGER, P_POSITION INTEGER) RETURN BINARY_INTEGER
            IS
                RV BINARY_INTEGER := UTL_RAW.CAST_TO_BINARY_INTEGER(DBMS_LOB.SUBSTR(P_BLOB, P_LENGTH, P_POSITION), UTL_RAW.LITTLE_ENDIAN);
            BEGIN
                IF RV < 0 THEN
                    RETURN RV + 4294967296;
                ELSE
                    RETURN RV;
                END IF;
            END;
        BEGIN
            V_HD_INDEX := BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 4, V_INDEX + 16) + 1;
            FOR I IN 1 .. BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_INDEX + 8) LOOP
                DECLARE
                    V_ENCODING VARCHAR2(32767) := CASE 
                                                  WHEN P_ENCODING IS NOT NULL THEN P_ENCODING
                                                  WHEN UTL_RAW.BIT_AND(DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, 1, V_HD_INDEX + 9), HEXTORAW('08')) = HEXTORAW('08') THEN 'AL32UTF8' -- utf8
                                                  ELSE 'US8PC437' -- IBM codepage 437
                                                  END;
                    FUNCTION RAW_TO_VARCHAR2(P_RAW RAW, P_ENCODING VARCHAR2) RETURN VARCHAR2
                    IS
                    BEGIN
                        RETURN COALESCE(
                                UTL_I18N.RAW_TO_CHAR(P_RAW, P_ENCODING), 
                                UTL_I18N.RAW_TO_CHAR(P_RAW, UTL_I18N.MAP_CHARSET(P_ENCODING, UTL_I18N.GENERIC_CONTEXT, UTL_I18N.IANA_TO_ORACLE))
                        );
                    END;
                BEGIN
                    IF I = 1 THEN
                        V_FILE_LIST := RAW_TO_VARCHAR2(DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 28), V_HD_INDEX + 46), V_ENCODING);
                    ELSE
                        V_FILE_LIST := V_FILE_LIST|| CHR(10)|| CHR(13) || RAW_TO_VARCHAR2(DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 28), V_HD_INDEX + 46), V_ENCODING);
                    END IF;
                END;
                V_HD_INDEX := V_HD_INDEX + 46
                            + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 28)  -- File name length
                            + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 30)  -- Extra field length
                            + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 32); -- File comment length
            END LOOP;
            RETURN V_FILE_LIST;
        END;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);

    END;

 --*--------------------------------------------------------------------------------------------------------------------
    MEMBER PROCEDURE GET_FILE(P_FILE_NAME VARCHAR2,P_FILE_FULL_NAME VARCHAR2, P_ENCODING VARCHAR2 := NULL)
    IS
        V_INDEX INTEGER := NVL(DBMS_LOB.GETLENGTH(SELF.FILE_CONTENT), 0) - 21;
        FUNCTION BLOB_TO_BINARY_INTEGER(P_BLOB BLOB, P_LENGTH INTEGER, P_POSITION INTEGER) RETURN BINARY_INTEGER
        IS
            RV BINARY_INTEGER := UTL_RAW.CAST_TO_BINARY_INTEGER(DBMS_LOB.SUBSTR(P_BLOB, P_LENGTH, P_POSITION), UTL_RAW.LITTLE_ENDIAN);
        BEGIN
            IF RV < 0 THEN
                RETURN RV + 4294967296;
            ELSE
                RETURN RV;
            END IF;
        END;
    BEGIN
        --! CHECK dIRECTORY IS EXIST
        IF UTL_PATH.CHECK_DIRECTORY_EXIST(UTL_PATH.GET_DIRECTORY_NAME(P_FILE_FULL_NAME)) <> 1 THEN
            RAISE_APPLICATION_ERROR(-20001, 'The directory/folder of [p_file_full_name] is not exist please check directory/folder is exist.' || CHR(10)
                                         || 'Value: ' || P_FILE_FULL_NAME);
        END IF;

        --! CHECK ZIP FILE IS EXIST
        IF DBMS_LOB.GETLENGTH(SELF.FILE_CONTENT) = 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'Zip File is Not Exist');
        END IF;

        --! CHECK TARGET FILE(P_FILE_NAME) IN ZIP FILE IS DIRECTORY/FOLDER
        IF SUBSTR(P_FILE_NAME, -1) IN ('/', '\') THEN  
            RAISE_APPLICATION_ERROR(-20002, 'The parameter [p_file_name] is directory/folder' || CHR(10)
                                         || 'Value:' || P_FILE_NAME);
        END IF;

        LOOP
            EXIT WHEN V_INDEX < 1 OR DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, 4, V_INDEX) = HEXTORAW('504B0506');
            V_INDEX := V_INDEX - 1;
        END LOOP;
    
        IF V_INDEX <= 0 THEN
            RETURN;
        END IF;

        DECLARE
            V_HD_INDEX BINARY_INTEGER := BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 4, V_INDEX + 16) + 1;
            V_TARGET_FILE_BLOB BLOB;

            FUNCTION RAW_TO_VARCHAR2(P_RAW RAW, P_ENCODING VARCHAR2) RETURN VARCHAR2
            IS
            BEGIN
                RETURN COALESCE(
                        UTL_I18N.RAW_TO_CHAR(P_RAW, P_ENCODING), 
                        UTL_I18N.RAW_TO_CHAR(P_RAW, UTL_I18N.MAP_CHARSET(P_ENCODING, UTL_I18N.GENERIC_CONTEXT, UTL_I18N.IANA_TO_ORACLE))
                );
            END;
        BEGIN
            FOR I IN 1 .. BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_INDEX + 8) LOOP
                DECLARE
                    V_ENCODING VARCHAR2(32767) := CASE 
                                                  WHEN P_ENCODING IS NOT NULL THEN P_ENCODING
                                                  WHEN UTL_RAW.BIT_AND(DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, 1, V_HD_INDEX + 9), HEXTORAW('08')) = HEXTORAW('08') THEN 'AL32UTF8' -- utf8
                                                  ELSE 'US8PC437' -- IBM codepage 437
                                                  END;
                BEGIN
                    IF P_FILE_NAME = RAW_TO_VARCHAR2(DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 28), V_HD_INDEX + 46), V_ENCODING) THEN
                        DECLARE
                            V_LENGTH BINARY_INTEGER := BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 4, V_HD_INDEX + 24); -- UNCOMPRESSED LENGTH
                        BEGIN
                            IF V_LENGTH = 0 THEN -- CHECK TARGET FILE IS EMPTY
                                RAISE_APPLICATION_ERROR(-20001, 'The target file[p_file_name] content is empty ' || CHR(10)
                                                             || 'Value:' || P_FILE_NAME);
                            END IF;

                            DECLARE
                                V_FL_INDEX BINARY_INTEGER;
                                V_TEMP BLOB;

                                FUNCTION LITTLE_ENDIAN(P_BIG BINARY_INTEGER, P_BYTES PLS_INTEGER := 4) RETURN RAW
                                IS
                                    V_BIG BINARY_INTEGER := CASE WHEN P_BIG > 2147483647 
                                                            THEN P_BIG - 4294967296 
                                                            ELSE P_BIG 
                                                            END;
                                BEGIN
                                    RETURN UTL_RAW.SUBSTR(UTL_RAW.CAST_FROM_BINARY_INTEGER(V_BIG, UTL_RAW.LITTLE_ENDIAN), 1, P_BYTES);
                                END;
                            BEGIN
                                IF DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, 2, V_HD_INDEX + 10) IN (HEXTORAW('0800'), HEXTORAW('0900')) THEN
                                    V_FL_INDEX := BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 4, V_HD_INDEX + 42);
                                    V_TEMP := HEXTORAW('1F8b0800000000000003'); -- gzip header
                                    DBMS_LOB.COPY(
                                        V_TEMP, 
                                        SELF.FILE_CONTENT,  
                                        BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 4, V_HD_INDEX + 20), 
                                        11, 
                                        V_FL_INDEX + 31
                                            + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_FL_INDEX + 27) -- File name length
                                            + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_FL_INDEX + 29) -- Extra field length
                                    );
                                                                       -- CRC32                                                   uncompressed length
                                    DBMS_LOB.APPEND(V_TEMP,UTL_RAW.CONCAT(DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, 4, V_HD_INDEX + 16), LITTLE_ENDIAN(V_LENGTH)));
                                    V_TARGET_FILE_BLOB := UTL_COMPRESS.LZ_UNCOMPRESS(V_TEMP);
                                    EXIT;
                                END IF;
                        
                                IF DBMS_LOB.SUBSTR(SELF.FILE_CONTENT, 2, V_HD_INDEX + 10) = HEXTORAW('0000') THEN -- The file is stored (no compression)
                                    V_FL_INDEX := BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 4, V_HD_INDEX + 42);
                                    DBMS_LOB.CREATETEMPORARY(V_TEMP, TRUE);
                                    DBMS_LOB.COPY(
                                        V_TEMP, 
                                        SELF.FILE_CONTENT, 
                                        V_LENGTH, 
                                        1, 
                                        V_FL_INDEX + 31
                                            + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_FL_INDEX + 27) -- File name length
                                            + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_FL_INDEX + 29) -- Extra field length
                                    );
                                    V_TARGET_FILE_BLOB := V_TEMP;
                                    EXIT;
                                END IF;
                            EXCEPTION 
                                WHEN OTHERS THEN 
                                    DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);

                            END;
                        END;
                    END IF;

                    V_HD_INDEX := V_HD_INDEX + 46
                                + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 28)  -- File name length
                                + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 30)  -- Extra field length
                                + BLOB_TO_BINARY_INTEGER(SELF.FILE_CONTENT, 2, V_HD_INDEX + 32); -- File comment length
                END;
            END LOOP;

            IF V_TARGET_FILE_BLOB IS NULL THEN
                RAISE_APPLICATION_ERROR(-20001, 'The parameter p_file_name is not exist' || CHR(10)
                                             || 'Value:' || P_FILE_NAME);
            END IF;

            DECLARE
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
                EXECUTE IMMEDIATE('CREATE OR REPLACE DIRECTORY TARGET_PATH AS ''' || UTL_PATH.GET_DIRECTORY_NAME(P_FILE_FULL_NAME) || '\''');
                DECLARE 
                    V_FH UTL_FILE.FILE_TYPE := UTL_FILE.FOPEN('TARGET_PATH', UTL_PATH.GET_FILE_NAME(P_FILE_FULL_NAME), 'WB');
                BEGIN
                    FOR I IN 0 .. TRUNC((DBMS_LOB.GETLENGTH(V_TARGET_FILE_BLOB) - 1) / 32767) LOOP
                        UTL_FILE.PUT_RAW(V_FH, DBMS_LOB.SUBSTR(V_TARGET_FILE_BLOB,32767, I * 32767 +1));
                    END LOOP;
                    UTL_FILE.FCLOSE(V_FH);
                    DISPOSE_DIRECTORY;
                EXCEPTION
                    WHEN OTHERS THEN
                        DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
                        DISPOSE_DIRECTORY;
                END;
            END;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
        END;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
    END;

 --*--------------------------------------------------------------------------------------------------------------------
    MEMBER PROCEDURE SAVE
    IS
        V_OFFS_DIR_HEADER INTEGER := DBMS_LOB.GETLENGTH(SELF.FILE_CONTENT);
        V_ZIPPED_BLOB BLOB := SELF.FILE_CONTENT;
        V_CNT PLS_INTEGER := 0;
        FUNCTION LITTLE_ENDIAN(P_BIG BINARY_INTEGER, P_BYTES PLS_INTEGER := 4) RETURN RAW
        IS
            V_BIG BINARY_INTEGER := CASE WHEN P_BIG > 2147483647 
                                    THEN P_BIG - 4294967296 
                                    ELSE P_BIG 
                                    END;
        BEGIN
            RETURN UTL_RAW.SUBSTR(UTL_RAW.CAST_FROM_BINARY_INTEGER(V_BIG, UTL_RAW.LITTLE_ENDIAN), 1, P_BYTES);
        END;
    BEGIN

        DECLARE
            V_OFFS INTEGER := 1;
            FUNCTION BLOB_TO_BINARY_INTEGER(P_BLOB BLOB, P_LENGTH INTEGER, P_POSITION INTEGER) RETURN BINARY_INTEGER
            IS
                RV BINARY_INTEGER := UTL_RAW.CAST_TO_BINARY_INTEGER(DBMS_LOB.SUBSTR(P_BLOB, P_LENGTH, P_POSITION), UTL_RAW.LITTLE_ENDIAN);
            BEGIN
                IF RV < 0 THEN
                    RETURN RV + 4294967296;
                ELSE
                    RETURN RV;
                END IF;
            END;
        BEGIN
            WHILE DBMS_LOB.SUBSTR(V_ZIPPED_BLOB, UTL_RAW.LENGTH(HEXTORAW('504B0304')), V_OFFS) = HEXTORAW('504B0304') LOOP
                V_CNT := V_CNT + 1;
                DECLARE
                    V_DIRECTORY_OR_FILE RAW(4) := CASE -- /                \
                                                  WHEN DBMS_LOB.SUBSTR( V_ZIPPED_BLOB, 1, V_OFFS + 30 + BLOB_TO_BINARY_INTEGER(V_ZIPPED_BLOB, 2, V_OFFS + 26) - 1) IN ( HEXTORAW('2F'), HEXTORAW('5C')) THEN HEXTORAW('10000000') -- a directory/folder
                                                  ELSE HEXTORAW('2000B681')
                                                  END;
                    V_FILE_NAME RAW(32767) := DBMS_LOB.SUBSTR(V_ZIPPED_BLOB, BLOB_TO_BINARY_INTEGER(V_ZIPPED_BLOB, 2, V_OFFS + 26), V_OFFS + 30);
                BEGIN
                    DBMS_LOB.APPEND(
                        V_ZIPPED_BLOB, 
                        UTL_RAW.CONCAT(
                            HEXTORAW('504B0102'),                               -- Central directory file header signature
                            HEXTORAW('1400'),                                   -- version 2.0
                            DBMS_LOB.SUBSTR(V_ZIPPED_BLOB, 26, V_OFFS + 4),     -- clone header 5th count 26 byte 
                            HEXTORAW('0000'),                                   -- File comment length
                            HEXTORAW('0000'),                                   -- Disk number where file starts
                            HEXTORAW('0000'),                                   -- Internal file attributes => 1. [0000] binary file 2. [0100] (ascii)text file
                            V_DIRECTORY_OR_FILE,                                -- External file attributes
                            LITTLE_ENDIAN(V_OFFS - 1),                          -- Relative offset of local file header
                            V_FILE_NAME                                         -- File name
                        )
                    );
                END;
                V_OFFS := V_OFFS + 30 + BLOB_TO_BINARY_INTEGER(V_ZIPPED_BLOB, 4, V_OFFS + 18)  -- compressed size
                                        + BLOB_TO_BINARY_INTEGER(V_ZIPPED_BLOB, 2, V_OFFS + 26)  -- File name length
                                        + BLOB_TO_BINARY_INTEGER(V_ZIPPED_BLOB, 2, V_OFFS + 28); -- Extra field length
            END LOOP;
        END;

        DECLARE
            V_COMMENT RAW(32767) := UTL_RAW.CAST_TO_RAW('Implementation by Littletrainee');
        BEGIN
            DBMS_LOB.APPEND(
                V_ZIPPED_BLOB,
                UTL_RAW.CONCAT(
                    HEXTORAW('504B0506'),                                                           -- End of central directory signature
                    HEXTORAW('0000'),                                                               -- Number of this disk
                    HEXTORAW('0000'),                                                               -- Disk where central directory starts
                    LITTLE_ENDIAN(V_CNT, 2),                                                        -- Number of central directory records on this disk
                    LITTLE_ENDIAN(V_CNT, 2),                                                        -- Total number of central directory records
                    LITTLE_ENDIAN(DBMS_LOB.GETLENGTH(V_ZIPPED_BLOB) - V_OFFS_DIR_HEADER),           -- Size of central directory
                    LITTLE_ENDIAN(V_OFFS_DIR_HEADER),                                               -- Offset of start of central directory, relative to start of archive
                    LITTLE_ENDIAN(NVL(UTL_RAW.LENGTH(V_COMMENT), 0), 2),                            -- ZIP file comment length
                    V_COMMENT
                )
            );
        END; 

        DECLARE
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
            EXECUTE IMMEDIATE('CREATE OR REPLACE DIRECTORY TARGET_PATH AS '''|| SELF.FILE_DIRECTORY_NAME ||'\''');
            DECLARE
                V_FH UTL_FILE.FILE_TYPE := UTL_FILE.FOPEN('TARGET_PATH', SELF.FILE_NAME, 'WB');
            BEGIN
                FOR I IN 0 .. TRUNC((DBMS_LOB.GETLENGTH(V_ZIPPED_BLOB) - 1) / 32767) LOOP
                    UTL_FILE.PUT_RAW(V_FH, DBMS_LOB.SUBSTR(V_ZIPPED_BLOB, 32767, I * 32767 + 1));
                END LOOP;
                UTL_FILE.FCLOSE(V_FH);
                DISPOSE_DIRECTORY;
            EXCEPTION
                WHEN OTHERS THEN 
                    DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
                    DISPOSE_DIRECTORY;
            END;    
        END;
    EXCEPTION
        WHEN OTHERS THEN 
            DBMS_OUTPUT.PUT_LINE('Error Line:' || $$PLSQL_LINE || CHR(9) || 'Error Code:' || SQLCODE || CHR(9) || 'Error Message:' || SQLERRM);
    END;
END;
