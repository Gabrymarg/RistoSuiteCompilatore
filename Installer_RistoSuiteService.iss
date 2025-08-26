; Script Inno Setup aggiornato per RistoSuite - Installazione in C:\RistoSuite

#define MyAppName "RistoSuite"
#define MyAppVersion "1"
#define MyAppPublisher "RistoSuite, Inc."
#define MyAppExeName "RistoSuiteService.exe"
#define MyAppAssocName MyAppName + " File"
#define MyAppAssocExt ".myp"
#define MyAppAssocKey StringChange(MyAppAssocName, " ", "") + MyAppAssocExt

[Setup]
AppId={{99162DAE-BEDE-4EF5-938E-37691A25E44B}}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName=C:\{#MyAppName}
DisableDirPage=yes
UninstallDisplayIcon=C:\COMPILATORE\Ristosuite\assets\unistaller.ico
ArchitecturesAllowed=x64
ChangesAssociations=yes
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
OutputDir=C:\COMPILATORE\Ristosuite\Output
OutputBaseFilename=RistoSuiteInstaller
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
Password=RistoSuite2025

WizardImageFile=C:\COMPILATORE\Ristosuite\assets\logo.bmp
LicenseFile=C:\COMPILATORE\Ristosuite\assets\terms.txt
SetupIconFile=C:\COMPILATORE\Ristosuite\assets\installer.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop icon"; GroupDescription: "Additional icons:"; Flags: unchecked

[Files]
; File principali
Source: "C:\COMPILATORE\Ristosuite\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "C:\COMPILATORE\Ristosuite\Struct.exe"; DestDir: "{app}"; Flags: ignoreversion
; Cartelle web
Source: "C:\COMPILATORE\Ristosuite\web\templates\*"; DestDir: "{app}\web\templates"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "C:\COMPILATORE\Ristosuite\web\static\*"; DestDir: "{app}\web\static"; Flags: ignoreversion recursesubdirs createallsubdirs
; Icona personalizzata per il collegamento
Source: "C:\COMPILATORE\Ristosuite\assets\Ristosuite.ico"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocExt}\OpenWithProgids"; ValueType: string; ValueName: "{#MyAppAssocKey}"; ValueData: ""; Flags: uninsdeletevalue
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocKey}"; ValueType: string; ValueName: ""; ValueData: "{#MyAppAssocName}"; Flags: uninsdeletekey
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocKey}\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\{#MyAppExeName},0"
Root: HKCU; Subkey: "Software\Classes\{#MyAppAssocKey}\shell\open\command"; ValueType: string; ValueName: ""; ValueData: """{app}\{#MyAppExeName}"" ""%1"""

[Icons]
; Collegamento menu Start al servizio (solo per amministrazione)
Name: "{group}\{#MyAppName} Service"; Filename: "{app}\{#MyAppExeName}"

; Collegamento desktop: apre l'interfaccia web
Name: "{userdesktop}\{#MyAppName}"; Filename: "http://127.0.0.1:5050"; IconFilename: "{app}\Ristosuite.ico"; Tasks: desktopicon

[Code]
procedure CurStepChanged(CurStep: TSetupStep);
var
  ResultCode: Integer;
  StructPath: string;
begin
  if CurStep = ssPostInstall then
  begin
    StructPath := ExpandConstant('{app}\Struct.exe');

    // Esegui Struct.exe e fai pausa di 2 secondi
    if FileExists(StructPath) then
    begin
      if Exec(StructPath, '', '', SW_SHOWNORMAL, ewWaitUntilTerminated, ResultCode) then
        Sleep(2000)
      else
        MsgBox('Errore durante l''esecuzione di Struct.exe', mbError, MB_OK);
    end
    else
      MsgBox('Struct.exe non trovato in: ' + StructPath, mbError, MB_OK);

    // Installa il servizio
    if not Exec(ExpandConstant('{app}\{#MyAppExeName}'), '/install', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
      MsgBox('Errore durante l''installazione del servizio', mbError, MB_OK);

    Sleep(2000);

    // Avvia il servizio
    if not Exec(ExpandConstant('{app}\{#MyAppExeName}'), '/start', '', SW_HIDE, ewNoWait, ResultCode) then
      MsgBox('Errore durante l''avvio del servizio', mbError, MB_OK);
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  ResultCode: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    // Ferma il servizio
    Exec(ExpandConstant('{app}\{#MyAppExeName}'), '/stop', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
    // Rimuovi il servizio
    Exec(ExpandConstant('{app}\{#MyAppExeName}'), '/remove', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
  if CurUninstallStep = usPostUninstall then
  begin
    // Elimina tutta la cartella C:\RistoSuite
    DelTree('C:\RistoSuite', True, True, True);
  end;
end;
