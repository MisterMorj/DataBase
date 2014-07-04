unit Ueditingform;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  Buttons, StdCtrls, metadata, DBCtrls, DB, sqldb, SqlComponents;

type

  TFormEdit = class;

  MyEditorCB = class(TObject)
    EtemLabel: TLabel;
    CBox: TDBLookupComboBox;
    DS, DSVariable: TDataSource;
    SQLQuery, SQLQueryVariable: TSQLQuery;
    constructor Create(Form: TFormEdit; Table: TTableInfo; Num, ID: integer);
  end;

  MyEditorEdit = class(TObject)
    EtemLabel: TLabel;
    Edit: TDBEdit;
    DSVariable: TDataSource;
    SQLQueryVariable: TSQLQuery;
    constructor Create(Form: TFormEdit; Table: TTableInfo; Num, ID: integer);
  end;

  TProc = procedure(Sender: TObject) of object;

  { TFormEdit }

  TFormEdit = class(TForm)
    Apply: TButton;
    Cancel: TButton;
    Datasource1: TDatasource;
    Panel1: TPanel;
    ScrollBox1: TScrollBox;
    SQLQuery: TSQLQuery;
    SQLQueryNew: TSQLQuery;
    procedure ApplyClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure CreateNewFields(ATable: TTableInfo; Num, ID: integer);
    procedure CreateNewFieldsWithField(ATable: TTableInfo; Num, ID: integer);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    constructor Init(Sender: TComponent; Id: integer; ATable: TTableInfo);
  private
    { private declarations }
  public
    ApplyProc: TProc;
    ID: integer;
    Table: TTableInfo;
    IdField: MyEditorEdit;
    Tags: array of integer;
  end;

var
  SQLQuery: TFormEdit;
  EditingForm: array of TFormEdit;

implementation

{$R *.lfm}
constructor TFormEdit.Init(Sender: TComponent; Id: integer; ATable: TTableInfo);
begin
  Create(Sender);
  SQLQuery.Close;
  SQLQuery.SQL.Text := 'SELECT * FROM ' + ATable.TableNameEng +
    ' WHERE ' + 'ID = ' + IntToStr(ID);
  SQLQuery.Open;
  Self.ID := ID;
  if ID = -1 then
  begin
    IdField := MyEditorEdit.Create(Self, Table, 0, 0);
    Self.Table := ATable;
  end;
end;

procedure TFormEdit.CreateNewFields(ATable: TTableInfo; Num, ID: integer);
begin
  MyEditorEdit.Create(Self, ATable, Num, ID);
end;

procedure TFormEdit.ApplyClick(Sender: TObject);
begin
  if ID = -1 then
  begin
    SQLQueryNew.Close;
    SQLQueryNew.SQL.Text := 'SELECT NEXT VALUE FOR ' + Table.ObjCounterName +
      ' FROM RDB$DATABASE';
    SQLQueryNew.Open;
    IdField.Edit.Text := IntToStr(SQLQueryNew.FieldByName('GEN_ID').AsInteger + 1);
  end;
  SQLQuery.ApplyUpdates;
  DataModule1.SQLTransaction1.Commit;
  ApplyProc(nil);
  Tags[Tag] := -1;
  Close;
end;

procedure TFormEdit.CancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFormEdit.CreateNewFieldsWithField(ATable: TTableInfo; Num, ID: integer);
begin
  MyEditorCB.Create(Self, ATable, Num, ID);
end;

procedure TFormEdit.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  Tags[Tag] := -1;
end;

procedure TFormEdit.FormCreate(Sender: TObject);
begin
end;

constructor MyEditorEdit.Create(Form: TFormEdit; Table: TTableInfo; Num, ID: integer);
begin
  SQLQueryVariable := TSQLQuery.Create(Form.ScrollBox1);
  SQLQueryVariable.Transaction := DataModule1.SQLTransaction1;
  SQLQueryVariable.DataBase := DataModule1.IBConnection1;

  DSVariable := TDataSource.Create(Form.ScrollBox1);
  DSVariable.DataSet := Form.SQLQuery;

  Edit := TDBEdit.Create(Form.ScrollBox1);
  Edit.Left := 50;

  if Num = 0 then
    Edit.Top := -100
  else
  begin
    Edit.Top := 35 * Num + 10;
    EtemLabel := TLabel.Create(Form);
    EtemLabel.Left := 160;
    EtemLabel.Top := 35 * Num + 15;
    EtemLabel.Parent := Form.ScrollBox1;
    EtemLabel.Caption := Table.Columns[Num].NameRus;
  end;
  Edit.Width := 100;
  Edit.Parent := Form.ScrollBox1;
  Edit.DataSource := DSVariable;
  Edit.DataField := Table.Columns[Num].NameEng;

end;

constructor MyEditorCB.Create(Form: TFormEdit; Table: TTableInfo; Num, ID: integer);
begin
  DSVariable := TDataSource.Create(Form.ScrollBox1);
  DSVariable.DataSet := Form.SQLQuery;

  SQLQueryVariable := TSQLQuery.Create(Form);
  SQLQueryVariable.Transaction := DataModule1.SQLTransaction1;
  SQLQueryVariable.DataBase := DataModule1.IBConnection1;

  DS := TDataSource.Create(Form.ScrollBox1);
  DS.DataSet := SQLQueryVariable;

  SQLQueryVariable.Close;
  SQLQueryVariable.SQL.Text := 'SELECT * FROM ' + Table.Columns[Num].Ref;
  SQLQueryVariable.Open;

  CBox := TDBLookupComboBox.Create(Form.ScrollBox1);
  CBox.Style := csDropDownList;
  CBox.Left := 50;
  CBox.Top := 35 * Num + 10;
  CBox.Parent := Form.ScrollBox1;
  CBox.ListSource := DS;
  CBox.ListField := Table.Columns[Num].RefVal;
  CBox.DataSource := DSVariable;
  CBox.DataField := Table.Columns[Num].NameEng;
  CBox.KeyField := Table.Columns[Num].RefPar;
  CBox.ItemIndex := ID;

  EtemLabel := TLabel.Create(Form);
  EtemLabel.Left := 160;
  EtemLabel.Top := 35 * Num + 15;
  EtemLabel.Parent := Form.ScrollBox1;
  EtemLabel.Caption := Table.Columns[Num].NameRus;
end;

end.
