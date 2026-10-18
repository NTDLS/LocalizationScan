#define AppVersion "1.0.0"

[Setup]
;-- Main Setup Information
 AppName                          = LocalizationScan
 AppVersion                       = {#AppVersion}
 AppVerName                       = LocalizationScan {#AppVersion}
 AppCopyright                     = Copyright © 1995-2026 NetworkDLS.
 DefaultDirName                   = {commonpf}\NetworkDLS\LocalizationScan
 DefaultGroupName                 = NetworkDLS\LocalizationScan
 UninstallDisplayIcon             = {app}\LocalizationScan.exe
 PrivilegesRequired               = admin 
 Uninstallable                    = Yes
 MinVersion                       = 0.0,7.0
 Compression                      = bZIP/9
 ChangesEnvironment               = Yes
 OutputBaseFilename               = LocalizationScan {#AppVersion}
 ArchitecturesInstallIn64BitMode  = x64compatible
 AppPublisher                     = NetworkDLS
 AppPublisherURL                  = http://www.NetworkDLS.com/
 AppUpdatesURL                    = http://www.NetworkDLS.com/

[Files]
 Source: "publish\LocalizationScan\*.*"; DestDir: "{app}"; Flags: IgnoreVersion RecurseSubDirs;
 Source: "..\README.md"; DestDir: "{app}"; Flags: IgnoreVersion;
 Source: "..\LICENSE"; DestDir: "{app}"; Flags: IgnoreVersion;

[Registry]
;-- LocalizationScan is a command line tool: add the install folder to the system PATH.
 Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Check: NeedsAddPath(ExpandConstant('{app}'))

[Code]
function NeedsAddPath(Param: string): Boolean;
var
  OrigPath: string;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', OrigPath) then
  begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Uppercase(Param) + ';', ';' + Uppercase(OrigPath) + ';') = 0;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  OrigPath, AppDir: string;
  P: Integer;
begin
  if CurUninstallStep <> usPostUninstall then exit;
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', OrigPath) then exit;
  AppDir := ExpandConstant('{app}');
  P := Pos(';' + Uppercase(AppDir), Uppercase(OrigPath));
  if P > 0 then
  begin
    Delete(OrigPath, P, Length(AppDir) + 1);
    RegWriteExpandStringValue(HKEY_LOCAL_MACHINE, 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment', 'Path', OrigPath);
  end;
end;
