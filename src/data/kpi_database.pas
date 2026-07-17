unit kpi_database;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB, SQLite3Conn, kpi_types;

type
  TKpiDatabase = class
  private
    FConnection: TSQLite3Connection;
    FTransaction: TSQLTransaction;
    function NewQuery: TSQLQuery;
    class function IsoDate(const ADate: TDateTime): string; static;
    procedure EnsureOpen;
  public
    constructor Create(const ADatabaseFile: string);
    destructor Destroy; override;
    procedure Open;
    procedure Close;
    procedure AddSession(const ASession: TPracticeSession);
    function DailyGoal: Integer;
    procedure SetDailyGoal(const AGoal: Integer);
    function ProblemsSolvedOn(const ADate: TDateTime): Integer;
    function ProblemsSolvedBetween(const AStartDate, AEndDate: TDateTime): Integer;
    function TotalSessions: Integer;
    function CurrentStreak(const AReferenceDate: TDateTime): Integer;
    function Snapshot(const AReferenceDate: TDateTime): TKpiSnapshot;
    procedure LoadRecentSessions(const ATarget: TStrings; const ALimit: Integer = 25);
    function AllSessions: TPracticeSessionArray;
  end;

implementation

uses
  DateUtils, kpi_calculator;

constructor TKpiDatabase.Create(const ADatabaseFile: string);
begin
  inherited Create;
  FConnection := TSQLite3Connection.Create(nil);
  FTransaction := TSQLTransaction.Create(nil);
  FConnection.DatabaseName := ADatabaseFile;
  FConnection.Transaction := FTransaction;
  FTransaction.Database := FConnection;
end;

destructor TKpiDatabase.Destroy;
begin
  try
    Close;
  except
    { Destructors must not propagate shutdown errors. }
  end;
  FreeAndNil(FTransaction);
  FreeAndNil(FConnection);
  inherited Destroy;
end;

