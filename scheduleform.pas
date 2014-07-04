unit ScheduleForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, DB, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Grids, DBCtrls, ColorBox, SqlComponents, metadata,
  Filters, UQuery;

type

  { ItemForSchedule }

  TItemForSchedule = class(TObject)
    Item: array of TStringList;
    Id: integer;
    Height: integer;
    procedure Next;
    procedure Add(S: String);
  public
    Count: Integer;
  end;

  TMyList = array of string;
  { TFShedule }

  TFShedule = class(TForm)
    Apply: TButton;
    addFilter: TButton;
    Datasource1: TDatasource;
    AxisY: TComboBox;
    AxisX: TComboBox;
    OutputField: TCheckGroup;
    DrawGrid1: TDrawGrid;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    SQLQuery1: TSQLQuery;
    procedure FindRefAndColumn(Axis: TComboBox; var RefTable: string;
      var RefColumn: string; var RusColName: string; ind: integer);
    procedure addFilterClick(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure DrawGrid1DrawCell(Sender: TObject; aCol, aRow: integer;
      aRect: TRect; aState: TGridDrawState);
    procedure FormCreate(Sender: TObject);
  private
    procedure AxisQuery(RefTable: string; RefColumm: string;
      var List: TMyList; var Count: integer);
    { private declarations }
  public
    FlagApply: boolean;
    ScheduleArray: array of array of TItemForSchedule;
    OXRefTable, OYRefTable, OXRefColumn, OYRefColumn, OxColName, OyColName: string;
    OxCount, OyCount: integer;
    ArrayFilters: TArrayFilters;
    SchTable: TTableInfo;
    { public declarations }
  end;

var
  FShedule: TFShedule;
const
  DistToNextLine = 14;
implementation

{ ItemForSchedule }

procedure TItemForSchedule.Next;
begin
  SetLength(Item, Length(Item) + 1);
  Item[High(Item)] := TStringList.Create;
  inc(Count);
end;

procedure TItemForSchedule.Add(S: String);
begin
  if Count = 0 then
    Next;
  Item[High(Item)].Add(S);
  if Item[High(Item)].Count > Height then
    Height := Item[High(Item)].Count;
end;

{$R *.lfm}

{ TFShedule }

procedure TFShedule.FormCreate(Sender: TObject);
var
  i: integer;
begin
  SchTable := Table[5];
  ArrayFilters := TArrayFilters.Create;
  for i := 1 to High(SchTable.Columns) do
  begin
    AxisX.Items.Add(SchTable.Columns[i].NameRus);
    AxisX.ItemIndex := 0;
    AxisY.Items.Add(SchTable.Columns[i].NameRus);
    AxisY.ItemIndex := 0;
    OutputField.Items.Add(SchTable.Columns[i].NameRus);
    OutputField.Checked[i - 1] := true;
  end;
  FlagApply := false;
end;

procedure TFShedule.addFilterClick(Sender: TObject);
begin
  ArrayFilters.AddFilter(5, ScrollBox1);
end;

procedure TFShedule.FindRefAndColumn(Axis: TComboBox; var RefTable: string;
  var RefColumn: string; var RusColName: string; ind: integer);
begin
  if SchTable.Columns[ind].NameRus = Axis.Caption then
  begin
    ReturnTblAndCol(SchTable, Ind, RefTable, RefColumn);
    RusColName := SchTable.Columns[ind].NameRus;
  end;
end;

procedure TFShedule.AxisQuery(RefTable: string; RefColumm: string;
  var List: TMyList; var Count: integer);
var
  LastStr: string;
  i: integer;
begin
  SQLQuery1.Close;
  SQLQuery1.SQL.Text := 'SELECT ' + RefTable + '.' + RefColumm +
    ' FROM ' + RefTable + ' Order by ' + RefTable + '.' + RefColumm;
  SQLQuery1.Open;
  LastStr := '';
  for i := 0 to SQLQuery1.RowsAffected do
  begin
    if LastStr <> SQLQuery1.FieldByName(RefColumm).AsString then
    begin
      Inc(Count);
      LastStr := SQLQuery1.FieldByName(RefColumm).AsString;
      SetLength(List, Count);
      List[Count - 1] := LastStr;
    end;
    SQLQuery1.Next;
  end;
end;

procedure TFShedule.ApplyClick(Sender: TObject);
var
  i, j, q, counter: integer;
  flagbreak: boolean;
  MainQuery: string;
  OxList, OyList: array of string;
begin
  if FlagApply then
  for i := 0 to OxCount do
    for j := 0 to OyCount do
      ScheduleArray[i][j].Destroy;

  FlagApply := True; OxCount := 0; OyCount := 0;

  for i := 0 to High(SchTable.Columns) do
  begin
    FindRefAndColumn(AxisX, OXRefTable, OXRefColumn, OxColName, i);
    FindRefAndColumn(AxisY, OYRefTable, OYRefColumn, OyColName, i);
  end;

  AxisQuery(OXRefTable, OXRefColumn, OxList, OxCount);
  AxisQuery(OYRefTable, OYRefColumn, OyList, OyCount);

  SetLength(ScheduleArray, OxCount + 1);
  for i := 0 to OxCount do
    SetLength(ScheduleArray[i], OyCount + 1);

  for i := 0 to OxCount do
    for j := 0 to OyCount do
    begin
      ScheduleArray[i, j] := TItemForSchedule.Create;
      if (i = 0) and (j <> 0) then
        ScheduleArray[i, j].Add(OyList[j - 1]);
      if (i <> 0) and (j = 0) then
        ScheduleArray[i, j].Add(OxList[i - 1]);
    end;
  DrawGrid1.ColCount := OxCount + 1;
  DrawGrid1.RowCount := OyCount + 1;
  DrawGrid1.FixedCols := 1;
  DrawGrid1.FixedRows := 1;

  MainQuery := MakeQuery(SchTable, ' ORDER BY ' + OXRefTable + '.' + OXRefColumn +
    ', ' + OYRefTable + '.' + OYRefColumn, False, ArrayFilters);
  ApplyQuery(SQLQuery1, MainQuery, ArrayFilters);
  i := -1; j := 0; counter := 0; flagbreak := false;

  while i < OxCount do
  begin
    j := 0;
    inc(i);
    while j < OyCount do
      begin
        while (SQLQuery1.FieldByName(OyColName).AsString <> OyList[j]) and (j <> OyCount) do
          inc(j);
        if (SQLQuery1.FieldByName(OyColName).AsString <> OyList[j]) or
          (SQLQuery1.FieldByName(OxColName).AsString <> OxList[i]) then
          break;
        //ScheduleArray[i + 1, j + 1].Next;
        for q := 0 to OutputField.Items.Count - 1 do
          if OutputField.Checked[q] then
          begin
            ScheduleArray[i + 1, j + 1].Add(OutputField.Items[q] + ': '
              + SQLQuery1.FieldByName(OutputField.Items[q]).AsString);
          end;
        if counter = SQLQuery1.RowsAffected then
        begin
           i := OxCount;
           j := OyCount;
        end;
        SQLQuery1.Next;
        inc(counter);
      end;
  end;
  DrawGrid1.Invalidate;
end;

procedure TFShedule.DrawGrid1DrawCell(Sender: TObject; aCol, aRow: integer;
  aRect: TRect; aState: TGridDrawState);
var
  i, j: Integer;
begin
  DrawGrid1.ColWidths[aCol] := 230;
  if (DrawGrid1.RowHeights[aRow] < ScheduleArray[aCol, aRow].Height * DistToNextLine) then
    DrawGrid1.RowHeights[aRow] := ScheduleArray[aCol, aRow].Height * DistToNextLine;
  for i := 0 to ScheduleArray[aCol, aRow].Count - 1 do
    for j := 0 to ScheduleArray[aCol, aRow].Item[i].Count - 1 do
      DrawGrid1.Canvas.TextOut(aRect.Left, aRect.Top + j * DistToNextLine, ScheduleArray[aCol, aRow].Item[i][j]);
end;

end.
