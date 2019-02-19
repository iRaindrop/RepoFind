# RepoJack

Scripts for searching and managing repository content and metadata.

## RepoFind.ps1

This script creates CSV files containing the search results or metadata for one or more repository folders. The script acts recursively on subfolders on all Markdown .md files. 

### Set up

- Save RepoFind.ps1 and RFconfig.xml to a folder.

In RFConfig.xml, do the following:

1. If the directory that contains your local repository folders is not under your home user account in C:\users, then you must specify its path for the `installDir` value. Leave this value empty if you have the repositories under your Windows user account, which is the default installation.
1. Specify one or more folders to search, by adding folder elements to the `<srchFolders>` node. Two example values currently exist. The key names must be "fld1", "fld2", "fld3", and so on.

In PowerShell, you might have to set your execution policy:
```
PS C:\RFind> Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```
### Run script

The script creates two types of reports: **RepoFindMetadata.csv** or **RepoFindResults.csv** 

To report on metadata only, run the script without a parameter, for example:
```
PS C:\RFind> .\RepoFind.ps1
```
To search for text, include the search string as the only parameter.
```
PS C:\RFind> .\RepoFind.ps1 "not supported by"
```

The files are written to the folder that contains the script. You are alerted to the number of occurrences or if no results were found.


