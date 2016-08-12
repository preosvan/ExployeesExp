{*******************************************************************************

                 Модуль SysLogUtils

  Разработчик:   Арбузов М.В.
  Назначение:    Ряд классов для ведения логов.

*******************************************************************************}

unit SysLogUtils;

interface

uses
  Classes;

const
  ReportError = 87.0;
  ReportWarning = 62.0;
  ReportMessage = 37.0;
  FilterAll = 100.0;
  FilterError = 75.0;
  FilterWarning = 50.0;
  FilterMessage = 25.0;
  FilterNone = 00.0;
  MaxCountRecord = 20000;

type

  ILogNode = Interface;
  IHandler = interface;

  {: Сообщение }
  IReport = interface(IUnknown)
    ['{129F7648-9B35-488A-94D8-623D6E5A4833}']
    function GetLevel: Single;
    function GetSender: ILogNode; stdcall;
    function GetText: string;
    function GetTime: TDateTime; stdcall;
  end;

  {: Интерфейс для логирования }
  ILog = interface(IUnknown)
    ['{8B669415-FB6E-43C8-BB5B-C77C4FC1BB87}']
    procedure Attach(AHandler: IHandler); stdcall;
    procedure Error(AError: string); stdcall;
    function GetActive: Boolean; stdcall;
    function GetFilter: Single; stdcall;
    function GetName: string; stdcall;
    function GetPathToLogFile: string; stdcall;
    function GetSubLogs(AName: string): ILog; stdcall;
    procedure Msg(AMessage: string);
    procedure Report(ALevel: Single; AText: string); overload; stdcall;
    procedure SetActive(const Value: Boolean); stdcall;
    procedure SetFilter(const Value: Single); stdcall;
    procedure Warning(AWarning: string); stdcall;
    property Active: Boolean read GetActive write SetActive;
    property Filter: Single read GetFilter write SetFilter;
    property Name: string read GetName;
    property PathToLogFile: string read GetPathToLogFile;
    property SubLogs[AName: string]: ILog read GetSubLogs; default;
  end;

  {: Инетрфейс очереди работающей внутри обработчика }
  IQueue = interface(IUnknown)
    ['{45D733A9-7828-4E55-A5FA-13344407E3F0}']
    procedure Post(AReport: IReport); stdcall;
    procedure SetQueue(AQueue: IQueue); stdcall;
  end;

  {: Интерфейс точки стыковки лога и его записи, филтрации и
     очередей }
  IHandler = interface(IUnknown)
    ['{90A9B2A5-CCD7-4057-98B9-2A8F72722500}']
    procedure AddQueue(AQueue: IQueue); stdcall;
    procedure Detach; stdcall;
    function GetFilter: Single; stdcall;
    procedure Reported(AReport: IReport);
    procedure SetAddr(AAddr: ILogNode); stdcall;
    procedure SetFilter(const Value: Single); stdcall;
    property Filter: Single read GetFilter write SetFilter;
  end;

  {: Расширение интерфейса ILog для служебных функций обслуживающих дерево
     логов. }
  ILogNode = interface(ILog)
    ['{C7D8AD62-BD22-405B-810D-0059EA102643}']
    procedure Breake;
    function ChildrenCount: Integer; stdcall;
    function GetChildren(AIndex: Integer): ILogNode; stdcall;
    function GetHeight: Integer; stdcall;
    function GetParent: ILogNode; stdcall;
    function IsRoot: Boolean; stdcall;
    procedure RemoveHandler(AHandler: IHandler); stdcall;
    procedure Report(AReport: IReport); overload; stdcall;
    property Children[AIndex: Integer]: ILogNode read GetChildren; default;
  end;

  {: Абстарктный класс - интерфейс записи события в лог }
  TLogWriter = class(TObject)
  public
    procedure BeginWrites; virtual; abstract;
    procedure Clear; virtual; abstract;
    procedure EndWrites; virtual; abstract;
    procedure Write(AReport: IReport; AHandlerAddr: ILogNode); virtual;
        abstract;
  end;

  {: Базовый класс для текстового логироваия. Наследники должны переопределить
     метод Write для записи строки лога. }
  TTxtLog = class(TLogWriter)
  public
    procedure Write(AReport: IReport; AHandlerAddr: ILogNode); override;
    procedure WriteLine(AString: string); virtual; abstract;
  end;

  {: Буффер для хранения лога }
  TLogBuffer = class(TLogWriter)
  private
    FFilter: Single;
    procedure SetFilter(const AValue: Single);
  public
    constructor Create(AWriter: TLogWriter);
    procedure BeginWrites; override;
    procedure Clear; override;
    procedure EndWrites; override;
    procedure Write(AReport: IReport; AHandlerAddr: ILogNode); override;
    property Filter: Single read FFilter write SetFilter;
  end;

  GetLogFunction = function: ILog;
{: Получить корневой лог }
function GetLog: ILog;
function CreateHandler(AWriter: TLogWriter; AQueue: IQueue = nil): IHandler;
procedure LogStrings(AStrings: TStrings; ALog: ILog = nil; ALevel: Single = ReportMessage);
procedure GetPath(ASenderAddr, AHandlerAddr: ILogNode; AStrings: TStrings);
function GetPathAsStr(ASenderAddr, AHandlerAddr: ILogNode): string;

