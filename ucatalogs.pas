unit UCatalogs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, DB, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, DBGrids, StdCtrls, SqlComponents, metadata, Spin, Buttons,
  Ueditingform, filters, UQuery, variants;

type

  { implementing_catalogs }

   { Timplementing_catalogs }

   Timplementing_catalogs = class(TObject)
    Datasource: TDatasource;
    SQLQuery: TSQLQuery;
    procedure AddField(FlagAdd: boolean);
    function ApplyFilter: TDataSource;
    function ReturnFieldVal(ColName: String): variant;
    procedure RemoveItem;
    constructor Create(Table_Ind: integer; OrderByPar: Pointer; FlagSortOrder: Pointer; AArrayFilters: TArrayFilters);
  private
    POrderByPar: ^string;
    PFlagSortOrder: ^boolean;
    Tag: integer;
    FlagAdd: boolean;
    Tags: array of integer;
    LastPar: string;
  public
    ArrayFilters: TArrayFilters;
  end;

  { TCatalog }

  TCatalog = class(TForm)
    AddField: TButton;
    Edit: TButton;
    Datasource: TDatasource;
    RemoveItem: TButton;
    AddFilter: TButton;
    ApplyFilter: TButton;
    DBGrid1: TDBGrid;
    SQLQuery: TSQLQuery;
    ToolPanel: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    procedure AddFieldClick(Sender: TObject);
    procedure ApplyFilterClick(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure DBGrid1TitleClick(Column: TColumn);
    procedure EditClick(Sender: TObject);
    procedure AddFilterClick(Sender: TObject);
    procedure RemoveItemClick(Sender: TObject);
    constructor Create(Sender: TComponent; Ind: integer);
  private
    FlagAdd: boolean;
    Tags: array of integer;
    LastPar: string;
    FlagSortOrder: boolean;
    OrderByPar: string;
    imp_ctlg: Timplementing_catalogs;
  public
    ArrayFilters: TArrayFilters;
  end;

procedure AddInCatalogs (Sender: TComponent; Ind: integer);

var
  Catalog: TCatalog;
  Catalogs: array of TCatalog;

implementation

procedure AddInCatalogs (Sender: TComponent; Ind: integer);
begin
  SetLength(Catalogs, Length(Catalogs) + 1);
  Catalogs[High(Catalogs)] := TCatalog.Create(Sender, Ind);
end;

{$R *.lfm}

{ Timplementing_catalogs }
function Timplementing_catalogs.ReturnFieldVal(ColName: String): variant;
begin
  Result := SQLQuery.FieldByName(ColName).Value;
end;

constructor Timplementing_catalogs.Create(Table_Ind: integer; OrderByPar: Pointer; FlagSortOrder: Pointer; AArrayFilters: TArrayFilters);
begin
  POrderByPar := OrderByPar;
  PFlagSortOrder := FlagSortOrder;
  ArrayFilters := AArrayFilters;
  Tag := Table_Ind;
  SQLQuery := TSQLQuery.Create(nil);
  Datasource := TDataSource.Create(nil);
  SQLQuery.DataBase := DataModule1.IBConnection1;
  SQLQuery.Transaction := DataModule1.SQLTransaction1;
  Datasource.DataSet := SQLQuery;
end;

function Timplementing_catalogs.ApplyFilter: TDatasource;
var
  s: string;
begin
  s := MakeQuery(Table[Tag], POrderByPar^, PFlagSortOrder^, ArrayFilters);
  ApplyQuery(SQLQuery, s, ArrayFilters);
  Result := Datasource;
end;


procedure Timplementing_catalogs.RemoveItem;
var
  s: string;
  i: integer;
begin
  if MessageDlg('Удалить выбранную запись?', mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    exit;
  s := 'DELETE FROM ' + Table[Tag].TableNameEng + ' WHERE ' +
    Table[Tag].Columns[0].NameEng + ' = ' +
    IntToStr(SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value) + ';';
  SQLQuery.Close;
  SQLQuery.SQL.Text := s;
  SQLQuery.ExecSQL;
  DataModule1.SQLTransaction1.commit;
end;


procedure Timplementing_catalogs.AddField(FlagAdd: boolean);
var
  i: integer;
begin
  SetLength(EditingForm, Length(EditingForm) + 1);
  if FlagAdd then                         ////////////////////////////////////////////////////////////////////
  begin
    EditingForm[High(EditingForm)] := TFormEdit.Init(nil, -1, Table[Tag]);
    for i := 1 to High(Table[Tag].Columns) do
      if Table[Tag].Columns[i].Ref <> '' then
        EditingForm[High(EditingForm)].CreateNewFieldsWithField(Table[Tag], i, -1)
      else
        EditingForm[High(EditingForm)].CreateNewFields(Table[Tag], i, -1);
  end
  else
  begin
    EditingForm[High(EditingForm)] :=
      TFormEdit.Init(nil, SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value, Table[Tag]);
    for i := 1 to High(Table[Tag].Columns) do
      if Table[Tag].Columns[i].Ref <> '' then
        EditingForm[High(EditingForm)].CreateNewFieldsWithField(Table[Tag],
          i, SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value)
      else
        EditingForm[High(EditingForm)].CreateNewFields(Table[Tag], i,
          SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value);
  end;
  EditingForm[High(EditingForm)].Show;
  FlagAdd := False;
end;

//////////////////////////////////////////////////////////////////////////////////////////

constructor TCatalog.Create(Sender: TComponent; Ind: integer);
begin
  inherited Create(Sender);
  ArrayFilters := TArrayFilters.Create(ScrollBox1, Table[Ind]);
  Tag := Ind;
  imp_ctlg := Timplementing_catalogs.Create(Ind, @OrderByPar, @FlagSortOrder, ArrayFilters);
  Show;
  ApplyFilter.Click;
end;

procedure TCatalog.ApplyFilterClick(Sender: TObject);
var
  s: string;
  i: integer;
begin
  Datasource := imp_ctlg.ApplyFilter;
  DBGrid1.DataSource := Datasource;
  for i := 0 to High(Table[Tag].Columns) do
    DBGrid1.Columns.Items[i].Width := Table[Tag].Columns[i].Width;
end;

procedure TCatalog.RemoveItemClick(Sender: TObject);
var
  s: string;
  i: integer;
begin
  for i := 0 to High(Tags) do
    if Tags[i] >= 0 then
    begin
      ShowMessage('Невозможно удалить запись во время редактирования!');
      exit;
    end;
  imp_ctlg.RemoveItem;
  ApplyFilterClick(nil);
end;

procedure TCatalog.AddFilterClick(Sender: TObject);
begin
  ArrayFilters.AddFilter;
end;

procedure TCatalog.DBGrid1TitleClick(Column: TColumn);
begin
  OrderByPar := Column.FieldName;
  if not (LastPar = Column.FieldName) then
  begin
    LastPar := Column.FieldName;
    FlagSortOrder := False;
  end
  else
    FlagSortOrder := not (FlagSortOrder);
  ApplyFilterClick(Table[Tag]);
end;

procedure TCatalog.EditClick(Sender: TObject);
begin
  DBGrid1DblClick(DBGrid1);
end;

procedure TCatalog.AddFieldClick(Sender: TObject);
begin
  FlagAdd := True;
  Edit.Click;
end;

procedure TCatalog.DBGrid1DblClick(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to High(Tags) do
    if imp_ctlg.ReturnFieldVal(Table[Tag].Columns[0].NameRus) = Tags[i] then
    begin
      EditingForm[i].SetFocus;
      exit;
    end;
  imp_ctlg.AddField(FlagAdd);
  SetLength(Tags, Length(Tags) + 1);
  Tags[High(Tags)] := imp_ctlg.ReturnFieldVal(Table[Tag].Columns[0].NameRus);
  EditingForm[High(EditingForm)].Tag := High(Tags);
  EditingForm[High(EditingForm)].Tags := Tags;
  EditingForm[High(EditingForm)].ApplyProc := @ApplyFilterClick;
  FlagAdd := False;
end;

end.
