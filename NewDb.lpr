program NewDb;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  main,
  metadata,
  SqlComponents,
  UCatalogs,
  Ueditingform,
  ScheduleForm,
  Filters,
  UQuery { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.CreateForm(TCatalog, Catalog);
  Application.CreateForm(TFShedule, FShedule);
  Application.Run;
end.
