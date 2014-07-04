unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, DB, FileUtil, Forms, Controls,
  Graphics, Dialogs, DBGrids, StdCtrls, Menus, Spin, Buttons, metadata, Grids,
  FormForHandbooks;
type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Datasource1: TDatasource;
    DBGrid1: TDBGrid;
    IBConnection1: TIBConnection;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure Button1Click(Sender: TObject);
    procedure DBGrid1DblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MyOnClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;



var
  Form1: TForm2;
  Form2: array of TForm2;
  MenuTable: array of TMenuItem;

implementation

{$R *.lfm}

{Form2}


{ TForm1 }


procedure TForm1.MyOnClick(Sender: TObject);
var
  i, j, TableNum, FormNum: integer;
  s: string;
begin
  SetLength(Form2, Length(Form2) + 1);
  FormNum := High(Form2);
  Form2[FormNum] := TForm2.CreateNew(Form1);
  Form2[FormNum].Tag := (Sender as TMenuItem).Tag;

  for i := 0 to High(Table[Form2[FormNum].Tag].Columns) do
  begin
    SetLength(Form2[FormNum].DataToFilter, Length(Form2[FormNum].DataToFilter) + 1);
    Form2[FormNum].DataToFilter[i] := TDataToFilter.Create;
    Form2[FormNum].DataToFilter[i].DataType := Table[Form2[FormNum].Tag].Columns[i].DataType;
    if Table[Form2[FormNum].Tag].Columns[i].Ref <> '' then
    begin
       Form2[FormNum].DataToFilter[i].Column := Table[Form2[FormNum].Tag].Columns[i].RefVal;
       Form2[FormNum].DataToFilter[i].Table := Table[Form2[FormNum].Tag].Columns[i].Ref;
    end
    else
    begin
       Form2[FormNum].DataToFilter[i].Column := Table[Form2[FormNum].Tag].Columns[i].NameEng;
       Form2[FormNum].DataToFilter[i].Table := Table[Form2[FormNum].Tag].TableNameEng;
    end;
  end;
  Form2[FormNum].ApplyFilter.OnClick(Form2[FormNum].ApplyFilter);
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
  try
    SQLQuery1.Close;
    SQLQuery1.SQL.Text := Memo1.Lines.Text;
    SQLQuery1.Open;
  except
    ShowMessage('Неверный запрос');
  end;
end;

procedure TForm1.DBGrid1DblClick(Sender: TObject);
begin
  //ShowMessage(IntToStr(Datasource1.DataSet.RecNo));
  //ShowMessage(SQLQuery1.FieldByName('Брррр').Value);
//  SELECT a.ID, a.NAME, a.GROUP_SIZE
//FROM GROUPS a
end;


procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
begin
  Memo1.Text := '';
  SetLength(MenuTable, NumberOfTables);
  for i := 0 to NumberOfTables - 1 do
  begin
    MenuTable[i] := TMenuItem.Create(MenuItem2);
    MenuTable[i].Caption := Table[i].TableNameRus;
    MenuTable[i].Tag := i;
    MenuTable[i].OnClick := @MyOnClick;
    MenuItem2.Add(MenuTable[i]);
  end;
end;

procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  Close;
end;

end.
