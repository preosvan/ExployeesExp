object ExportToHtmlForm: TExportToHtmlForm
  Left = 0
  Top = 0
  BorderIcons = []
  Caption = 'Export to HTML'
  ClientHeight = 60
  ClientWidth = 240
  Color = clBtnFace
  Constraints.MaxHeight = 99
  Constraints.MaxWidth = 256
  Constraints.MinHeight = 99
  Constraints.MinWidth = 256
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object pgsExport: TProgressBar
    Left = 8
    Top = 8
    Width = 225
    Height = 17
    MarqueeInterval = 1
    Step = 1
    TabOrder = 0
  end
  object btnCancel: TButton
    Left = 80
    Top = 31
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 1
  end
end
