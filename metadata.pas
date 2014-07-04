unit metadata;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs;

type ColumnInfo = record
  Width: integer;
  NameEng: string;
  NameRus: string;
end;

TTableInfo = class(TObject)
public
  TableNameRus: string;
  TableNameEng: string;
  Columns: array of ColumnInfo;
  procedure AddColumn (NameRus, NameEng: string; W: integer);
  constructor Create (NameRus, NameEng: string);
end;

var

Table: array of TTableInfo;

const
  NumberOfTables = 10;

implementation

procedure TTableInfo.AddColumn(NameRus, NameEng: string; W: integer);
begin
  SetLength(Columns, Length(Columns) + 1);
  Columns[High(Columns)].NameEng := NameEng;
  Columns[High(Columns)].NameRus := NameRus;
  Columns[High(Columns)].Width := W;
end;

constructor TTableInfo.Create(NameRus, NameEng: string);
begin
  TableNameEng := NameEng;
  TableNameRus := NameRus;
end;


initialization
  setlength(Table, NumberOfTables);
  Table[0] := TTableInfo.Create('Дни недели', 'DAYS');
  Table[0].AddColumn('Индекс', '"Index"', 70);
  Table[0].AddColumn('День', 'NAME', 100);

  Table[1] := TTableInfo.Create('Группы', 'GROUPS');
  Table[1].AddColumn('ID', 'ID', 40);
  Table[1].AddColumn('Номер', 'NAME', 70);
  Table[1].AddColumn('Размер', 'GROUP_SIZE', 60);

  Table[2] := TTableInfo.Create('Профессора', 'PROFESSORS');
  Table[2].AddColumn('ID', 'ID', 40);
  Table[2].AddColumn('Ф.И.О', 'NAME', 150);

  Table[3] := TTableInfo.Create('Професора - предметы', 'PROFESSORS_SUBJECTS');
  Table[3].AddColumn('ID', 'ID', 40);
  Table[3].AddColumn('ID профессора', 'PROFESSOR_ID', 100);
  Table[3].AddColumn('ID предмета', 'SUBJECT_ID', 100);

  Table[4] := TTableInfo.Create('Аудитории', 'ROOMS');
  Table[4].AddColumn('ID', 'ID', 40);
  Table[4].AddColumn('Номер', 'NAME', 60);
  Table[4].AddColumn('Вместимость', '"Size"', 90);

  Table[5] := TTableInfo.Create('Расписание', 'SCHEDULE_ITEMS');
  Table[5].AddColumn('ID', 'ID', 40);
  Table[5].AddColumn('ID предмета', 'SUBJECT_ID', 80);
  Table[5].AddColumn('ID типа предмета', 'SUBJECT_TYPE_ID', 100);
  Table[5].AddColumn('ID проффесора', 'PROFESSOR_ID', 90);
  Table[5].AddColumn('ID время', 'TIME_INDEX', 70);
  Table[5].AddColumn('ID дня', 'DAY_INDEX', 70);
  Table[5].AddColumn('ID группы', 'GROUP_ID', 70);
  Table[5].AddColumn('ID комнаты', 'ROOM_ID', 70);

  Table[6] := TTableInfo.Create('Предметы', 'SUBJECTS');
  Table[6].AddColumn('ID', 'ID', 40);
  Table[6].AddColumn('Предмет', 'NAME', 350);

  Table[7] := TTableInfo.Create('Предметы - группы', 'SUBJECTS_GROUPS');
  Table[7].AddColumn('ID', 'ID', 40);
  Table[7].AddColumn('ID предмета', 'SUBJECT_ID', 90);
  Table[7].AddColumn('ID группы', 'GROUP_ID', 90);

  Table[8] := TTableInfo.Create('Типы лекций', 'SUBJECT_TYPES');
  Table[8].AddColumn('ID', 'ID', 40);
  Table[8].AddColumn('Тип', 'NAME', 40);

  Table[9] := TTableInfo.Create('Расписание', 'TIMES');
  Table[9].AddColumn('Индекс', '"Index"', 60);
  Table[9].AddColumn('Начало', '"Begin"', 70);
  Table[9].AddColumn('Конец', '"End"', 70);
end.

