unit UCatalogs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, DB, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, DBGrids, StdCtrls, SqlComponents, metadata, Spin, Buttons,
  Ueditingform, filters, UQuery;

type

  TCatalog = class;

  { TCatalog }

  TCatalog = class(TForm)
    Edit: TButton;
    Datasource: TDatasource;
    RemoveFilter: TButton;
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
    procedure FormCreate(Sender: TObject);
    procedure RemoveFilterClick(Sender: TObject);
  private
    FlagAdd: boolean;
    Tags: array of integer;
    ArrayFilters: TArrayFilters;
    LastPar: string;
    FlagSortOrder: boolean;
    OrderByPar: string;
  public

  end;

var
  Catalog: TCatalog;
  Catalogs: array of TCatalog;

implementation

{$R *.lfm}

procedure TCatalog.ApplyFilterClick(Sender: TObject);
var
  s: string;
  i: integer;
begin
  s := MakeQuery(Table[Tag], OrderByPar, FlagSortOrder, ArrayFilters);
  ApplyQuery(SQLQuery, s, ArrayFilters);
  for i := 0 to High(Table[Tag].Columns) do
    DBGrid1.Columns.Items[i].Width := Table[Tag].Columns[i].Width;
end;

procedure TCatalog.RemoveFilterClick(Sender: TObject);
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
  if MessageDlg('Удалить выбранную запись?',
    mtConfirmation, [mbYes, mbNo], 0) = mrNo then
    exit;
  s := 'DELETE FROM ' + Table[Tag].TableNameEng + ' WHERE ' +
    Table[Tag].Columns[0].NameEng + ' = ' +
    IntToStr(SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value) + ';';
  SQLQuery.Close;
  SQLQuery.SQL.Text := s;
  SQLQuery.ExecSQL;
  DataModule1.SQLTransaction1.commit;
  ApplyFilterClick(Table[Tag]);
end;

procedure TCatalog.AddFilterClick(Sender: TObject);
begin
  ArrayFilters.AddFilter(Tag, ScrollBox1);
end;

procedure TCatalog.FormCreate(Sender: TObject);
begin
  ArrayFilters := TArrayFilters.Create;
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
    if SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value = Tags[i] then
    begin
      EditingForm[i].SetFocus;
      exit;
    end;

  SetLength(EditingForm, Length(EditingForm) + 1);
  if FlagAdd then
    EditingForm[High(EditingForm)] := TFormEdit.Init(Self, -1, Table[Tag])
  else
    EditingForm[High(EditingForm)] :=
      TFormEdit.Init(Self, SQLQuery.FieldByName('ID').Value, Table[Tag]);
  EditingForm[High(EditingForm)].Show;
  SQLQuery.Open;

  SetLength(Tags, Length(Tags) + 1);
  Tags[High(Tags)] := SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value;

  EditingForm[High(EditingForm)].Tag := High(Tags);
  EditingForm[High(EditingForm)].Tags := Tags;
  EditingForm[High(EditingForm)].ApplyProc := @ApplyFilterClick;

  for i := 1 to High(Table[Tag].Columns) do
    if Table[Tag].Columns[i].Ref <> '' then
      EditingForm[High(EditingForm)].CreateNewFieldsWithField(Table[Tag],
        i, SQLQuery.FieldByName('ID').Value)
    else
      EditingForm[High(EditingForm)].CreateNewFields(Table[Tag], i,
        SQLQuery.FieldByName('ID').Value);
  FlagAdd := False;
end;

end.
