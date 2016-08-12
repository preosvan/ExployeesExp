unit ExportToHtmlFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ComCtrls, ExportToHtmlUnit, ConstUnit, DepModelUnit,
  Data.SqlExpr;

type
  TExportToHtmlForm = class(TForm)
    pgsExport: TProgressBar;
    btnCancel: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    FPathToHTML: string;
    FExporterToHTML: TExporterToHTML;
    FDepItem: TDepItem;
    FSQLDataSet: TSQLDataSet;
    procedure CancelExport;
    procedure InitExporter;
    procedure AfterExport(var Message: TMessage); message WM_AFTER_EXPORT;
  public
    procedure SetProgress;
    procedure ShowExportForm(APathToHTML: string; ADepItem: TDepItem;
      ASQLDataSet: TSQLDataSet);
    property DepItem: TDepItem read FDepItem;
    property ExporterToHTML: TExporterToHTML read FExporterToHTML write FExporterToHTML;
    property SQLDataSet: TSQLDataSet read FSQLDataSet write FSQLDataSet;
    property PathToHTML: string read FPathToHTML;
  end;

var
  ExportToHtmlForm: TExportToHtmlForm;

implementation

uses
  MyDocUnit, System.UITypes;

{$R *.dfm}

{ TExportToHtmlForm }

procedure TExportToHtmlForm.AfterExport(var Message: TMessage);
begin
  if Message.WParam.ToBoolean then
    if MessageDlg('Export to HTML has been successfully completed.' + #13#10 +
      'Open file location?' , TMsgDlgType.mtInformation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], 0) = mrYes then
      OpenFolderAndSelectFile(PathToHTML);
  ModalResult := mrCancel;
end;

procedure TExportToHtmlForm.CancelExport;
begin
  if Assigned(ExporterToHTML) then
  begin
    ExporterToHTML.IsStop := True;
    ExporterToHTML := nil;
  end;
end;

procedure TExportToHtmlForm.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  CancelExport;
end;

procedure TExportToHtmlForm.InitExporter;
begin
  CancelExport;
  ExporterToHTML := TExporterToHTML.Create(Handle, FPathToHTML, DepItem,
    SQLDataSet, SetProgress);
end;

procedure TExportToHtmlForm.SetProgress;
begin
  pgsExport.Position := pgsExport.Position + 1;
end;

procedure TExportToHtmlForm.ShowExportForm(APathToHTML: string;
  ADepItem: TDepItem; ASQLDataSet: TSQLDataSet);
begin
  FPathToHTML := APathToHTML;
  FDepItem := ADepItem;
  FSQLDataSet := ASQLDataSet;
  pgsExport.Min := 0;
  pgsExport.Max := ADepItem.EmployCount;
  InitExporter;
  ShowModal;
end;

end.
