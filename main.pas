unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  ExtCtrls, metadata, UCatalogs, ScheduleForm;

type

  { TFMain }

  TFMain = class(TForm)
    MainMenu1: TMainMenu;
    CatalogsMenu: TMenuItem;
    Schedule: TMenuItem;
    procedure CatalogsMenuClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ScheduleClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  FMain: TFMain;
  MenuTable: array of TMenuItem;

implementation

{$R *.lfm}


{ TFMain }

procedure TFMain.CatalogsMenuClick(Sender: TObject);
begin
  AddInCatalogs(Self, (Sender as TMenuItem).Tag);
end;

procedure TFMain.FormCreate(Sender: TObject);
var
  i: integer;
begin
  SetLength(MenuTable, NumberOfTables);
  for i := 0 to NumberOfTables - 1 do
  begin
    MenuTable[i] := TMenuItem.Create(CatalogsMenu);
    MenuTable[i].Caption := Table[i].TableNameRus;
    MenuTable[i].Tag := i;
    MenuTable[i].OnClick := @CatalogsMenuClick;
    CatalogsMenu.Add(MenuTable[i])
  end;
end;


procedure TFMain.ScheduleClick(Sender: TObject);
begin
  FShedule.Show;
end;

end.

