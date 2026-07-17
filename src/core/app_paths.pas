unit app_paths;

{$mode objfpc}{$H+}

interface

function ApplicationDataDirectory: string;
function DatabaseFileName: string;

implementation

uses
  SysUtils;

function ApplicationDataDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(GetAppConfigDir(False)) +
    'competitive-kpi-tool' + DirectorySeparator;
  if not ForceDirectories(Result) then
    raise Exception.CreateFmt('Unable to create application data directory: %s', [Result]);
end;

function DatabaseFileName: string;
begin
  Result := ApplicationDataDirectory + 'competitive_kpi.sqlite3';
end;

end.
