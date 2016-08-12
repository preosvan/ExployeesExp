unit ConfigUnit;

interface

uses
  IniFiles, System.SysUtils;

type
  TCustomConfig = class
  private
    FIniFile: TIniFile;
  public
    constructor Create(APathToConfig: string);
    destructor Destroy; override;
    procedure Apply; virtual; abstract;
    procedure Load; virtual; abstract;
    property IniFile: TIniFile read FIniFile;
  end;

implementation

uses
  MyDocUnit;

constructor TCustomConfig.Create(APathToConfig: string);
begin
  FIniFile := TIniFile.Create(APathToConfig);
  Load;
end;

destructor TCustomConfig.Destroy;
begin
  Apply;
  if Assigned(FIniFile) then
    FreeAndNil(FIniFile);
  inherited;
end;

end.
