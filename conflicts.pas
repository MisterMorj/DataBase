unit conflicts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Hash, sqldb, db, metadata, Filters, UCatalogs, Ueditingform;

type

  TFieldForComparison = record
    Cmp: string;
    Val_tbl1, Val_tbl2: string;
  end;

  TInnerJoin = record
    InnerJoinTable: string;
    NewName: string;
    CompField: array of TFieldForComparison;
  end;

  { TFConflict }

  TFConflict = class(TForm)
    DataSource1: TDataSource;
    ScrollBox1: TScrollBox;
    SQLQuery1: TSQLQuery;
    TreeView1: TTreeView;
    procedure FindConflicts;
    procedure TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  public
    ProcApply: TProc;
  private
    TblSch: TTableInfo;
    AbsoluteIndexID: array of integer;
  end;

  { TConflict }

  TConflict = class(TObject)
    Header: String;
    Titles: array of string;
    InnerJoinList: array of TInnerJoin;
    WhereParam: string;
    procedure AddInnerJoin(TableName: string);
    procedure AddNewTitle (Title: string);
    procedure AddCMPField(Field_tbl1, CMP, Field_tbl2: string);
    function ReturnSqlQuery: string;
  end;

procedure AddConflict (AHeader: string);

var
  FConflict: TFConflict;
  ArrConflict: array of TConflict;
  HAllItems, HKeyConflicts: THash;
implementation

procedure AddConflict(AHeader: string);
begin
  SetLength(ArrConflict, Length(ArrConflict) + 1);
  ArrConflict[High(ArrConflict)] := TConflict.Create;
  ArrConflict[High(ArrConflict)].Header := AHeader;
end;

{$R *.lfm}

{ TFConflict }

procedure TFConflict.FindConflicts;
var
  i, j, q, k, ItemNum, MainHeaderNum, ConflictHeaderNum: integer;
  NowRecord, LocalStrList: TStringList;
  TitleOneConflict, PastConflicts, LastItem: string;
begin
  TreeView1.Items.Clear;
  TblSch := Table[5];
  for i := 0 to High(ArrConflict) do
  begin
    TreeView1.Items.AddChild(Nil, ArrConflict[i].Header);
    SetLength(AbsoluteIndexID, Length(AbsoluteIndexID) + 1);
    MainHeaderNum := TreeView1.Items.Count - 1;
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := ArrConflict[i].ReturnSqlQuery;
    SQLQuery1.Open;
    for ItemNum := 0 to SQLQuery1.RowsAffected - 1 do
    begin
      HKeyConflicts.AddNewItemInRecord(SQLQuery1.FieldByName(TblSch.Columns[0].NameEng).Value, ArrConflict[i].Header);
      LocalStrList := HAllItems.ReturnVal(SQLQuery1.FieldByName(TblSch.Columns[0].NameEng).Value).List;
      TitleOneConflict := '';
      LastItem := '';
      for j := 0 to LocalStrList.Count - 1 do
      begin
        if TblSch.Columns[j + 1].Clarification then
          LastItem += TblSch.Columns[j + 1].NameRus + ': ';
        LastItem += LocalStrList[j];
        if j < LocalStrList.Count - 1 then
          LastItem += ', ';
      end;
      for j := 0 to High(ArrConflict[i].Titles) do
        for q := 0 to High(TblSch.Columns) do
          if ArrConflict[i].Titles[j] = TblSch.Columns[q].NameEng then
          begin
            if TblSch.Columns[q].Clarification then
              TitleOneConflict += TblSch.Columns[q].NameRus + ': ';
            TitleOneConflict += LocalStrList[q - 1];
            if j <> High(ArrConflict[i].Titles) then
              TitleOneConflict += ', ';
          end;
      if PastConflicts <> TitleOneConflict then
      begin
        TreeView1.Items.AddChild(TreeView1.Items[MainHeaderNum], TitleOneConflict);
        SetLength(AbsoluteIndexID, Length(AbsoluteIndexID) + 1);
        ConflictHeaderNum := TreeView1.Items.Count - 1;
      end;
      TreeView1.Items.AddChild(TreeView1.Items[ConflictHeaderNum], LastItem);
      SetLength(AbsoluteIndexID, Length(AbsoluteIndexID) + 1);
      AbsoluteIndexID[High(AbsoluteIndexID)] :=
        SQLQuery1.FieldByName(TblSch.Columns[0].NameEng).Value;
      PastConflicts := TitleOneConflict;
      SQLQuery1.Next;
    end;
  end;
