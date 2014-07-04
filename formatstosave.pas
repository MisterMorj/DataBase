unit FormatsToSave;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Ueditingform, Dialogs;

type
  TSaveClass = array of array of array of TStringList;

  TFormat = class(TObject)
    Signature: integer;
    FormatName: string;
    Extension: string;
  end;

  procedure AddNewFormat (ASignature: integer; AFormatName, AExtension: string);
  procedure AddFormatInSaveDialog (SaveDialog: TSaveDialog);

var
  Formats: array of TFormat;

implementation

procedure AddNewFormat(ASignature: integer; AFormatName, AExtension: string);
begin
  SetLength(Formats, Length(Formats) + 1);
  Formats[High(Formats)] := TFormat.Create;
  Formats[High(Formats)].Signature := ASignature;
  Formats[High(Formats)].FormatName := AFormatName;
  Formats[High(Formats)].extension := AExtension;
end;

procedure AddFormatInSaveDialog(SaveDialog: TSaveDialog);
var
  i: integer;
begin
  for i := 0 to High(Formats) do
   SaveDialog.Filter := Format('%s|%s (*%s )|*%s', [SaveDialog.Filter, Formats[i].FormatName, Formats[i].Extension, Formats[i].Extension]);
end;

initialization
  AddNewFormat(0, 'HTML', '.html');
  AddNewFormat($00000032, 'Excel 2007', '.xls');
  AddNewFormat($00000038, 'Excel 2003', '.xls');
  AddNewFormat($00000027, 'Excel 95', '.xls');
end.

