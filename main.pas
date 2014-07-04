unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, Menus,
  metadata, UCatalogs;

type

  { TForm1 }

  TForm1 = class(TForm)
    MainMenu1: TMainMenu;
    CatalogsMenu: TMenuItem;
    procedure CatalogsMenuClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  Form1: TForm1;
  MenuTable: array of TMenuItem;

implementation

{$R *.lfm}


{ TForm1 }

procedure TForm1.CatalogsMenuClick(Sender: TObject);
var
  i, j, TableNum, FormNum: integer;
  s: string;
begin
  SetLength(Catalogs, Length(Catalogs) + 1);
  FormNum := High(Catalogs);
  Catalogs[FormNum] := TCatalog.Create(Form1);
  Catalogs[FormNum].Tag := (Sender as TMenuItem).Tag;
  Catalogs[FormNum].Show;
  Catalogs[FormNum].ApplyFilter.Click;
end;


procedure TForm1.FormCreate(Sender: TObject);
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

end.

