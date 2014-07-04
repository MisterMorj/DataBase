unit Save;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FormatsToSave, Dialogs, FileUtil, ActiveX, ComObj, windows;

procedure SaveToFile(FilterIndex: integer; Data: TSaveClass; FileName, OxStr, OyStr: string; Header, Filters: TStringList);
function SaveToHTML(Data: TSaveClass; Header, Filters: TStringList; OxStr, OyStr: string): string;

var
  OutputFile: Text;
  OleExcel: OleVariant;
  ExcelFileName: string;
const
  TmpFileName = 'Temp.temp';
  ExcelApp = 'Excel.Application';
implementation

function IsOLEObjectInstalled(Name: String): boolean;
var
  ClassID: TCLSID;
  Rez : HRESULT;
begin
  Rez := CLSIDFromProgID(PWideChar(WideString(Name)), ClassID);
  if Rez = S_OK then
    Result := true
  else
    Result := false;
end;

function CheckExcel: boolean;
begin
  Result := IsOLEObjectInstalled(ExcelApp);
  if not IsOLEObjectInstalled(ExcelApp) then
    ShowMessage('Excel не установлен')
end;

function RunExcel: boolean;
var
  CLID: TCLSID;
begin
  Result := CLSIDFromProgID(ExcelApp, CLID) = 0;
  if CLSIDFromProgID(ExcelApp, CLID) = 0 then
    OleExcel := CreateOleObject(ExcelApp);
  if not Result then
    ShowMessage('Не удалось запустить Excel. Действие отменено.');
end;

procedure CreateExcelFile(TMPFileName, ExcelFileName: string; Ind: integer);
begin
  try
    OleExcel.WorkBooks.Open(WideString(TMPFileName));
    OleExcel.WorkBooks.Item[1].SaveAs(WideString(ExcelFileName), Formats[Ind - 1].Signature);
    OleExcel.WorkBooks.Item[1].Save;
    OleExcel.Quit;
    OleExcel := Unassigned;
  except
    ShowMessage('Ошибка при использовании Excel');
  end;
end;

procedure SaveToFile(FilterIndex: integer; Data: TSaveClass; FileName, OxStr, OyStr: string; Header, Filters: TStringList);
begin
  AssignFile(OutputFile, TmpFileName);
  Rewrite(OutputFile);
  Write(OutputFile, SaveToHTML(Data, Header, Filters, OxStr, OyStr));
  if FilterIndex = 1 then
    CopyFile(TmpFileName, PChar(Utf8ToAnsi(FileName)), True)
  else
    if RunExcel and CheckExcel then
      CreateExcelFile(TmpFileName, FileName, FilterIndex);
  CloseFile(OutputFile);
  DeleteFile(TmpFileName);
end;

function SaveToHTML(Data: TSaveClass; Header, Filters: TStringList; OxStr, OyStr: string): string;
var
  i, j, q, z: integer;
  HTMLCode: TStringList;
begin
  HTMLCode := TStringList.Create;
  HTMLCode.Add('<!doctype html>');
  HTMLCode.Add('<html>');
  HTMLCode.Add(  '<head>');
  HTMLCode.Add(    '<meta charset="utf-8">');
  HTMLCode.Add(    '<title>' + 'Расписание занятий' + '</TITLE>');
  HTMLCode.Add(  '</head>');
  HTMLCode.Add(  '<body>');
  HTMLCode.Add(    '<table cellspacing="0" cellpadding="0" border="1" bordercolor="black">');

  HTMLCode.Add(        '<TR>' + '<TH bgcolor="LightGray">' + 'Видимые&nbsp;поля' + '</TH>' + '</TR>');
  for i := 0 to Header.Count - 1 do
    HTMLCode.Add(      '<TR>' + '<TH>' + Header[i] + '</TH>' + '</TR>');

  if Filters.Count > 0 then
    HTMLCode.Add(      '<TR>' + '<TH bgcolor="LightGray">' + 'Фильтры' + '</TH>' + '</TR>');
  for i := 0 to Filters.Count - 1 do
    HTMLCode.Add(      '<TR>' + '<TH>' + Filters[i] + '</TH>' + '</TR>');

  HTMLCode.Add(             '<TH bgcolor="LightGray">' + OxStr + '<HR>' + OyStr + '</TH>');
  for i := 1 to High(Data[0]) do
     HTMLCode.Add(          '<TH bgcolor="LightGray">' + Data[0][i][0].Text + '</TH>');
  for i := 1 to High(Data) do
    begin
      HTMLCode.Add(     '<TR>');
      HTMLCode.Add(         '<TH bgcolor="LightGray">' + Data[i][0][0].Text + '</TH>');
      for j := 1 to High(Data[i]) do
      begin
        HTMLCode.Add(       '<TD nowrap valign="top" bgcolor="White">');
        for q := 0 to High(Data[i, j]) do
        begin
          for z := 0 to Data[i, j, q].Count - 1 do
          begin
            HTMLCode.Add(   Data[i, j, q][z]);
            if (z <> Data[i, j, q].Count - 1) then
               HTMLCode.Add('<BR>');
          end;
          if (q <> High(Data[i, j])) then
             HTMLCode.Add(  '<HR>');
        end;
      end;
      HTMLCode.Add(     '</TR>');
    end;
  HTMLCode.Add(    '</table>');
  HTMLCode.Add(  '</body>');
  HTMLCode.Add('</html>');
  Result := HTMLCode.Text;
end;

end.

