unit UCatalogs;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, DBGrids, StdCtrls, SqlComponents, metadata, Spin, Buttons;

type

  TCatalog = class;

  {TFilter}

  TFilter = class(TObject)
    FormCatalog: TCatalog;
    ColName: TComboBox;
    cmp: TComboBox;
    FilterVal: TCustomEdit;
    BRemove: TSpeedButton;
    DataType: string;
    TableNumber: integer;
    procedure OnColumnChange(Sender: TObject);
    constructor Create(Ind: integer; TableNum: integer; Form: TCatalog);
  end;

  { TCatalog }

  TCatalog = class(TForm)
    AddField: TButton;
    Datasource: TDatasource;
    RemoveFilter: TButton;
    AddFilter: TButton;
    ApplyFilter: TButton;
    DBGrid1: TDBGrid;
    SQLQuery: TSQLQuery;
    ToolPanel: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    procedure ApplyFilterClick(Sender: TObject);
    procedure DBGrid1TitleClick(Column: TColumn);
    procedure RemoveF (Sender: TObject);
    procedure AddFilterClick(Sender: TObject);
    function MakeQuery(Table: TTableInfo): string;
    procedure SendQuery(s: string);
  private
    Filters: array of TFilter;
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
  for i := 0 to High(Filters) do
    SQLQuery.ParamByName('value' + IntToStr(i)).AsString := Filters[i].FilterVal.Text;
  ShowMessage(s);
  SQLQuery.Open;
  for i := 0 to High(Table[Tag].Columns) do
    DBGrid1.Columns.Items[i].Width := Table[Tag].Columns[i].Width;
  ApplyFilter.Enabled := False;
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

procedure TCatalog.AddFilterClick(Sender: TObject);
begin
  SetLength(Filters, Length(Filters) + 1);
  Filters[High(Filters)] := TFilter.Create(High(Filters), Tag, Self);
end;

procedure TCatalog.RemoveF(Sender: TObject);
var
  i, Index: integer;
begin
  ApplyFilter.Enabled := True;
  Index := (Sender as TSpeedButton).Tag;
  Filters[Index].cmp.Destroy;
  Filters[Index].ColName.Destroy;
  Filters[Index].FilterVal.Destroy;
  Filters[Index].Destroy;
  Filters[Index].BRemove.Destroy;
  for i := Index to High(Filters) - 1 do
  begin
    Filters[i] := Filters[i + 1];
    Filters[i].BRemove.Tag := i;
    Filters[i].cmp.Top := i * 50 + 10;
    Filters[i].FilterVal.Top := i * 50 + 10;
    Filters[i].BRemove.Top := i * 50 + 10;
    Filters[i].ColName.Top := i * 50 + 10;
  end;
  SetLength(Filters, Length(Filters) - 1);
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

procedure TCatalog.ApplyFilterClick(Sender: TObject);
var
  s, Col, Tbl: string;
  i, Ind: integer;
begin
  s += MakeQuery(Table[Tag]);
  if High(Filters) >= 0 then
    s += ' WHERE ';


  for i := 0 to High(Filters) do
  begin
    Ind := Filters[i].ColName.ItemIndex;
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

    if Filters[i].cmp.Text = include then
    begin
      s += 'POSITION( :value' + IntToStr(i) + ', ';
      s += Tbl + '.' + Col + ') > 0 ';
    end
    else
    begin
      s += Tbl + '.' + Col + ' ';
      s += Filters[i].cmp.Text + ' ' +  ' :value' + IntToStr(i);
    end;
    if i <> High(Filters) then
      s += ' AND ';
  end;
  s += OrderByPar;
  if FlagSortOrder then
    s += ' ' + 'desc';
  SendQuery(s);
end;

////////////////////////////////////////////Filters\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

procedure TFilter.OnColumnChange(Sender: TObject);
var
  i, j: integer;
begin
  FormCatalog.ApplyFilter.Enabled := True;
  for i := 0 to High(Table[TableNumber].Columns) do
    if Table[TableNumber].Columns[i].NameRus = ColName.Text then
    begin
      DataType := Table[TableNumber].Columns[i].DataType;
      FilterVal.Destroy;
      cmp.Items.Clear;
      cmp.Items.Add('=');
      cmp.Items.Add('>');
      cmp.Items.Add('<');
      cmp.ItemIndex := 0;
      if DataType = 'Int' then
        FilterVal := TSpinEdit.Create(FormCatalog)
      else
      begin
        FilterVal := TEdit.Create(FormCatalog);
        cmp.Items.Add(include);
      end;
      FilterVal.Top := BRemove.Tag * 50 + 10;
      FilterVal.Width := 100;
      FilterVal.Height := 30;
      FilterVal.Left := 200;
      FilterVal.Parent := FormCatalog.ScrollBox1;
    end;
end;

constructor TFilter.Create(Ind: integer; TableNum: integer; Form: TCatalog);
var
  i: integer;
begin
  FormCatalog := Form;

  TableNumber := TableNum;
  ColName := TComboBox.Create(Form);
  ColName.Top := Ind * 50 + 10;
  ColName.Width := 100;
  ColName.Height := 30;
  ColName.Left := 30;
  ColName.Parent := (Form).ScrollBox1;
  for i := 0 to High(Table[(Form).Tag].Columns) do
    ColName.Items.Add(Table[(Form).Tag].Columns[i].NameRus);
  ColName.Style := csDropDownList;
  ColName.ItemIndex := 0;
  ColName.OnChange := @OnColumnChange;

  cmp := TComboBox.Create((Form).ScrollBox1);
  cmp.Top := Ind * 50 + 10;
  cmp.Width := 60;
  cmp.Height := 30;
  cmp.Parent := (Form).ScrollBox1;
  cmp.Style := csDropDownList;
  cmp.Left := 135;

  BRemove := TSpeedButton.Create(Form.ScrollBox1);
  BRemove.Height := 23;
  BRemove.Width := 23;
  BRemove.Top := Ind * 50 + 10;
  BRemove.Parent := Form.ScrollBox1;
  BRemove.Caption := 'X';
  BRemove.Tag := Ind;
  BRemove.OnClick := @Form.RemoveF;
  BRemove.Left := 2;

  FilterVal := TEdit.Create(BRemove);

  OnColumnChange(Self);
end;

end.
