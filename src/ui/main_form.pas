unit main_form;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Spin, Dialogs, Grids,
  kpi_database, kpi_types;

type
  TMainForm = class(TForm)
  private
    FDatabase: TKpiDatabase;
    FDateEdit: TEdit;
    FPlatformEdit: TComboBox;
    FSolvedEdit: TSpinEdit;
    FMinutesEdit: TSpinEdit;
    FNotesEdit: TMemo;
    FGoalEdit: TSpinEdit;
    FTodayLabel: TLabel;
    FAverageLabel: TLabel;
    FStreakLabel: TLabel;
    FSessionsLabel: TLabel;
    FHistory: TStringGrid;
    procedure BuildInterface;
    procedure SaveSessionClick(Sender: TObject);
    procedure SaveGoalClick(Sender: TObject);
    procedure ExportCsvClick(Sender: TObject);
    procedure ExportSqlClick(Sender: TObject);
    procedure RefreshDashboard;
    procedure RefreshHistory;
    function ParsedPracticeDate: TDateTime;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

uses
  DateUtils, app_paths, export_service, reminder_service;

constructor TMainForm.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  Caption := 'Competitive KPI Tool';
  Width := 920;
  Height := 650;
  Position := poScreenCenter;
  BuildInterface;

  FDatabase := TKpiDatabase.Create(DatabaseFileName);
  try
    FDatabase.Open;
    FGoalEdit.Value := FDatabase.DailyGoal;
    RefreshDashboard;
    RefreshHistory;
    if ReminderIsDue(FDatabase.ProblemsSolvedOn(Date), FDatabase.DailyGoal) then
      ShowMessage('Your daily competitive-programming goal is still incomplete.');
  except
    on E: Exception do
      MessageDlg('Startup error', E.Message, mtError, [mbOK], 0);
  end;
end;

destructor TMainForm.Destroy;
begin
  FreeAndNil(FDatabase);
  inherited Destroy;
end;

procedure TMainForm.BuildInterface;
var
  L: TLabel;
  SaveButton, GoalButton, CsvButton, SqlButton: TButton;
begin
  L := TLabel.Create(Self); L.Parent := Self; L.Caption := 'Practice date (YYYY-MM-DD)'; L.Left := 24; L.Top := 24;
  FDateEdit := TEdit.Create(Self); FDateEdit.Parent := Self; FDateEdit.Left := 24; FDateEdit.Top := 46; FDateEdit.Width := 150; FDateEdit.Text := FormatDateTime('yyyy-mm-dd', Date);

  L := TLabel.Create(Self); L.Parent := Self; L.Caption := 'Platform'; L.Left := 194; L.Top := 24;
  FPlatformEdit := TComboBox.Create(Self); FPlatformEdit.Parent := Self; FPlatformEdit.Left := 194; FPlatformEdit.Top := 46; FPlatformEdit.Width := 150; FPlatformEdit.Items.Add('Codeforces'); FPlatformEdit.Items.Add('AtCoder'); FPlatformEdit.Items.Add('CSES'); FPlatformEdit.Items.Add('ICPC'); FPlatformEdit.Text := 'Codeforces';

  L := TLabel.Create(Self); L.Parent := Self; L.Caption := 'Solved'; L.Left := 364; L.Top := 24;
  FSolvedEdit := TSpinEdit.Create(Self); FSolvedEdit.Parent := Self; FSolvedEdit.Left := 364; FSolvedEdit.Top := 46; FSolvedEdit.MinValue := 0; FSolvedEdit.MaxValue := 500; FSolvedEdit.Value := 1;

  L := TLabel.Create(Self); L.Parent := Self; L.Caption := 'Minutes'; L.Left := 464; L.Top := 24;
  FMinutesEdit := TSpinEdit.Create(Self); FMinutesEdit.Parent := Self; FMinutesEdit.Left := 464; FMinutesEdit.Top := 46; FMinutesEdit.MinValue := 0; FMinutesEdit.MaxValue := 1440; FMinutesEdit.Value := 60;

  L := TLabel.Create(Self); L.Parent := Self; L.Caption := 'Notes'; L.Left := 24; L.Top := 86;
  FNotesEdit := TMemo.Create(Self); FNotesEdit.Parent := Self; FNotesEdit.Left := 24; FNotesEdit.Top := 108; FNotesEdit.Width := 540; FNotesEdit.Height := 70;

  SaveButton := TButton.Create(Self); SaveButton.Parent := Self; SaveButton.Caption := 'Save session'; SaveButton.Left := 584; SaveButton.Top := 108; SaveButton.Width := 130; SaveButton.OnClick := @SaveSessionClick;

  L := TLabel.Create(Self); L.Parent := Self; L.Caption := 'Daily goal'; L.Left := 734; L.Top := 86;
  FGoalEdit := TSpinEdit.Create(Self); FGoalEdit.Parent := Self; FGoalEdit.Left := 734; FGoalEdit.Top := 108; FGoalEdit.MinValue := 1; FGoalEdit.MaxValue := 100;
  GoalButton := TButton.Create(Self); GoalButton.Parent := Self; GoalButton.Caption := 'Save goal'; GoalButton.Left := 734; GoalButton.Top := 142; GoalButton.Width := 120; GoalButton.OnClick := @SaveGoalClick;

  FTodayLabel := TLabel.Create(Self); FTodayLabel.Parent := Self; FTodayLabel.Left := 24; FTodayLabel.Top := 210; FTodayLabel.Font.Style := [fsBold];
  FAverageLabel := TLabel.Create(Self); FAverageLabel.Parent := Self; FAverageLabel.Left := 240; FAverageLabel.Top := 210; FAverageLabel.Font.Style := [fsBold];
  FStreakLabel := TLabel.Create(Self); FStreakLabel.Parent := Self; FStreakLabel.Left := 470; FStreakLabel.Top := 210; FStreakLabel.Font.Style := [fsBold];
  FSessionsLabel := TLabel.Create(Self); FSessionsLabel.Parent := Self; FSessionsLabel.Left := 670; FSessionsLabel.Top := 210; FSessionsLabel.Font.Style := [fsBold];

  FHistory := TStringGrid.Create(Self); FHistory.Parent := Self; FHistory.Left := 24; FHistory.Top := 250; FHistory.Width := 840; FHistory.Height := 300; FHistory.ColCount := 4; FHistory.FixedRows := 1; FHistory.Cells[0,0] := 'Date'; FHistory.Cells[1,0] := 'Platform'; FHistory.Cells[2,0] := 'Solved'; FHistory.Cells[3,0] := 'Minutes'; FHistory.ColWidths[0] := 130; FHistory.ColWidths[1] := 250; FHistory.ColWidths[2] := 100; FHistory.ColWidths[3] := 100;

  CsvButton := TButton.Create(Self); CsvButton.Parent := Self; CsvButton.Caption := 'Export CSV'; CsvButton.Left := 24; CsvButton.Top := 570; CsvButton.Width := 120; CsvButton.OnClick := @ExportCsvClick;
  SqlButton := TButton.Create(Self); SqlButton.Parent := Self; SqlButton.Caption := 'Export SQL'; SqlButton.Left := 160; SqlButton.Top := 570; SqlButton.Width := 120; SqlButton.OnClick := @ExportSqlClick;