class function TKpiDatabase.IsoDate(const ADate: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd', ADate);
end;

procedure TKpiDatabase.EnsureOpen;
begin
  if not FConnection.Connected then
    raise Exception.Create('The database is not open.');
end;

function TKpiDatabase.NewQuery: TSQLQuery;
begin
  EnsureOpen;
  Result := TSQLQuery.Create(nil);
  Result.Database := FConnection;
  Result.Transaction := FTransaction;
end;

procedure TKpiDatabase.Open;
begin
  if FConnection.Connected then
    Exit;

  FConnection.Open;
  FTransaction.Active := True;
  try
    FConnection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS schema_version (' +
      'version INTEGER NOT NULL);');
    FConnection.ExecuteDirect(
      'INSERT INTO schema_version(version) ' +
      'SELECT 1 WHERE NOT EXISTS (SELECT 1 FROM schema_version);');
    FConnection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS settings (' +
      'id INTEGER PRIMARY KEY CHECK (id = 1), ' +
      'daily_goal INTEGER NOT NULL DEFAULT 3 CHECK (daily_goal BETWEEN 1 AND 100), ' +
      'reminder_enabled INTEGER NOT NULL DEFAULT 1 CHECK (reminder_enabled IN (0, 1)));');
    FConnection.ExecuteDirect(
      'INSERT OR IGNORE INTO settings(id, daily_goal, reminder_enabled) VALUES (1, 3, 1);');
    FConnection.ExecuteDirect(
      'CREATE TABLE IF NOT EXISTS practice_sessions (' +
      'id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'practiced_on TEXT NOT NULL, ' +
      'platform TEXT NOT NULL CHECK (length(platform) BETWEEN 1 AND 80), ' +
      'problems_solved INTEGER NOT NULL CHECK (problems_solved >= 0), ' +
      'minutes_spent INTEGER NOT NULL CHECK (minutes_spent >= 0), ' +
      'notes TEXT NOT NULL DEFAULT ' + QuotedStr('') + ', ' +
      'created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP);');
    FConnection.ExecuteDirect(
      'CREATE INDEX IF NOT EXISTS idx_sessions_practiced_on ' +
      'ON practice_sessions(practiced_on);');
    FTransaction.CommitRetaining;
  except
    FTransaction.Rollback;
    raise;
  end;
end;

procedure TKpiDatabase.Close;
begin
  if Assigned(FTransaction) and FTransaction.Active then
    FTransaction.Commit;
  if Assigned(FConnection) and FConnection.Connected then
    FConnection.Close;
end;

procedure TKpiDatabase.AddSession(const ASession: TPracticeSession);
var
  Q: TSQLQuery;
begin
  if Trim(ASession.Platform) = '' then
    raise EArgumentException.Create('Platform is required.');
  if ASession.ProblemsSolved < 0 then
    raise EArgumentException.Create('Problems solved cannot be negative.');
  if ASession.MinutesSpent < 0 then
    raise EArgumentException.Create('Minutes spent cannot be negative.');

  Q := NewQuery;
  try
    try
      Q.SQL.Text :=
        'INSERT INTO practice_sessions ' +
        '(practiced_on, platform, problems_solved, minutes_spent, notes) ' +
        'VALUES (:practiced_on, :platform, :problems_solved, :minutes_spent, :notes);';
      Q.Params.ParamByName('practiced_on').AsString := IsoDate(ASession.PracticedOn);
      Q.Params.ParamByName('platform').AsString := Trim(ASession.Platform);
      Q.Params.ParamByName('problems_solved').AsInteger := ASession.ProblemsSolved;
      Q.Params.ParamByName('minutes_spent').AsInteger := ASession.MinutesSpent;
      Q.Params.ParamByName('notes').AsString := ASession.Notes;
      Q.ExecSQL;
      FTransaction.CommitRetaining;
    except
      FTransaction.RollbackRetaining;
      raise;
    end;
  finally
    Q.Free;
  end;
end;

function TKpiDatabase.DailyGoal: Integer;
var
  Q: TSQLQuery;
begin
  Q := NewQuery;
  try
    Q.SQL.Text := 'SELECT daily_goal FROM settings WHERE id = 1;';
    Q.Open;
    Result := Q.FieldByName('daily_goal').AsInteger;
  finally
    Q.Free;
  end;
end;

procedure TKpiDatabase.SetDailyGoal(const AGoal: Integer);
var
  Q: TSQLQuery;
begin
  if (AGoal < 1) or (AGoal > 100) then
    raise EArgumentException.Create('Daily goal must be between 1 and 100.');
  Q := NewQuery;
  try
    try
      Q.SQL.Text := 'UPDATE settings SET daily_goal = :goal WHERE id = 1;';
      Q.Params.ParamByName('goal').AsInteger := AGoal;
      Q.ExecSQL;
      FTransaction.CommitRetaining;
    except
      FTransaction.RollbackRetaining;
      raise;
    end;
  finally
    Q.Free;
  end;
end;

function TKpiDatabase.ProblemsSolvedOn(const ADate: TDateTime): Integer;
var
  Q: TSQLQuery;
begin
  Q := NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COALESCE(SUM(problems_solved), 0) AS solved ' +
      'FROM practice_sessions WHERE practiced_on = :practiced_on;';
    Q.Params.ParamByName('practiced_on').AsString := IsoDate(ADate);
    Q.Open;
    Result := Q.FieldByName('solved').AsInteger;
  finally
    Q.Free;
  end;
end;

function TKpiDatabase.ProblemsSolvedBetween(const AStartDate, AEndDate: TDateTime): Integer;
var
  Q: TSQLQuery;
begin
  Q := NewQuery;
  try
    Q.SQL.Text :=
      'SELECT COALESCE(SUM(problems_solved), 0) AS solved FROM practice_sessions ' +
      'WHERE practiced_on BETWEEN :start_date AND :end_date;';
    Q.Params.ParamByName('start_date').AsString := IsoDate(AStartDate);
    Q.Params.ParamByName('end_date').AsString := IsoDate(AEndDate);
    Q.Open;
    Result := Q.FieldByName('solved').AsInteger;
  finally
    Q.Free;
  end;
end;

function TKpiDatabase.TotalSessions: Integer;
var
  Q: TSQLQuery;
begin
  Q := NewQuery;
  try
    Q.SQL.Text := 'SELECT COUNT(*) AS session_count FROM practice_sessions;';
    Q.Open;
    Result := Q.FieldByName('session_count').AsInteger;
  finally
    Q.Free;
  end;
end;

function TKpiDatabase.CurrentStreak(const AReferenceDate: TDateTime): Integer;
var
  CursorDate: TDateTime;
begin
  Result := 0;
  CursorDate := Trunc(AReferenceDate);
  if ProblemsSolvedOn(CursorDate) = 0 then
    CursorDate := IncDay(CursorDate, -1);

  while (Result < 3660) and (ProblemsSolvedOn(CursorDate) > 0) do
  begin
    Inc(Result);
    CursorDate := IncDay(CursorDate, -1);
  end;
end;

function TKpiDatabase.Snapshot(const AReferenceDate: TDateTime): TKpiSnapshot;
var
  SevenDayTotal: Integer;
begin
  Result.DailyGoal := DailyGoal;
  Result.TodaySolved := ProblemsSolvedOn(AReferenceDate);
  Result.GoalCompletionPercent :=
    GoalCompletionPercent(Result.TodaySolved, Result.DailyGoal);
  SevenDayTotal := ProblemsSolvedBetween(IncDay(AReferenceDate, -6), AReferenceDate);
  Result.SevenDayAverage := AveragePerDay(SevenDayTotal, 7);
  Result.TotalSessions := TotalSessions;
  Result.CurrentStreak := CurrentStreak(AReferenceDate);
end;

procedure TKpiDatabase.LoadRecentSessions(const ATarget: TStrings; const ALimit: Integer);
var
  Q: TSQLQuery;
begin
  ATarget.BeginUpdate;
  try
    ATarget.Clear;
    Q := NewQuery;
    try
      Q.SQL.Text :=
        'SELECT practiced_on, platform, problems_solved, minutes_spent ' +
        'FROM practice_sessions ORDER BY practiced_on DESC, id DESC LIMIT :row_limit;';
      Q.Params.ParamByName('row_limit').AsInteger := ALimit;
      Q.Open;
      while not Q.EOF do
      begin
        ATarget.Add(Format('%s'#9'%s'#9'%d'#9'%d', [
          Q.FieldByName('practiced_on').AsString,
          Q.FieldByName('platform').AsString,
          Q.FieldByName('problems_solved').AsInteger,
          Q.FieldByName('minutes_spent').AsInteger]));
        Q.Next;
      end;
    finally
      Q.Free;
    end;
  finally
    ATarget.EndUpdate;
  end;
end;

function TKpiDatabase.AllSessions: TPracticeSessionArray;
var
  Q: TSQLQuery;
  Index: Integer;
begin
  SetLength(Result, 0);
  Q := NewQuery;
  try
    Q.SQL.Text :=
      'SELECT id, practiced_on, platform, problems_solved, minutes_spent, notes, created_at ' +
      'FROM practice_sessions ORDER BY id;';
    Q.Open;
    Index := 0;
    while not Q.EOF do
    begin
      SetLength(Result, Index + 1);
      Result[Index].Id := Q.FieldByName('id').AsLargeInt;
      if not TryISO8601ToDate(Q.FieldByName('practiced_on').AsString, Result[Index].PracticedOn, False) then
        Result[Index].PracticedOn := 0;
      Result[Index].Platform := Q.FieldByName('platform').AsString;
      Result[Index].ProblemsSolved := Q.FieldByName('problems_solved').AsInteger;
      Result[Index].MinutesSpent := Q.FieldByName('minutes_spent').AsInteger;
      Result[Index].Notes := Q.FieldByName('notes').AsString;
      Result[Index].CreatedAt := Q.FieldByName('created_at').AsString;
      Inc(Index);
      Q.Next;
    end;
  finally
    Q.Free;
  end;
end;

end.
