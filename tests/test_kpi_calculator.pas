unit test_kpi_calculator;

{$mode objfpc}{$H+}

interface

uses
  fpcunit, testregistry;

type
  TKpiCalculatorTests = class(TTestCase)
  published
    procedure CompletionWithZeroGoalIsZero;
    procedure CompletionCalculatesPercentage;
    procedure EmptyAverageIsZero;
  end;

implementation

uses
  kpi_calculator;

procedure TKpiCalculatorTests.CompletionWithZeroGoalIsZero;
begin
  AssertEquals(0.0, GoalCompletionPercent(3, 0), 0.0001);
end;

procedure TKpiCalculatorTests.CompletionCalculatesPercentage;
begin
  AssertEquals(150.0, GoalCompletionPercent(3, 2), 0.0001);
end;

procedure TKpiCalculatorTests.EmptyAverageIsZero;
begin
  AssertEquals(0.0, AveragePerDay(0, 7), 0.0001);
end;

initialization
  RegisterTest(TKpiCalculatorTests);

end.