end;

function TMainForm.ParsedPracticeDate: TDateTime;
var
  Y, M, D: Word;
  IY, IM, ID: Integer;
  Value: string;
begin
  Value := Trim(FDateEdit.Text);
  if (Length(Value) <> 10) or (Value[5] <> '-') or (Value[8] <> '-') then
    raise EConvertError.Create('Date must use YYYY-MM-DD.');
  if not TryStrToInt(Copy(Value, 1, 4), IY) or
     not TryStrToInt(Copy(Value, 6, 2), IM) or
     not TryStrToInt(Copy(Value, 9, 2), ID) or
     (IY < 1) or (IY > 9999) or (IM < 1) or (IM > 12) or
     (ID < 1) or (ID > 31) then
    raise EConvertError.Create('Date is invalid.');
  Y := IY;
  M := IM;
  D := ID;
  if not TryEncodeDate(Y, M, D, Result) then
    raise EConvertError.Create('Date is invalid.');
end;

procedure TMainForm.SaveSessionClick(Sender: TObject);
var
  Session: TPracticeSession;
begin
  try
    Session.Id := 0;
    Session.PracticedOn := ParsedPracticeDate;
    Session.Platform := Trim(FPlatformEdit.Text);
    Session.ProblemsSolved := FSolvedEdit.Value;
    Session.MinutesSpent := FMinutesEdit.Value;
    Session.Notes := FNotesEdit.Text;
    Session.CreatedAt := '';
    FDatabase.AddSession(Session);
    FNotesEdit.Clear;
    RefreshDashboard;
    RefreshHistory;
  except
    on E: Exception do
      MessageDlg('Unable to save session', E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.SaveGoalClick(Sender: TObject);
begin
  try
    FDatabase.SetDailyGoal(FGoalEdit.Value);
    RefreshDashboard;
  except
    on E: Exception do
      MessageDlg('Unable to save goal', E.Message, mtError, [mbOK], 0);
  end;
end;

procedure TMainForm.ExportCsvClick(Sender: TObject);
var
  D: TSaveDialog;
begin
  D := TSaveDialog.Create(Self);
  try
    D.Filter := 'CSV files|*.csv'; D.DefaultExt := 'csv'; D.FileName := 'competitive-kpi-sessions.csv';
    if D.Execute then ExportSessionsToCsv(FDatabase, D.FileName);
  finally D.Free; end;
end;

procedure TMainForm.ExportSqlClick(Sender: TObject);
var
  D: TSaveDialog;
begin
  D := TSaveDialog.Create(Self);
  try
    D.Filter := 'SQL files|*.sql'; D.DefaultExt := 'sql'; D.FileName := 'competitive-kpi-backup.sql';
    if D.Execute then ExportSessionsToSql(FDatabase, D.FileName);
  finally D.Free; end;
end;

procedure TMainForm.RefreshDashboard;
var
  Kpi: TKpiSnapshot;
begin
  Kpi := FDatabase.Snapshot(Date);
  FTodayLabel.Caption := Format('Today: %d / %d (%.0f%%)', [Kpi.TodaySolved, Kpi.DailyGoal, Kpi.GoalCompletionPercent]);
  FAverageLabel.Caption := Format('7-day average: %.2f', [Kpi.SevenDayAverage]);
  FStreakLabel.Caption := Format('Streak: %d days', [Kpi.CurrentStreak]);
  FSessionsLabel.Caption := Format('Sessions: %d', [Kpi.TotalSessions]);
end;

procedure TMainForm.RefreshHistory;
var
  Rows, Parts: TStringList;
  I, J: Integer;
begin
  Rows := TStringList.Create;
  Parts := TStringList.Create;
  try
    Parts.StrictDelimiter := True; Parts.Delimiter := #9;
    FDatabase.LoadRecentSessions(Rows, 25);
    FHistory.RowCount := Rows.Count + 1;
    for I := 0 to Rows.Count - 1 do
    begin
      Parts.DelimitedText := Rows[I];
      for J := 0 to 3 do
        if J < Parts.Count then FHistory.Cells[J, I + 1] := Parts[J];
    end;
  finally
    Parts.Free; Rows.Free;
  end;
end;

end.
