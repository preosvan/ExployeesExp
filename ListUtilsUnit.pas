unit ListUtilsUnit;

interface

uses
  System.Classes, Winapi.Windows;

type
  {: Базовый класс элемента списка }
  TCustomItem = class(TPersistent)
  private
    FId: Integer;
    FName: string;
  public
    constructor Create(AId: Integer; AName: string); overload;
    property Id: Integer read FId write FId;
    property Name: string read FName write FName;
  end;

  {: Базовый класс списка элементов }
  TCustomList = class(TPersistent)
  private
    FList: TList;
    FLock: TRTLCriticalSection;
    function GetCount: Integer;
    function GetItems(Index: Integer): TCustomItem;
    function GetLastId: Integer;
    function GetLastItem: TCustomItem;
  public
    constructor Create; overload;
    destructor Destroy; override;
    function Add(AItem: TCustomItem): TCustomItem;
    procedure Clear(AIsFreeItems: Boolean = True); virtual;
    procedure DestroyNotClear;
    function GetItemById(AId: Integer): TCustomItem;
    function GetItemByName(AName: string): TCustomItem;
    function LockList: TList;
    procedure Remove(AItem: TCustomItem; IsFreeItem: Boolean = False);
    procedure Sort(ACompare: TListSortCompare);
    procedure UnlockList;
    property Count: Integer read GetCount;
    property Items[Index: integer]: TCustomItem read GetItems; default;
    property LastId: Integer read GetLastId;
    property LastItem: TCustomItem read GetLastItem;
  end;

implementation

{ TCustomItem }

constructor TCustomItem.Create(AId: Integer; AName: string);
begin
  inherited Create;
  FId := AId;
  FName := AName;
end;

{ TCustomItems }

function TCustomList.Add(AItem: TCustomItem): TCustomItem;
begin
  LockList;
  try
    FList.Add(AItem);
    Result := AItem;
  finally
    UnlockList;
  end;
end;

procedure TCustomList.Clear(AIsFreeItems: Boolean);
var
  I: Integer;
begin
  if Assigned(FList) then
  begin
    if AIsFreeItems then
      for I := FList.Count - 1 downto 0 do
        if Assigned(FList[I]) then
        begin
          TCustomItem(FList[I]).Free;
          FList[I] := nil;
        end;
    FList.Clear;
  end;
end;

constructor TCustomList.Create;
begin
  inherited Create;
  InitializeCriticalSection(FLock);
  FList := TList.Create;
end;

destructor TCustomList.Destroy;
begin
  Clear;
  LockList;
  try
    FList.Free;
    inherited;
  finally
    UnlockList;
    DeleteCriticalSection(FLock);
  end;
end;

procedure TCustomList.DestroyNotClear;
begin
  LockList;
  try
    FList.Free;
    inherited;
  finally
    UnlockList;
    DeleteCriticalSection(FLock);
  end;
end;

function TCustomList.GetCount: Integer;
begin
  Result := FList.Count;
end;

function TCustomList.GetItemById(AId: Integer): TCustomItem;
var
  I: Integer;
  Item: TCustomItem;
begin
  Result := nil;
  LockList;
  try
    for I := 0 to Count - 1 do
    begin
      Item := FList[I];
      if Assigned(Item) then
        if Item.Id = AId then
        begin
          Result := Item;
          Break;
        end;
    end;
  finally
    UnlockList;
  end;
end;

function TCustomList.GetItemByName(AName: string): TCustomItem;
var
  I: Integer;
  Item: TCustomItem;
begin
  Result := nil;
  LockList;
  try
    for I := 0 to Count - 1 do
    begin
      Item := FList[I];
      if Assigned(Item) then
        if Item.Name = AName then
        begin
          Result := Item;
          Break;
        end;
    end;
  finally
    UnlockList;
  end;
end;

function TCustomList.GetItems(Index: Integer): TCustomItem;
begin
  if Index < FList.Count then
    Result := FList[Index] else
    Result := nil;
end;

function TCustomList.GetLastId: Integer;
var
  I: Integer;
  Item: TCustomItem;
begin
  Result := 0;
  if Assigned(FList) then
  begin
    LockList;
    try
      for I := 0 to FList.Count - 1 do
      begin
        Item := FList[I];
        if Result < Item.Id then
          Result := Item.Id;
      end;
    finally
      UnlockList;
    end;
  end;
end;

function TCustomList.GetLastItem: TCustomItem;
begin
  Result := GetItemById(LastId);
end;

function TCustomList.LockList: TList;
begin
  EnterCriticalSection(FLock);
  Result := FList;
end;

procedure TCustomList.Remove(AItem: TCustomItem; IsFreeItem: Boolean);
var
  I: Integer;
begin
  LockList;
  try
    for I := 0 to Count - 1 do
    if FList[I] = AItem then
    begin
      if IsFreeItem then
        AItem.Free;
      FList.Delete(I);
      Break;
    end;
  finally
    UnlockList;
  end;
end;

procedure TCustomList.Sort(ACompare: TListSortCompare);
begin
  FList.Sort(ACompare);
end;

procedure TCustomList.UnlockList;
begin
  LeaveCriticalSection(FLock);
end;

end.
