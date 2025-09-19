#define MyAppName "RistoSuite"
#define MyAppVersion "2.0"
#define MyAppPublisher "RistoSuite, Inc."
#define MyAppExeName "RistoSuiteService.exe"
#define MyKioskExeName "RistoSuite_Kiosk.exe"

[Setup]
AppId={{99162DAE-BEDE-4EF5-938E-37691A25E44B}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName=C:\{#MyAppName}
DisableDirPage=yes
UninstallDisplayIcon=C:\COMPILATORE\RistoSuiteCompilatore\assets\unistaller.ico
ArchitecturesAllowed=x64
ChangesAssociations=yes
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
OutputDir=C:\COMPILATORE\RistoSuiteCompilatore\Output
OutputBaseFilename=RistoSuiteInstaller
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
Password=RistoSuite2025

WizardImageFile=C:\COMPILATORE\RistoSuiteCompilatore\assets\logo.bmp
LicenseFile=C:\COMPILATORE\RistoSuiteCompilatore\assets\terms.txt
SetupIconFile=C:\COMPILATORE\RistoSuiteCompilatore\assets\installer.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
Source: "C:\COMPILATORE\RistoSuiteCompilatore\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\COMPILATORE\RistoSuiteCompilatore\Struct.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\COMPILATORE\RistoSuiteCompilatore\web\templates\*"; DestDir: "{app}\web\templates"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\COMPILATORE\RistoSuiteCompilatore\web\static\*"; DestDir: "{app}\web\static"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\COMPILATORE\RistoSuiteCompilatore\assets\Ristosuite.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\COMPILATORE\RistoSuiteCompilatore\assets\sfondo_ristosuite.bmp"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Software\Classes\.myp\OpenWithProgids"; ValueType: string; ValueName: "RistoSuiteMYP.myp"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\RistoSuiteMYP.myp"; ValueType: string; ValueName: ""; ValueData: "RistoSuite File"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\RistoSuiteMYP.myp\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\RistoSuiteMYP.myp\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Icons]
Name: "{group}\{#MyAppName} Service"; Filename: "{app}\{#MyAppExeName}"

[Code]
procedure SetWallpaper(const FilePath: string);
var
  ResultCode: Integer;
  CmdLine: string;
begin
  CmdLine := 'powershell -command "Add-Type -TypeDefinition ''using System; using System.Runtime.InteropServices; ' +
             'public class Wallpaper { [DllImport(\"user32.dll\",SetLastError=true)] public static extern bool SystemParametersInfo(int uAction,int uParam,string lpvParam,int fuWinIni); }''; ' +
             '[Wallpaper]::SystemParametersInfo(20,0,'''+FilePath+''',3)"';
  Exec('cmd.exe', '/C ' + CmdLine, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;

procedure CreateWebAppShortcutsAndWallpaper;
var
  ResultCode: Integer;
  EdgePath, DesktopShortcut, StartupShortcut, IconPath, TargetArgs, WallpaperPath: string;
begin
  EdgePath := 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe';
  DesktopShortcut := ExpandConstant('{userdesktop}\RistoSuite WebApp.lnk');
  StartupShortcut := ExpandConstant('{userappdata}\Microsoft\Windows\Start Menu\Programs\Startup\RistoSuite WebApp.lnk');
  IconPath := ExpandConstant('{app}\Ristosuite.ico');
  WallpaperPath := ExpandConstant('{app}\sfondo_ristosuite.bmp');

  TargetArgs := '--kiosk http://127.0.0.1:5050/login_web --edge-kiosk-type=fullscreen --no-first-run --test-type --ignore-certificate-errors --allow-insecure-localhost';

  Exec('powershell.exe',
       '-Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut(''' + DesktopShortcut + '''); $s.TargetPath = ''' + EdgePath + '''; $s.Arguments = ''' + TargetArgs + '''; $s.IconLocation = ''' + IconPath + '''; $s.Save()"',
       '', SW_SHOW, ewWaitUntilTerminated, ResultCode);

  Exec('powershell.exe',
       '-Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut(''' + StartupShortcut + '''); $s.TargetPath = ''' + EdgePath + '''; $s.Arguments = ''' + TargetArgs + '''; $s.IconLocation = ''' + IconPath + '''; $s.Save()"',
       '', SW_SHOW, ewWaitUntilTerminated, ResultCode);

  SetWallpaper(WallpaperPath);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  StructPath: string;
begin
  if CurStep = ssPostInstall then
  begin
    StructPath := ExpandConstant('{app}\Struct.exe');
    if FileExists(StructPath) then
      Exec(StructPath, '', '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode);

    Exec(ExpandConstant('{app}\{#MyAppExeName}'), '/install', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec(ExpandConstant('{app}\{#MyAppExeName}'), '/start', '', SW_HIDE, ewNoWait, ResultCode);

    CreateWebAppShortcutsAndWallpaper;

    Exec(ExpandConstant('{userdesktop}\RistoSuite WebApp.lnk'), '', '', SW_SHOWNORMAL, ewNoWait, ResultCode);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
  DesktopShortcut, StartupShortcut: string;
begin
  DesktopShortcut := ExpandConstant('{userdesktop}\RistoSuite WebApp.lnk');
  StartupShortcut := ExpandConstant('{userappdata}\Microsoft\Windows\Start Menu\Programs\Startup\RistoSuite WebApp.lnk');

  if CurUninstallStep = usUninstall then
  begin
    Exec(ExpandConstant('{app}\{#MyAppExeName}'), '/stop', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    Exec(ExpandConstant('{app}\{#MyAppExeName}'), '/remove', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);

    if FileExists(DesktopShortcut) then
      DeleteFile(DesktopShortcut);
    if FileExists(StartupShortcut) then
      DeleteFile(StartupShortcut);
  end;

  if CurUninstallStep = usPostUninstall then
  begin
    DelTree(ExpandConstant('{app}'), True, True, True);
  end;
end;
