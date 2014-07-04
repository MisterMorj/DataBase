unit ScheduleForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, DB, FileUtil, SynHighlighterHTML, Forms, Controls,
  Graphics, Dialogs, ExtCtrls, StdCtrls, Grids, move, DBCtrls, metadata,
  conflicts, FormatsToSave, Save, Filters, UQuery, types, UCatalogs, Buttons, Menus,
  Ueditingform, Math, Hash;

type
  TFShedule = class;
  TMyList = array of string;
  { TControlButtons }

  TControlButtons = class(TObject)
    s: string;
    Flag: boolean;
    ID: integer;
    Table: TTableInfo;
    ProcedureArr: array of TProc;
    ButtonArr: array of TSpeedButton;
    Form: TFShedule;
    ImageList: TImageList;
    Row, Col, Count: integer;
    ArrFilter: TArrayFilters;
    Catalog: Timplementing_catalogs;
    constructor Create(Sender: TWinControl; AForm: TFShedule; aCol, aRow,
      aCount: integer);
    constructor AddOnlyCreate(Sender: TWinControl; AForm: TFShedule; aCol, aRow,
      aCount: integer);
    procedure MyClickVeiwItem(Sender: TObject);
    procedure MyClickEditItem(Sender: TObject);
    procedure MyClickDeleteItem(Sender: TObject);
    procedure AddProcedure(Proc: TProc);
    procedure FixateEd;
    destructor Destroy;
  private
    procedure AddFilterForVeiw(List: TMyList; Ind, LastInd: integer; Sender: TObject);
    procedure move(x, y: integer);
    procedure MyClickAddNewItem(Sender: TObject);
    procedure OpenCatalogForm(Sender: TObject);
  end;

  TConButton = array of TControlButtons;

  { TItemForSchedule }

  TItemForSchedule = class(TObject)
    FlagClick: boolean;
    Item: array of TStringList;
    Id: array of integer;
    ControlButtons: TConButton;
    TotalHeight: integer;
    procedure Next(NewId: integer; Sender: TComponent; var OneItemHeight: integer);
    procedure Add(S: string; Sender: TComponent; var OneItemHeight: integer);
  private
  public
    Count: integer;
  end;



  { TFShedule }

  TFShedule = class(TForm)
    Apply: TButton;
    addFilter: TButton;
    Datasource1: TDatasource;
    AxisYCB: TComboBox;
    AxisXCB: TComboBox;
    Image1: TImage;
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
    procedure BAddClick(Sender: TObject);
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
    VeryLastRow, VeryLastColumn: integer;
    FlagApply: boolean;
    ScheduleArray: array of array of TItemForSchedule;
    OXRefTable, OYRefTable, OXRefColumn, OYRefColumn, OxColName, OyColName: string;
    OxCount, OyCount: integer;
    ArrayFilters: TArrayFilters;
    SchTable: TTableInfo;
    FlagMoveB: boolean;
  end;

var
  FShedule: TFShedule;

implementation

const
  ColumnWidths = 250;
  DistToNextLine = 16;
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
  for i := 0 to High(ButtonArr) do
    FormatButton(x - 2, y + 2 + EditButtonSize * i, ButtonArr[i]);
end;

constructor TControlButtons.AddOnlyCreate(Sender: TWinControl; AForm: TFShedule; aCol, aRow, aCount: integer);
begin
  Col := aCol;
  Row := aRow;
  Count := aCount;
  Form := AForm;
  Table := Form.SchTable;
  ImageList := Form.ImageList1;

  s := '';
  Flag := false;
  ArrFilter := TArrayFilters.Create(Form.ScrollBox2, Table);
  ArrFilter.AddFilter;
  ArrFilter.Filters[High(ArrFilter.Filters)].ColName.ItemIndex := 0;
  ArrFilter.Filters[High(ArrFilter.Filters)].cmp.ItemIndex := 0;
  ArrFilter.Filters[High(ArrFilter.Filters)].FilterVal.Caption := '-1';
  Catalog := Timplementing_catalogs.Create(NumTable, @s, @Flag, ArrFilter);

  AddProcedure(@MyClickAddNewItem);
  SetLength(ButtonArr, Length(ButtonArr) + 1);
  ButtonArr[0] := TSpeedButton.Create(Sender);
  ButtonArr[0].Parent := Sender;
  Form.ImageList1.GetBitmap(3, ButtonArr[0].Glyph);
  ButtonArr[0].OnClick := ProcedureArr[0];
