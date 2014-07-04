unit FormForHandbooks;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, DB, FileUtil, Forms, Controls,
  Graphics, Dialogs, DBGrids, StdCtrls, Menus, Spin, Buttons, metadata, Grids;

type

TDataToFilter = class(TObject)
  Table, Column, DataType: string;
end;

TFilter = class(TObject)
  ColName: TComboBox;
  cmp: TComboBox;
  FilterVal: TEdit;
  FilterValInt: TSpinEdit;
  DataType: string;
  TableNumber: integer;
  procedure OnColumnChange (Sender: TObject);
  procedure Assign(Filter: TFilter);
  constructor Create(Ind: integer; Sender: TObject; TableNum: integer);
end;

TForm2 = class(TForm)
  DS: TDataSource;
  SQLQuery: TSQLQuery;
  T: TDBGrid;
  SQLTr: TSQLTransaction;
  IBCon: TIBConnection;
  BCreateNewFilter, ApplyFilter: TButton;
  CheckBoxApply: TCheckBox;
  LabelApply: TLabel;
  ScrollBox: TScrollBox;
  procedure MyOnDoubleClick (Sender: TObject);
  procedure SendQuery(s: string);
  function MakeQuery: string;
  procedure MyOnResize(Sender: TObject);
  procedure CreateNewFilter(Sender: TObject);
  procedure ApplyFilterOnClick(Sender: TObject);
  procedure RemoveFilterOnClick (Sender: TObject);
  procedure MyOnTitleClick (Column: TColumn);
  constructor CreateNew (Sender: TComponent);
public
  DataToFilter: array of TDataToFilter;
private
  LastPar:  string;
  FlagSortOrder: boolean;
  OrderByPar: string;
  Filters: array of TFilter;
  BRemoveFilter: array of TSpeedButton;
end;

TFormForEditing = class(TForm)
public
  StringEditor: array of TEdit;
  IntEditor: array of TSpinEdit;
end;

const
  include: string = 'включает';

implementation

procedure TForm2.MyOnDoubleClick (sender: TObject);
begin

end;

constructor TForm2.CreateNew (Sender: TComponent);
begin
  inherited;
  T := TDBGrid.Create(Self);
  T.Left := 0;
  T.Top := 0;
  T.Width := Width - 390;
  T.Height := Height;
  T.Parent := Self;

  CheckBoxApply := TCheckBox.Create(Self);
  CheckBoxApply.Parent := Self;
  CheckBoxApply.Width := 30;
  CheckBoxApply.Height := 30;
  CheckBoxApply.Left := T.Width + 30;
  CheckBoxApply.Top := 65;
  CheckBoxApply.Checked := True;
  CheckBoxApply.Enabled := False;
  CheckBoxApply.Caption := 'фильтры применены';

  ScrollBox := TScrollBox.Create(Self);
  ScrollBox.Parent := Self;
  ScrollBox.Left := T.Width + 2;
  ScrollBox.VertScrollBar.Tracking:= true;
  ScrollBox.Width := 375;
  ScrollBox.Top := CheckBoxApply.Top + CheckBoxApply.Height + 35;

  SQLTr := TSQLTransaction.Create(Self);
  IBCon := TIBConnection.Create(Self);
  IBCon.DatabaseName := 'C:\database\NEWDB.FDB';
  IBCon.Password := 'masterkey';
  IBCon.UserName := 'SYSDBA';
  SQLTr.DataBase := IBCon;
  SQLQuery := TSQLQuery.Create(self);
  SQLQuery.Transaction := SQLTr;
  SQLQuery.DataBase := IBCon;
  DS := TDataSource.Create(Self);
  DS.DataSet := SQLQuery;
  T.DataSource := DS;

  Position := poScreenCenter;
  Width := 1000;
  Height := 500;

  OnResize := @MyOnResize;
  BCreateNewFilter := TButton.Create(Self);
  BCreateNewFilter.Parent := Self;
  BCreateNewFilter.Left := 2;
  BCreateNewFilter.Top := 25;
  BCreateNewFilter.Width := 130;
  BCreateNewFilter.Height := 35;
  BCreateNewFilter.Caption := 'Добавить Фильтр';
  BCreateNewFilter.OnClick := @CreateNewFilter;

  ApplyFilter := TButton.Create(Self);
  ApplyFilter.Parent := Self;
  ApplyFilter.Left := T.Width + 210;
  ApplyFilter.Top := 25;
  ApplyFilter.Width := 130;
  ApplyFilter.Height := 35;
  ApplyFilter.Caption := 'Применить Фильтры';
  ApplyFilter.OnClick := @ApplyFilterOnClick;

  T.OnTitleClick := @MyOnTitleClick;
  OrderByPar := '';
  Show;
end;

