; Inno Setup Script for AetherDrop Windows Installer
; Compiles all Flutter release binaries and assets into a single standalone setup executable.

#ifndef AppVersion
#define AppVersion "1.0.0"
#endif

#ifndef SourceDir
#define SourceDir "..\build\windows\x64\runner\Release"
#endif

#define AppName "AetherDrop"
#define AppPublisher "AetherDrop"
#define AppURL "https://github.com/YOUR_GITHUB_USERNAME/aetherdrop"
#define AppExeName "aetherdrop_app.exe"
#define AppOutputBaseName "AetherDrop-Windows-Setup"

[Setup]
; Unique AppId for update tracking and clean uninstallation
AppId={{9F82B7D6-981F-4B83-A845-F5D54B86A410}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
AppUpdatesURL={#AppURL}
DefaultDirName={autopf}\{#AppName}
DisableProgramGroupPage=yes
; Architecture targeting x64
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Non-admin install into user directory prevents UAC admin elevation popups
PrivilegesRequired=lowest
OutputDir=.
OutputBaseFilename={#AppOutputBaseName}
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\{#AppExeName}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
; Copy all binaries, dlls, and data directory produced by 'flutter build windows --release'
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{app}\{#AppExeName}"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\{#AppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#AppExeName}"; Description: "{cm:LaunchProgram,{#AppName}}"; Flags: nowait postinstall skipifsilent

