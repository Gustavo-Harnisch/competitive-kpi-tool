unit reminder_service;

{$mode objfpc}{$H+}

interface

function ReminderIsDue(const TodaySolved, DailyGoal: Integer): Boolean;

implementation

function ReminderIsDue(const TodaySolved, DailyGoal: Integer): Boolean;
begin
  Result := (DailyGoal > 0) and (TodaySolved < DailyGoal);
end;

end.