implementation

uses
  SysUtils,
  SyncObjs,
  MyDocUnit;

var
  RootLog: ILogNode;


type
  TLogList = class(TObject)
  private
    FList: TList;
    constructor Create;
    destructor Destroy; override;
    function Add(AParent: ILogNode; AName: string): Integer;
    function Count: Integer;
    function GetItems(AIndex: Integer): ILogNode;
    property Items[AIndex: Integer]: ILogNode read GetItems; default;
  end;

  TLog = class(TInterfacedObject, ILog, ILogNode)
  private
    FActive: Boolean;
    FChildList: TLogList;
    FCriticalSection: TCriticalSection;
    FFilter: Single;
    FHandlerList: TInterfaceList;
    FName: string;
    FParent: ILogNode;
    constructor Create(AParent: ILogNode; AName: string);
    destructor Destroy; override;
    procedure Attach(AHandler: IHandler); stdcall;
    procedure Breake;
    function ChildrenCount: Integer; stdcall;
    procedure Error(AError: string); stdcall;
    function GetActive: Boolean; stdcall;
    function GetChildren(AIndex: Integer): ILogNode; stdcall;
    function GetFilter: Single; stdcall;
    function GetHandlers(AIndex: Integer): IHandler;
    function GetHeight: Integer; stdcall;
    function GetName: string; stdcall;
    function GetPathToLogFile: string; stdcall;
    function GetParent: ILogNode; stdcall;
    function GetSubLogs(AName: string): ILog; stdcall;
    function IsRoot: Boolean; stdcall;
    procedure SetActive(const Value: Boolean); stdcall;
    procedure Msg(AMessage: string);
    procedure RemoveHandler(AHandler: IHandler); stdcall;
    procedure Report(ALevel: Single; AText: string); overload; stdcall;
    procedure Report(AReport: IReport); overload; stdcall;
    procedure SetFilter(const Value: Single); stdcall;
    procedure Warning(AWarning: string); stdcall;
    property Active: Boolean read GetActive write SetActive;    
  end;

  {: Реализует фильтрацию и регистрацию }
  THandler = class(TInterfacedObject, IHandler, IQueue)
  private
    FAddr: ILogNode;
    FFilter: Single;
    FQueue: IQueue;
    FWriter: TLogWriter;
    constructor Create(AWriter: TLogWriter);
    destructor Destroy; override;
    procedure AddQueue(AQueue: IQueue); stdcall;
    procedure Detach; stdcall;
    function GetFilter: Single; stdcall;
    procedure Post(AReport: IReport); stdcall;
    procedure Reported(AReport: IReport);
    procedure SetAddr(AAddr: ILogNode); stdcall;
    procedure SetFilter(const Value: Single); stdcall;
    procedure SetQueue(AQueue: IQueue); stdcall;
  end;

  TReport = class(TInterfacedObject, IReport)
  private
    FLevel: Single;
    FSender: ILogNode;
    FText: string;
    FTime: TDateTime;
    constructor Create(ALevel: Single; AText: string; ASender: ILogNode);
    destructor Destroy; override;
    function GetLevel: Single;
    function GetSender: ILogNode; stdcall;
    function GetText: string;
    function GetTime: TDateTime; stdcall;
  end;

function GetLog: ILog;
begin
  if not Assigned(RootLog) then
    RootLog := TLog.Create(nil, '');
  Result := RootLog;
end;

function CreateHandler(AWriter: TLogWriter; AQueue: IQueue): IHandler;
begin
  Result := THandler.Create(AWriter);
  Result.AddQueue(AQueue);
end;

function GetPathAsStr(ASenderAddr, AHandlerAddr: ILogNode): string;
var
  Strings: TStrings;
  I: Integer;
