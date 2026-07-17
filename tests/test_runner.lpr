program test_runner;

{$mode objfpc}{$H+}

uses
  consoletestrunner, test_kpi_calculator;

type
  TRunner = class(TTestRunner);

var
  Runner: TRunner;
begin
  Runner := TRunner.Create(nil);
  try
    Runner.Initialize;
    Runner.Run;
  finally
    Runner.Free;
  end;
end.
