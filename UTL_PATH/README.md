# UTL_PATH Package Usage Examples

The following examples demonstrate how to use the functions provided by the `UTL_PATH` package to work with file paths and directories.

## Example 1: Extract File Name with Extension

### Function: `GET_FILE_NAME`

**Purpose:** Extracts the file name (including extension) from a full file path.

```SQL
DECLARE
    V_FILE_NAME VARCHAR2(255) := UTL_PATH.GET_FILE_NAME('/home/user/documents/file.txt');
BEGIN
    DBMS_OUTPUT.PUT_LINE('File Name: ' || V_FILE_NAME);
END;
/
```

**Output:**

```
File Name: file.txt
```

---

## Example 2: Extract Directory Name

### Function: `GET_DIRECTORY_NAME`

**Purpose:** Extracts the directory name (excluding the file name) from a full file path.

```SQL
DECLARE
    V_DIRECTORY_NAME VARCHAR2(255) := UTL_PATH.GET_DIRECTORY_NAME('/home/user/documents/file.txt');
BEGIN
    DBMS_OUTPUT.PUT_LINE('Directory Name: ' || V_DIRECTORY_NAME);
END;
/
```

**Output:**

```
Directory Name: /home/user/documents
```

---

## Example 3: Extract File Name Without Extension

### Function: `GET_FILE_NAME_NO_EXTENSION`

**Purpose:** Extracts the file name without the extension from a full file path.

```SQL
DECLARE
    V_FILE_EXTENSION VARCHAR2(255) := UTL_PATH.GET_FILE_NAME_NO_EXTENSION('/home/user/documents/file.txt');
BEGIN
    DBMS_OUTPUT.PUT_LINE('File Name Without Extension: ' || V_FILE_EXTENSION);
END;
/
```

**Output:**

```
File Name Without Extension: file
```

---

## Example 4: Check If a File Exists

### Function: `CHECK_FILE_EXISTS`

**Purpose:** Checks whether the specified file exists.

```SQL
DECLARE
    V_FILE_IS_EXISTS INTEGER := UTL_PATH.CHECK_FILE_EXISTS('/home/user/documents/file.txt');
BEGIN
    IF V_FILE_IS_EXISTS = 1 THEN
        DBMS_OUTPUT.PUT_LINE('The file exists.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('The file does not exist.');
    END IF;
END;
/
```

**Output:**

```
The file exists.
```

(Assuming the file exists at the specified location.)

---

## Example 5: Check If a Directory Exists

### Function: `CHECK_DIRECTORY_EXIST`

**Purpose:** Checks whether the specified directory exists.

```sql
DECLARE
    V_DIRECTORY_IS_EXISTS INTEGER := UTL_PATH.CHECK_DIRECTORY_EXIST('/home/user/documents');
BEGIN
    IF V_DIRECTORY_IS_EXISTS = 1 THEN
        DBMS_OUTPUT.PUT_LINE('The directory exists.');
    ELSE
        DBMS_OUTPUT.PUT_LINE('The directory does not exist.');
    END IF;
END;
/
```

**Output:**

```
The directory exists.
```

(Assuming the directory exists at the specified location.)

---

### Notes:

1. Ensure you have the necessary permissions to access the specified file paths or directories.
2. If working on a Windows environment, adjust the file paths accordingly, e.g., `C:\Users\Documents\file.txt`.

These examples illustrate basic use cases. Adapt them as needed for your specific requirements.
