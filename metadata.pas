unit metadata;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, db;


type ColumnInfo = record
  Width: integer;
  NameEng: string;
  NameRus: string;
  Clarification: boolean;
  Ref, RefPar, RefVal: string;
  DataType: TFieldType;
end;

{ TTableInfo }

TTableInfo = class(TObject)
public
  TableNameRus: string;
  TableNameEng: string;
  ObjCounterName: string;
  SortParam: string;
  Columns: array of ColumnInfo;
  procedure AddColumn (NameRus, NameEng, RefT, RefP, RefV: String; DT: TFieldType;
    W: integer; AClarification: boolean);
  constructor Create (NameRus, NameEng: string);
end;

function ReturnSortPar (TableName, ColName: String): String;
function ReturnRusName (TableName, ItemName: string): String;

var
  Table: array of TTableInfo;

const
  include = 'Включает';

implementation

function ReturnSortPar(TableName, ColName: String): String;
var
  i: integer;
begin
  for i := 0 to High(Table) do
    if Table[i].TableNameEng = TableName then
    begin
      result := Table[i].SortParam;
      if Result = 'NO' then
        Result := ColName;
      exit;
    end;
end;

function ReturnRusName(TableName, ItemName: string): String;
var
  i: integer;
begin
  //for i := 0 to High(Table) do
  //  if Table[i].TableNameEng = TableName then
  //    for j := 0 to Table[i].
end;

procedure TTableInfo.AddColumn(NameRus, NameEng, RefT, RefP, RefV: String; DT: TFieldType;
  W: integer; AClarification: boolean);
begin
  SetLength(Columns, Length(Columns) + 1);
  Columns[High(Columns)].NameEng := NameEng;
  Columns[High(Columns)].NameRus := NameRus;
  Columns[High(Columns)].Ref := RefT;
  Columns[High(Columns)].RefPar := RefP;
  Columns[High(Columns)].RefVal := RefV;
  Columns[High(Columns)].Width := W;
  Columns[High(Columns)].DataType := DT;
  Columns[High(Columns)].Clarification := AClarification;
end;

constructor TTableInfo.Create(NameRus, NameEng: string);
begin
  TableNameEng := NameEng;
  TableNameRus := NameRus;
end;

procedure AddTable (S1, S2, S3, SortPAram: string);
begin
  setlength(Table, Length(Table) + 1);
  Table[High(Table)] := TTableInfo.Create(S1, S2);
  Table[High(Table)].ObjCounterName := S3;
  Table[High(Table)].SortParam := SortParam;
end;

procedure AddColumnInLastTables (S1, S2, RefT, RefP, RefV: string; DT: TFieldType;
  W: integer; AClarification: boolean);
begin
  Table[High(Table)].AddColumn(S1, S2, RefT, RefP, RefV, DT, W, AClarification);
end;

initialization

  AddTable('Дни недели', 'DAYS', 'Day_Index', 'ID');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 70, false);
  AddColumnInLastTables('День', 'NAME', '', '', '', ftString, 100, false);

  AddTable('Группы', 'GROUPS', 'Group_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40, false);
  AddColumnInLastTables('Номер', 'NAME', '', '', '', ftString, 70, false);
  AddColumnInLastTables('Размер', 'GROUP_SIZE', '', '', '', ftInteger, 60, false);

  AddTable('Профессора', 'PROFESSORS', 'Professor_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40, false);
  AddColumnInLastTables('Ф.И.О', 'NAME', '', '', '', ftString, 150, false);

  AddTable('Профессора - предметы', 'PROFESSORS_SUBJECTS', 'PS_ID', 'NO');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40, false);
  AddColumnInLastTables('Профессор', 'PROFESSOR_ID', 'PROFESSORS', 'ID', 'NAME', ftString, 150, false);
  AddColumnInLastTables('Предмет', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', ftString, 400, false);

  AddTable('Аудитории', 'ROOMS', 'Room_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40, false);
  AddColumnInLastTables('Номер', 'NAME', '', '', '', ftString, 60, false);
  AddColumnInLastTables('Вместимость', 'Size_', '', '', '', ftInteger, 90, false);

  AddTable('Расписание', 'SCHEDULE_ITEMS', 'Item_ID', 'NO');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40, false);
  AddColumnInLastTables('Предмет', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', ftString, 400, false);
  AddColumnInLastTables('Тип лекции', 'SUBJECT_TYPE_ID', 'SUBJECT_TYPES', 'ID', 'NAME', ftString, 100, true);
  AddColumnInLastTables('Имя профессора', 'PROFESSOR_ID', 'PROFESSORS', 'ID', 'NAME', ftString, 150, false);
  AddColumnInLastTables('Номер пары', 'TIME_INDEX', '', '', '', ftInteger, 70, true);
  AddColumnInLastTables('День недели', 'DAY_INDEX', 'DAYS', 'ID', 'NAME', ftString, 70, false);
  AddColumnInLastTables('№ группы', 'GROUP_ID', 'GROUPS', 'ID', 'NAME', ftString, 70, true);
  AddColumnInLastTables('Кабинет', 'ROOM_ID', 'ROOMS', 'ID', 'NAME', ftString, 70, true);
  AddColumnInLastTables('Неделя', 'Week', '', '', '', ftString, 60, true);

  AddTable('Предметы', 'SUBJECTS', 'Subject_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40, false);
  AddColumnInLastTables('Предмет', 'NAME', '', '', '', ftString, 350, false);

  AddTable('Предметы - группы', 'SUBJECTS_GROUPS', 'SG_ID', 'NO');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40, false);
  AddColumnInLastTables('ID предмета', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', ftString, 400, false);
  AddColumnInLastTables('ID группы', 'GROUP_ID', 'GROUPS', 'ID', 'NAME', ftString, 90, false);

  AddTable('Типы лекций', 'SUBJECT_TYPES', 'Type_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40, false);
  AddColumnInLastTables('Тип', 'NAME', '', '', '', ftString, 40, false);

  AddTable('Пары', 'TIMES', 'Time_Index', 'Begin_');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 60, false);
  AddColumnInLastTables('Начало', 'Begin_', '', '', '', ftString, 70, false);
  AddColumnInLastTables('Конец', 'End_', '', '', '', ftString, 70, false);
end.
