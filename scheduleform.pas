unit ScheduleForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, DB, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Grids, DBCtrls, ColorBox, SqlComponents, metadata,
  Filters, UQuery, types, UCatalogs, Spin, Buttons, Ueditingform, math;

type

  { ItemForSchedule }

  { TControlButtons }

  TControlButtons = class(TObject)
    ID: integer;
    Table: TTableInfo;
    ViewItem: TSpeedButton;
    EditItem: TSpeedButton;
    DeleteItem: TSpeedButton;
    AddNewItem: TSpeedButton;
    constructor create(Sender: TWinControl; AId: Integer; ATable: TTableInfo);
    procedure MyClickVeiwItem (Sender: TObject);
    procedure MyClickEditItem(Sender: TObject);
    procedure MyClickDeleteItem (Sender: TObject);
  private
    procedure move(x, y: integer);
    procedure MyClickAddNewItem(Sender: TObject);
  end;

  { TItemForSchedule }

  TItemForSchedule = class(TObject)
    FlagClick: boolean;
    Item: array of TStringList;
    Id: array of integer;
    ControlButtons: array of TControlButtons;
    TotalHeight: integer;
    procedure Next(NewId: integer; Sender: TComponent; var OneItemHeight: Integer);
    procedure Add(S: String; sender: TComponent; var OneItemHeight: integer);
  private
  public
    Count: Integer;
  end;

  TMyList = array of string;
  { TFShedule }

  TFShedule = class(TForm)
    Apply: TButton;
    addFilter: TButton;
    Datasource1: TDatasource;
    AxisYCB: TComboBox;
    AxisXCB: TComboBox;
    ImageList1: TImageList;
    OutputField: TCheckGroup;
    DG: TDrawGrid;
    AxisXName: TLabel;
    AxisYName: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    SQLQuery1: TSQLQuery;
    TimerExtension: TTimer;
    TimerCollapsing: TTimer;
    procedure DGMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure DGMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FindRefAndColumn(Axis: TComboBox; var RefTable: string;
      var RefColumn: string; var RusColName: string; ind: integer);
    procedure addFilterClick(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure DGDrawCell(Sender: TObject; aCol, aRow: integer;
      aRect: TRect; aState: TGridDrawState);
    procedure FormCreate(Sender: TObject);
    procedure TimerExtensionTimer(Sender: TObject);
    procedure TimerCollapsingTimer(Sender: TObject);
  private
    procedure AxisQuery(RefTable: string; RefColumm: string; var List: TMyList;
      var Count: integer; var SortParam: string);
    procedure DestroyButtons(Cord: TPoint);
    procedure SendToHell;
    procedure BAddClick (Sender: TObject);
  public
    BAddNewItem : TSpeedButton;
    OneItemHeight: Integer;
    MouseMovePoint: TPoint;
    ButtonCount: integer;
    SortParamX, SortParamY: string;
    LastColumn, LastRow: integer;
    VeryLastRow, VeryLastColumn: integer;
    FlagApply: boolean;
    ScheduleArray: array of array of TItemForSchedule;
    OXRefTable, OYRefTable, OXRefColumn, OYRefColumn, OxColName, OyColName: string;
    OxCount, OyCount: integer;
    ArrayFilters: TArrayFilters;
    SchTable: TTableInfo;
  end;

var
  FShedule: TFShedule;

implementation

const
  ColumnWidths = 250;
  DistToNextLine = 14;
  FirstColumnH = 40;
  NumTable = 5;
  EditButtonSize = 20;
  TableDays = 'DAYS';
  SortParDays = 'ID';

procedure FormatButton (x, y: integer; B: TSpeedButton);
begin
  if y < FirstColumnH then
    B.Height := 0
  else
    B.Height := EditButtonSize;
  B.Top := y;

  if x - EditButtonSize < ColumnWidths then
    B.Width :=  0
  else
    B.Width := EditButtonSize;
  B.Left := x  - EditButtonSize;
end;

{ TControlButtons }

procedure TControlButtons.move (x, y: integer);/////////////////////
begin
  FormatButton(x - 2, y + 2, ViewItem);
  FormatButton(x - 2, y + 2 + EditButtonSize, EditItem);
  FormatButton(x - 2, y + 2 + EditButtonSize * 2, DeleteItem);
  FormatButton(x - 2, y + 2 + EditButtonSize * 3, AddNewItem);
end;

constructor TControlButtons.create(Sender: TWinControl; AId: Integer; ATable: TTableInfo); /////////////////////
begin
  ID := AId;
  Table := ATable;

  ViewItem := TSpeedButton.Create(Sender);
  ViewItem.Parent := Sender;
  ViewItem.OnClick := @MyClickVeiwItem;
  FShedule.ImageList1.GetBitmap(0, ViewItem.Glyph);

  EditItem := TSpeedButton.Create(Sender);
  EditItem.Parent := Sender;
  EditItem.OnClick := @MyClickEditItem;
  FShedule.ImageList1.GetBitmap(1, EditItem.Glyph);

  DeleteItem := TSpeedButton.Create(Sender);
  DeleteItem.Parent := Sender;
  DeleteItem.OnClick := @MyClickDeleteItem;
  FShedule.ImageList1.GetBitmap(2, DeleteItem.Glyph);

  AddNewItem := TSpeedButton.Create(Sender);
  AddNewItem.Parent := Sender;
  AddNewItem.OnClick := @MyClickAddNewItem;
  FShedule.ImageList1.GetBitmap(3, AddNewItem.Glyph);
end;

procedure TControlButtons.MyClickVeiwItem(Sender: TObject);
var
  Filter: TFilter;
begin
  AddInCatalogs(Sender as TComponent, NumTable);
  Catalogs[High(Catalogs)].AddFilter.Click;
  Filter := Catalogs[High(Catalogs)].ArrayFilters.Filters[High(Catalogs[High(Catalogs)].ArrayFilters.Filters)];
  Filter.ColName.ItemIndex := 0;
  Filter.cmp.ItemIndex := 0;
  Filter.FilterVal.Caption := IntToStr(ID);
  Catalogs[High(Catalogs)].ApplyFilter.Click;
end;

procedure TControlButtons.MyClickEditItem(Sender: TObject);
begin
  MyClickVeiwItem(Sender);
  Catalogs[High(Catalogs)].Close;
  Catalogs[High(Catalogs)].Edit.Click;
  EditingForm[High(EditingForm)].ApplyProc := @FShedule.ApplyClick;
end;

procedure TControlButtons.MyClickDeleteItem(Sender: TObject);
begin
  MyClickVeiwItem(Sender);
  Catalogs[High(Catalogs)].Close;
  Catalogs[High(Catalogs)].RemoveItem.Click;
  FShedule.Apply.Click;
end;

procedure TControlButtons.MyClickAddNewItem(Sender: TObject);
begin
  MyClickVeiwItem(Sender);
  Catalogs[High(Catalogs)].Close;
  Catalogs[High(Catalogs)].AddFieldClick(nil);
  EditingForm[High(EditingForm)].ApplyProc := @FShedule.ApplyClick;
end;

{ ItemForSchedule }
procedure TFShedule.BAddClick (Sender: TObject);
begin
  AddInCatalogs(Sender as TComponent, NumTable);
  Catalogs[High(Catalogs)].ApplyFilter.Click;
  Catalogs[High(Catalogs)].Close;
  Catalogs[High(Catalogs)].AddFieldClick(nil);
  EditingForm[High(Catalogs)].ApplyProc := @FShedule.ApplyClick;
end;

procedure TFShedule.SendToHell;///////////////////////////////////////////////////////////
var
  i: integer;
begin
  for i := 0 to High(ScheduleArray[LastColumn, LastRow].ControlButtons) do
  begin
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].ViewItem.left := -50;
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].EditItem.left := -50;
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].DeleteItem.left := -50;
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].AddNewItem.left := -50;
  end;
