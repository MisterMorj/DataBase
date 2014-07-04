unit Filters;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, DBGrids, StdCtrls, SqlComponents, metadata, Spin, Buttons;

type

Tproc = procedure (Sender: TObject) of object;

TFilter = class(TObject)
  NewComp: TWinControl;
  ColName: TComboBox;
  cmp: TComboBox;
  FilterVal: TCustomEdit;
  BRemove: TSpeedButton;
  DataType: string;
  TableNumber: integer;
  procedure OnColumnChange(Sender: TObject);
  constructor Create(Ind: integer; TableNum: integer; Parent: TWinControl; ProcRemove: TProc);
end;

TArrayFilters = class(TObject)
  Filters: array of TFilter;
  procedure AddFilter(TableNum: integer; Parent: TWinControl);
  procedure RemoveFilter(Sender: TObject);
end;

implementation

procedure TArrayFilters.AddFilter(TableNum: integer; Parent: TWinControl);
begin
  SetLength(Filters, Length(Filters) + 1);
  Filters[High(Filters)] := TFilter.Create(High(Filters), TableNum, Parent, @RemoveFilter);
end;

procedure TArrayFilters.RemoveFilter(Sender: TObject);
var
  i, Index: integer;
begin
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



procedure TFilter.OnColumnChange(Sender: TObject);
var
  i, j: integer;
begin
  for i := 0 to High(Table[TableNumber].Columns) do
    if Table[TableNumber].Columns[i].NameRus = ColName.Text then
    begin
      FilterVal.Destroy;
      cmp.Items.Clear;
      cmp.Items.Add('=');
      cmp.Items.Add('>');
      cmp.Items.Add('<');
      cmp.ItemIndex := 0;
      if Table[TableNumber].Columns[i].DataType = ftInteger then
      begin
        FilterVal := TSpinEdit.Create(NewComp);
        (FilterVal as TSpinEdit).MaxValue := 10000000;
      end
      else
      begin
        FilterVal := TEdit.Create(NewComp);
        cmp.Items.Add(include);
      end;
      FilterVal.Top := BRemove.Tag * 50 + 10;
      FilterVal.Width := 100;
      FilterVal.Height := 30;
      FilterVal.Left := 200;
      FilterVal.Parent := NewComp;
    end;
end;

constructor TFilter.Create(Ind: integer; TableNum: integer; Parent: TWinControl; ProcRemove: TProc);
var
  i: integer;
begin
  NewComp := Parent;
  TableNumber := TableNum;
  ColName := TComboBox.Create(Parent);
  ColName.Top := Ind * 50 + 10;
  ColName.Width := 100;
  ColName.Height := 30;
  ColName.Left := 30;
  ColName.Parent := Parent;
  for i := 0 to High(Table[TableNum].Columns) do
    ColName.Items.Add(Table[TableNum].Columns[i].NameRus);
  ColName.Style := csDropDownList;
  ColName.ItemIndex := 0;
  ColName.OnChange := @OnColumnChange;

  cmp := TComboBox.Create(Parent);
  cmp.Top := Ind * 50 + 10;
  cmp.Width := 60;
  cmp.Height := 30;
  cmp.Parent := Parent;
  cmp.Style := csDropDownList;
  cmp.Left := 135;

  BRemove := TSpeedButton.Create(Parent);
  BRemove.Height := 23;
  BRemove.Width := 23;
  BRemove.Top := Ind * 50 + 10;
  BRemove.Parent := Parent;
  BRemove.Caption := 'X';
  BRemove.Tag := Ind;
  BRemove.OnClick := ProcRemove;
  BRemove.Left := 2;

  FilterVal := TEdit.Create(BRemove);

  OnColumnChange(Self);
end;

end.

