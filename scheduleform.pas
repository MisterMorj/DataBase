unit ScheduleForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, sqldb, db, FileUtil, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, StdCtrls, Grids, DbCtrls, ColorBox, SqlComponents, metadata,
  Filters;

type

  { TFShedule }

  TFShedule = class(TForm)
    Apply: TButton;
    addFilter: TButton;
    Datasource1: TDatasource;
    AxisY: TComboBox;
    AxisX: TComboBox;
    OutputField: TCheckGroup;
    DrawGrid1: TDrawGrid;
    Label1: TLabel;
    Label2: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    ScrollBox1: TScrollBox;
    SQLQuery1: TSQLQuery;
    procedure addFilterClick(Sender: TObject);
    procedure DrawGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure FormCreate(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
  private
    { private declarations }
  public
    ArrayFilters: TArrayFilters;
    SchTable: TTableInfo;
    { public declarations }
  end;

var
  FShedule: TFShedule;

implementation

{$R *.lfm}

{ TFShedule }

procedure TFShedule.RadioGroup1Click(Sender: TObject);
begin

end;

procedure TFShedule.FormCreate(Sender: TObject);
var
  i: integer;
begin
  SchTable := Table[5];
  ArrayFilters := TArrayFilters.Create;
  for i := 0 to High(SchTable.Columns) do
  begin
    AxisX.Items.Add(SchTable.Columns[i].NameRus);
    AxisX.ItemIndex := 0;
    AxisY.Items.Add(SchTable.Columns[i].NameRus);
    AxisY.ItemIndex := 0;
    OutputField.Items.Add(SchTable.Columns[i].NameRus);
  end;

end;

procedure TFShedule.addFilterClick(Sender: TObject);
begin
  ArrayFilters.AddFilter(5, ScrollBox1);
end;

procedure TFShedule.DrawGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
begin
    Canvas.TextOut(0, 0, 'hgdhgdhf');
end;

end.