end;

procedure TFConflict.TreeView1MouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Filters: TArrayFilters;
  Catalog: Timplementing_catalogs;
  f: boolean;
  s: string;
  i: integer;
begin
  s := '';
  f := false;
  if TreeView1.GetNodeAt(X, Y) <> nil then
    if TreeView1.GetNodeAt(X, Y).Selected and not TreeView1.GetNodeAt(X, Y).HasChildren then
    begin
      Filters := TArrayFilters.Create(Self.ScrollBox1, TblSch);
      Filters.AddFilterWithFixId(AbsoluteIndexID[TreeView1.GetNodeAt(X, Y).AbsoluteIndex]);
      Catalog := Timplementing_catalogs.Create(5, @s, @f, Filters);
      Catalog.ApplyFilter;
      for i := 0 to High(EditingForm) do
        EditingForm[i].Close;
      Catalog.AddField(False);
      EditingForm[High(EditingForm)].ApplyProc := ProcApply;
    end;
end;

{ TFConflict }


{ TConflict }

procedure TConflict.AddInnerJoin(TableName: string);
begin
  SetLength(InnerJoinList, Length(InnerJoinList) + 1);
  InnerJoinList[High(InnerJoinList)].InnerJoinTable := TableName;
  InnerJoinList[High(InnerJoinList)].NewName := 'Tbl' + IntToStr(High(InnerJoinList));
end;

procedure TConflict.AddNewTitle(Title: string);
begin
  SetLength(Titles, Length(Titles) + 1);
  Titles[High(Titles)] := Title;
end;

procedure TConflict.AddCMPField (Field_tbl1, CMP, Field_tbl2: string);
begin
  SetLength(InnerJoinList[High(InnerJoinList)].CompField, Length(InnerJoinList[High(InnerJoinList)].CompField) + 1);
  InnerJoinList[High(InnerJoinList)].CompField[High(InnerJoinList[High(InnerJoinList)].CompField)].Val_tbl1 := Field_tbl1;
  InnerJoinList[High(InnerJoinList)].CompField[High(InnerJoinList[High(InnerJoinList)].CompField)].Val_tbl2 := Field_tbl2;
  InnerJoinList[High(InnerJoinList)].CompField[High(InnerJoinList[High(InnerJoinList)].CompField)].CMP := CMP;
end;

function TConflict.ReturnSqlQuery: string;
var
  Query: string;
  i, j: integer;
begin
  Query += ' SELECT DISTINCT SCHEDULE_ITEMS.ID FROM SCHEDULE_ITEMS ';
  for i := 0 to High(InnerJoinList) do
  begin
    Query += ' INNER JOIN ';
    Query += InnerJoinList[i].InnerJoinTable + ' ' + InnerJoinList[i].NewName;
    Query += ' ON ';
    for j := 0 to High(InnerJoinList[i].CompField) do
    begin
      if j > 0 then
        Query += ' AND ';
      Query += InnerJoinList[i].NewName + '.' + InnerJoinList[i].CompField[j].Val_tbl2;
      Query += ' ' + InnerJoinList[i].CompField[j].Cmp + ' ';
      Query += 'SCHEDULE_ITEMS' + '.' + InnerJoinList[i].CompField[j].Val_tbl1;
    end;
  end;
  Query += ' ' + WhereParam;
  Query += ' ORDER BY ';
  for i := 0 to High(Titles) do
  begin
    Query += 'SCHEDULE_ITEMS' + '.' + Titles[i];
    if i < High(Titles) then
      Query += ', ';
  end;
  Result := Query;
