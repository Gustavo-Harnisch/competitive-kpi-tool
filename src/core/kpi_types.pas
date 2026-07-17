unit kpi_types;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TPracticeSession = record
    Id: Int64;
    PracticedOn: TDateTime;
    Platform: string;
    ProblemsSolved: Integer;
    MinutesSpent: Integer;
    Notes: string;
    CreatedAt: string;
  end;

  TPracticeSessionArray = array of TPracticeSession;

  TKpiSnapshot = record
    TodaySolved: Integer;
    DailyGoal: Integer;
    GoalCompletionPercent: Double;
    SevenDayAverage: Double;
    TotalSessions: Integer;
    CurrentStreak: Integer;
  end;

implementation

end.