begin
  Strings := TStringList.Create;
  try
    Getpath(ASenderAddr, AHandlerAddr, Strings);
    Result := '';
    for I := 0 to Strings.Count - 1 do
      Result := Result + '\' + Strings[i];
  finally
    Strings.Free;
  end;
end;

procedure LogStrings(AStrings: TStrings; ALog: ILog = nil; ALevel: Single = ReportMessage);
var
  I: Integer;
begin
  if not Assigned(ALog) then
    ALog := GetLog;
  try
    for I := 0 to AStrings.Count - 1 do
      ALog.Msg(AStrings[i]);
  except
    on E: Exception do
      ALog.Warning('Ошибка записи в лог TStrings: ' + E.Message);
  end;
end;
{
********************************** TLogBuffer **********************************
}
constructor TLogBuffer.Create(AWriter: TLogWriter);
begin
end;

procedure TLogBuffer.BeginWrites;
begin
end;

procedure TLogBuffer.Clear;
begin
end;

procedure TLogBuffer.EndWrites;
begin
end;

procedure TLogBuffer.SetFilter(const AValue: Single);
begin
  FFilter := AValue;
  FFilter := AValue;
end;

procedure TLogBuffer.Write(AReport: IReport; AHandlerAddr: ILogNode);
begin
end;

{
*********************************** TLogList ***********************************
}
constructor TLogList.Create;
begin
  FList := TList.Create;
end;

destructor TLogList.Destroy;
var
  I: Integer;
begin
  for I := 0 to FList.Count - 1 do
    ILog(FList.List[I]) := nil;
  FList.Free;
end;

function TLogList.Add(AParent: ILogNode; AName: string): Integer;
begin
  Result := FList.Add(nil);
  ILogNode(FList.List[Result]) := TLog.Create(AParent, AName);
end;

function TLogList.Count: Integer;
begin
  Result := FList.Count;
end;

function TLogList.GetItems(AIndex: Integer): ILogNode;
begin
  Result := ILogNode(FList.List[AIndex]);
end;

{
************************************* TLog *************************************
}
constructor TLog.Create(AParent: ILogNode; AName: string);
begin
  FActive := True;
  FCriticalSection := TCriticalSection.Create;
  if Assigned(AParent) then
    FFilter := AParent.Filter
  else
    FFilter := FilterNone;
  FParent := AParent;
  FName := AName;
  FChildList := TLogList.Create;
  FHandlerList := TInterfaceList.Create;
end;

destructor TLog.Destroy;
begin
  FChildList.Free;
  FHandlerList.Free;
  FCriticalSection.Free;
end;

procedure TLog.Attach(AHandler: IHandler);
begin
  AHandler.Detach; // Хандлер сам себя удалит из FHandlerList
  AHandler.SetAddr(self);
  FHandlerList.Add(AHandler);
end;

procedure TLog.Breake;
var
  I: Integer;
begin
  FParent := nil;
  while FHandlerList.Count > 0 do
    GetHandlers(0).Detach; // Хандлер сам себя удалит из FHandlerList
  for I := 0 to FChildList.Count - 1 do
    FChildList.Items[I].Breake;
end;

function TLog.ChildrenCount: Integer;
begin
  Result := FChildList.Count;
end;

procedure TLog.Error(AError: string);
begin
  Report(ReportError, AError);
end;

function TLog.GetChildren(AIndex: Integer): ILogNode;
begin
  Result := FChildList[AIndex];
end;

function TLog.GetFilter: Single;
begin
  Result := FFilter;
end;

function TLog.GetHandlers(AIndex: Integer): IHandler;
begin
  Result := FHandlerList[AIndex] as IHandler;
end;

function TLog.GetHeight: Integer;
var
  Log: ILogNode;
begin
  Log := self;
  Result := 0;
  while not Log.IsRoot do
  begin
    Log := Log.GetParent;
    Inc(Result);
  end;
end;

function TLog.GetName: string;
begin
  Result := FName;
end;

function TLog.GetParent: ILogNode;
begin
  if Assigned(FParent) then
    Result := FParent
  else
    Result := self;
end;

function TLog.GetSubLogs(AName: string): ILog;
var
  I: Integer;
begin
  FCriticalSection.Enter;
  try
    Result := nil;
    I := 0;
    while (not Assigned(Result)) and (I < FChildList.Count) do
    begin
      if FChildList[i].Name = AName then
        Result := FChildList[i];
      Inc(i);
    end;
    if not Assigned(Result) then
      Result := FChildList[FChildList.Add(self, AName)];
  finally
    FCriticalSection.Leave;
  end;
end;

