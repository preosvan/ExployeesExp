program EmployeesExport;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  ConfigUnit in 'ConfigUnit.pas',
  MyDocUnit in 'MyDocUnit.pas',
  DBUnit in 'DBUnit.pas',
  SysLogToFile in 'SysLogToFile.pas',
  SysLogUtils in 'SysLogUtils.pas',
  ConstUnit in 'ConstUnit.pas',
  DepModelUnit in 'DepModelUnit.pas',
  ListUtilsUnit in 'ListUtilsUnit.pas',
  DepViewUnit in 'DepViewUnit.pas',
  ExportToHtmlUnit in 'ExportToHtmlUnit.pas',
  ExportToHtmlFrm in 'ExportToHtmlFrm.pas' {ExportToHtmlForm},
  Vcl.Themes,
  Vcl.Styles;

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Light');
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