end;

constructor TControlButtons.Create(Sender: TWinControl; AForm: TFShedule; aCol, aRow, aCount: integer);
var
  i: integer;
begin
  Col := aCol;
  Row := aRow;
  Count := aCount;
  Form := AForm;
  ID := Form.ScheduleArray[Col, Row].ID[Count];
  Table := Form.SchTable;
  ImageList := Form.ImageList1;

  s := '';
  Flag := false;
  ArrFilter := TArrayFilters.Create(Form.ScrollBox2, Table);
  ArrFilter.AddFilter;
  ArrFilter.Filters[High(ArrFilter.Filters)].ColName.ItemIndex := 0;
  ArrFilter.Filters[High(ArrFilter.Filters)].cmp.ItemIndex := 0;
  ArrFilter.Filters[High(ArrFilter.Filters)].FilterVal.Caption := IntToStr(ID);

  Catalog := Timplementing_catalogs.Create(NumTable, @s, @Flag, ArrFilter);

  AddProcedure(@MyClickVeiwItem);
  AddProcedure(@MyClickEditItem);
  AddProcedure(@MyClickDeleteItem);
  AddProcedure(@MyClickAddNewItem);
  for i := 0 to High(ProcedureArr) do
  begin
    SetLength(ButtonArr, Length(ButtonArr) + 1);
    ButtonArr[i] := TSpeedButton.Create(Sender);
    ButtonArr[i].Parent := Sender;
    Form.ImageList1.GetBitmap(i, ButtonArr[i].Glyph);
    ButtonArr[i].OnClick := ProcedureArr[i];
  end;
end;

procedure TControlButtons.OpenCatalogForm(Sender: TObject);
var
  i: integer;
begin
  Catalog.ApplyFilter;
  for i := 0 to High(EditingForm) do
    EditingForm[i].Close;
end;

