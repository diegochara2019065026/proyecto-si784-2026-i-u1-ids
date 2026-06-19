#define MyAppName "TrafficWatch IDS"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "TrafficWatch"
#define MyAppExeName "TrafficWatchIDS.exe"

[Setup]
AppId={{9F870207-1ED1-4F40-9864-985E2D0F19A7}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\TrafficWatchIDS
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
OutputDir=..\installer_output
OutputBaseFilename=TrafficWatchIDS_Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; GroupDescription: "Accesos directos:"; Flags: checkedonce
Name: "openreadme"; Description: "Abrir guia del proyecto al finalizar"; GroupDescription: "Documentacion:"; Flags: unchecked
Name: "installnmap"; Description: "Instalar Nmap y Npcap para escaneos y captura de red"; GroupDescription: "Herramientas opcionales:"; Flags: unchecked
Name: "installpython"; Description: "Instalar Python 3.12 para scripts y desarrollo"; GroupDescription: "Herramientas opcionales:"; Flags: unchecked

[Files]
Source: "..\dist\TrafficWatchIDS\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\INSTALAR_TRAFFICWATCH_WINDOWS.ps1"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{group}\TrafficWatch IDS"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\Instalar dependencias opcionales"; Filename: "powershell.exe"; Parameters: "-NoExit -ExecutionPolicy Bypass -File ""{app}\INSTALAR_TRAFFICWATCH_WINDOWS.ps1"""; WorkingDir: "{app}"
Name: "{autodesktop}\TrafficWatch IDS"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Iniciar TrafficWatch IDS"; Flags: nowait postinstall skipifsilent
Filename: "notepad.exe"; Parameters: """{app}\README.md"""; Description: "Abrir README"; Tasks: openreadme; Flags: postinstall skipifsilent

[Code]
function InstallWingetPackage(const PackageId, PackageName: String): Boolean;
var
  ResultCode: Integer;
  Parameters: String;
begin
  Parameters := '/C winget install --id ' + PackageId +
    ' --exact --silent --accept-package-agreements --accept-source-agreements';

  Result := ShellExec('runas', ExpandConstant('{cmd}'), Parameters, '', SW_SHOWNORMAL,
    ewWaitUntilTerminated, ResultCode);

  if not Result then begin
    MsgBox('No se pudo iniciar la instalacion de ' + PackageName +
      '. Acepta el aviso de administrador y verifica que winget este disponible.',
      mbError, MB_OK);
    Exit;
  end;

  if ResultCode <> 0 then begin
    MsgBox(PackageName + ' no se instalo correctamente. Codigo de salida: ' +
      IntToStr(ResultCode) + '. Verifica tu conexion a Internet y winget.',
      mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep <> ssPostInstall then
    Exit;

  if WizardIsTaskSelected('installnmap') then
    InstallWingetPackage('Insecure.Nmap', 'Nmap y Npcap');

  if WizardIsTaskSelected('installpython') then
    InstallWingetPackage('Python.Python.3.12', 'Python 3.12');
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
end;
