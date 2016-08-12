unit ExportToHtmlUnit;

interface

uses
  System.Classes, Vcl.Controls, DepModelUnit, Data.SqlExpr;

type
  TSetProgres = procedure of object;

  TExporterToHTML = class(TThread)
  private
    FMainFormHandle: THandle;
    FPathToHTML: string;
    FIsStop: Boolean;
    FDepItem: TDepItem;
    FSQLDataSet: TSQLDataSet;
    FProcSetProgres: TSetProgres;
    procedure CopyCSS(APathToHTML: string);
    function ExportToHTML: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(AHandle: THandle; APathToHTML: string;
      ADepItem: TDepItem; ASQLDataSet: TSQLDataSet;
      AProcSetProgres: TSetProgres); overload;
    property DepItem: TDepItem read FDepItem write FDepItem;
    property MainFormHandle: THandle read FMainFormHandle;
    property PathToHTML: string read FPathToHTML;
    property SQLDataSet: TSQLDataSet read FSQLDataSet;
    //������� ����������� �������� � ����������� ������
    property IsStop: Boolean read FIsStop write FIsStop;
  end;

implementation

uses
  ConstUnit, Winapi.Windows, Vcl.Graphics, System.SysUtils, Data.DB,
  System.IOUtils;

{ TExporterToHTML }

procedure TExporterToHTML.CopyCSS(APathToHTML: string);
var
  PathToCSS: string;
begin
  PathToCSS := ExtractFilePath(ParamStr(0));
  TFile.Copy(PathToCSS + EXP_CSS_FN_TABLE, APathToHTML + PathDelim + EXP_CSS_FN_TABLE, True);
  TFile.Copy(PathToCSS + EXP_CSS_FN_CAPT_BLUE, APathToHTML + PathDelim + EXP_CSS_FN_CAPT_BLUE, True);
  TFile.Copy(PathToCSS + EXP_CSS_FN_CAPT_BLACK, APathToHTML + PathDelim + EXP_CSS_FN_CAPT_BLACK, True);
end;

constructor TExporterToHTML.Create(AHandle: THandle; APathToHTML: string;
  ADepItem: TDepItem; ASQLDataSet: TSQLDataSet; AProcSetProgres: TSetProgres);
begin
  inherited Create(False);
  FIsStop := False;
  FMainFormHandle := AHandle;
  FPathToHTML := APathToHTML;
  FDepItem := ADepItem;
  FSQLDataSet := ASQLDataSet;
  FProcSetProgres := AProcSetProgres;
  FreeOnTerminate := True;
end;

procedure TExporterToHTML.Execute;
var
  ResExport: Integer;
begin
  inherited;
  ResExport := ExportToHTML.ToInteger;
  SendMessage(FMainFormHandle, WM_AFTER_EXPORT, ResExport, 0);
end;

function TExporterToHTML.ExportToHTML: Boolean;
var
  HtmlStr: WideString;
  I: Integer;
  HtmlFile: TextFile;
begin
  Result := False;
  if Assigned(DepItem) then
  begin
    //��������� ��������
    HtmlStr := '<title>Employees</title>' + #13#10;

    //�����
    HtmlStr := HtmlStr + '<link rel="stylesheet" type="text/css" href="' + EXP_CSS_FN_TABLE + '">' + #13#10;
    if DepItem.Color = clBlue then
      HtmlStr := HtmlStr + '<link rel="stylesheet" type="text/css" href="' + EXP_CSS_FN_CAPT_BLUE + '">' + #13#10
    else
      HtmlStr := HtmlStr + '<link rel="stylesheet" type="text/css" href="' + EXP_CSS_FN_CAPT_BLACK + '">' + #13#10;

    //��������� �������
    HtmlStr := HtmlStr + '<table class="table_blur">' + #13#10;
    HtmlStr := HtmlStr + '<caption>Department: "' + DepItem.Name + '"<caption>' + #13#10;
    HtmlStr := HtmlStr + '<tr>' + #13#10;
    for I := 0 to SqlDataSet.FieldCount - 1 do
    begin
      HtmlStr := HtmlStr + '<th>';
      HtmlStr := HtmlStr + '' + SqlDataSet.Fields[i].DisplayName + '';
      HtmlStr := HtmlStr + '</th>' + #13#10;
    end;
    HtmlStr := HtmlStr + '</tr>' + #13#10;

    //���� �������
    SqlDataSet.First;
    while not SqlDataSet.Eof do
    begin
      //������������ ���������
      Synchronize(FProcSetProgres);
      //��� ����� ������� ����������� ���������
      Sleep(100); // ��������, ����� ������ ������� �������� ��������

      HtmlStr := HtmlStr + '<tr>' + #13#10;
      for I := 0 to SqlDataSet.FieldCount - 1 do
      begin
//        if SqlDataSet.Fields[I].DataType in AvailableFields then
        begin
          HtmlStr := HtmlStr + '<td>';
          HtmlStr := HtmlStr + SqlDataSet.Fields[I].AsString;
          HtmlStr := HtmlStr + '</td>' + #13#10;
        end;
      end;
      HtmlStr := HtmlStr + '</tr>' + #13#10;
      SqlDataSet.Next;
      if IsStop then
        Exit;
    end;
    HtmlStr := HtmlStr + '</table>' + #13#10;

    AssignFile(Htmlfile, PathToHTML);
    try
      Rewrite(HtmlFile);
      WriteLn(HtmlFile, HtmlStr);
    finally
      CloseFile(HtmlFile);
    end;
    Result := True;
    CopyCSS(TPath.GetDirectoryName(PathToHTML));
  end;
end;

end.
