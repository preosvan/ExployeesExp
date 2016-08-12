unit MyDocUnit;

interface

  function AppDocPath: string;
  function CheckFileUsed(APathToFile: string): Boolean;
  function MyDocPath: string;
  function OpenFolderAndSelectFile(const AFileName: string): Boolean;

const
  OFASI_EDIT = $0001;
  OFASI_OPENDESKTOP = $0002;

implementation

uses
  System.Classes, System.SysUtils, Winapi.ShlObj, System.Types, Winapi.ShellAPI,
  Winapi.Windows;

const
  PATH_FIRST = 'Conquest\';

function OpenFolderAndSelectFile(const AFileName: string): Boolean;
var
  IIDL: PItemIDList;
begin
  Result := False;
  IIDL := ILCreateFromPath(PWideChar(AFileName));
  if IIDL <> nil then
  try
    Result := SHOpenFolderAndSelectItems(IIDL, 0, nil, 0) = S_OK;
    if not Result then
      ShellExecute(0, nil, 'explorer.exe', PWideChar('/select, ' + AFileName), nil, SW_SHOWNORMAL)
  finally
    ILFree(IIDL);
  end;
end;

function CheckFileUsed(APathToFile: string): Boolean;
var
  F: TFileStream;
begin
  try
    F := TFileStream.Create(APathToFile, fmOpenReadWrite or fmShareExclusive);
    try
      Result := False;
    finally
      FreeAndNil(F);
    end;
  except
    Result := True;
  end;
end;

function MyDocPath: string;
var
  Path: string;
begin
  Result := '';
  SetLength(Path, MAX_PATH);
  if SHGetSpecialFolderPath(0, PChar(Path), CSIDL_PERSONAL, true) then
    Result := PChar(Path) + '\';
end;

function AppDocPath: string;
var
  Path: string;
begin
  Path := MyDocPath + PATH_FIRST;
  ForceDirectories(Path);
  Result := Path;
end;

end.