function TLog.IsRoot: Boolean;
begin
  Result := not Assigned(FParent);
end;

procedure TLog.Msg(AMessage: string);
begin
  Report(ReportMessage, AMessage);
end;

procedure TLog.RemoveHandler(AHandler: IHandler);
begin
  FHandlerList.Remove(AHandler);
end;

procedure TLog.Report(ALevel: Single; AText: string);
begin
  if (ALevel > FFilter) and Active then
    Report(TReport.Create(ALevel, AText, self));
end;

procedure TLog.Report(AReport: IReport);
var
  i: Integer;
begin
  if Active then
  begin
    if Assigned(FParent) then
      FParent.Report(AReport);
    for i := 0 to FHandlerList.Count - 1 do
      GetHandlers(i).Reported(AReport);
  end;
end;

procedure TLog.SetFilter(const Value: Single);
var
  i: Integer;
begin
  FCriticalSection.Enter;
  try
    FFilter := Value;
  finally
    FCriticalSection.Leave;
  end;
  for i := 0 to FChildList.Count - 1 do
    FChildList[i].Filter := Value;
end;

procedure TLog.Warning(AWarning: string);
begin
  Report(ReportWarning, AWarning);
end;

{
*********************************** THandler ***********************************
}
constructor THandler.Create(AWriter: TLogWriter);
begin
  FWriter := AWriter;
  SetQueue(Self);
  // Уменьшаем на еденицу счетчик - поскольку создаем цыклическую ссылку,
  // которая если не уменьшить счетчик не даст самоубиться обьекту
  _Release;
end;

destructor THandler.Destroy;
begin
  FreeAndNil(FWriter);
  FQueue := nil;
end;

procedure THandler.AddQueue(AQueue: IQueue);
begin
  if Assigned(AQueue) then
  begin
    // Порядок присвоения важен - поскольку счетчик Self исскуственно
    // уменьшен на единицу.
    AQueue.SetQueue(Self);
    FQueue.SetQueue(AQueue);
  end
end;

procedure THandler.Detach;
begin
  if Assigned(FAddr) then
    FAddr.RemoveHandler(self);
  FAddr := nil;
end;

function THandler.GetFilter: Single;
begin
  Result := FFilter;
end;

procedure THandler.Post(AReport: IReport);
begin
  FWriter.Write(AReport, FAddr);
end;

procedure THandler.Reported(AReport: IReport);
begin
  if AReport.GetLevel > FFilter then
    FQueue.Post(AReport)
end;

procedure THandler.SetAddr(AAddr: ILogNode);
begin
  FAddr := AAddr;
end;

procedure THandler.SetFilter(const Value: Single);
begin
  FFilter := Value;
end;

procedure THandler.SetQueue(AQueue: IQueue);
begin
  FQueue := AQueue;
end;

{
*********************************** TReport ************************************
}
constructor TReport.Create(ALevel: Single; AText: string; ASender: ILogNode);
begin
  FText := AText;
  FTime := Now;
  FLevel := ALevel;
  FSender := ASender;
end;

destructor TReport.Destroy;
begin
  try
    FText := '';
    FSender := nil;
  except
  end;
end;

function TReport.GetLevel: Single;
begin
  Result := FLevel;
end;

function TReport.GetSender: ILogNode;
begin
  Result := FSender;
end;

function TReport.GetText: string;
begin
  Result := FText;
end;

function TReport.GetTime: TDateTime;
begin
  Result := FTime;
end;

procedure GetPath(ASenderAddr, AHandlerAddr: ILogNode; AStrings: TStrings);
var
  Log: ILogNode;
begin
  Log := ASenderAddr;
  while (not Log.IsRoot) and (Log <> AHandlerAddr) do
  begin
    AStrings.Insert(0, Log.Name);
    Log := Log.GetParent;
  end;
end;

{
*********************************** TTxtLog ************************************
}
procedure TTxtLog.Write(AReport: IReport; AHandlerAddr: ILogNode);
var
  Path: string;
begin
  Path := GetPathAsStr(AReport.GetSender, AHandlerAddr);
  if Path <> '' then
    Path := Path + ': ';
  WriteLine(Path + AReport.GetText);
end;

function TLog.GetActive: Boolean;
begin
  Result := FActive
end;

procedure TLog.SetActive(const Value: Boolean);
begin
  FActive := Value;
end;

function TLog.GetPathToLogFile: string;
begin
  Result := AppDocPath + 'logs\' + FName + '.log';
end;

initialization
  RootLog := nil;
finalization
  if Assigned(RootLog) then
    RootLog.Breake;
end.
