unit MainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Data.DB, Vcl.StdCtrls, Vcl.Grids,
  Vcl.DBGrids, Vcl.ExtCtrls, Vcl.ComCtrls, Data.DBXFirebird, Data.SqlExpr,
  DBUnit, DepModelUnit, System.Actions, Vcl.ActnList;

type
  TMainForm = class(TForm)
    pnBottomTools: TPanel;
    pnMain: TPanel;
    lvDep: TListView;
    Splitter: TSplitter;
    dbgEmployees: TDBGrid;
    btnExportToHTML: TButton;
    Button1: TButton;
    dsEmployees: TDataSource;
    alMain: TActionList;
    actExportToHTML: TAction;
    actClose: TAction;
    actRefreshDeps: TAction;
    Button2: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lvDepCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure actRefreshDepsExecute(Sender: TObject);
    procedure InitEmployees(ADepId: Integer);
    procedure actExportToHTMLExecute(Sender: TObject);
    procedure lvDepSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure actCloseExecute(Sender: TObject);
  private
    DBController: TSQLiteDBController;
    DepList: TDepList;
    function GetPathToExport: string;
    procedure RefreshDeps;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  ConstUnit, DepViewUnit, ExportToHtmlFrm, MyDocUnit, System.UITypes;

{$R *.dfm}

procedure TMainForm.actCloseExecute(Sender: TObject);
begin
  Close;
end;

procedure TMainForm.actExportToHTMLExecute(Sender: TObject);
var
  ExportToHtmlForm: TExportToHtmlForm;
  PathToExport: string;
  DepItem: TDepItem;
begin
  DepItem := TDepItem(lvDep.Selected.Data);
  if Assigned(DepItem) then
  begin
    ExportToHtmlForm := TExportToHtmlForm.Create(Self);
    try
      PathToExport := GetPathToExport;
      if PathToExport <> EmptyStr then
        ExportToHtmlForm.ShowExportForm(PathToExport, DepItem,
          DBController.SQLDataSet);
    finally
      FreeAndNil(ExportToHtmlForm);
    end;
  end;
end;

procedure TMainForm.actRefreshDepsExecute(Sender: TObject);
begin
  RefreshDeps;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  DBController := TSQLiteDBController.Create;
  dsEmployees.DataSet := DBController.ClientDataSet;
  DepList := TDepList.Create;
  if not DBController.ConnTest then
  begin
    MessageDlg('Database connection error. ' + #13#10 +
      'Check the settings of the configuration file: ' + #13#10 +
      '"' + DBController.DBInfo.IniFile.FileName + '"', TMsgDlgType.mtError, [mbOK], 0);
    Halt;
  end;
  RefreshDeps;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  if Assigned(DepList) then
    FreeAndNil(DepList);
  if Assigned(DBController) then
    FreeAndNil(DBController);
end;

function TMainForm.GetPathToExport: string;
var
  SaveDlg: TSaveDialog;
begin
  Result := EmptyStr;
  SaveDlg := TSaveDialog.Create(Self);
  try
    SaveDlg.Filter := 'html|*.html';
    SaveDlg.InitialDir := AppDocPath;
    SaveDlg.FileName := AppDocPath + 'Employees.html';
    if SaveDlg.Execute then
    begin
      if FileExists(SaveDlg.FileName) then
        if CheckFileUsed(SaveDlg.FileName) then
        begin
          MessageDlg('The file "' + SaveDlg.FileName +
            '" is opened for editing. Close other applications and try again',
            TMsgDlgType.mtWarning, [mbOK], 0);
          Exit;
        end;
        Result := SaveDlg.FileName;
    end;
  finally
    FreeAndNil(SaveDlg);
  end;

end;

procedure TMainForm.InitEmployees(ADepId: Integer);
var
  SQLText: string;
begin
  begin
    SQLText := 'select ' + FN_EMPL_ID + ', ' + FN_FIRST_NAME + ', ' +
      FN_LAST_NAME + ', ' + FN_EMAIL + ', ' + FN_PHONE_NUMBER + ', ' +
      FN_JOB_ID + ', ' + FN_SALARY + ', ' + FN_COMMISSION_PCT +
      ' from ' + TN_EMPL + ' e ' +
      'where e.' + FN_DEP_ID + ' = ' + IntToStr(ADepId) +
      ' order by ' + FN_FIRST_NAME + ', ' + FN_LAST_NAME;
    DBController.RefreshClientDataSet(SQLText);
  end;
end;

procedure TMainForm.lvDepCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  DepCustomDrawItem(Sender, Item, State, DefaultDraw);
end;

procedure TMainForm.lvDepSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
var
  DepItem: TDepItem;
begin
  if Selected then
  begin
    DepItem := TDepItem(Item.Data);
    if Assigned(DepItem) then
    begin
      InitEmployees(DepItem.Id);
      actExportToHTML.Enabled := DepItem.Salary > 0;
    end;
  end;
end;

procedure TMainForm.RefreshDeps;
begin
  DepList.Load(DBController);
  DepToListView(DepList, lvDep);
end;

end.
