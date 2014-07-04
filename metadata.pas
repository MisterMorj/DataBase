unit metadata;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, db;


type ColumnInfo = record
  Width: integer;
  NameEng: string;
  NameRus: string;
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
  procedure AddColumn (NameRus, NameEng, RefT, RefP, RefV: String; DT: TFieldType; W: integer);
  constructor Create (NameRus, NameEng: string);
end;

function ReturnSortPar (TableName: String; ColName: String): String;

var
  Table: array of TTableInfo;

const
  NumberOfTables = 10;
  include = 'Включает';

implementation

function ReturnSortPar(TableName: String; ColName: String): String;
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

procedure TTableInfo.AddColumn(NameRus, NameEng, RefT, RefP, RefV: String; DT: TFieldType; W: integer);
begin
  SetLength(Columns, Length(Columns) + 1);
  Columns[High(Columns)].NameEng := NameEng;
  Columns[High(Columns)].NameRus := NameRus;
  Columns[High(Columns)].Ref := RefT;
  Columns[High(Columns)].RefPar := RefP;
  Columns[High(Columns)].RefVal := RefV;
  Columns[High(Columns)].Width := W;
  Columns[High(Columns)].DataType := DT;
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

procedure AddColumnInLastTables (S1, S2, RefT, RefP, RefV: string; DT: TFieldType; W: integer);
begin
  Table[High(Table)].AddColumn(S1, S2, RefT, RefP, RefV, DT, W);
end;

initialization

  AddTable('Дни недели', 'DAYS', 'Day_Index', 'ID');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 70);
  AddColumnInLastTables('День', 'NAME', '', '', '', ftString, 100);

  AddTable('Группы', 'GROUPS', 'Group_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40);
  AddColumnInLastTables('Номер', 'NAME', '', '', '', ftString, 70);
  AddColumnInLastTables('Размер', 'GROUP_SIZE', '', '', '', ftInteger, 60);

  AddTable('Профессора', 'PROFESSORS', 'Professor_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40);
  AddColumnInLastTables('Ф.И.О', 'NAME', '', '', '', ftString, 150);

  AddTable('Профессора - предметы', 'PROFESSORS_SUBJECTS', 'PS_ID', 'NO');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40);
  AddColumnInLastTables('Профессор', 'PROFESSOR_ID', 'PROFESSORS', 'ID', 'NAME', ftString, 150);
  AddColumnInLastTables('Предмет', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', ftString, 400);

  AddTable('Аудитории', 'ROOMS', 'Room_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40);
  AddColumnInLastTables('Номер', 'NAME', '', '', '', ftString, 60);
  AddColumnInLastTables('Вместимость', 'Size_', '', '', '', ftInteger, 90);

  AddTable('Расписание', 'SCHEDULE_ITEMS', 'Item_ID', 'NO');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40);
  AddColumnInLastTables('Предмет', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', ftString, 400);
  AddColumnInLastTables('Тип лекции', 'SUBJECT_TYPE_ID', 'SUBJECT_TYPES', 'ID', 'NAME', ftString, 100);
  AddColumnInLastTables('Имя профессора', 'PROFESSOR_ID', 'PROFESSORS', 'ID', 'NAME', ftString, 150);
  AddColumnInLastTables('Номер пары', 'TIME_INDEX', '', '', '', ftInteger, 70);
  AddColumnInLastTables('День недели', 'DAY_INDEX', 'DAYS', 'ID', 'NAME', ftString, 70);
  AddColumnInLastTables('№ группы', 'GROUP_ID', 'GROUPS', 'ID', 'NAME', ftString, 70);
  AddColumnInLastTables('Кабинет', 'ROOM_ID', 'ROOMS', 'ID', 'NAME', ftString, 70);
  AddColumnInLastTables('Неделя', 'Week', '', '', '', ftString, 60);

  AddTable('Предметы', 'SUBJECTS', 'Subject_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40);
  AddColumnInLastTables('Предмет', 'NAME', '', '', '', ftString, 350);

  AddTable('Предметы - группы', 'SUBJECTS_GROUPS', 'SG_ID', 'NO');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40);
  AddColumnInLastTables('ID предмета', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', ftString, 400);
  AddColumnInLastTables('ID группы', 'GROUP_ID', 'GROUPS', 'ID', 'NAME', ftString, 90);

  AddTable('Типы лекций', 'SUBJECT_TYPES', 'Type_ID', 'NAME');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 40);
  AddColumnInLastTables('Тип', 'NAME', '', '', '', ftString, 40);

  AddTable('Пары', 'TIMES', 'Time_Index', 'Begin_');
  AddColumnInLastTables('ID', 'ID', '', '', '', ftInteger, 60);
  AddColumnInLastTables('Начало', 'Begin_', '', '', '', ftString, 70);
  AddColumnInLastTables('Конец', 'End_', '', '', '', ftString, 70);
end.