procedure TControlButtons.AddFilterForVeiw(List: TMyList; Ind, LastInd: integer;
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

procedure TControlButtons.MyClickVeiwItem(Sender: TObject);
begin
  AddInCatalogs(Form, NumTable);
  AddFilterForVeiw(Form.OxList, Form.OxIndex, Col, Sender);
  AddFilterForVeiw(Form.OyList, Form.OyIndex, Row, Sender);
  Form.ArrayFilters.Copy(Catalogs[High(Catalogs)].ArrayFilters);
  Catalogs[High(Catalogs)].ApplyFilter.Click;
end;

procedure TControlButtons.MyClickEditItem(Sender: TObject);
begin
  OpenCatalogForm(Form);
  Catalog.AddField(False);
  EditingForm[High(EditingForm)].ApplyProc := @Form.ApplyClick;
  FixateEd;
end;

procedure TControlButtons.MyClickDeleteItem(Sender: TObject);
begin
  OpenCatalogForm(Sender);
  Catalog.RemoveItem;
  Form.Apply.Click;
end;

procedure TControlButtons.MyClickAddNewItem(Sender: TObject);
begin
  OpenCatalogForm(Form);
  Catalog.AddField(true);
  EditingForm[High(EditingForm)].ApplyProc := @Form.ApplyClick;
  FixateEd;
end;

procedure TControlButtons.AddProcedure(Proc: TProc);
begin
  SetLength(ProcedureArr, length(ProcedureArr) + 1);
  ProcedureArr[High(ProcedureArr)] := Proc;
end;

procedure TControlButtons.FixateEd;
begin
  EditingForm[High(EditingForm)].FixVal(Form.OxIndex, IntToStr(Col));
  EditingForm[High(EditingForm)].FixVal(Form.OyIndex, IntToStr(Row));
end;

destructor TControlButtons.Destroy;
var
  i: integer;
begin
  for i := 0 to High(ButtonArr) do
    ButtonArr[i].Destroy;
end;

{ ItemForSchedule }
procedure TItemForSchedule.Next(NewId: integer; Sender: TComponent;
  var OneItemHeight: integer);
begin
  Inc(Count);
  SetLength(Item, Count);
  SetLength(Id, Count);
  Item[Count - 1] := TStringList.Create;
  Id[Count - 1] := NewId;
  TotalHeight := OneItemHeight * Count;
end;

procedure TItemForSchedule.Add(S: string; Sender: TComponent;
  var OneItemHeight: integer);
begin
  if Count = 0 then
    Next(-1, Sender, OneItemHeight);
  Item[High(Item)].Add(S);
  OneItemHeight := max(Item[High(Item)].Count * DistToNextLine, OneItemHeight);
end;

{$R *.lfm}

{ TFShedule }

procedure TFShedule.BAddClick(Sender: TObject);
begin
  AddInCatalogs(Sender as TComponent, NumTable);
  Catalogs[High(Catalogs)].ApplyFilter.Click;
  Catalogs[High(Catalogs)].Close;
  Catalogs[High(Catalogs)].AddFieldClick(nil);
  EditingForm[High(Catalogs)].ApplyProc := @FShedule.ApplyClick;
end;

procedure TFShedule.DestroyButtons(var CB: TConButton);
var
  i: integer;
begin
  for i := 0 to High(CB) do
    CB[i].Destroy;
  SetLength(CB, 0);
end;

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
    OutputField.Checked[i - 1] := True;
  end;
  FlagApply := False;
  AddFormatInSaveDialog(FShedule.SaveDialog1);
end;

procedure TFShedule.FileConflictClick(Sender: TObject);
begin
  FConflict.Show;
end;

procedure TFShedule.FileSaveClick(Sender: TObject);
var
  i, j, q: integer;
  DataToSave: TSaveClass;
  HeaderList, FiltersList: TStringList;
begin
  if not FlagApply then
  begin
    ShowMessage('Задайте таблицу для сохранения');
    exit;
  end;
  SaveDialog1.Execute;
  SetLength(DataToSave, OyCount + 1);
  for i := 0 to OyCount do
  begin
    SetLength(DataToSave[i], OxCount + 1);
    for j := 0 to OxCount do
      for q := 0 to High(ScheduleArray[j, i].Item) do
      begin
        SetLength(DataToSave[i, j], q + 1);
        DataToSave[i, j, q] := ScheduleArray[j, i].Item[q];
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

procedure TFShedule.FileCloseClick(Sender: TObject);
begin
  Close;
end;

function ReturnCof(x, y: double): double;
begin
  if (y = 0) then
    Result := 0.2
  else
    Result := sin(pi * (x / y)) * 2 + 0.3;
end;

procedure TFShedule.DGMouseMove(Sender: TObject; Shift: TShiftState; X, Y: integer);
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
    if FlagMoveB then
    begin
      FlagMoveB := false;
      DestroyButtons(ScheduleArray[MouseMovePoint.x, MouseMovePoint.y].ControlButtons);
    end;

    if (ScheduleArray[Cord.x, Cord.y].FlagClick) or (Cord.x * Cord.y = 0) then
      exit;

    FlagMoveB := true;
    for i := 0 to min(DG.RowHeights[Cord.y] div OneItemHeight - 1, ScheduleArray[Cord.x, Cord.y].Count - 1) do
    begin
      SetLength(ScheduleArray[Cord.x, Cord.y].ControlButtons, i + 1);
      ScheduleArray[Cord.x, Cord.y].ControlButtons[i] :=
        TControlButtons.Create(DG, FShedule, Cord.x, Cord.y, i);
    end;

    if (ScheduleArray[Cord.x, Cord.y].Count = 0) then
    begin
      SetLength(ScheduleArray[Cord.x, Cord.y].ControlButtons, 1);
      ScheduleArray[Cord.x, Cord.y].ControlButtons[i] :=
        TControlButtons.AddOnlyCreate(DG, FShedule, Cord.x, Cord.y, 0);
    end;
  end;
  MouseMovePoint := Cord;
  if (ScheduleArray[Cord.x, Cord.y].FlagClick) or (Cord.x * Cord.y = 0) then
    exit;
  if ScheduleArray[Cord.x, Cord.y].Count * OneItemHeight > DG.RowHeights[Cord.y] then
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

procedure TFShedule.DGMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: integer);
var
  Cord: TPoint;