end;

procedure TFShedule.DestroyButtons(Cord: TPoint);///////////////////////////////////////////////////////////////////////
var
  i: integer;
begin
  for i := 0 to High(ScheduleArray[Cord.x, Cord.y].ControlButtons) do
  begin
    ScheduleArray[Cord.x, Cord.y].ControlButtons[i].ViewItem.Destroy;
    ScheduleArray[Cord.x, Cord.y].ControlButtons[i].EditItem.Destroy;
    ScheduleArray[Cord.x, Cord.y].ControlButtons[i].DeleteItem.Destroy;
    ScheduleArray[Cord.x, Cord.y].ControlButtons[i].AddNewItem.Destroy;
    ScheduleArray[Cord.x, Cord.y].ControlButtons[i].Destroy;
  end;
  SetLength(ScheduleArray[Cord.x, Cord.y].ControlButtons, 0);
end;

procedure TItemForSchedule.Next (NewId: integer; Sender: TComponent; var OneItemHeight: Integer);
begin
  inc(Count);
  SetLength(Item, Count);
  SetLength(Id, Count);
  Item[Count - 1] := TStringList.Create;
  Id[Count - 1] := NewId;
  TotalHeight := OneItemHeight * Count;
end;

procedure TItemForSchedule.Add(S: String; sender: TComponent; var OneItemHeight: integer);
begin
  if Count = 0 then
    Next(-1, Sender, OneItemHeight);
  Item[High(Item)].Add(S);
  OneItemHeight := max(Item[High(Item)].Count * DistToNextLine, OneItemHeight);
