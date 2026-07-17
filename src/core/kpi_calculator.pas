unit kpi_calculator;

{$mode objfpc}{$H+}

interface

function GoalCompletionPercent(const Solved, Goal: Integer): Double;
function AveragePerDay(const TotalSolved, NumberOfDays: Integer): Double;

implementation

function GoalCompletionPercent(const Solved, Goal: Integer): Double;
begin
  if (Solved <= 0) or (Goal <= 0) then
    Exit(0.0);
  Result := (Solved / Goal) * 100.0;
end;

function AveragePerDay(const TotalSolved, NumberOfDays: Integer): Double;
begin
  if (TotalSolved <= 0) or (NumberOfDays <= 0) then
    Exit(0.0);
  Result := TotalSolved / NumberOfDays;
end;

end.
