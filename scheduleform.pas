unit ScheduleForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, DB, FileUtil, SynHighlighterHTML, Forms, Controls,
  Graphics, Dialogs, ExtCtrls, StdCtrls, Grids, move, DBCtrls, metadata,
  conflicts, FormatsToSave, Save, Filters, UQuery, types, UCatalogs, Buttons, Menus,
  Ueditingform, Math, Hash;

type
  TFSchedule = class;
  TMyList = array of string;
  { TControlButtons }

  TControlButtons = class(TObject)
    s: string;
    FlagF: boolean;
    ID: integer;
    Table: TTableInfo;
    Procedures: array of TProc;
    Buttons: array of TSpeedButton;
    Form: TFSchedule;
    ImageList: TImageList;
    Row, Col, Count: integer;
    Filters: TArrayFilters;
    Catalog: Timplementing_catalogs;
    constructor Create(
      Sender: TWinControl; AForm: TFSchedule; aCol, aRow, aCount: integer; FlagFreeItem: boolean);
    procedure MyClickViewItem(Sender: TObject);
    procedure MyClickEditItem(Sender: TObject);
    procedure MyClickDeleteItem(Sender: TObject);
    procedure AddProcedure(Proc: TProc);
    procedure CreateCatalog(aID: integer);
    procedure FixEdit;
    destructor Destroy;
  private
    procedure AddFilterForView(List: TMyList; Ind, LastInd: integer; Sender: TObject);
    procedure move(x, y: integer);
    procedure MyClickAddNewItem(Sender: TObject);
    procedure OpenCatalogForm(Sender: TObject);
  end;

  TConButton = array of TControlButtons;

  { TScheduleRecord }

  TScheduleRecord = class(TObject)
    FlagClick: boolean;///////////////////////////////////////////////////////////////////////////
    Items: array of TStringList;
    Id: array of integer;
    ControlButtons: TConButton;
    TotalHeight: integer;
    procedure NextRecord(NewId: integer; Sender: TComponent; var OneItemHeight: integer);
    procedure AddItem(S: string; Sender: TComponent; var OneItemHeight: integer);
  private
  public
    Count: integer;
  end;

  { TFSchedule }

  TFSchedule = class(TForm)
    Apply: TButton;
    addFilter: TButton;
    Datasource: TDatasource;
    AxisYCB: TComboBox;
    AxisXCB: TComboBox;
    ImageList1: TImageList;
    MainMenu1: TMainMenu;
    FileConflict: TMenuItem;
    ItemFile: TMenuItem;
    FileSave: TMenuItem;
    FileClose: TMenuItem;
    OutputField: TCheckGroup;
    DG: TDrawGrid;
    AxisXName: TLabel;
    AxisYName: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    SaveDialog1: TSaveDialog;
    SaveDialog2: TSaveDialog;
    ScrollBox1: TScrollBox;
    ScrollBox2: TScrollBox;
    SQLQuery1: TSQLQuery;
    TimerExtension: TTimer;
    TimerCollapsing: TTimer;
    procedure AxisCBChange(Sender: TObject);
    procedure DGMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: integer);
    procedure DGMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
    procedure FindRefAndColumn(Axis: TComboBox; var RefTable: string;
      var RefColumn: string; var RusColName: string; ind: integer);
    procedure addFilterClick(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure DGDrawCell(Sender: TObject; aCol, aRow: integer;
      aRect: TRect; aState: TGridDrawState);
    procedure FormCreate(Sender: TObject);
    procedure FileConflictClick(Sender: TObject);
    procedure FileSaveClick(Sender: TObject);
    procedure FileCloseClick(Sender: TObject);
    procedure TimerExtensionTimer(Sender: TObject);
    procedure TimerCollapsingTimer(Sender: TObject);
  private
    procedure AxisQuery(RefTable: string; RefColumm: string;
      var List: TMyList; var Count: integer; var SortParam: string);
    procedure DestroyButtons(var CB: TConButton);
    procedure move_buttons(cord: TPoint);
  public
    LastXClick, LastYClick: integer;
    BForDest: array of TConButton;
    OxList, OyList: array of string;
    OneItemHeight: integer;
    MouseMovePoint: TPoint;
    BCount, OxIndex, OyIndex: integer;
    SortParamX, SortParamY: string;
    LastColumn, LastRow: integer;
    CollapsingRow, CollapsingColumn: integer;
    FlagApply: boolean;
    ScheduleData: array of array of TScheduleRecord;
    OXRefTable, OYRefTable, OXRefColumn, OYRefColumn, OxColName, OyColName: string;
    OxCount, OyCount: integer;
    ArrayFilters: TArrayFilters;
    SchTable: TTableInfo;
    FlagButtonsCreated: boolean;
  end;

var
  FSchedule: TFSchedule;

implementation

const
  ColumnWidths = 250;
  DistToNextLine = 18;
  FirstColumnH = 40;
  NumTable = 5;
  EditButtonSize = 20;

procedure FormatButton(x, y: integer; B: TSpeedButton);
begin
  if y < FirstColumnH then
    B.Height := 0
  else
    B.Height := EditButtonSize;
  B.Top := y;

  if x - EditButtonSize < ColumnWidths then
    B.Width := 0
  else
    B.Width := EditButtonSize;
  B.Left := x - EditButtonSize;
end;

{ TControlButtons }

procedure TControlButtons.move(x, y: integer);
var
  i: integer;
begin
  for i := 0 to High(Buttons) do
    FormatButton(x - 2, y + 2 + EditButtonSize * i, Buttons[i]);
end;

procedure TControlButtons.CreateCatalog(aID: integer);
begin
  Filters := TArrayFilters.Create(Form.ScrollBox2, Table);
  Filters.AddFilterWithFixId(aID);
  FlagF := false;
  Catalog := Timplementing_catalogs.Create(NumTable, @s, @FlagF, Filters);
end;

constructor TControlButtons.Create(
  Sender: TWinControl; AForm: TFSchedule; aCol, aRow, aCount: integer; FlagFreeItem: boolean);
var
  i, j: integer;
  Hint: string;
  StrList: TStringList;
begin
  Hint := '';
  Col := aCol;
  Row := aRow;
  Count := aCount;
  Form := AForm;
  if not FlagFreeItem then
    ID := Form.ScheduleData[Col, Row].ID[Count];

  Table := Form.SchTable;
  ImageList := Form.ImageList1;

  s := '';
  if not FlagFreeItem then
  begin
    AddProcedure(@MyClickViewItem);
    AddProcedure(@MyClickEditItem);
    AddProcedure(@MyClickDeleteItem);
  end;
  AddProcedure(@MyClickAddNewItem);
  if (HKeyConflicts.ReturnVal(ID).InvolvedInConflict) and (not FlagFreeItem) then
    AddProcedure(nil);
  for i := 0 to High(Procedures) do
  begin
    SetLength(Buttons, Length(Buttons) + 1);
    Buttons[i] := TSpeedButton.Create(Sender);
    Buttons[i].Parent := Sender;
    Form.ImageList1.GetBitmap(i, Buttons[i].Glyph);
    Buttons[i].OnClick := Procedures[i];
    if Procedures[i] = nil then
    begin
      StrList := TStringList.Create;
      StrList := HKeyConflicts.ReturnVal(ID).List;
      for j := 0 to StrList.Count - 1 do
      begin
        Hint +=  StrList[j];
        if j <> StrList.Count - 1 then
          Hint += #10#13;
      end;
      Buttons[i].Hint := Hint;
      Buttons[i].ShowHint := true;
    end;
  end;
  if FlagFreeItem then
    Form.ImageList1.GetBitmap(3, Buttons[0].Glyph);
end;

procedure TControlButtons.OpenCatalogForm(Sender: TObject);
var
  i: integer;
begin
  Catalog.ApplyFilter;
  for i := 0 to High(EditingForm) do
    EditingForm[i].Close;
end;

procedure TControlButtons.AddFilterForView(List: TMyList; Ind, LastInd: integer;
  Sender: TObject);
var
  Filter: TFilter;
begin
  Catalogs[High(Catalogs)].AddFilter.Click;
  Filter := Catalogs[High(Catalogs)].ArrayFilters.Filters[High(
    Catalogs[High(Catalogs)].ArrayFilters.Filters)];
  Filter.ColName.ItemIndex := Ind;
  Filter.OnColumnChange(Filter);
  Filter.cmp.ItemIndex := 0;
  Filter.FilterVal.Caption := List[LastInd - 1];
end;

procedure TControlButtons.MyClickViewItem(Sender: TObject);
begin
  AddInCatalogs(Form, NumTable);
  AddFilterForView(Form.OxList, Form.OxIndex, Col, Sender);
  AddFilterForView(Form.OyList, Form.OyIndex, Row, Sender);
  Form.ArrayFilters.Copy(Catalogs[High(Catalogs)].ArrayFilters);
  Catalogs[High(Catalogs)].ApplyFilter.Click;
end;

procedure TControlButtons.MyClickEditItem(Sender: TObject);
begin
  CreateCatalog(ID);///////////////////////////////////////////////////////////
  OpenCatalogForm(Form);
  Catalog.AddField(False);
  EditingForm[High(EditingForm)].ApplyProc := @Form.ApplyClick;
end;

procedure TControlButtons.MyClickDeleteItem(Sender: TObject);
begin
  CreateCatalog(ID);
  OpenCatalogForm(Sender);
  Catalog.RemoveItem;
  Form.Apply.Click;
end;

procedure TControlButtons.MyClickAddNewItem(Sender: TObject);
begin
  CreateCatalog(-1);
  OpenCatalogForm(Form);
  Catalog.AddField(true);
  EditingForm[High(EditingForm)].ApplyProc := @Form.ApplyClick;
  FixEdit;
end;

procedure TControlButtons.AddProcedure(Proc: TProc);
begin
  SetLength(Procedures, length(Procedures) + 1);
  Procedures[High(Procedures)] := Proc;
end;

procedure TControlButtons.FixEdit;
begin
  EditingForm[High(EditingForm)].FixVal(Form.OxIndex, IntToStr(Col));
  EditingForm[High(EditingForm)].FixVal(Form.OyIndex, IntToStr(Row));
end;

destructor TControlButtons.Destroy;
var
  i: integer;
begin
  for i := 0 to High(Buttons) do
    Buttons[i].Destroy;
end;

{ ItemForSchedule }
procedure TScheduleRecord.NextRecord(NewId: integer; Sender: TComponent;
  var OneItemHeight: integer);
begin
  Inc(Count);
  SetLength(Items, Count);
  SetLength(Id, Count);
  Items[Count - 1] := TStringList.Create;
  Id[Count - 1] := NewId;
  TotalHeight := OneItemHeight * Count;
end;

procedure TScheduleRecord.AddItem(S: string; Sender: TComponent;
  var OneItemHeight: integer);
begin
  if Count = 0 then
    NextRecord(-1, Sender, OneItemHeight);
  Items[High(Items)].Add(S);
  OneItemHeight := max(Items[High(Items)].Count * DistToNextLine, OneItemHeight);
end;

{$R *.lfm}

{ TFSchedule }
procedure TFSchedule.DestroyButtons(var CB: TConButton);
var
  i: integer;
begin
  if not FlagApply then
    exit;
  for i := 0 to High(CB) do
    CB[i].Destroy;
  SetLength(CB, 0);
end;

procedure TFSchedule.FormCreate(Sender: TObject);
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
    OutputField.Checked[i - 1] := True;
    AxisCBChange(AxisXCB);
  end;
  FlagApply := False;
  AddFormatInSaveDialog(FSchedule.SaveDialog1);
end;

procedure TFSchedule.FileConflictClick(Sender: TObject);
begin
  if not FlagApply then
  begin
    ShowMessage('Задайте расписание для вывода конфликтов!');
    exit;
  end;
  FConflict.Show;
end;

procedure TFSchedule.FileSaveClick(Sender: TObject);
var
  i, j, q: integer;
  DataToSave: TSaveClass;
  HeaderList, FiltersList: TStringList;
begin
  if not FlagApply then
  begin
    ShowMessage('Задайте расписание для сохранения!');
    exit;
  end;
  SaveDialog1.Execute;
  SetLength(DataToSave, OyCount + 1);
  for i := 0 to OyCount do
  begin
    SetLength(DataToSave[i], OxCount + 1);
    for j := 0 to OxCount do
      for q := 0 to High(ScheduleData[j, i].Items) do
      begin
        SetLength(DataToSave[i, j], q + 1);
        DataToSave[i, j, q] := ScheduleData[j, i].Items[q];
      end;
  end;
  HeaderList := TStringList.Create;
  for i := 0 to OutputField.Items.Count - 1 do
    if OutputField.Checked[i] then
      HeaderList.Add(OutputField.Items[i]);

  FiltersList := TStringList.Create;
  for i := 0 to High(ArrayFilters.Filters) do
    FiltersList.Add(ArrayFilters.Filters[i].ColName.Caption + ' ' +
      ArrayFilters.Filters[i].cmp.Caption + ' ' +
      ArrayFilters.Filters[i].FilterVal.Caption);
  SaveToFile(SaveDialog1.FilterIndex, DataToSave, SaveDialog1.FileName,
    OxColName, OyColName, HeaderList, FiltersList);
end;

procedure TFSchedule.FileCloseClick(Sender: TObject);
begin
  Close;
end;

function ReturnCof(x, y: double): double; //easing
begin
  if (y = 0) then
    Result := 0.2
  else
    Result := sin(pi * (x / y)) * 2 + 0.3;
end;

procedure TFSchedule.DGMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
var
  Cord: TPoint;
  Rect: TRect;
  i: integer;
begin
  if not (FlagApply) then
    exit;
  Cord := DG.MouseToCell(Point(X, Y));
  if (Cord.x <> MouseMovePoint.x) or (Cord.y <> MouseMovePoint.y) then
  begin
    DG.Invalidate;
    if FlagButtonsCreated then
    begin
      FlagButtonsCreated := false;
      DestroyButtons(ScheduleData[MouseMovePoint.x, MouseMovePoint.y].ControlButtons);
    end;

    if (ScheduleData[Cord.x, Cord.y].FlagClick) or (Cord.x * Cord.y = 0) then
      exit;

    FlagButtonsCreated := true;
    for i := 0 to min(DG.RowHeights[Cord.y] div OneItemHeight - 1, ScheduleData[Cord.x, Cord.y].Count - 1) do
    begin
      SetLength(ScheduleData[Cord.x, Cord.y].ControlButtons, i + 1);
      ScheduleData[Cord.x, Cord.y].ControlButtons[i] :=
        TControlButtons.Create(DG, FSchedule, Cord.x, Cord.y, i, false);
    end;

    if (ScheduleData[Cord.x, Cord.y].Count = 0) then
    begin
      SetLength(ScheduleData[Cord.x, Cord.y].ControlButtons, 1);
      ScheduleData[Cord.x, Cord.y].ControlButtons[i] :=
        TControlButtons.Create(DG, FSchedule, Cord.x, Cord.y, 0, true);
    end;
  end;
  MouseMovePoint := Cord;
  if (ScheduleData[Cord.x, Cord.y].FlagClick) or (Cord.x * Cord.y = 0) then
    exit;
  if ScheduleData[Cord.x, Cord.y].Count * OneItemHeight > DG.RowHeights[Cord.y] then
    DG.Canvas.Pen.Color := clRed
  else
    DG.Canvas.Pen.Color := clBlue;

  DG.Canvas.Pen.Width := 3;
  DG.Canvas.Brush.Style := bsClear;
  Rect := DG.CellRect(Cord.x, Cord.y);
  if Rect.Top < FirstColumnH then
    Rect.Top := FirstColumnH;
  if Rect.Left < ColumnWidths then
    Rect.Left := ColumnWidths;
  DG.Canvas.Rectangle(Rect);
  DG.Canvas.Pen.Width := 1;
end;

procedure TFSchedule.DGMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  Cord: TPoint;
begin
  if not FlagApply then
    exit;
  Cord := DG.MouseToCell(Point(X, Y));
  if (ScheduleData[Cord.x, Cord.y].Count = 0) or (Cord.x * Cord.y = 0) then
    exit;
  BCount := 0;
  if LastRow > 0 then
  begin
    DestroyButtons(ScheduleData[LastColumn, LastRow].ControlButtons);
    CollapsingColumn := LastColumn;
    CollapsingRow := LastRow;
    TimerCollapsing.Enabled := ScheduleData[CollapsingColumn, CollapsingRow].FlagClick;
    if (LastRow <> Cord.y) or (LastColumn <> Cord.x) then
      ScheduleData[LastColumn, LastRow].FlagClick := False;
  end;
  ScheduleData[Cord.x, Cord.y].FlagClick := not ScheduleData[Cord.x, Cord.y].FlagClick;
  DestroyButtons(ScheduleData[MouseMovePoint.x, MouseMovePoint.y].ControlButtons);
  TimerExtension.Enabled := ScheduleData[Cord.x, Cord.y].FlagClick and not
    (TimerCollapsing.Enabled);
  if ScheduleData[Cord.x, Cord.y].FlagClick then
  begin
    LastColumn := Cord.x;
    LastRow := Cord.y;
  end;
  FlagButtonsCreated := false;
end;

procedure TFSchedule.AxisCBChange(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to OutputField.Items.Count - 1 do
    if (OutputField.Items[i] = AxisXCB.Caption) or (OutputField.Items[i] = AxisYCB.Caption) then
      OutputField.Checked[i] := False
    else
      OutputField.Checked[i] := true;
end;



procedure TFSchedule.TimerExtensionTimer(Sender: TObject);
var
  Cof: double;
begin
  DG.Enabled := False;
  if (BCount < DG.RowHeights[LastRow] div OneItemHeight) and
    (ScheduleData[LastColumn, LastRow].Count > 0) then
  begin
    BCount := DG.RowHeights[LastRow] div OneItemHeight;
    SetLength(ScheduleData[LastColumn, LastRow].ControlButtons, BCount);
    ScheduleData[LastColumn, LastRow].ControlButtons[BCount - 1] :=
      TControlButtons.Create(DG, FSchedule, LastColumn, LastRow, BCount - 1, false);
  end;
  if (DG.RowHeights[LastRow] < ScheduleData[LastColumn, LastRow].TotalHeight) then
  begin
    Cof := ReturnCof(DG.RowHeights[LastRow], ScheduleData[LastColumn,
      LastRow].TotalHeight);
    DG.RowHeights[LastRow] := DG.RowHeights[LastRow] + Round(DistToNextLine * Cof);
  end
  else
  begin
    DG.RowHeights[LastRow] := max(ScheduleData[LastColumn, LastRow].TotalHeight,
      OneItemHeight);
    TimerExtension.Enabled := False;
    DG.Enabled := True;
  end;
end;

procedure TFSchedule.TimerCollapsingTimer(Sender: TObject);
var
  APoint: TPoint;
  Cof: double;
  Shift: TShiftState;
  aRect: TRect;
begin
  DG.Enabled := False;
  if (DG.RowHeights[CollapsingRow] > OneItemHeight) then
  begin
    Cof := ReturnCof(DG.RowHeights[CollapsingRow],
      ScheduleData[CollapsingColumn, CollapsingRow].TotalHeight);
    DG.RowHeights[CollapsingRow] :=
      DG.RowHeights[CollapsingRow] - Round(DistToNextLine * Cof);
  end
  else
  begin
    DG.RowHeights[CollapsingRow] := OneItemHeight;
    TimerCollapsing.Enabled := False;
    if (LastColumn <> CollapsingColumn) or (LastRow <> CollapsingRow) then
      TimerExtension.Enabled := True
    else
    begin
      DG.Enabled := True;
      aRect := DG.CellRect(DG.ColCount - 1, DG.RowCount - 1);
      if (aRect.Bottom < 200) then
      begin
        DG.CheckPosition;
        DG.Invalidate;
      end;
    end;
  end;
end;

procedure TFSchedule.addFilterClick(Sender: TObject);
begin
  ArrayFilters.AddFilter;
end;

procedure TFSchedule.FindRefAndColumn(Axis: TComboBox; var RefTable: string;
  var RefColumn: string; var RusColName: string; ind: integer);
begin
  if SchTable.Columns[ind].NameRus = Axis.Caption then
  begin
    ReturnTblAndCol(SchTable, Ind, RefTable, RefColumn);
    RusColName := SchTable.Columns[ind].NameRus;
  end;
end;

procedure TFSchedule.AxisQuery(RefTable: string; RefColumm: string;
  var List: TMyList; var Count: integer; var SortParam: string);
var
  LastStr: string;
  i: integer;
begin
  SortParam := ReturnSortPar(RefTable, RefColumm);
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

procedure TFSchedule.ApplyClick(Sender: TObject);
var
  i, j, q, counter: integer;
  MainQuery, OrderByVal: string;
  HashItem: TItemForHash;
begin

  OneItemHeight := DistToNextLine * 6;
  if FlagApply then
  begin
    for i := 0 to High(ScheduleData) do
      for j := 0 to High(ScheduleData[i]) do
      begin
        if (i > 0) and (j > 0) then
          for q := 0 to High(ScheduleData[i, j].id) do
          begin
            HAllItems.Remove(ScheduleData[i, j].id[q]);
            HKeyConflicts.Remove(ScheduleData[i, j].id[q]);
          end;
        if (Sender <> nil) then
          DestroyButtons(ScheduleData[i, j].ControlButtons)
        else
        begin
          SetLength(BForDest, Length(BForDest) + 1);
          BForDest[High(BForDest)] := ScheduleData[i, j].ControlButtons;
        end;
      end;
    for i := 0 to OxCount do
      for j := 0 to OyCount do
        ScheduleData[i][j].Destroy;
  end;
  OxCount := 0;
  OyCount := 0;
  OxIndex := AxisXCB.ItemIndex + 1;
  OyIndex := AxisYCB.ItemIndex + 1;

  for i := 0 to High(SchTable.Columns) do
  begin
    FindRefAndColumn(AxisXCB, OXRefTable, OXRefColumn, OxColName, i);
    FindRefAndColumn(AxisYCB, OYRefTable, OYRefColumn, OyColName, i);
  end;
  AxisQuery(OXRefTable, OXRefColumn, OxList, OxCount, SortParamX);
  AxisQuery(OYRefTable, OYRefColumn, OyList, OyCount, SortParamY);

  SetLength(ScheduleData, OxCount + 1);
  for i := 0 to OxCount do
    SetLength(ScheduleData[i], OyCount + 1);

  for i := 0 to OxCount do
    for j := 0 to OyCount do
    begin
      ScheduleData[i, j] := TScheduleRecord.Create;
      if (i = 0) and (j <> 0) then
        ScheduleData[i, j].AddItem(OyList[j - 1], Self, OneItemHeight);
      if (i <> 0) and (j = 0) then
        ScheduleData[i, j].AddItem(OxList[i - 1], Self, OneItemHeight);
    end;

  DG.ColCount := OxCount + 1;
  DG.RowCount := OyCount + 1;
  DG.FixedCols := 1;
  DG.FixedRows := 1;
  OrderByVal := ' ORDER BY ' + OXRefTable + '.' + SortParamX + ', ' +
    OYRefTable + '.' + SortParamY;
  MainQuery := MakeQuery(SchTable, OrderByVal, False, ArrayFilters);
  ApplyQuery(SQLQuery1, MainQuery, ArrayFilters);
  i := -1;
  j := 0;
  counter := 0;
  LastColumn := 0;

  for i := 0 to OyCount do
    DG.RowHeights[i] := DistToNextLine;
  for i := 0 to OxCount do
    DG.ColWidths[i] := ColumnWidths;
  DG.RowHeights[0] := FirstColumnH;

  HashItem.List := TStringList.Create;
  for i := 0 to OxCount - 1 do
  begin
    for j := 0 to OyCount - 1 do
    begin
      while (SQLQuery1.FieldByName(OyColName).AsString = OyList[j]) and
        (SQLQuery1.FieldByName(OxColName).AsString = OxList[i]) and
        (counter < SQLQuery1.RowsAffected) do
      begin
        ScheduleData[i + 1, j + 1].NextRecord(
          SQLQuery1.FieldByName(SchTable.Columns[0].NameRus).AsInteger,
          Self, OneItemHeight);
        HashItem.ID := SQLQuery1.FieldByName(SchTable.Columns[0].NameRus).AsInteger;
        HashItem.List.Clear;
        for q := 0 to OutputField.Items.Count - 1 do
        begin
          HashItem.List.Add(SQLQuery1.FieldByName(OutputField.Items[q]).AsString);
          if OutputField.Checked[q] then
          begin
            ScheduleData[i + 1, j + 1].AddItem(OutputField.Items[q] +
              ': ' + SQLQuery1.FieldByName(OutputField.Items[q]).AsString,
              Self, OneItemHeight);
          end;
          if (DG.RowHeights[j + 1] < OneItemHeight) then
            DG.RowHeights[j + 1] := OneItemHeight;
        end;
        HAllItems.Add(HashItem);
        HKeyConflicts.Add(HashItem);
        SQLQuery1.Next;
        Inc(counter);
      end;
    end;
  end;
  DG.Invalidate;
  FConflict.ProcApply := @Self.ApplyClick;
  FConflict.FindConflicts;
end;

procedure TFSchedule.move_buttons (cord: TPoint);
var
  Rect: TRect;
  i: integer;
begin
  Rect := Self.DG.CellRect(cord.x, cord.y);
  for i := 0 to High(ScheduleData[cord.x, cord.y].ControlButtons) do
  begin
    ScheduleData[cord.x, cord.y].ControlButtons[i].move(
      Rect.Right, Rect.Top + i * OneItemHeight);
  end;
end;

procedure TFSchedule.DGDrawCell(Sender: TObject; aCol, aRow: integer;
  aRect: TRect; aState: TGridDrawState);
var
  i, j: integer;
  LocalTop, LineHeight: integer;
  Rect: TRect;
  APoint: TPoint;
  triangle: array of TPoint;
begin
  FlagApply := True;

  if High(BForDest) > 0 then
  begin
    for i := 0 to High(BForDest) do
      DestroyButtons(BForDest[i]);
    SetLength(BForDest, 0);
  end;

  if (aCol + aRow = 0) then//Отрисовка левого верхнего угла
  begin
    DG.Canvas.Font.Height := 18;
    DG.Canvas.TextOut(aRect.Left + 2, aRect.Bottom - 20, AxisYCB.Text);
    DG.Canvas.TextOut(aRect.Right - Length(AxisXCB.Text) * 4, aRect.Top -
      2, AxisXCB.Text);
    DG.Canvas.Brush.Color := clGradientActiveCaption;
    DG.Canvas.Pen.Color := clBlack;
    DG.Canvas.Rectangle(aRect.Right div 2, aRect.Top, aRect.Left, aRect.Bottom div 2);
    DG.Canvas.Rectangle(aRect.Right div 2, aRect.Bottom div 2, aRect.Right,
      aRect.Bottom);
  end;

  for i := 0 to ScheduleData[aCol, aRow].Count - 1 do
  begin
    for j := 0 to ScheduleData[aCol, aRow].Items[i].Count - 1 do
    begin
      LocalTop := aRect.Top + j * DistToNextLine + i * OneItemHeight;
      DG.Canvas.TextOut(aRect.Left + 2, LocalTop, ScheduleData[aCol, aRow].Items[i][j]);
    end;
    LineHeight := aRect.Top + OneItemHeight * (i + 1) - 1;
    DG.Canvas.Pen.Color := clBlack;
    DG.Canvas.Pen.Style := psDash;
    DG.Canvas.Line(aRect.Left, LineHeight, aRect.Right, LineHeight);
    DG.Canvas.Pen.Style := psSolid;
  end;

  if FlagButtonsCreated then
    move_buttons(MouseMovePoint);
  move_buttons(Point(LastColumn, LastRow));

  DG.Canvas.Brush.Style := bsClear;
  if (aCol = LastColumn) and (aRow = LastRow) and//Отрисовка рамки для выделеной ячейки
    ScheduleData[aCol, aRow].FlagClick then
  begin
    DG.Canvas.Pen.Color := clLime;
    DG.Canvas.Pen.Width := 5;
    Rect := aRect;
    Rect.Top := max(Rect.Top, FirstColumnH);
    DG.Canvas.Rectangle(Rect);
  end;

  DG.Canvas.Pen.Width := 1;//Отрисовка индикаторов
  DG.Canvas.Pen.Color := clBlack;
  DG.Canvas.Rectangle(aRect);
  if (DG.RowHeights[aRow] < ScheduleData[aCol, aRow].TotalHeight) and
    (aRow * aCol <> 0) then
  begin
    SetLength(triangle, 3);
    DG.Canvas.Brush.Style := bsSolid;
    DG.Canvas.Brush.Color := clBlack;
    triangle[0] := Point(aRect.Right - 30, aRect.Bottom);
    triangle[1] := Point(aRect.Right, aRect.Bottom);
    triangle[2] := Point(aRect.Right, aRect.Bottom - 30);
    DG.Canvas.Polygon(triangle);
  end;
end;

initialization
  HAllItems := THash.Create;
  HKeyConflicts := THash.Create;

end.