procedure TFOrm2.CreateNewFilter(Sender: TObject);
begin
  CheckBoxApply.Checked := False;
  SetLength(BRemoveFilter, Length(BRemoveFilter) + 1);
  BRemoveFilter[High(BRemoveFilter)] := TSpeedButton.Create(Self);
  BRemoveFilter[High(BRemoveFilter)].Height := 23;
  BRemoveFilter[High(BRemoveFilter)].Width := 23;
  BRemoveFilter[High(BRemoveFilter)].Top := (High(BRemoveFilter)) * 50 + 10;
  BRemoveFilter[High(BRemoveFilter)].Parent := ScrollBox;
  BRemoveFilter[High(BRemoveFilter)].Caption := 'X';
  BRemoveFilter[High(BRemoveFilter)].Tag := High(BRemoveFilter);
  BRemoveFilter[High(BRemoveFilter)].OnClick := @Self.RemoveFilterOnClick;
  BRemoveFilter[High(BRemoveFilter)].Left := 2;

  SetLength(Filters, Length(Filters) + 1);
  Filters[High(Filters)] := TFilter.Create(High(Filters), Self, Tag);
  self.OnResize(Sender);
end;

procedure TForm2.MyOnResize(Sender: TObject);
var
  i: integer;
begin
  T.Height := Height;
  T.Width := Width - 390;
  BCreateNewFilter.Left := T.Width + 30;
  ApplyFilter.Left := T.Width + 210;
  CheckBoxApply.Left := T.Width + 30;
  ScrollBox.Left := T.Width + 2;
  ScrollBox.Height := Self.Height - CheckBoxApply.Top - 65;
end;

procedure TForm2.MyOnTitleClick(Column: TColumn);
begin
  OrderByPar := Column.FieldName;
  if not (LastPar = Column.FieldName) then
  begin
    LastPar := Column.FieldName;
    FlagSortOrder := False;
  end
  else
    FlagSortOrder := not(FlagSortOrder);
  ApplyFilterOnClick(self);
end;

procedure TForm2.RemoveFilterOnClick (sender: TObject);
var
  i: integer;
begin
  CheckBoxApply.Checked := False;
  for i := (sender as TSpeedButton).Tag to High(Filters) - 1 do
  begin
    Filters[i].Assign(Filters[i + 1]);
    BRemoveFilter[i].Tag := i;
  end;
  BRemoveFilter[High(BRemoveFilter)].Destroy;
  Filters[High(Filters)].cmp.Destroy;
  Filters[High(Filters)].ColName.Destroy;
  Filters[High(Filters)].FilterVal.Destroy;
  Filters[High(Filters)].FilterValInt.Destroy;
  Filters[High(Filters)].Destroy;
  SetLength(Filters, Length(Filters) - 1);
  SetLength(BRemoveFilter, Length(BRemoveFilter) - 1);
end;

/////////////////////////////////////////////////////////////////////////////////////////////////////////

procedure TForm2.SendQuery (s: string);
var
  TableWidth: array of integer;
  i: integer;
  TableNum: integer;
begin
  TableNum := Tag;
  SQLQuery.Close;
  SQLQuery.SQL.Text := s;
  SQLQuery.Open;
  for i := 0 to High(Table[TableNum].Columns) do
  begin
    SetLength(TableWidth, Length(TableWidth) + 1);
    TableWidth[High(TableWidth)] := Table[TableNum].Columns[i].Width;
  end;
  for i := 0 to High(Table[TableNum].Columns) do
    T.Columns.Items[i].Width := TableWidth[i];
end;

function TForm2.MakeQuery: string;
var
  TableNum, i: integer;
  s: string;
begin
  TableNum := Tag;
  s := 'SELECT ';
  for i := 0 to High(Table[TableNum].Columns) do
  begin
    if Table[TableNum].Columns[i].Ref <> '' then
    begin
      s += Table[TableNum].Columns[i].Ref + '.' + Table[TableNum].Columns[i].RefVal;
      if (OrderByPar = Table[TableNum].Columns[i].NameRus) then
      begin
        OrderByPar := ' ORDER BY ' + Table[TableNum].Columns[i].Ref;
        OrderByPar += '.' + Table[TableNum].Columns[i].RefVal;
      end;
    end
    else
    begin
      s += Table[TableNum].TableNameEng + '.' + Table[TableNum].Columns[i].NameEng;
      if (OrderByPar = Table[TableNum].Columns[i].NameRus) then
      begin
        OrderByPar := ' ORDER BY ' + Table[TableNum].TableNameEng;
        OrderByPar += '.' +  Table[TableNum].Columns[i].NameEng;
      end;
    end;
    s += ' as "' + Table[TableNum].Columns[i].NameRus + '"';
    if (i < High(Table[TableNum].Columns)) then
      s += ', ';
  end;
  s += ' FROM ' + Table[TableNum].TableNameEng;
  for i := 0 to High(Table[TableNum].Columns) do
    if Table[TableNum].Columns[i].Ref <> '' then
    begin
      s += ' INNER JOIN ' + Table[TableNum].Columns[i].Ref + ' ON ';
      s += Table[TableNum].TableNameEng + '.';
      s += Table[TableNum].Columns[i].NameEng + ' = ';
      s += Table[TableNum].Columns[i].Ref + '.';
      s += Table[TableNum].Columns[i].RefPar;
    end;
  s += OrderByPar;
  if FlagSortOrder then
    s += ' ' + 'desc';
  result := s;
