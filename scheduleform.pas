unit ScheduleForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, DB, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Grids, DBCtrls, ColorBox, SqlComponents, metadata,
  Filters, UQuery, types, UCatalogs, Spin, Buttons, Ueditingform;

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
    OneItemHeight: integer;
    TotalHeight: integer;
    procedure Next(NewId: integer; Sender: TComponent);
    procedure Add(S: String; sender: TComponent);
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
    AxisY: TComboBox;
    AxisX: TComboBox;
    ImageList1: TImageList;
    OutputField: TCheckGroup;
    DrawGrid1: TDrawGrid;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    SQLQuery1: TSQLQuery;
    Timer1: TTimer;
    procedure DrawGrid1SelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure FindRefAndColumn(Axis: TComboBox; var RefTable: string;
      var RefColumn: string; var RusColName: string; ind: integer);
    procedure addFilterClick(Sender: TObject);
    procedure ApplyClick(Sender: TObject);
    procedure DrawGrid1DrawCell(Sender: TObject; aCol, aRow: integer;
      aRect: TRect; aState: TGridDrawState);
    procedure FormCreate(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    procedure AxisQuery(RefTable: string; RefColumm: string; var List: TMyList;
      var Count: integer; var SortParam: string);
    procedure DestroyButtons;
    { private declarations }
  public
    ButtonCount: integer;
    SortParamX, SortParamY: string;
    LastColumn, LastValue, LastRow: integer;
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
  ColumnWidths = 250;
  DistToNextLine = 15;
  FirstColumnH = 40;
  NumTable = 5;
  EditButtonSize = 20;
  TableDays = 'DAYS';
  SortParDays = 'ID';
implementation

{ TControlButtons }
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

procedure TControlButtons.move (x, y: integer);
begin
  FormatButton(x, y, ViewItem);
  FormatButton(x, y + EditButtonSize, EditItem);
  FormatButton(x, y + EditButtonSize * 2, DeleteItem);
  FormatButton(x, y + EditButtonSize * 3, AddNewItem);
end;

constructor TControlButtons.create(Sender: TWinControl; AId: Integer; ATable: TTableInfo);
begin
  ID := AId;
  Table := ATable;

  ViewItem := TSpeedButton.Create(Sender);
  ViewItem.Parent := Sender;
  ViewItem.OnClick := @MyClickVeiwItem;
  FShedule.ImageList1.GetBitmap(0, ViewItem.Glyph);/////////////////////

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
  Catalogs[High(Catalogs)].AddFieldClick(nil);
  Catalogs[High(Catalogs)].Close;
  EditingForm[High(EditingForm)].ApplyProc := @FShedule.ApplyClick;
end;

{ ItemForSchedule }

procedure TFShedule.DestroyButtons;
var
  i: integer;
begin
  for i := 0 to High(ScheduleArray[LastColumn, LastRow].ControlButtons) do
  begin
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].ViewItem.Destroy;
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].EditItem.Destroy;
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].DeleteItem.Destroy;
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].AddNewItem.Destroy;
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].Destroy;
  end;
  SetLength(ScheduleArray[LastColumn, LastRow].ControlButtons, 0);
end;

procedure TItemForSchedule.Next (NewId: integer; Sender: TComponent);
begin
  inc(Count);
  SetLength(Item, Count);
  SetLength(Id, Count);
  Item[Count - 1] := TStringList.Create;
  Id[Count - 1] := NewId;
  TotalHeight := OneItemHeight * Count;
end;

procedure TItemForSchedule.Add(S: String; sender: TComponent);
begin
  if Count = 0 then
    Next(-1, Sender);
  Item[High(Item)].Add(S);
  if Item[High(Item)].Count * DistToNextLine > OneItemHeight  then
    OneItemHeight := Item[High(Item)].Count * DistToNextLine;
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
    AxisX.Items.Add(SchTable.Columns[i].NameRus);
    AxisX.ItemIndex := 0;
    AxisY.Items.Add(SchTable.Columns[i].NameRus);
    AxisY.ItemIndex := 0;
    OutputField.Items.Add(SchTable.Columns[i].NameRus);
    OutputField.Checked[i - 1] := true;
  end;
  FlagApply := false;
