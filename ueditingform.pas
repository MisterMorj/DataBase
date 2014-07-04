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
    Tag: integer;
    constructor Create(Form: TFormEdit; Table: TTableInfo; Num, ID, ATag: integer);
  end;

  MyEditorEdit = class(TObject)
    EtemLabel: TLabel;
    Edit: TDBEdit;
    DSVariable: TDataSource;
    SQLQueryVariable: TSQLQuery;
    Tag: integer;
    constructor Create(Form: TFormEdit; ATable: TTableInfo; Num, ID, ATag: integer);
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
    procedure FixVal(ColNum: integer; ItemVal: String);
    procedure ApplyClick(Sender: TObject);
    procedure CancelClick(Sender: TObject);
    procedure CreateNewFields(ATable: TTableInfo; Num, ID: integer);
    procedure CreateNewFieldsWithField(ATable: TTableInfo; Num, ID: integer);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    constructor Init(Sender: TComponent; Id: integer; ATable: TTableInfo);
  private
    function ReturTag: integer;
    { private declarations }
  public
    EditorsCB: array of MyEditorCB;
    EditorsEdit: array of MyEditorEdit;
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
    IdField := MyEditorEdit.Create(Self, ATable, 0, 0, -1);
    Self.Table := ATable;
  end;
end;

function TFormEdit.ReturTag: integer;
begin
  Result := Length(EditorsCB) + Length(EditorsEdit);
end;

procedure TFormEdit.CreateNewFields(ATable: TTableInfo; Num, ID: integer);
begin
  SetLength(EditorsEdit, Length(EditorsEdit) + 1);
  EditorsEdit[High(EditorsEdit)] := MyEditorEdit.Create(Self, ATable, Num, ID, ReturTag);
end;

procedure TFormEdit.CreateNewFieldsWithField(ATable: TTableInfo; Num, ID: integer);
begin
  SetLength(EditorsCB, Length(EditorsCB) + 1);
  EditorsCB[High(EditorsCB)] := MyEditorCB.Create(Self, ATable, Num, ID, ReturTag);
end;

procedure TFormEdit.ApplyClick(Sender: TObject);
var
  i: integer;
begin
  for i := 0 to High(EditorsEdit) do
    if EditorsEdit[i].Edit.Caption = '' then
    begin
      ShowMessage('Неободимо заполнить все поля!');
      exit;
    end;

  for i := 0 to High(EditorsCB) do
    if EditorsCB[i].CBox.Caption = '' then
    begin
      ShowMessage('Неободимо заполнить все поля!');
      exit;
    end;
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
  if Tags <> nil then
     Tags[Tag] := -1;
  Close;
end;

procedure TFormEdit.CancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFormEdit.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Tags <> nil then
    Tags[Tag] := -1;
end;

procedure TFormEdit.FormCreate(Sender: TObject);
begin
end;

procedure TFormEdit.FixVal (ColNum: integer; ItemVal: String);
var
  i: integer;
begin
  for i := 0 to High(EditorsEdit) do
  begin
    if EditorsEdit[i].Tag = ColNum then
    begin
      EditorsEdit[i].Edit.Caption := ItemVal;
      EditorsEdit[i].Edit.Enabled := false;
    end;
  end;

  for i := 0 to High(EditorsCB) do
  begin
    if EditorsCB[i].Tag = ColNum then
    begin
      if not (Datasource1.DataSet.State in [dsEdit, dsInsert]) then
        Datasource1.DataSet.Edit;
      EditorsCB[i].CBox.ItemIndex := StrToInt(ItemVal) - 1;
      EditorsCB[i].CBox.Field.Value := EditorsCB[i].CBox.KeyValue;
      EditorsCB[i].CBox.Enabled := false;
    end;
  end;
end;

constructor MyEditorEdit.Create(Form: TFormEdit; ATable: TTableInfo; Num, ID, ATag: integer);
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
    EtemLabel.Left := 260;
    EtemLabel.Top := 35 * Num + 15;
    EtemLabel.Parent := Form.ScrollBox1;
    EtemLabel.Caption := ATable.Columns[Num].NameRus;
  end;
  Edit.Width := 200;
  Edit.Parent := Form.ScrollBox1;
  Edit.DataSource := DSVariable;
  Edit.DataField := ATable.Columns[Num].NameEng;
  Tag := ATag;
end;

constructor MyEditorCB.Create(Form: TFormEdit; Table: TTableInfo; Num, ID, ATag: integer);
begin
  DSVariable := TDataSource.Create(Form.ScrollBox1);
  DSVariable.DataSet := Form.SQLQuery;

  SQLQueryVariable := TSQLQuery.Create(Form);
  SQLQueryVariable.Transaction := DataModule1.SQLTransaction1;
  SQLQueryVariable.DataBase := DataModule1.IBConnection1;

  DS := TDataSource.Create(Form.ScrollBox1);
  DS.DataSet := SQLQueryVariable;

  SQLQueryVariable.Close;
  SQLQueryVariable.SQL.Text := 'SELECT * FROM ' + Table.Columns[Num].Ref +
    ' ORDER BY ' +  ReturnSortPar(Table.Columns[Num].Ref, Table.Columns[Num].NameEng);
  SQLQueryVariable.Open;

  CBox := TDBLookupComboBox.Create(Form.ScrollBox1);
  CBox.Style := csDropDownList;
  CBox.Left := 50;
  CBox.Top := 35 * Num + 10;
  CBox.Width := 200;
  CBox.Parent := Form.ScrollBox1;
  CBox.ListSource := DS;
  CBox.ListField := Table.Columns[Num].RefVal;
  CBox.DataSource := DSVariable;
  CBox.DataField := Table.Columns[Num].NameEng;
  CBox.KeyField := Table.Columns[Num].RefPar;
  CBox.ItemIndex := ID;

  EtemLabel := TLabel.Create(Form);
  EtemLabel.Left := 260;
  EtemLabel.Top := 35 * Num + 15;
  EtemLabel.Parent := Form.ScrollBox1;
  EtemLabel.Caption := Table.Columns[Num].NameRus;

  Tag := ATag;
end;

end.
