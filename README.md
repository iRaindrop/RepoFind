# RepoJack

Scripts for searching and managing repository content and metadata.

## RepoFind.ps1

This script creates a CSV file containing the search results on one or more repository folders. The script acts recursively on subfolders on all Markdown .md files. You can specify any search string and search one ore more folders in both the azure and sql repos. 

Only the **azure-docs-pr** and **sql-docs-pr** are currenty supported.

The script creates these spreadsheet columns:

|Column|Description|
|---|---|
|A|URL to the published topic.|
|B|Repo (either sql-docs-pr or azure-docs-pr).|
|C|The last directory in the path of the search folder.|
|D|The Markdown file name.|
|E|The line number in the file of the search hit.|
|F|The occurence with up to 40 characers before and after.|
|G|The section heading the search hit is under.|

If you see `#NAME?` errors in Excel, line in column F, try removing the first charactres of the string which are probabley a minus or equals character.

### Set up

- Save RepoFind.ps1 and RFconfig.xml to a folder.

In RFConfig.xml, do the following:

1. If the directory that contains your local repository folders is not under your home user account in C:\users, then you must specify its path for the `installDir` value. Leave this value empty if you do the repositories under your user account, which is the default installation.
1. Specify one or more folders to search, by adding folder elements to the `<srchFolders>` node. Two example values currently exist. The key names must be "fld1", "fld2", "fld3", and so on. The paths must start with either "sql-docs-pr" or "azure-docs-pr".

Disregard the `<filters>` node for now. You will soon be able to seach and filter on file metadata.

### Run script

Invoke the script with the search string as its only parameter.

- Open PowerShell, and run the following command. In this example, the script and xml files are in a folder named 'RFInd' specifying "not supported by" for the search string. Be sure to include the `.\` before the script file name.

```
PS C:\RFind> .\RepoFind.ps1 "not supported by"
```

The file **RepoSearchResults.csv** is written to the folder that contains the script. You are alerted to the number of occurrences or if no results were found.


