#define MyAppName "pyRevit 7 for Revit 2019 (Experimental)"
[Setup]
AppId={{AD41BB93-8AEC-4603-9110-635146B2C679}
AppName={#MyAppName}
AppVersion=7.0.0.26278
DefaultDirName={userdocs}\pyRevit-7-Revit2019
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\..\installer-build
OutputBaseFilename=pyRevit7-Revit2019-experimental
Compression=lzma2/fast
SolidCompression=yes
#ifdef SANDBOXTEST
Uninstallable=no
#endif

[Files]
Source: "..\bin\*"; DestDir: "{app}\bin"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\extensions\*"; DestDir: "{app}\extensions"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\pyrevitlib\*"; DestDir: "{app}\pyrevitlib"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\site-packages\*"; DestDir: "{app}\site-packages"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\licenses\*"; DestDir: "{app}\licenses"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\pyRevitfile"; DestDir: "{app}"; Flags: ignoreversion
Source: ".pyrevitargs"; DestDir: "{app}"; Flags: ignoreversion

[Code]
function EscapeXml(const Value: String): String;
begin
  Result := Value;
  StringChangeEx(Result, '&', '&amp;', True);
  StringChangeEx(Result, '<', '&lt;', True);
  StringChangeEx(Result, '>', '&gt;', True);
  StringChangeEx(Result, '"', '&quot;', True);
end;

function ManifestPath: String;
begin
#ifdef SANDBOXTEST
  Result := GetEnv('PYREVIT_TEST_MANIFEST');
  if Result = '' then RaiseException('Sandbox manifest path is required.');
#else
  Result := ExpandConstant('{userappdata}\Autodesk\Revit\Addins\2019\pyRevit.addin');
#endif
end;

function LoaderPath: String;
begin
  Result := ExpandConstant('{app}\bin\netfx\engines\IPY2712PR\pyRevitLoader.dll');
end;

function IsOurManifest(const Path: String): Boolean;
var Content: AnsiString;
begin
  Result := LoadStringFromFile(Path, Content) and (Pos(Lowercase(EscapeXml(LoaderPath)), Lowercase(UTF8Decode(Content))) > 0);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var OldManifest, Backup, Text: String; ResultCode: Integer;
begin
  if CurStep = ssInstall then begin
    if FileExists(ExpandConstant('{app}\bin\netfx\engines\IPY2712PR\RevitAPI.dll')) or
       FileExists(ExpandConstant('{app}\bin\netfx\engines\IPY2712PR\RevitDBAPI.dll')) or
       FileExists(ExpandConstant('{app}\bin\netfx\engines\IPY342\RevitAPI.dll')) or
       FileExists(ExpandConstant('{app}\bin\netfx\engines\IPY342\RevitDBAPI.dll')) then
      RaiseException('This installation folder contains old Revit application DLLs. Choose a new, empty folder for this build.');
  end;
  if CurStep = ssPostInstall then begin
    OldManifest := ManifestPath;
    Backup := ExpandConstant('{app}\previous-pyRevit-2019.addin');
    if not ForceDirectories(ExtractFileDir(OldManifest)) then
      RaiseException('Could not create the Revit 2019 add-in folder.');
    if FileExists(OldManifest) and not IsOurManifest(OldManifest) then begin
      if FileExists(Backup) then
        RaiseException('A previous add-in backup already exists. Existing registration was left unchanged.');
      if not FileCopy(OldManifest, Backup, False) then
        RaiseException('Could not back up the existing pyRevit registration.');
    end;
    if not Exec(ExpandConstant('{app}\bin\pyrevit.exe'), 'clones add pyrevit7-2019-packaged "' + ExpandConstant('{app}') + '" --force', ExpandConstant('{app}'), SW_HIDE, ewWaitUntilTerminated, ResultCode) or (ResultCode <> 0) then
      RaiseException('Could not register the experimental clone. Existing Revit registration was left unchanged.');
    Text := '<?xml version="1.0" encoding="utf-8"?>' + #13#10 + '<RevitAddIns><AddIn Type="Application"><Name>PyRevitLoader</Name><Assembly>' + EscapeXml(LoaderPath) + '</Assembly><AddInId>B39107C3-A1D7-47F4-A5A1-532DDF6EDB5D</AddInId><FullClassName>PyRevitLoader.PyRevitLoaderApplication</FullClassName><VendorId>eirannejad</VendorId></AddIn></RevitAddIns>';
    if not SaveStringToFile(OldManifest, UTF8Encode(Text), False) then
      RaiseException('Could not update the Revit registration. The old manifest backup remains in the install folder.');
  end;
end;

#ifndef SANDBOXTEST
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var OldManifest, Backup: String;
begin
  if CurUninstallStep = usUninstall then begin
    OldManifest := ManifestPath;
    Backup := ExpandConstant('{app}\previous-pyRevit-2019.addin');
    if IsOurManifest(OldManifest) then begin
      if FileExists(Backup) then begin
        if not FileCopy(Backup, OldManifest, False) then
          MsgBox('Could not restore the previous pyRevit manifest. Backup: ' + Backup, mbError, MB_OK);
      end else if not DeleteFile(OldManifest) then
        MsgBox('Could not remove the experimental pyRevit manifest: ' + OldManifest, mbError, MB_OK);
    end;
  end;
end;
#endif

