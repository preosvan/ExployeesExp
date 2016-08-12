unit DepViewUnit;

interface

uses
  DepModelUnit, Vcl.ComCtrls, System.Types;

  procedure DepCustomDrawItem(ASender: TCustomListView; AItem: TListItem;
    AState: TCustomDrawState; var ADefaultDraw: Boolean);
  procedure DepToListView(ADepList: TDepList; AListView: TListView);

implementation

uses
  Vcl.Graphics;

procedure DepToListView(ADepList: TDepList; AListView: TListView);
var
  I: Integer;
begin
  if Assigned(ADepList) and Assigned(AListView) then
  begin
    AListView.Items.BeginUpdate;
    try
      AListView.Clear;
      for I := 0 to ADepList.Count - 1 do
        AListView.AddItem(ADepList[I].Name, ADepList[I]);
    finally
      AListView.Items.EndUpdate;
    end;
    if Assigned(AListView.Items[0]) then
      AListView.Items[0].Selected := True;
  end;
end;

procedure DepCustomDrawItem(ASender: TCustomListView; AItem: TListItem;
  AState: TCustomDrawState; var ADefaultDraw: Boolean);
var
  DepItem: TDepItem;
begin
  DepItem := TDepItem(AItem.Data);
  if Assigned(DepItem) then
    ASender.Canvas.Font.Color := DepItem.Color;
end;

end.