begin
  Cord := DG.MouseToCell(Point(X, Y));
  if (ScheduleArray[Cord.x, Cord.y].Count = 0) or (Cord.x * Cord.y = 0) then
    exit;
  BCount := 0;
  if LastRow > 0 then
  begin
    DestroyButtons(ScheduleArray[LastColumn, LastRow].ControlButtons);
    VeryLastColumn := LastColumn;
    VeryLastRow := LastRow;
    TimerCollapsing.Enabled := ScheduleArray[VeryLastColumn, VeryLastRow].FlagClick;
    if (LastRow <> Cord.y) or (LastColumn <> Cord.x) then
      ScheduleArray[LastColumn, LastRow].FlagClick := False;
  end;
  ScheduleArray[Cord.x, Cord.y].FlagClick := not ScheduleArray[Cord.x, Cord.y].FlagClick;
  DestroyButtons(ScheduleArray[MouseMovePoint.x, MouseMovePoint.y].ControlButtons);
  TimerExtension.Enabled := ScheduleArray[Cord.x, Cord.y].FlagClick and not
    (TimerCollapsing.Enabled);
  if ScheduleArray[Cord.x, Cord.y].FlagClick then
  begin
    LastColumn := Cord.x;
    LastRow := Cord.y;
  end;
  FlagMoveB := false;
end;

procedure TFShedule.TimerExtensionTimer(Sender: TObject);
var
  Cof: double;
begin
  DG.Enabled := False;
  if (BCount < DG.RowHeights[LastRow] div OneItemHeight) and
    (ScheduleArray[LastColumn, LastRow].Count > 0) then
  begin
    BCount := DG.RowHeights[LastRow] div OneItemHeight;
    SetLength(ScheduleArray[LastColumn, LastRow].ControlButtons, BCount);
    ScheduleArray[LastColumn, LastRow].ControlButtons[BCount - 1] :=
      TControlButtons.Create(DG, FShedule, LastColumn, LastRow, BCount - 1);
  end;
  if (DG.RowHeights[LastRow] < ScheduleArray[LastColumn, LastRow].TotalHeight) then
  begin
    Cof := ReturnCof(DG.RowHeights[LastRow], ScheduleArray[LastColumn,
      LastRow].TotalHeight);
    DG.RowHeights[LastRow] := DG.RowHeights[LastRow] + Round(DistToNextLine * Cof);
  end
  else
  begin
    DG.RowHeights[LastRow] := max(ScheduleArray[LastColumn, LastRow].TotalHeight,
      OneItemHeight);
    TimerExtension.Enabled := False;
    DG.Enabled := True;
  end;
end;

procedure TFShedule.TimerCollapsingTimer(Sender: TObject);
var
  APoint: TPoint;
  Cof: double;
  Shift: TShiftState;
  aRect: TRect;
begin
  DG.Enabled := False;
  if (DG.RowHeights[VeryLastRow] > OneItemHeight) then
  begin
    Cof := ReturnCof(DG.RowHeights[VeryLastRow],
      ScheduleArray[VeryLastColumn, VeryLastRow].TotalHeight);
    DG.RowHeights[VeryLastRow] :=
      DG.RowHeights[VeryLastRow] - Round(DistToNextLine * Cof);
  end
  else
  begin
    DG.RowHeights[VeryLastRow] := OneItemHeight;
    TimerCollapsing.Enabled := False;
    if (LastColumn <> VeryLastColumn) or (LastRow <> VeryLastRow) then
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