end;

function ReturnCof (x, y :double) : double;
begin
  if (y = 0) then
    Result := 1
  else
    Result := sin(pi * (x / y)) * 1.5 + 1;
end;

procedure TFShedule.Timer1Timer(Sender: TObject);
var
  Cof: Double;
  aRect: TRect;
begin
  if ScheduleArray[DrawGrid1.Col, DrawGrid1.Row].OneItemHeight <> 0 then
  if ButtonCount < DrawGrid1.RowHeights[DrawGrid1.Row] div ScheduleArray[DrawGrid1.Col, DrawGrid1.Row].OneItemHeight then
  begin
    ButtonCount := DrawGrid1.RowHeights[DrawGrid1.Row] div ScheduleArray[DrawGrid1.Col, DrawGrid1.Row].OneItemHeight;
    aRect := Self.DrawGrid1.CellRect(DrawGrid1.Col, DrawGrid1.Row);
    SetLength(ScheduleArray[DrawGrid1.Col, DrawGrid1.Row].ControlButtons, ButtonCount);
    ScheduleArray[DrawGrid1.Col, DrawGrid1.Row].ControlButtons[ButtonCount - 1] :=
      TControlButtons.create
      (DrawGrid1, ScheduleArray[DrawGrid1.Col, DrawGrid1.Row].Id[ButtonCount - 1], SchTable);
  end;
  if (DrawGrid1.RowHeights[DrawGrid1.Row] < ScheduleArray[DrawGrid1.Col, DrawGrid1.Row].TotalHeight) then
  begin
    Cof := ReturnCof(DrawGrid1.RowHeights[DrawGrid1.Row], ScheduleArray[DrawGrid1.Col, DrawGrid1.Row].TotalHeight);
    DrawGrid1.RowHeights[DrawGrid1.Row] := DrawGrid1.RowHeights[DrawGrid1.Row] + Round(DistToNextLine * Cof)
  end
  else
    Timer1.Enabled := false;
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

procedure TFShedule.DrawGrid1SelectCell(Sender: TObject; aCol, aRow: Integer;
  var CanSelect: Boolean);
var
  i: integer;
begin
  if Timer1.Enabled = False then
    ButtonCount := 0;
  if not(FlagApply) then
    exit;
  if LastRow <> 0 then
  begin
    DrawGrid1.RowHeights[LastRow] := LastValue;
    if (LastRow <> aRow) or (LastColumn <> aCol) then
      ScheduleArray[LastColumn, LastRow].FlagClick := false;
    DestroyButtons;
  end;
  ScheduleArray[aCol, aRow].FlagClick := not ScheduleArray[aCol, aRow].FlagClick;
  Timer1.Enabled := ScheduleArray[aCol, aRow].FlagClick;
  if ScheduleArray[aCol, aRow].FlagClick then
  begin
    LastRow := aRow;
    LastColumn := aCol;
    LastValue := DrawGrid1.RowHeights[aRow];
    ButtonCount := 0;
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
  flagbreak: boolean;
  MainQuery: string;
  OxList, OyList: array of string;
