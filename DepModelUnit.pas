unit DepModelUnit;

interface

uses
  ListUtilsUnit, DBUnit;

type
  TDepItem = class(TCustomItem)
  private
    FSalary: Double;
    FEmployCount: Integer;
    function GetColor: Integer;
  public
    constructor Create(ADepId: Integer; ADemName: string; ASalary: Double;
      AEmployCount: Integer); overload;
    property Salary: Double read FSalary write FSalary;
    property Color: Integer read GetColor;
    property EmployCount: Integer read FEmployCount;
  end;

  TDepList = class(TCustomDBList)
  public
    function Load(ADBContr: TCustomDBController): Boolean; override;
    function Save(ADBContr: TCustomDBController): Boolean; override;
  end;

implementation

uses
  ConstUnit, System.SysUtils, Vcl.Graphics;

{ TDepItem }

constructor TDepItem.Create(ADepId: Integer; ADemName: string; ASalary: Double;
  AEmployCount: Integer);
begin
  inherited Create(ADepId, ADemName);
  FSalary := ASalary;
  FEmployCount := AEmployCount;
end;

function TDepItem.GetColor: Integer;
begin
  if Salary > 50000 then
    Result := clBlue
  else if Salary <= 0 then
    Result := clRed
  else
    Result := clBlack;
end;

{ TDepList }

function TDepList.Load(ADBContr: TCustomDBController): Boolean;
var
  StrSQL: string;
begin
  Result := True;
  Clear;
  ADBContr.Open;
  StrSQL := 'select d.' + FN_DEP_ID + ', d.' + FN_DEP_NAME + ', (select sum(e.' + FN_SALARY + ') ' +
                         'from ' + TN_EMPL + ' e ' +
                         'where e.' + FN_DEP_ID + ' = d.' + FN_DEP_ID + ') ' + FN_SALARY + ', ' +
                         '(select count(e.' + FN_EMPL_ID + ') ' +
                         'from ' + TN_EMPL + ' e ' +
                         'where e.' + FN_DEP_ID + ' = d.' + FN_DEP_ID + ') EMPL_COUNT ' +
            'from ' + TN_DEP + ' d ' +
            'order by ' + FN_SALARY + ' desc, ' + FN_DEP_NAME + ' ';
  StrSQL := 'select d.DEPARTMENT_ID, d.DEPARTMENT_NAME, Cast((select sum(e.SALARY) SALARY from EMPLOYEES e where e.DEPARTMENT_ID = d.DEPARTMENT_ID) as numeric(8, 2)) SALARY , '
    + '(select count(e.EMPLOYEE_ID) EMPL_COUNT from EMPLOYEES e where e.DEPARTMENT_ID = d.DEPARTMENT_ID) EMPL_COUNT from DEPARTMENTS d order by SALARY desc, DEPARTMENT_NAME';
  try
    if ADBContr.SelectSQL(StrSQL) then
      while not ADBContr.SQLQuery.Eof do
      begin
        try
          Add(TDepItem.Create(
            ADBContr.SQLQuery.FieldByName(FN_DEP_ID).AsInteger,
            ADBContr.SQLQuery.FieldByName(FN_DEP_NAME).AsString,
            StrToFloatDef(ADBContr.SQLQuery.Fields[2].AsString, 0),
            StrToIntDef(ADBContr.SQLQuery.Fields[3].AsString, 0)));
        except
          on E: Exception do
          begin
            ADBContr.Log.Error('Error TDepList.Load: ' + E.Message);
            Result := False;
          end;
        end;
        ADBContr.SQLQuery.Next;
      end;
  finally
    ADBContr.Close;
  end;
end;

function TDepList.Save(ADBContr: TCustomDBController): Boolean;
begin
  //Реализация не требуется
  Result := True;
end;

end.