procedure TFShedule.ApplyClick(Sender: TObject);
var
  i, j, q, counter: integer;
  MainQuery, OrderByVal: string;
  HashItem: TItemForHash;
begin

  OneItemHeight := DistToNextLine * 6;
  if FlagApply then
  begin
    for i := 0 to High(ScheduleArray) do
      for j := 0 to High(ScheduleArray[i]) do
      begin
        if (i > 0) and (j > 0) then
          for q := 0 to High(ScheduleArray[i, j].id) do
            HConflict.Remove(ScheduleArray[i, j].id[q]);
        if (Sender <> nil) then
          DestroyButtons(ScheduleArray[i, j].ControlButtons)
        else
        begin
          SetLength(BForDest, Length(BForDest) + 1);
          BForDest[High(BForDest)] := ScheduleArray[i, j].ControlButtons;
        end;
      end;
    for i := 0 to OxCount do
      for j := 0 to OyCount do
        ScheduleArray[i][j].Destroy;
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

  for i := 0 to OutputField.Items.Count - 1 do
    if (OutputField.Items[i] = OxColName) or (OutputField.Items[i] = OyColName) then
      OutputField.Checked[i] := False;
  HashItem.List := TStringList.Create;
  for i := 0 to OxCount - 1 do
  begin
    for j := 0 to OyCount - 1 do
    begin
      while (SQLQuery1.FieldByName(OyColName).AsString = OyList[j]) and
        (SQLQuery1.FieldByName(OxColName).AsString = OxList[i]) and
        (counter < SQLQuery1.RowsAffected) do
      begin
        ScheduleArray[i + 1, j + 1].Next(
          SQLQuery1.FieldByName(SchTable.Columns[0].NameRus).AsInteger,
          Self, OneItemHeight);
        HashItem.ID := SQLQuery1.FieldByName(SchTable.Columns[0].NameRus).AsInteger;
        HashItem.List.Clear;
        for q := 0 to OutputField.Items.Count - 1 do
        begin
          if OutputField.Checked[q] then
          begin
            HashItem.List.Add(SQLQuery1.FieldByName(OutputField.Items[q]).AsString);
            ScheduleArray[i + 1, j + 1].Add(OutputField.Items[q] +
              ': ' + SQLQuery1.FieldByName(OutputField.Items[q]).AsString,
              Self, OneItemHeight);
          end;
          if (DG.RowHeights[j + 1] < OneItemHeight) then
            DG.RowHeights[j + 1] := OneItemHeight;
        end;
        HConflict.Add(HashItem);
        SQLQuery1.Next;
        Inc(counter);
      end;
    end;
  end;
  DG.Invalidate;
end;

procedure TFShedule.move_buttons (cord: TPoint);
var
  Rect: TRect;
  i: integer;
begin
  Rect := Self.DG.CellRect(cord.x, cord.y);
  for i := 0 to High(ScheduleArray[cord.x, cord.y].ControlButtons) do
  begin
    ScheduleArray[cord.x, cord.y].ControlButtons[i].move
    (Rect.Right, Rect.Top + i * OneItemHeight);
  end;
end;

procedure TFShedule.DGDrawCell(Sender: TObject; aCol, aRow: integer;
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

  if FlagMoveB then
    move_buttons(MouseMovePoint);
  move_buttons(Point(LastColumn, LastRow));

  DG.Canvas.Brush.Style := bsClear;
  if (aCol = LastColumn) and (aRow = LastRow) and//Отрисовка рамки для выделеной ячейки
    ScheduleArray[aCol, aRow].FlagClick then
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
  if (DG.RowHeights[aRow] < ScheduleArray[aCol, aRow].TotalHeight) and
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
  HConflict := THash.Create;

end.
