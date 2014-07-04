unit metadata;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs;

type ColumnInfo = record
  Width: integer;
  NameEng: string;
  NameRus: string;
  Ref, RefPar, RefVal: string;
  DataType: string;
end;

TTableInfo = class(TObject)
public
  TableNameRus: string;
  TableNameEng: string;
  Columns: array of ColumnInfo;
  procedure AddColumn (NameRus, NameEng, RefT, RefP, RefV, DT: string; W: integer);
  constructor Create (NameRus, NameEng: string);
end;

var
  Table: array of TTableInfo;

const
  NumberOfTables = 10;

implementation

procedure TTableInfo.AddColumn(NameRus, NameEng, RefT, RefP, RefV, DT: string; W: integer);
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

procedure AddTable (S1, S2: string);
begin
  setlength(Table, Length(Table) + 1);
  Table[High(Table)] := TTableInfo.Create(S1, S2);
end;

procedure AddColumnInLastTables (S1, S2, RefT, RefP, RefV, DT: string; W: integer);
begin
  Table[High(Table)].AddColumn(S1, S2, RefT, RefP, RefV, DT, W);
end;

initialization

  AddTable('Дни недели', 'DAYS');
  AddColumnInLastTables('Индекс', '"Index"', '', '', '', 'Int', 70);
  AddColumnInLastTables('День', 'NAME', '', '', '', 'Str', 100);

  AddTable('Группы', 'GROUPS');
  AddColumnInLastTables('ID', 'ID', '', '', '', 'Int', 40);
  AddColumnInLastTables('Номер', 'NAME', '', '', '', 'Str', 70);
  AddColumnInLastTables('Размер', 'GROUP_SIZE', '', '', '', 'Str', 60);

  AddTable('Профессора', 'PROFESSORS');
  AddColumnInLastTables('ID', 'ID', '', '', '', 'Int', 40);
  AddColumnInLastTables('Ф.И.О', 'NAME', '', '', '', 'Str', 150);

  AddTable('Професора - предметы', 'PROFESSORS_SUBJECTS');
  AddColumnInLastTables('ID', 'ID', '', '', '', 'Int', 40);
  AddColumnInLastTables('Профессор', 'PROFESSOR_ID', 'PROFESSORS', 'ID', 'NAME', 'Str', 150);
  AddColumnInLastTables('Предмет', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', 'Str', 400);

  AddTable('Аудитории', 'ROOMS');
  AddColumnInLastTables('ID', 'ID', '', '', '', 'Int', 40);
  AddColumnInLastTables('Номер', 'NAME', '', '', '', 'Str', 60);
  AddColumnInLastTables('Вместимость', '"Size"', '', '', '', 'Str', 90);

  AddTable('Расписание', 'SCHEDULE_ITEMS');
  AddColumnInLastTables('ID', 'ID', '', '', '', 'Int', 40);
  AddColumnInLastTables('Предмет', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', 'Str', 400);
  AddColumnInLastTables('Тип лекции', 'SUBJECT_TYPE_ID', 'SUBJECT_TYPES', 'ID', 'NAME', 'Str', 100);
  AddColumnInLastTables('Имя професора', 'PROFESSOR_ID', 'PROFESSORS', 'ID', 'NAME', 'Str', 150);
  AddColumnInLastTables('Номер пары', 'TIME_INDEX', '', '', '', 'Str', 70);
  AddColumnInLastTables('День недели', 'DAY_INDEX', 'DAYS', '"Index"', 'NAME', 'Str', 70);
  AddColumnInLastTables('№ группы', 'GROUP_ID', 'GROUPS', 'ID', 'NAME', 'Str', 70);
  AddColumnInLastTables('Кабинет', 'ROOM_ID', 'ROOMS', 'ID', 'NAME', 'Str', 70);

  AddTable('Предметы', 'SUBJECTS');
  AddColumnInLastTables('ID', 'ID', '', '', '', 'Int', 40);
  AddColumnInLastTables('Предмет', 'NAME', '', '', '', 'Str', 350);

  AddTable('Предметы - группы', 'SUBJECTS_GROUPS');
  AddColumnInLastTables('ID', 'ID', '', '', '', 'Int', 40);
  AddColumnInLastTables('ID предмета', 'SUBJECT_ID', 'SUBJECTS', 'ID', 'NAME', 'Str', 400);
  AddColumnInLastTables('ID группы', 'GROUP_ID', 'GROUPS', 'ID', 'NAME', 'Str', 90);

  AddTable('Типы лекций', 'SUBJECT_TYPES');
  AddColumnInLastTables('ID', 'ID', '', '', '', 'Int', 40);
  AddColumnInLastTables('Тип', 'NAME', '', '', '', 'Str', 40);

  AddTable('Расписание', 'TIMES');
  AddColumnInLastTables('Индекс', '"Index"', '', '', '', 'Int', 60);
  AddColumnInLastTables('Начало', '"Begin"', '', '', '', 'Str', 70);
  AddColumnInLastTables('Конец', '"End"', '', '', '', 'Str', 70);
end.