end;

{$R *.lfm}

{ TFShedule }

procedure TFShedule.FormCreate(Sender: TObject);
var
  i: integer;
begin
  SchTable := Table[NumTable];
  ArrayFilters := TArrayFilters.Create(ScrollBox1, SchTable);
  for i := 1 to High(SchTable.Columns) do
  begin
    AxisXCB.Items.Add(SchTable.Columns[i].NameRus);
    AxisXCB.ItemIndex := 4;
    AxisYCB.Items.Add(SchTable.Columns[i].NameRus);
    AxisYCB.ItemIndex := 3;
    OutputField.Items.Add(SchTable.Columns[i].NameRus);
    OutputField.Checked[i - 1] := true;
  end;
  FlagApply := false;
end;

function ReturnCof (x, y :double) : double;
begin
  if (y = 0) then
    Result := 0.2
  else
    Result := sin(pi * ((x) / y)) * 2 + 0.3
end;

procedure TFShedule.DGMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  Cord: TPoint;
  i: integer;
begin
  if not(FlagApply) then
    exit;
  Cord := DG.MouseToCell(Point(X, Y));
  if (Cord.x <> MouseMovePoint.x) or (Cord.y <> MouseMovePoint.y) then
    DG.Invalidate;
  if (ScheduleArray[Cord.x, Cord.y].FlagClick) or (Cord.x * Cord.y = 0) then
    exit;
  if ScheduleArray[Cord.x, Cord.y].Count *  OneItemHeight > DG.RowHeights[Cord.y]  then
    DG.Canvas.Pen.Color := clRed
  else
    DG.Canvas.Pen.Color := clBlue;
  DG.Canvas.Pen.Width := 3;
  DG.Canvas.Brush.Style := bsClear;
  DG.Canvas.Rectangle(DG.CellRect(Cord.x, Cord.y));
  DG.Canvas.Pen.Width := 1;
  MouseMovePoint := Cord;
end;

procedure TFShedule.DGMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Cord: TPoint;
  Rect: TRect;
  i: integer;
begin
  Cord := DG.MouseToCell(Point(X, Y));
  Rect := DG.CellRect(Cord.x, Cord.y);
  if BAddNewItem <> nil then
    FreeAndNil(BAddNewItem);
  if (ScheduleArray[Cord.x, Cord.y].Count = 0) and (Cord.x * Cord.y <> 0) then
  begin
    BAddNewItem := TSpeedButton.Create(DG);
    BAddNewItem.Height := EditButtonSize;
    BAddNewItem.Width := EditButtonSize;
    BAddNewItem.OnClick := @BAddClick;
    BAddNewItem.Parent := DG;
    ImageList1.GetBitmap(3, BAddNewItem.Glyph);
  end;

  if Cord.x * Cord.y = 0 then
    exit;
  ButtonCount := 0;
  if LastRow > 0 then
  begin
    DestroyButtons(Point(LastColumn, LastRow));
    VeryLastColumn := LastColumn;
    VeryLastRow := LastRow;
    if ScheduleArray[VeryLastColumn, VeryLastRow].FlagClick then
      TimerCollapsing.Enabled := True;
    if (LastRow <> Cord.y) or (LastColumn <> Cord.x) then
      ScheduleArray[LastColumn, LastRow].FlagClick := false;
  end;
  ScheduleArray[Cord.x, Cord.y].FlagClick := not ScheduleArray[Cord.x, Cord.y].FlagClick;
  TimerExtension.Enabled := ScheduleArray[Cord.x, Cord.y].FlagClick and not(TimerCollapsing.Enabled);
  if ScheduleArray[Cord.x, Cord.y].FlagClick then
  begin
    LastColumn := Cord.x;
    LastRow := Cord.y;
  end;
end;

procedure TFShedule.TimerExtensionTimer(Sender: TObject);
var
  Cof: Double;
