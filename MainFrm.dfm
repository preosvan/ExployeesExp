object MainForm: TMainForm
  Left = 0
  Top = 0
  Width = 873
  Height = 645
  AutoScroll = True
  Caption = 'Export employees to HTML'
  Color = clBtnFace
  Constraints.MinHeight = 322
  Constraints.MinWidth = 400
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnBottomTools: TPanel
    Left = 0
    Top = 565
    Width = 857
    Height = 41
    Align = alBottom
    TabOrder = 0
    DesignSize = (
      857
      41)
    object btnExportToHTML: TButton
      Left = 612
      Top = 6
      Width = 115
      Height = 25
      Action = actExportToHTML
      Anchors = [akTop, akRight]
      TabOrder = 0
    end
    object Button1: TButton
      Left = 733
      Top = 6
      Width = 115
      Height = 25
      Action = actClose
      Anchors = [akTop, akRight]
      TabOrder = 1
    end
    object Button2: TButton
      Left = 8
      Top = 6
      Width = 176
      Height = 25
      Action = actRefreshDeps
      TabOrder = 2
    end
  end
  object pnMain: TPanel
    Left = 0
    Top = 0
    Width = 857
    Height = 565
    Align = alClient
    TabOrder = 1
    object Splitter: TSplitter
      Left = 191
      Top = 1
      Height = 563
      ExplicitLeft = 296
      ExplicitTop = 120
      ExplicitHeight = 100
    end
    object lvDep: TListView
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 184
      Height = 557
      Align = alLeft
      Columns = <
        item
          AutoSize = True
          Caption = 'DEPARTMENTS'
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
      OnCustomDrawItem = lvDepCustomDrawItem
      OnSelectItem = lvDepSelectItem
    end
    object dbgEmployees: TDBGrid
      AlignWithMargins = True
      Left = 197
      Top = 4
      Width = 656
      Height = 557
      Align = alClient
      DataSource = dsEmployees
      ReadOnly = True
      TabOrder = 1
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clWindowText
      TitleFont.Height = -11
      TitleFont.Name = 'Tahoma'
      TitleFont.Style = []
    end
  end
  object dsEmployees: TDataSource
    Left = 216
    Top = 48
  end
  object alMain: TActionList
    Left = 288
    Top = 48
    object actExportToHTML: TAction
      Caption = 'Export to HTML'
      Hint = 'Export to HTML'
      OnExecute = actExportToHTMLExecute
    end
    object actClose: TAction
      Caption = 'Close'
      Hint = 'Close'
      OnExecute = actCloseExecute
    end
    object actRefreshDeps: TAction
      Caption = 'Refresh departments'
      Hint = 'Refresh departments'
      OnExecute = actRefreshDepsExecute
    end
  end
end
