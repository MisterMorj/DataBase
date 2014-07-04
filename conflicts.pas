unit conflicts;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls, Hash;

type

  TFieldForComparison = record
    Cmp: string;
    Val: string;
  end;

  TInnerJoin = record
    InnerJoinTable: string;
    NewName: string;
    CompField: array of TFieldForComparison;
  end;

  TMainItem = record
    ItemName: string;
    TableName: string;
  end;

  { TFConflict }

  TFConflict = class(TForm)
    TreeView1: TTreeView;
  private
    { private declarations }
  public
    { public declarations }
  end;

  { TConflict }

  TConflict = class(TObject)
    Header: String;
    MainItem: array of TMainItem;
    InnerJoin: array of TInnerJoin;
    WhereParam: string;
    procedure AddInnerJoin(TableName: string);
  private
    procedure AddCMPField(Field, CMP: string);
  end;

procedure AddConflict (AHeader: string);

var
  FConflict: TFConflict;
  ArrConflict: array of TConflict;
  HConflict: THash;
implementation

procedure AddConflict(AHeader: string);
begin
  SetLength(ArrConflict, Length(ArrConflict) + 1);
  ArrConflict[High(ArrConflict)] := TConflict.Create;
  ArrConflict[High(ArrConflict)].Header := AHeader;
end;

{$R *.lfm}

{ TConflict }

procedure TConflict.AddInnerJoin(TableName: string);
begin
  SetLength(InnerJoin, Length(InnerJoin) + 1);
  InnerJoin[High(InnerJoin)].InnerJoinTable := TableName;
  InnerJoin[High(InnerJoin)].NewName := 'Tbl' + IntToStr(High(InnerJoin));
end;

procedure TConflict.AddCMPField (Field, CMP: string);
begin
  SetLength(InnerJoin[High(InnerJoin)].CompField, Length(InnerJoin[High(InnerJoin)].CompField) + 1);
  InnerJoin[High(InnerJoin)].CompField[High(InnerJoin[High(InnerJoin)].CompField)].Val := Field;
  InnerJoin[High(InnerJoin)].CompField[High(InnerJoin[High(InnerJoin)].CompField)].CMP := CMP;
end;

initialization
/////////////////////////////////////////////////////////////////////////////////////////////////////
  AddConflict('Два преподавателя в одной аудитории в одно время');                                 //
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');                                   //
  ArrConflict[High(ArrConflict)].AddCMPField('PROFESSOR_ID', '<>');                                //
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=');                                    //
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '=');                                      //
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=');                                    //
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=');                                   //
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=');                                         //
  ArrConflict[High(ArrConflict)].WhereParam := '';                                                 //
                                                                                                   //
  AddConflict('Одна группы в одно время в разных аудиториях');                                     //
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');                                   //
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=');                                    //
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '<>');                                     //
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=');                                    //
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=');                                   //
  ArrConflict[High(ArrConflict)].AddCMPField('GROUP', '=');                                        //
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=');                                         //
  ArrConflict[High(ArrConflict)].WhereParam := '';                                                 //
                                                                                                   //
  AddConflict('Один преподователь в разных аудиториях в одно время');                              //
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');                                   //
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=');                                    //
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '<>');                                     //
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=');                                    //
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=');                                   //
  ArrConflict[High(ArrConflict)].AddCMPField('PROFESSOR_ID', '=');                                 //
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=');                                         //
  ArrConflict[High(ArrConflict)].WhereParam := '';                                                 //
                                                                                                   //
  AddConflict('В одной аудитории в одно время разные типы лекций');                                //
  ArrConflict[High(ArrConflict)].AddInnerJoin('SCHEDULE_ITEMS');                                   //
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=');                                    //
  ArrConflict[High(ArrConflict)].AddCMPField('ROOM_ID', '<>');                                     //
  ArrConflict[High(ArrConflict)].AddCMPField('DAY_INDEX', '=');                                    //
  ArrConflict[High(ArrConflict)].AddCMPField('TIME_INDEX', '=');                                   //
  ArrConflict[High(ArrConflict)].AddCMPField('PROFESSOR_ID', '=');                                 //
  ArrConflict[High(ArrConflict)].AddCMPField('WEEK', '=');                                         //
  ArrConflict[High(ArrConflict)].WhereParam := '';                                                 //
                                                                                                   //
                                                                                                   //
                                                                                                   //
/////////////////////////////////////////////////////////////////////////////////////////////////////
end.