end;

procedure TForm2.ApplyFilterOnClick(Sender: TObject);
var
  s: string;
  i: integer;
begin
  CheckBoxApply.Checked := True;
  s := MakeQuery;
  if High(Filters) >= 0 then
    s += ' WHERE ';
  for i := 0 to High(Filters) do
  begin
    if Filters[i].cmp.Text = include then
    begin
      s += 'POSITION(';
      s += char(39) + Filters[i].FilterVal.Text + char(39) + ', ';
      s += DataToFilter[Filters[i].ColName.ItemIndex].Table + '.';
      s += DataToFilter[Filters[i].ColName.ItemIndex].Column + ') > 0 ';
    end
    else
    begin
      s += DataToFilter[Filters[i].ColName.ItemIndex].Table + '.';
      s += DataToFilter[Filters[i].ColName.ItemIndex].Column + ' ';
      s += Filters[i].cmp.Text + ' ';
      if Filters[i].DataType = 'Int' then
        s += Filters[i].FilterValInt.Text
      else
        s += char(39) + Filters[i].FilterVal.Text + char(39);
    end;
    if i <> High(Filters) then
      s += ' AND ';
  end;
  SendQuery(s);
end;


//////////////////////////////////////////////////////////////////////////////////////////////////


{Filter}

procedure TFilter.assign (Filter: TFilter);
begin
  ColName.ItemIndex := Filter.ColName.ItemIndex;
  cmp.ItemIndex := Filter.cmp.ItemIndex;
  FilterVal.Caption := Filter.FilterVal.Caption;
  FilterVal.Visible := Filter.FilterVal.Visible;
  FilterValInt.Caption := Filter.FilterValInt.Caption;
  FilterValInt.Visible := Filter.FilterValInt.Visible;
  DataType := Filter.DataType;
  TableNumber := Filter.TableNumber;
end;

procedure TFilter.OnColumnChange (Sender: TObject);
var
  i, j: integer;
begin
  for i := 0 to High(Table[TableNumber].Columns) do
    if Table[TableNumber].Columns[i].NameRus = ColName.Text then
    begin
      DataType := Table[TableNumber].Columns[i].DataType;
      FilterVal.Visible := False;
      FilterValInt.Visible := False;
      if DataType = 'Int' then
      begin
        FilterValInt.Visible := true;
        cmp.Items.Clear;
        cmp.Items.Add('=');
        cmp.Items.Add('>');
        cmp.Items.Add('<');
        cmp.ItemIndex := 0;
      end
      else
      begin
        FilterVal.Visible := true;
        cmp.Items.Clear;
        cmp.Items.Add('=');
        cmp.Items.Add('>');
        cmp.Items.Add('<');
        cmp.Items.Add(include);
        cmp.ItemIndex := 0;
      end;
    end;
end;

constructor TFilter.Create(Ind: integer; Sender: TObject; TableNum: integer);
var
  i: integer;
begin
  TableNumber := TableNum;
  ColName := TComboBox.Create(Sender as TForm2);
  ColName.Top := Ind * 50 + 10;
  ColName.Width := 100;
  ColName.Height := 30;
  ColName.Left := 30;
  ColName.Parent := (Sender as TForm2).ScrollBox;
  for i := 0 to High(Table[(Sender as TForm2).Tag].Columns) do
    ColName.Items.Add(Table[(Sender as TForm2).Tag].Columns[i].NameRus);
  ColName.Style := csDropDownList;
  ColName.ItemIndex := 0;
  ColName.OnChange := @OnColumnChange;

  FilterValInt := TSpinEdit.Create(Sender as TForm2);
  FilterValInt.Top := Ind * 50 + 10;
  FilterValInt.Width := 100;
  FilterValInt.Height := 30;
  FilterValInt.Parent := (Sender as TForm2).ScrollBox;
  FilterValInt.Visible := False;
  FilterValInt.Left := 240;

  FilterVal := TEdit.Create((Sender as TForm2).ScrollBox);
  FilterVal.Top := Ind * 50 + 10;
  FilterVal.Width := 100;
  FilterVal.Height := 30;
  FilterVal.Parent := (Sender as TForm2).ScrollBox;
  FilterVal.Text := '';
  FilterVal.Left := 240;

  cmp := TComboBox.Create((Sender as TForm2).ScrollBox);
  cmp.Top := Ind * 50 + 10;
  cmp.Width := 60;
  cmp.Height := 30;
  cmp.Parent := (Sender as TForm2).ScrollBox;
  cmp.Style := csDropDownList;
  cmp.Left := 160;
  Self.OnColumnChange(sender);
end;

end.

