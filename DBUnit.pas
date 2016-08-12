unit DBUnit;

interface

uses
  Data.DB, Data.SqlExpr, Data.DbxSqlite, Datasnap.Provider, Datasnap.DBClient, SysLogUtils, ConfigUnit,
  ListUtilsUnit;

type
  {: Класс для работы с настройками подключения к базе данных }
  TDBInfo = class(TCustomConfig)
  private
    FDBPass: string;
    FDBHost: string;
    FDBUserName: string;
    FDBName: string;
    function GetIsRemoteHost: Boolean;
  public
    procedure Apply; override;
    procedure Load; override;
    property DBName: string read FDBName write FDBName;
    property DBHost: string read FDBHost write FDBHost;
    property DBUserName: string read FDBUserName write FDBUserName;
    property DBPass: string read FDBPass write FDBPass;
    property IsRemoteHost: Boolean read GetIsRemoteHost;
  end;

  {: Базовый класс менеджера работы с базой данных }
  TCustomDBController = class
  private
    FDBInfo: TDBInfo;
    FLog: ILog;
    FSQLConn: TSQLConnection;
    FSQLQuery: TSQLQuery;
    FConnActive: Boolean;
    FDataSetProvider: TDataSetProvider;
    FSQLDataSet: TSQLDataSet;
    FClientDataSet: TClientDataSet;
    procedure SetConnActive(const Value: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    procedure InitConnection; virtual; abstract;
    procedure InitParams; virtual; abstract;
    procedure RefreshClientDataSet(ASql: string);
    function ExecSQL(ASQL: string): Boolean;
    function SelectSQL(ASQL: string): Boolean;
    function ConnTest: Boolean;
    property Log: ILog read FLog write FLog;
    property ConnActive: Boolean read FConnActive write SetConnActive;
    property DBInfo: TDBInfo read FDBInfo write FDBInfo;
    property SQLConn: TSQLConnection read FSQLConn write FSQLConn;
    property SQLQuery: TSQLQuery read FSQLQuery write FSQLQuery;
    property SQLDataSet: TSQLDataSet read FSQLDataSet write FSQLDataSet;
    property ClientDataSet: TClientDataSet read FClientDataSet write FClientDataSet;
  end;

  {: Интерфейс списка объектов, которые хранятся в БД }
  TCustomDBList = class(TCustomList)
    function Load(ADBContr: TCustomDBController): Boolean; virtual; abstract;
    function Save(ADBContr: TCustomDBController): Boolean; virtual; abstract;
  end;

  {: Менеджер работы с базой данных SQLite }
  TSQLiteDBController = class(TCustomDBController)
  public
    procedure InitConnection; override;
    procedure InitParams; override;
  end;

implementation

uses
  SysLogToFile, MyDocUnit, ConstUnit, System.SysUtils;

{ DBController }

procedure TCustomDBController.Close;
begin
  if SQLQuery.Active then
    SQLQuery.Close;
  ConnActive := False;
end;

function TCustomDBController.ConnTest: Boolean;
begin
  try
    Open;
  finally
    Result := ConnActive;
  end;
end;

constructor TCustomDBController.Create;
begin
  FDBInfo := TDBInfo.Create(AppDocPath + 'DBInfo.ini');

  FSQLConn := TSQLConnection.Create(nil);
  FSQLConn.LoginPrompt := False;

  FSQLQuery := TSQLQuery.Create(nil);
  FSQLQuery.SQLConnection := FSQLConn;

  FSQLDataSet := TSQLDataSet.Create(nil);
  FSQLDataSet.SQLConnection := FSQLConn;

  FDataSetProvider := TDataSetProvider.Create(nil);
  FDataSetProvider.DataSet := FSQLDataSet;

  FClientDataSet := TClientDataSet.Create(nil);
  FClientDataSet.SetProvider(FDataSetProvider);

  GetLog.Attach(CreateDirectoryHandler);
  FLog := GetLog['DataBase'];
end;

destructor TCustomDBController.Destroy;
begin
  FreeAndNil(FDBInfo);
  FreeAndNil(FClientDataSet);
  FreeAndNil(FSQLQuery);
  FreeAndNil(FSQLDataSet);
  FreeAndNil(FSQLConn);
  FreeAndNil(FDataSetProvider);
  inherited;
end;

function TCustomDBController.ExecSQL(ASQL: string): Boolean;
begin
  Result := True;
  Open;
  try
    if ConnActive then
    begin
      SQLQuery.SQL.Clear;
      SQLQuery.SQL.Add(ASQL);
      try
        SQLQuery.ExecSQL(True);
      except
        on e: exception do
        begin
          FLog.Msg('Error executing query: ' + e.Message + '. SQL: ' + ASQL);
          Result := False;
        end;
      end;
    end;
  finally
    Close;
  end;
end;

procedure TCustomDBController.Open;
begin
  ConnActive := True;
end;

procedure TCustomDBController.RefreshClientDataSet(ASql: string);
begin
  FClientDataSet.Active := False;
  FSQLDataSet.Active := False;
  FSQLDataSet.CommandText := ASQL;
  FClientDataSet.SetProvider(FDataSetProvider);
  FSQLDataSet.Active := True;
  FClientDataSet.Active := True;
end;

function TCustomDBController.SelectSQL(ASQL: string): Boolean;
begin
  Result := False;
  Open;
  SQLQuery.Close;
  if ConnActive then
    try
      SQLQuery.SQL.Clear;
      SQLQuery.Params.Clear;
      SQLQuery.Fields.Clear;
      SQLQuery.SQL.Add(ASQL);
      SQLQuery.Open;
      SQLQuery.First;
      Result := True;
    except
      on e: exception do
      begin
        FLog.Msg('Error executing query: ' + e.Message + '. SQL: ' + ASQL);
        Result := False;
      end;
    end;
end;

procedure TCustomDBController.SetConnActive(const Value: Boolean);
begin
  if Value <> FConnActive then
  begin
    FConnActive := False;
    if Value then
    begin
      InitConnection;
      InitParams;
    end;

    try
      FSQLConn.Connected := Value;
      FConnActive := Value;
    except
      on e: exception do
        FLog.Msg('Error connecting to the database: ' + e.Message);
    end;
  end;
end;

{ TDBInfo }

procedure TDBInfo.Apply;
begin
  IniFile.WriteString(SECTION_GENERAL, KEY_DB_NAME, DBName);
  IniFile.WriteString(SECTION_GENERAL, KEY_DB_HOST, DBHost);
  IniFile.WriteString(SECTION_GENERAL, KEY_DB_USER_NAME, DBUserName);
  IniFile.WriteString(SECTION_GENERAL, KEY_DB_PASS, DBPass);
end;

function TDBInfo.GetIsRemoteHost: Boolean;
begin
  Result := (Trim(DBHost) <> EmptyStr) and
            (UpperCase(Trim(DBHost)) <> 'LOCALHOST') and
            (Trim(DBHost) <> '127.0.0.1');
end;

procedure TDBInfo.Load;
var
  DefDBName: string;
begin
  DefDBName := ExtractFilePath(ParamStr(0)) + 'EmployeesDB.SQLite';
  FDBName := IniFile.ReadString(SECTION_GENERAL, KEY_DB_NAME, DefDBName);
  FDBHost := IniFile.ReadString(SECTION_GENERAL, KEY_DB_HOST, 'localhost');
  FDBUserName := IniFile.ReadString(SECTION_GENERAL, KEY_DB_USER_NAME, '');
  FDBPass := IniFile.ReadString(SECTION_GENERAL, KEY_DB_PASS, '');
end;

{ TFirebirdDBController }

procedure TSQLiteDBController.InitConnection;
begin
  SQLConn.LoginPrompt := False;
  SQLConn.DriverName := 'Sqlite';
  SQLConn.ConnectionName := 'SQLITECONNECTION';
end;

procedure TSQLiteDBController.InitParams;
begin
  SQLConn.Params.Clear;
  SQLConn.Params.Values['HostName'] := DBInfo.DBHost;
  if DBInfo.IsRemoteHost then
    SQLConn.Params.Values['Database'] := DBInfo.DBHost + ':' + DBInfo.DBName
  else
    SQLConn.Params.Values['Database'] := DBInfo.DBName;
  SQLConn.Params.Values['User'] := DBInfo.DBUserName;
  SQLConn.Params.Values['Password'] := DBInfo.DBPass;
end;

end.
