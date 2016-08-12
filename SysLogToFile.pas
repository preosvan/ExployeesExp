{*******************************************************************************

                 Модуль SysLogToFile

  Разработчик:   Арбузов М.В.
  Назначение:    Набор классов для регистрации сообщений в лог-файл.

*******************************************************************************}
unit SysLogToFile;

interface

uses
  SysLogUtils, MyDocUnit;

type
  {: Обьект пишуший в файл }
  TFileWriter = class(TTxtLog)
  private
    {: Имя файла }
    FName: string;
    {: Путь к файлу }
    FPath: string;
    FIsCreatingLog: Boolean;
    function FileName: string;
  public
    constructor Create(AFileName: string);
    procedure BeginWrites; override;
    procedure Clear; override;
    procedure EndWrites; override;
    procedure WriteLine(AString: string); override;
    property IsCreatingLog: Boolean read FIsCreatingLog write FIsCreatingLog default True;
  end;

  {: Объект ведущий логи (правильно) по иерархической системе}
  TStructLogWriter = class(TLogWriter)
  private
    FRootPath: string;
    function GetFilePath(AHandlerAddr: ILogNode; AReport: IReport): string;
  public
    constructor Create;
    procedure BeginWrites; override;
    procedure Clear; override;
    procedure EndWrites; override;
    procedure Write(AReport: IReport; AHandlerAddr: ILogNode); override;
  end;

function CreateFileHandler(AFileName: string): IHandler; overload;
function CreateDirectoryHandler: IHandler; overload;
procedure InitLogFile(AFileName: string; AIsActiveLog: Boolean; var ALog: ILog;
  AIsDelLog: Boolean = False);

implementation
uses
{$IFDEF VER130}
  FileCtrl,
{$ENDIF}
  SysUtils;

{ Процедура инициализации лог-файла
  AFileName - имя лог-файла (без полного пути и расширения)
  AIsActiveLog - активность логирования
  ALog - ссылка на объект логирования }
procedure InitLogFile(AFileName: string; AIsActiveLog: Boolean; var ALog: ILog;
  AIsDelLog: Boolean);
begin

  if AIsDelLog then
    if FileExists(AppDocPath + 'logs\' + AFileName + '.log') then
      DeleteFile(AppDocPath + 'logs\' + AFileName + '.log');

  if not Assigned(ALog) then
  begin
    GetLog.Attach(CreateDirectoryHandler);
    ALog := GetLog[AFileName];
  end;
  ALog.Active := AIsActiveLog;
end;

function CreateFileHandler(AFileName: string): IHandler; overload;
begin
  Result := CreateHandler(TFileWriter.Create(AFileName));
end;

function CreateDirectoryHandler: IHandler; overload;
begin
  Result := CreateHandler(TStructLogWriter.Create);
end;

{
********************************* TFileWriter **********************************
}

constructor TFileWriter.Create(AFileName: string);
begin
  inherited Create;
  FName := AFileName;
  FIsCreatingLog := True;
  //ежели задан не полный путь добиваем его до кондиции
  if ExtractFileDrive(FName) = '' then
    FPath := AppDocPath + 'logs\'
  else
    FPath := '';
end;

procedure TFileWriter.BeginWrites;
begin
end;

procedure TFileWriter.Clear;
begin
end;

procedure TFileWriter.EndWrites;
begin
end;

function TFileWriter.FileName: string;
begin
  Result := FPath + FName;
end;

procedure TFileWriter.WriteLine(AString: string);
var
  F: TextFile;
  fn: string;
begin
  fn := FileName;
  //if FIsCreatingLog then
  try
    if not FileExists(fn) then
    begin
      ForceDirectories(ExtractFileDir(fn));
      AssignFile(F, fn);
      {I-}
      Rewrite(F);
      {I+}
      WriteLn(F, '~~~~~~~~~~~~~~~~~~~~~ Лог создан (' +
        DateTimeToStr(Now) + ')');
    end
    else
    begin
      AssignFile(F, fn);
      Append(F);
    end;
    WriteLn(F, AString);
    CloseFile(F);
  except
    ///
  end;
end;

{
****************************** TStructLogWriter ********************************
}

constructor TStructLogWriter.Create;
begin
  FRootPath := AppDocPath + 'logs';
end;

procedure TStructLogWriter.BeginWrites;
begin
  //
end;

procedure TStructLogWriter.Clear;
begin
  //
end;

procedure TStructLogWriter.EndWrites;
begin
  //
end;

procedure TStructLogWriter.Write(AReport: IReport; AHandlerAddr: ILogNode);
var
  f: TextFile;
  fn: string;
  msg: string;
begin
  try
    try
      msg := FormatDateTime('dd-mm-yyyy hh:mm:ss ', AReport.GetTime) + AReport.GetText;
    except
      on E: Exception do
        msg := 'Не удалось получить текст и/или время сообщения! ' + E.Message;
    end;
    try
      fn := GetFilePath(AHandlerAddr, AReport);
    except
      on E: Exception do
      begin
        msg := 'Не удалось получить адрес сообщения! ' + E.Message + ' : ' + msg;
        fn := AppDocPath + 'logs\failed.log'
      end;
    end;
    if not FileExists(fn) then
    begin
      ForceDirectories(ExtractFileDir(fn));
      AssignFile(f, fn);
      Rewrite(f);
      WriteLn(f, Concat('===================== Лог создан [', DateTimeToStr(Now), ']'));
    end
    else
    begin
      AssignFile(f, fn);
      Append(f);
    end;
    Writeln(f, msg);
    CloseFile(f);
  except
    ///
  end;
end;

function TStructLogWriter.GetFilePath(AHandlerAddr: ILogNode; AReport: IReport): string;
var
  Path: string;
begin
  Path := GetPathAsStr(AReport.GetSender, AHandlerAddr);
  if Path = '' then
    Path := '\Root';
  Result := FRootPath + Path + '.log';
end;

end.