begin
  if FlagApply then
  begin
    DestroyButtons;
    for i := 0 to OxCount do
      for j := 0 to OyCount do
        ScheduleArray[i][j].Destroy;
  end;
  OxCount := 0; OyCount := 0;

  for i := 0 to High(SchTable.Columns) do
  begin
    FindRefAndColumn(AxisX, OXRefTable, OXRefColumn, OxColName, i);
    FindRefAndColumn(AxisY, OYRefTable, OYRefColumn, OyColName, i);
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
        ScheduleArray[i, j].Add(OyList[j - 1], Self);
      if (i <> 0) and (j = 0) then
        ScheduleArray[i, j].Add(OxList[i - 1], Self);
    end;
  DrawGrid1.ColCount := OxCount + 1;
  DrawGrid1.RowCount := OyCount + 1;
  DrawGrid1.FixedCols := 1;
  DrawGrid1.FixedRows := 1;

  MainQuery := MakeQuery(SchTable, ' ORDER BY ' + OXRefTable + '.' + SortParamX +
    ', ' + OYRefTable + '.' + SortParamY, False, ArrayFilters);
  ApplyQuery(SQLQuery1, MainQuery, ArrayFilters);
  i := -1; j := 0; counter := 0; flagbreak := false; LastColumn := 0;

  for i := 0 to OyCount do
    DrawGrid1.RowHeights[i] := DistToNextLine;
  DrawGrid1.RowHeights[0] := FirstColumnH;

  for i := 0 to OxCount - 1 do
    begin
      for j := 0 to OyCount - 1 do
        begin
          while (SQLQuery1.FieldByName(OyColName).AsString = OyList[j])
            and (SQLQuery1.FieldByName(OxColName).AsString = OxList[i])
            and (counter < SQLQuery1.RowsAffected) do
          begin
            ScheduleArray[i + 1, j + 1].Next(SQLQuery1.FieldByName(SchTable.Columns[0].NameRus).AsInteger, Self);
            for q := 0 to OutputField.Items.Count - 1 do
            begin
              if OutputField.Checked[q] then
              begin
                ScheduleArray[i + 1, j + 1].Add(OutputField.Items[q] + ': '
                  + SQLQuery1.FieldByName(OutputField.Items[q]).AsString, Self);
              end;
              if (DrawGrid1.RowHeights[j + 1] < ScheduleArray[i + 1, j + 1].OneItemHeight) then
                DrawGrid1.RowHeights[j + 1] := ScheduleArray[i + 1, j + 1].OneItemHeight;
            end;
            SQLQuery1.Next;
            inc(counter);
          end;
        end;
    end;
  DrawGrid1.Invalidate;
end;

procedure TFShedule.DrawGrid1DrawCell(Sender: TObject; aCol, aRow: integer;
  aRect: TRect; aState: TGridDrawState);
var
  i, j: Integer;
  LocalTop, LineHeight: integer;
  R: TRect;
begin
  FlagApply := True;
  if (aCol = 0) and (aRow = 0) then
  begin
    DrawGrid1.Canvas.Font.Height := 18;
    DrawGrid1.Canvas.TextOut(aRect.Left + 2, aRect.Bottom - 20, AxisY.Text);
    DrawGrid1.Canvas.TextOut(aRect.Right - Length(AxisX.Text) * 4, aRect.Top - 2, AxisX.Text);
    DrawGrid1.Canvas.Brush.Color := clPurple;
    DrawGrid1.Canvas.Pen.Color := clBlack;
    DrawGrid1.Canvas.Rectangle(aRect.Right div 2, aRect.Top, aRect.Left, aRect.Bottom div 2);
    DrawGrid1.Canvas.Rectangle(aRect.Right div 2, aRect.Bottom div 2, aRect.Right, aRect.Bottom);
  end;

  DrawGrid1.ColWidths[aCol] := ColumnWidths;
  for i := 0 to ScheduleArray[aCol, aRow].Count - 1 do
  begin
    for j := 0 to ScheduleArray[aCol, aRow].Item[i].Count - 1 do
    begin
      LocalTop := aRect.Top + j * DistToNextLine + i * ScheduleArray[aCol, aRow].OneItemHeight;
      DrawGrid1.Canvas.TextOut(aRect.Left + 2, LocalTop, ScheduleArray[aCol, aRow].Item[i][j]);
    end;
    LineHeight := aRect.Top + ScheduleArray[aCol, aRow].OneItemHeight * (i + 1) - 1;
    DrawGrid1.Canvas.Line(aRect.Left, LineHeight, aRect.Right, LineHeight);
  end;
  for i := 0 to High(ScheduleArray[LastColumn, LastRow].ControlButtons) do
  begin
    R := Self.DrawGrid1.CellRect(LastColumn, LastRow);
    ScheduleArray[LastColumn, LastRow].ControlButtons[i].move
      (R.Right, R.Top + i * ScheduleArray[LastColumn, LastRow].OneItemHeight);
  end;
end;

end.