begin
  DG.Enabled := false;
  if (ButtonCount < DG.RowHeights[LastRow] div OneItemHeight)
    and (ScheduleArray[LastColumn, LastRow].Count > 0) then
  begin
    ButtonCount := DG.RowHeights[LastRow] div OneItemHeight;
    SetLength(ScheduleArray[LastColumn, LastRow].ControlButtons, ButtonCount);
    ScheduleArray[LastColumn, LastRow].ControlButtons[ButtonCount - 1] :=
      TControlButtons.create(
        DG, ScheduleArray[LastColumn, LastRow].Id[ButtonCount - 1], SchTable);
  end;
  if (DG.RowHeights[LastRow] < ScheduleArray[LastColumn, LastRow].TotalHeight) then
  begin
    Cof := ReturnCof(DG.RowHeights[LastRow], ScheduleArray[LastColumn, LastRow].TotalHeight);
    DG.RowHeights[LastRow] := DG.RowHeights[LastRow] + Round(DistToNextLine * Cof)
  end
  else
  begin
    DG.RowHeights[LastRow] := max(ScheduleArray[LastColumn, LastRow].TotalHeight, OneItemHeight);
    TimerExtension.Enabled := false;
    DG.Enabled := true;
  end;
end;

procedure TFShedule.TimerCollapsingTimer(Sender: TObject);
var
  Cof: Double;
begin
  DG.Enabled := false;
  if (DG.RowHeights[VeryLastRow] > OneItemHeight) then
  begin
    Cof := ReturnCof(DG.RowHeights[VeryLastRow],
      ScheduleArray[VeryLastColumn, VeryLastRow].TotalHeight);
    DG.RowHeights[VeryLastRow] :=
      DG.RowHeights[VeryLastRow] - Round(DistToNextLine * Cof)
  end
  else
  begin
    DG.RowHeights[VeryLastRow] := OneItemHeight;
    TimerCollapsing.Enabled := false;
    if (LastColumn <> VeryLastColumn) or (LastRow <> VeryLastRow) then
      TimerExtension.Enabled := true
    else
      DG.Enabled := true;
  end;
end;

procedure TFShedule.addFilterClick(Sender: TObject);
begin
  ArrayFilters.AddFilter;
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
  var List: TMyList; var Count: integer; Var SortParam: string);
var
  LastStr: string;
  i: integer;
begin
  if RefTable = TableDays then
    SortParam := SortParDays
  else
    SortParam := RefColumm;
  SQLQuery1.Close;
  SQLQuery1.SQL.Text := 'SELECT ' + RefTable + '.' + RefColumm +
    ' FROM ' + RefTable + ' Order by ' + RefTable + '.' + SortParam;
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
  flagbreak, NenujniyBomj: boolean;
  MainQuery: string;
  OxList, OyList: array of string;
begin
  OneItemHeight := DistToNextLine * 6;
  DG.FocusColor := clBlue;
  if FlagApply then
  begin
    if (sender <> nil) then
      DestroyButtons(Point(LastColumn, LastRow))
    else
      SendToHell;
    for i := 0 to OxCount do
      for j := 0 to OyCount do
        ScheduleArray[i][j].Destroy;
  end;
  OxCount := 0; OyCount := 0;

  for i := 0 to High(SchTable.Columns) do
  begin
    FindRefAndColumn(AxisXCB, OXRefTable, OXRefColumn, OxColName, i);
    FindRefAndColumn(AxisYCB, OYRefTable, OYRefColumn, OyColName, i);
  end;
  AxisQuery(OXRefTable, OXRefColumn, OxList, OxCount, SortParamX);
  AxisQuery(OYRefTable, OYRefColumn, OyList, OyCount, SortParamY);

  SetLength(ScheduleArray, OxCount + 1);
  for i := 0 to OxCount do
    SetLength(ScheduleArray[i], OyCount + 1);

  for i := 0 to OxCount do
    for j := 0 to OyCount do
    begin
      ScheduleArray[i, j] := TItemForSchedule.Create;
      if (i = 0) and (j <> 0) then
        ScheduleArray[i, j].Add(OyList[j - 1], Self, OneItemHeight);
      if (i <> 0) and (j = 0) then
        ScheduleArray[i, j].Add(OxList[i - 1], Self, OneItemHeight);
    end;
  DG.ColCount := OxCount + 1;
  DG.RowCount := OyCount + 1;
  DG.FixedCols := 1;
  DG.FixedRows := 1;

  MainQuery := MakeQuery(SchTable, ' ORDER BY ' + OXRefTable + '.' + SortParamX +
    ', ' + OYRefTable + '.' + SortParamY, False, ArrayFilters);
  ApplyQuery(SQLQuery1, MainQuery, ArrayFilters);
  i := -1; j := 0; counter := 0; flagbreak := false; LastColumn := 0;

  for i := 0 to OyCount do
    DG.RowHeights[i] := DistToNextLine;
  DG.RowHeights[0] := FirstColumnH;

  for i := 0 to OxCount - 1 do
    begin
      for j := 0 to OyCount - 1 do
        begin
          while (SQLQuery1.FieldByName(OyColName).AsString = OyList[j])
            and (SQLQuery1.FieldByName(OxColName).AsString = OxList[i])
            and (counter < SQLQuery1.RowsAffected) do
          begin
            ScheduleArray[i + 1, j + 1].Next(
              SQLQuery1.FieldByName(SchTable.Columns[0].NameRus).AsInteger, Self, OneItemHeight);
            for q := 0 to OutputField.Items.Count - 1 do
            begin
              if OutputField.Checked[q] then
              begin
                ScheduleArray[i + 1, j + 1].Add(OutputField.Items[q] + ': '
                  + SQLQuery1.FieldByName(OutputField.Items[q]).AsString,
                  Self, OneItemHeight);
              end;
              if (DG.RowHeights[j + 1] < OneItemHeight) then
                DG.RowHeights[j + 1] := OneItemHeight;
            end;
            SQLQuery1.Next;
            inc(counter);
          end;
        end;
    end;
  DG.Invalidate;
