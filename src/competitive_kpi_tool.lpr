program competitive_kpi_tool;

{$mode objfpc}{$H+}

uses
  Interfaces, Forms, main_form;

begin
  RequireDerivedFormResource := False;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
