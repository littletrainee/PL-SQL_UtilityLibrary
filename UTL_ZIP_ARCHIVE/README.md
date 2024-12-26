# UTL_ZIP_ARCHIVE Object Type Usage Examples

The following examples demonstrate how to use the `UTL_ZIP_ARCHIVE` object type to manage zip archives, including adding files, retrieving file names, extracting files, and saving the archive.

---

## Example 1: Initialize a UTL_ZIP_ARCHIVE Object

### Constructor: `UTL_ZIP_ARCHIVE`

**Purpose:** Initializes a `UTL_ZIP_ARCHIVE` object with the specified file full name.

```SQL
DECLARE
    V_ZIP_ARCHIVE UTL_ZIP_ARCHIVE := UTL_ZIP_ARCHIVE('C:\archives\example.zip');
BEGIN
    DBMS_OUTPUT.PUT_LINE('Archive initialized: ' || V_ZIP_ARCHIVE.FILE_FULL_NAME);
END;
/
```

**Output:**

```
Archive initialized: C:\archives\example.zip
```

---

## Example 2: Add a File to the Zip Archive

### Procedure: `ADD_FILE`

**Purpose:** Adds a file to the zip archive.

```SQL
DECLARE
    V_ZIP_ARCHIVE UTL_ZIP_ARCHIVE := UTL_ZIP_ARCHIVE('C:\archives\example.zip');
BEGIN
    V_ZIP_ARCHIVE.ADD_FILE('C:\files\document.txt', 'archive_document.txt');
    DBMS_OUTPUT.PUT_LINE('File added to the archive.');
END;
/
```

**Output:**

```
File added to the archive.
```

---

## Example 3: Retrieve File Names in the Archive

### Function: `GET_FILE_NAMES`

**Purpose:** Retrieves the names of all files in the zip archive.

```SQL
DECLARE
    V_ZIP_ARCHIVE UTL_ZIP_ARCHIVE := UTL_ZIP_ARCHIVE('C:\archives\example.zip');
BEGIN
    DBMS_OUTPUT.PUT_LINE('Files in archive: ' || V_ZIP_ARCHIVE.GET_FILE_NAMES);
END;
/
```

**Output:**

```
Files in archive: archive_document.txt
```

---

## Example 4: Extract a File from the Archive

### Procedure: `GET_FILE`

**Purpose:** Extracts a specified file from the zip archive and saves it to a specified path.

```SQL
DECLARE
    V_ZIP_ARCHIVE UTL_ZIP_ARCHIVE := UTL_ZIP_ARCHIVE('C:\archives\example.zip');
BEGIN
    V_ZIP_ARCHIVE.GET_FILE('archive_document.txt', 'C:\extracted\document.txt');
    DBMS_OUTPUT.PUT_LINE('File extracted successfully.');
END;
/
```

**Output:**

```
File extracted successfully.
```

---

## Example 5: Save the Current State of the Archive

### Procedure: `SAVE`

**Purpose:** Saves the current state of the zip archive.

```SQL
DECLARE
    V_ZIP_ARCHIVE UTL_ZIP_ARCHIVE := UTL_ZIP_ARCHIVE('C:\archives\example.zip');
BEGIN
    V_ZIP_ARCHIVE.SAVE;
    DBMS_OUTPUT.PUT_LINE('Archive saved successfully.');
END;
/
```

**Output:**

```
Archive saved successfully.
```

---

### Notes:

1. Ensure you have the necessary permissions to access the specified file paths and directories.
2. Adjust file paths for your operating system (e.g., use `/home/user/` for Linux).
3. Handle exceptions appropriately in a production environment to capture errors such as file not found or permission denied.
