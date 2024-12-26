CREATE OR REPLACE TYPE UTL_ZIP_ARCHIVE AS OBJECT(
 --*--------------------------------------------------------------------------------------------------------------------
 -- Type Name: UTL_ZIP_ARCHIVE
 -- Author: Littletrainee
 -- Version: 1.0
 -- Description: Definition of the UTL_ZIP_ARCHIVE object type.
 -- This type represents a zip archive and provides methods for adding files, retrieving file names, extracting files, and saving the archive.
 --*---------------------------------------------- Attributes ----------------------------------------------------------
    FILE_FULL_NAME      VARCHAR2(4000),         -- Full path of the file associated with the archive.
    FILE_NAME           VARCHAR2(1000),         -- Name of the file without the directory.
    FILE_DIRECTORY_NAME VARCHAR2(3000),         -- Directory path of the file.
    FILE_CONTENT BLOB,                          -- Binary content of the file.

 --*---------------------------------------------- CONSTRUCTOR ---------------------------------------------------------
    CONSTRUCTOR FUNCTION UTL_ZIP_ARCHIVE(SELF IN OUT NOCOPY UTL_ZIP_ARCHIVE, P_FILE_FULL_NAME VARCHAR2) RETURN SELF AS RESULT,
 -- Description:
 --     Initializes a UTL_ZIP_ARCHIVE object with the specified file full name.
 -- Parameters:
 --     P_FILE_FULL_NAME (VARCHAR2): The full path of the file.

 --*---------------------------------------------- SIGNATURE -----------------------------------------------------------
    MEMBER PROCEDURE ADD_FILE(P_FILE_FULL_NAME VARCHAR2, P_COMPRESSED_FILE_FULL_NAME VARCHAR2 := NULL),
 -- Description:
 --     Adds a file to the zip archive.
 -- Parameters:
 --     P_FILE_FULL_NAME (VARCHAR2): Full path of the file to be added.
 --     P_COMPRESSED_FILE_FULL_NAME (VARCHAR2, optional): Name of the compressed file within the archive.

 --*--------------------------------------------------------------------------------------------------------------------
    MEMBER FUNCTION GET_FILE_NAMES(P_ENCODING VARCHAR2 := NULL) RETURN VARCHAR2,
 -- Description:
 --     Retrieves the names of all files in the zip archive.
 -- Parameters:
 --     P_ENCODING (VARCHAR2, optional): Character encoding for the file names.
 -- Returns:
 --     VARCHAR2: A comma-separated list of file names in the archive.

 --*--------------------------------------------------------------------------------------------------------------------
    MEMBER PROCEDURE GET_FILE(P_FILE_NAME VARCHAR2, P_FILE_FULL_NAME VARCHAR2, P_ENCODING VARCHAR2 := NULL),
    -- Description:
    --     Extracts a specified file from the zip archive and saves it to the specified path.
    -- Parameters:
    --     P_FILE_NAME (VARCHAR2): Name of the file to be extracted from the archive.
    --     P_FILE_FULL_NAME (VARCHAR2): Full path where the extracted file will be saved.
    --     P_ENCODING (VARCHAR2, optional): Character encoding for the file content.

 --*--------------------------------------------------------------------------------------------------------------------
    MEMBER PROCEDURE SAVE
 -- Description:
 --     Saves the current state of the zip archive.
);
