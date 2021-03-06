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
  UQuery, Move, conflicts, Save, Hash;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TFMain, FMain);
  Application.CreateForm(TDataModule1, DataModule1);
  Application.CreateForm(TCatalog, Catalog);
  Application.CreateForm(TFSchedule, FSchedule);
  Application.CreateForm(TFConflict, FConflict);
  Application.Run;
end.