end;

procedure TFShedule.DGDrawCell(Sender: TObject; aCol, aRow: integer;
  aRect: TRect; aState: TGridDrawState);
var
  i, j: Integer;
  LocalTop, LineHeight: integer;
  R: TRect;
begin
  FlagApply := True;
  if (aCol = 0) and (aRow = 0) then
  begin
    DG.Canvas.Font.Height := 18;
    DG.Canvas.TextOut(aRect.Left + 2, aRect.Bottom - 20, AxisYCB.Text);
    DG.Canvas.TextOut(aRect.Right - Length(AxisXCB.Text) * 4, aRect.Top - 2, AxisXCB.Text);
    DG.Canvas.Brush.Color := clGradientActiveCaption;
    DG.Canvas.Pen.Color := clBlack;
    DG.Canvas.Rectangle(aRect.Right div 2, aRect.Top, aRect.Left, aRect.Bottom div 2);
    DG.Canvas.Rectangle(aRect.Right div 2, aRect.Bottom div 2, aRect.Right, aRect.Bottom);
  end;

  DG.ColWidths[aCol] := ColumnWidths;
  for i := 0 to ScheduleArray[aCol, aRow].Count - 1 do
  begin
    for j := 0 to ScheduleArray[aCol, aRow].Item[i].Count - 1 do
    begin
      LocalTop := aRect.Top + j * DistToNextLine + i * OneItemHeight;
      DG.Canvas.TextOut(aRect.Left + 2, LocalTop, ScheduleArray[aCol, aRow].Item[i][j]);
    end;
    LineHeight := aRect.Top + OneItemHeight * (i + 1) - 1;
    DG.Canvas.Pen.Color := clBlack;
    DG.Canvas.Pen.Style := psDash;
    DG.Canvas.Line(aRect.Left, LineHeight, aRect.Right, LineHeight);
    DG.Canvas.Pen.Style := psSolid;
  end;
  for i := 0 to High(ScheduleArray[LastColumn, LastRow].ControlButtons) do
  begin
    R := Self.DG.CellRect(LastColumn, LastRow);
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].move
      (R.Right, R.Top + i * OneItemHeight);
  end;

  DG.Canvas.Brush.Style := bsClear;
  if (aCol = LastColumn) and (aRow = LastRow)
    and ScheduleArray[aCol, aRow].FlagClick  then
    begin
      DG.Canvas.Pen.Color := clLime;
      DG.Canvas.Pen.Width := 5;
      DG.Canvas.Rectangle(aRect);
      if (ScheduleArray[aCol, aRow].Count = 0) and (aCol * aRow <> 0) then
        FormatButton(aRect.Right, aRect.Top, BAddNewItem);
    end;

  DG.Canvas.Pen.Width := 1;
  DG.Canvas.Pen.Color := clBlack;
  DG.Canvas.Rectangle(aRect);
end;

end.
