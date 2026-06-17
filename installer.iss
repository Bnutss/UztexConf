[Setup]
AppName=UztexConf
AppVersion=1.0.0
AppVerName=UztexConf 1.0.0
AppPublisher=Uztex Group
AppPublisherURL=https://uztex-app.uz
AppSupportURL=https://bnutss.github.io/UztexConf/support.html
DefaultDirName={autopf}\UztexConf
DefaultGroupName=UztexConf
OutputBaseFilename=UztexConf_Setup
OutputDir=Output

; Иконка установщика и приложения
SetupIconFile=windows\runner\resources\app_icon.ico
UninstallDisplayIcon={app}\uztexconf.exe
UninstallDisplayName=UztexConf

; Внешний вид wizard
WizardStyle=modern
WizardSizePercent=110
WizardImageFile=assets\images\installer_wizard.bmp
WizardSmallImageFile=assets\images\installer_small.bmp

; Сжатие
Compression=lzma
SolidCompression=yes

; Поведение
ShowLanguageDialog=no
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
MinVersion=10.0

; Windows 64-bit
ArchitecturesInstallIn64BitMode=x64

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; \
  Description: "Создать ярлык на рабочем столе"; \
  GroupDescription: "Дополнительные задачи:"

[Files]
Source: "build\windows\x64\runner\Release\*"; \
  DestDir: "{app}"; \
  Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\UztexConf"; \
  Filename: "{app}\uztexconf.exe"; \
  IconFilename: "{app}\uztexconf.exe"

Name: "{autodesktop}\UztexConf"; \
  Filename: "{app}\uztexconf.exe"; \
  IconFilename: "{app}\uztexconf.exe"; \
  Tasks: desktopicon

[Run]
Filename: "{app}\uztexconf.exe"; \
  Description: "Запустить UztexConf"; \
  Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
