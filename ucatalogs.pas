unit UCatalogs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, DBGrids, StdCtrls, SqlComponents, metadata, Spin, Buttons,
  Ueditingform, filters;

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
    function MakeQuery(Table: TTableInfo): string;
    procedure RemoveFilterClick(Sender: TObject);
    procedure SendQuery(s: string);
  private
    FlagAdd: Boolean;
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


procedure TCatalog.SendQuery(s: string);
var
  TableWidth: array of integer;
  Str: String;
  i: integer;
  TableNum: integer;
begin
  SQLQuery.Close;
  SQLQuery.SQL.Text := s;
  for i := 0 to High(ArrayFilters.Filters) do
    SQLQuery.ParamByName('value' + IntToStr(i)).AsString := ArrayFilters.Filters[i].FilterVal.Text;
  SQLQuery.Open;
  for i := 0 to High(Table[Tag].Columns) do
    DBGrid1.Columns.Items[i].Width := Table[Tag].Columns[i].Width;
end;

function TCatalog.MakeQuery(Table: TTableInfo): string;
var
  i: integer;
  s, inner_join: string;
begin
  s := 'SELECT ';
  for i := 0 to High(Table.Columns) do
  begin
    if Table.Columns[i].Ref <> '' then
    begin
      s += Table.Columns[i].Ref + '.' + Table.Columns[i].RefVal;
      if (OrderByPar = Table.Columns[i].NameRus) then
        OrderByPar := ' ORDER BY ' + Table.Columns[i].Ref + '.' + Table.Columns[i].RefVal;
    end
    else
    begin
      s += Table.TableNameEng + '.' + Table.Columns[i].NameEng;
      if (OrderByPar = Table.Columns[i].NameRus) then
        OrderByPar := ' ORDER BY ' + Table.TableNameEng + '.' + Table.Columns[i].NameEng;
    end;
    s += ' as "' + Table.Columns[i].NameRus + '"';
    if (i < High(Table.Columns)) then
      s += ', ';
  end;
  s += ' FROM ' + Table.TableNameEng;
  for i := 0 to High(Table.Columns) do
    if Table.Columns[i].Ref <> '' then
    begin
      inner_join += ' INNER JOIN ' + Table.Columns[i].Ref + ' ON ' + Table.TableNameEng + '.';
      inner_join += Table.Columns[i].NameEng + ' = ' + Table.Columns[i].Ref + '.';
      inner_join += Table.Columns[i].RefPar;
    end;

  if FlagSortOrder then
    OrderByPar += ' ' + 'desc';

  Result := s + inner_join;
end;

procedure TCatalog.RemoveFilterClick(Sender: TObject);
var
  s: string;
  i: integer;
begin
  for i := 0 to High(Tags) do
   if  Tags[i] >= 0 then
   begin
     ShowMessage('Невозможно удалить запись во время редактирования!');
     exit;
   end;
  if MessageDlg ('Удалить выбранную запись?', mtConfirmation, [mbYes, mbNo] ,0) = mrNo then
     exit;
  s += 'DELETE FROM ' + Table[Tag].TableNameEng +
    ' WHERE ' + Table[Tag].Columns[0].NameEng + ' = '
    + IntToStr(SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value) + ';';
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

procedure TCatalog.ApplyFilterClick(Sender: TObject);
var
  s, Col, Tbl: string;
  i, Ind: integer;
begin

  s += MakeQuery(Table[Tag]);
  if High(ArrayFilters.Filters) >= 0 then
    s += ' WHERE ';
  for i := 0 to High(ArrayFilters.Filters) do
  begin
    Ind := ArrayFilters.Filters[i].ColName.ItemIndex;
    if (Table[Tag].Columns[Ind].Ref <> '') then
    begin
      Tbl := Table[Tag].Columns[Ind].RefVal;
      Col := Table[Tag].Columns[Ind].Ref;
    end
    else
    begin
      Tbl := Table[Tag].TableNameEng;
      Col := Table[Tag].Columns[Ind].NameEng;
    end;

    if ArrayFilters.Filters[i].cmp.Text = include then
    begin
      s += 'POSITION( :value' + IntToStr(i) + ', ';
      s += Tbl + '.' + Col + ') > 0 ';
    end
    else
    begin
      s += Tbl + '.' + Col + ' ';
      s += ArrayFilters.Filters[i].cmp.Text + ' ' +  ' :value' + IntToStr(i);
    end;
    if i <> High(ArrayFilters.Filters) then
      s += ' AND ';
  end;
  s += OrderByPar;
  SendQuery(s);
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
    if SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value = Tags[i]  then
    begin
      EditingForm[i].SetFocus;
      exit;
    end;

  SetLength(EditingForm, Length(EditingForm) + 1);
  if FlagAdd then
    EditingForm[High(EditingForm)] := TFormEdit.Init(Self, -1, Table[Tag])
  else
    EditingForm[High(EditingForm)] := TFormEdit.Init(Self, SQLQuery.FieldByName('ID').Value, Table[Tag]);
  EditingForm[High(EditingForm)].Show;
  SQLQuery.Open;

  SetLength(Tags, Length(Tags) + 1);
  Tags[High(Tags)] := SQLQuery.FieldByName(Table[Tag].Columns[0].NameRus).Value;

  EditingForm[High(EditingForm)].Tag := High(Tags);
  EditingForm[High(EditingForm)].Tags := Tags;
  EditingForm[High(EditingForm)].ApplyProc := @ApplyFilterClick;

  for i := 1 to High(Table[Tag].Columns) do
    if Table[Tag].Columns[i].Ref <> '' then
      EditingForm[High(EditingForm)].CreateNewFieldsWithField(Table[Tag], i, SQLQuery.FieldByName('ID').Value)
    else
      EditingForm[High(EditingForm)].CreateNewFields(Table[Tag], i, SQLQuery.FieldByName('ID').Value);
  FlagAdd := False;
end;

end.

