unit UQuery;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, metadata, Filters, sqldb, DBCtrls, Dialogs;

function MakeQuery(Table: TTableInfo; OrderByPar: string; FlagSortOrder: boolean;
  ArrayFilters: TArrayFilters): string;

procedure ApplyQuery(SqlQuery: TSQLQuery; StrQuery: string; ArrayFilters: TArrayFilters);

procedure ReturnTblAndCol (table: TTableInfo; ind: integer; var RefTable: string; var RefColumn: string);

implementation


procedure ReturnTblAndCol (table: TTableInfo; ind: integer; var RefTable: string; var RefColumn: string);
begin
  if (table.Columns[ind].Ref <> '') then
  begin
    RefTable := table.Columns[ind].Ref;
    RefColumn := table.Columns[ind].RefVal;
  end
  else
  begin
    RefTable := table.TableNameEng;
    RefColumn := table.Columns[ind].NameEng;
  end;
end;

function MakeQuery(Table: TTableInfo; OrderByPar: string; FlagSortOrder: boolean;
  ArrayFilters: TArrayFilters): string;
var
  s, Tbl, Col, inner_join: string;
  Ind, i: integer;
begin
  inner_join := '';
  s := 'SELECT ';
  for i := 0 to High(Table.Columns) do
  begin
    if Table.Columns[i].Ref <> '' then
    begin
      s += Table.Columns[i].Ref + '.' + Table.Columns[i].RefVal;
      if (OrderByPar = Table.Columns[i].NameRus) then
        OrderByPar := ' ORDER BY ' + Table.Columns[i].Ref + '.' +
          Table.Columns[i].RefVal;
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
      inner_join += ' INNER JOIN ' + Table.Columns[i].Ref + ' ON ' +
        Table.TableNameEng + '.';
      inner_join += Table.Columns[i].NameEng + ' = ' + Table.Columns[i].Ref + '.';
      inner_join += Table.Columns[i].RefPar;
    end;

  if FlagSortOrder then
    OrderByPar += ' ' + 'desc';
  s += inner_join;

  if High(ArrayFilters.Filters) >= 0 then
    s += ' WHERE ';
  for i := 0 to High(ArrayFilters.Filters) do
  begin
    Ind := ArrayFilters.Filters[i].ColName.ItemIndex;
    ReturnTblAndCol(Table, Ind, Tbl, Col);

    if ArrayFilters.Filters[i].cmp.Text = include then
    begin
      s += 'POSITION( :value' + IntToStr(i) + ', ';
      s += Tbl + '.' + Col + ') > 0 ';
    end
    else
    begin
      s += Tbl + '.' + Col + ' ';
      s += ArrayFilters.Filters[i].cmp.Text + ' ' + ' :value' + IntToStr(i);
    end;
    if i <> High(ArrayFilters.Filters) then
      s += ' AND ';
  end;
  s += OrderByPar;
  Result := s;
end;

procedure ApplyQuery(SqlQuery: TSQLQuery; StrQuery: string; ArrayFilters: TArrayFilters);
var
  i: integer;
begin
  SQLQuery.Close;
  SQLQuery.SQL.Text := StrQuery;
  for i := 0 to High(ArrayFilters.Filters) do
  begin
    SQLQuery.ParamByName('value' + IntToStr(i)).AsString :=
      ArrayFilters.Filters[i].FilterVal.Text;
  end;
  SQLQuery.Open;
end;

end.