end;

initialization

  AddConflict('Два преподавателя в одной аудитории в одно время');
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');
  ArrConflict[High(ArrConflict)].AddCMPField('PROFESSOR_ID', '<>', 'PROFESSOR_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=', 'DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '=', 'ROOM_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=', 'TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=', 'WEEK');
  ArrConflict[High(ArrConflict)].AddNewTitle('ROOM_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('Week');
  ArrConflict[High(ArrConflict)].WhereParam := '';

  AddConflict('Одна группы в одно время в разных аудиториях');
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '<>', 'ROOM_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=', 'DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=', 'TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('GROUP_ID', '=', 'GROUP_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=', 'WEEK');
  ArrConflict[High(ArrConflict)].AddNewTitle('GROUP_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('Week');
  ArrConflict[High(ArrConflict)].WhereParam := '';

  AddConflict('Один преподователь в разных аудиториях в одно время');
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '<>', 'ROOM_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=', 'DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=', 'TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('PROFESSOR_ID', '=', 'PROFESSOR_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=', 'WEEK');
  ArrConflict[High(ArrConflict)].AddNewTitle('PROFESSOR_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('Week');
  ArrConflict[High(ArrConflict)].WhereParam := '';

  AddConflict('В одной аудитории в одно время разные типы лекций');
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '=', 'ROOM_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=', 'DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=', 'TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=', 'WEEK');
  ArrConflict[High(ArrConflict)].AddCMPField('SUBJECT_TYPE_ID', '<>', 'SUBJECT_TYPE_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('ROOM_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('Week');
  ArrConflict[High(ArrConflict)].WhereParam := '';

  AddConflict('Аудитория вмещает меньше людей чем в ней есть по рассписанию');
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');
  ArrConflict[High(ArrConflict)].AddCMPField('GROUP_ID', '<>', 'GROUP_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=', 'DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=', 'TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=', 'WEEK');
  ArrConflict[High(ArrConflict)].AddInnerJoin('ROOMS');
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '=', 'ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('GROUP_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('ROOM_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('Week');
  ArrConflict[High(ArrConflict)].WhereParam := 'WHERE ' +
     ArrConflict[High(ArrConflict)].InnerJoinList[1].NewName +
    '.SIZE_ < (SELECT sum(GROUPS.GROUP_SIZE) FROM' +
    ' GROUPS WHERE GROUPS.ID' +
    '= SCHEDULE_ITEMS.GROUP_ID group BY GROUPS.GROUP_SIZE)';

  AddConflict('В одной аудитории в одно время разные предметы');
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '=', 'ROOM_ID');
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=', 'DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=', 'TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=', 'WEEK');
  ArrConflict[High(ArrConflict)].AddCMPField('SUBJECT_ID', '<>', 'SUBJECT_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('ROOM_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('Week');
  ArrConflict[High(ArrConflict)].WhereParam := '';

  AddConflict('Преподователь не ведет данный предмет');
  ArrConflict[High(ArrConflict)].AddNewTitle('ROOM_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('DAY_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('TIME_INDEX');
  ArrConflict[High(ArrConflict)].AddNewTitle('Week');
  ArrConflict[High(ArrConflict)].AddNewTitle('SUBJECT_ID');
  ArrConflict[High(ArrConflict)].AddNewTitle('PROFESSOR_ID');
  ArrConflict[High(ArrConflict)].WhereParam := 'WHERE 1 > ' +
    '(SELECT count(*) FROM PROFESSORS_SUBJECTS ' +
    'WHERE PROFESSORS_SUBJECTS.PROFESSOR_ID = SCHEDULE_ITEMS.PROFESSOR_ID ' +
    'AND PROFESSORS_SUBJECTS.SUBJECT_ID = SCHEDULE_ITEMS.SUBJECT_ID) ';


end.

