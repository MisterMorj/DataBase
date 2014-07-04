unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IBConnection, sqldb, DB, FileUtil, Forms, Controls,
  Graphics, Dialogs, DBGrids, StdCtrls, Menus, metadata;

type

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    //NowUsedTables: TTableInfo;
    Datasource1: TDatasource;
    DBGrid1: TDBGrid;
    IBConnection1: TIBConnection;
    MainMenu1: TMainMenu;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    SQLQuery1: TSQLQuery;
    SQLTransaction1: TSQLTransaction;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure MenuItem3Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MyOnClick(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;



var
  Form1: TForm1;
  Form2: TForm;
  T: TDBGrid;
  SQLQuery: TSQLQuery;
  DataSource: TDataSource;
  MenuTable: array of TMenuItem;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.MyOnClick(Sender: TObject);
var
  i, j: integer;
  s: string;
begin
  Form2 := TForm.Create(Form1);
  Form2.Position := poScreenCenter;
  Form2.Width := 1000;
  Form2.Height := 500;
  Form2.Show;
  //
  SQLQuery := TSQLQuery.Create(Form2);
  SQLQuery.Transaction := SQLTransaction1;
  DataSource := TDataSource.Create(Form2);
  DataSource.DataSet := SQLQuery;
  //
  SQLQuery.Close;
  s := 'SELECT ';
  for i := 0 to High(Table[(Sender as TMenuItem).Tag].Columns) do
  begin

    s += Table[(Sender as TMenuItem).Tag].TableNameEng + '.';
    s += Table[(Sender as TMenuItem).Tag].Columns[i].NameEng;
    if (i < High(Table[(Sender as TMenuItem).Tag].Columns)) then
      s += ', ';
  end;
  s += ' FROM ';
  s += Table[(Sender as TMenuItem).Tag].TableNameEng;
  SQLQuery.SQL.Text := s;
  SQLQuery.Open;
  T := TDBGrid.Create(Form2);
  T.Left := 0;
  T.Top := 0;
  T.Width := 1000;
  T.Height := 500;
  T.Parent := Form2;
  T.DataSource := Datasource;//
  for i := 0 to T.Columns.Count - 1 do
    for j := 0 to High(Table[(Sender as TMenuItem).Tag].Columns) do
    begin
      s  := Table[(Sender as TMenuItem).Tag].Columns[j].NameEng;
      if s[1] = '"' then
        s := Copy(s, 2, Length(s) - 2);
      if T.Columns.Items[i].FieldName = s then
      begin
        T.Columns.Items[i].Title.Caption := Table[(Sender as TMenuItem).Tag].Columns[j].NameRus;
        T.Columns[i].Width := Table[(Sender as TMenuItem).Tag].Columns[j].Width;
      end;
    end;
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

procedure TForm1.FormCreate(Sender: TObject);
var
  i: integer;
begin
  //Form2 := TForm1.Create(Memo1);
  Memo1.Text := '';
  SetLength(MenuTable, NumberOfTables);
  for i := 0 to NumberOfTables - 1 do
  begin
    MenuTable[i] := TMenuItem.Create(MenuItem4);
    MenuTable[i].Caption := Table[i].TableNameRus;
    MenuTable[i].Tag := i;
    MenuTable[i].OnClick := @MyOnClick;
    MenuItem4.Add(MenuTable[i]);
  end;
end;


procedure TForm1.MenuItem3Click(Sender: TObject);
begin
  Close;
end;

procedure TForm1.MenuItem4Click(Sender: TObject);
begin
  //T := TDBGrid.Create(Form1);
  //T := Form1.DBGrid1;

  //T.Top := 100;
end;


end.
