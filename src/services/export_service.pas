unit export_service;

{$mode objfpc}{$H+}

interface

uses
  kpi_database;

procedure ExportSessionsToCsv(const ADatabase: TKpiDatabase; const AFileName: string);
procedure ExportSessionsToSql(const ADatabase: TKpiDatabase; const AFileName: string);

implementation

uses
  Classes, SysUtils, kpi_types;

function CsvField(const AValue: string): string;
begin
  Result := '"' + StringReplace(AValue, '"', '""', [rfReplaceAll]) + '"';
end;

function SqlString(const AValue: string): string;
begin
  Result := #39 + StringReplace(AValue, #39, #39#39, [rfReplaceAll]) + #39;
end;

procedure ExportSessionsToCsv(const ADatabase: TKpiDatabase; const AFileName: string);
var
  Sessions: TPracticeSessionArray;
  Output: TStringList;
  I: Integer;
begin
  Sessions := ADatabase.AllSessions;
  Output := TStringList.Create;
  try
    Output.Add('id,practiced_on,platform,problems_solved,minutes_spent,notes,created_at');
    for I := 0 to High(Sessions) do
      Output.Add(
        IntToStr(Sessions[I].Id) + ',' +
        CsvField(FormatDateTime('yyyy-mm-dd', Sessions[I].PracticedOn)) + ',' +
        CsvField(Sessions[I].Platform) + ',' +
        IntToStr(Sessions[I].ProblemsSolved) + ',' +
        IntToStr(Sessions[I].MinutesSpent) + ',' +
        CsvField(Sessions[I].Notes) + ',' +
        CsvField(Sessions[I].CreatedAt));
    Output.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    Output.Free;
  end;
end;

procedure ExportSessionsToSql(const ADatabase: TKpiDatabase; const AFileName: string);
var
  Sessions: TPracticeSessionArray;
  Output: TStringList;
  I: Integer;
begin
  Sessions := ADatabase.AllSessions;
  Output := TStringList.Create;
  try
    Output.Add('-- Competitive KPI Tool SQL export');
    Output.Add('BEGIN TRANSACTION;');
    Output.Add(Format(
      'INSERT OR REPLACE INTO settings(id, daily_goal, reminder_enabled) VALUES (1, %d, 1);',
      [ADatabase.DailyGoal]));
    for I := 0 to High(Sessions) do
      Output.Add(Format(
        'INSERT INTO practice_sessions(id, practiced_on, platform, problems_solved, minutes_spent, notes, created_at) VALUES (%d, %s, %s, %d, %d, %s, %s);',
        [Sessions[I].Id,
         SqlString(FormatDateTime('yyyy-mm-dd', Sessions[I].PracticedOn)),
         SqlString(Sessions[I].Platform),
         Sessions[I].ProblemsSolved,
         Sessions[I].MinutesSpent,
         SqlString(Sessions[I].Notes),
         SqlString(Sessions[I].CreatedAt)]));
    Output.Add('COMMIT;');
    Output.SaveToFile(AFileName, TEncoding.UTF8);
  finally
    Output.Free;
  end;
end;

end.
