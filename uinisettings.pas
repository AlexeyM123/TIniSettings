unit uIniSettings;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, contnrs,
  IniFiles;

const
  sNoValue = 'ValueNotAssigned';

type

  { TSettingsClass }

  TSettingsClass = class
  private
    FIniKeys: TstringList;
    FIniSection: string;
    FModified: boolean;
    //
    function CheckKeyName(const KeyName: string): Boolean;
  protected
    property IniKeys: TstringList read FIniKeys;
  public
    property IniSection: string read FIniSection;
    //
    procedure RegisterIniKey(const KeyName: string; const DefaultValue: string = sNoValue);
    function GetIniValue(const KeyName: string): string;
    procedure SetIniValue(const KeyName, Value: string);

    property Modified: boolean read FModified;
    //
    constructor Create(const aIniSection: string);
    destructor Destroy; override;
  end;

  { TSettingsHolder }

  TSettingsHolder = class
  private
    FSettingsList: TObjectList;
    FSourcePath: string;
    //
    function IniSectionExists(const aIniSection: string): Boolean;
  protected
    function IsModified: boolean;
  public
    property SettingsList: TObjectList read FSettingsList;
    property SourcePath: string read FSourcePath write FSourcePath;
    //
    function RegisterIniSection(const aIniSection: string): TSettingsClass;
    function GetSettingsByIniSection(const aIniSection: string): TSettingsClass;
    //
    function CheckExists: boolean; virtual; abstract;
    function Load: Boolean; virtual;
    function Update: Boolean; virtual; abstract;
    //
    constructor Create;
    destructor Destroy; override;
  end;

  { TIniSettingsReader }

  TIniSettingsReader = class(TSettingsHolder)
  private
    FIniFile: TMemIniFile ;
    function GetIniFile: TMemIniFile ;
  public
    property IniFile: TMemIniFile read GetIniFile;
    //
    function CheckExists: boolean; override;
    function Load: Boolean; override;
    function Update: Boolean; override;
    procedure BackupFile;
    //
    constructor Create;
    destructor Destroy; override;
  end;

  { TAppSettings }

  TAppSettings = class
  private
    FIniSettingsReader: TIniSettingsReader;
    function GetSettingsByIniSection(const aIniSection: string): TSettingsClass;
  protected
    procedure init; virtual;
    procedure DefaultValues; virtual;
  public
    constructor Create;
    destructor Destroy; override;

    function RegisterIniSection(const aIniSection: string): TSettingsClass;

    function GetIniValue(const aIniSection, KeyName: string): string;
    procedure SetIniValue(const aIniSection, KeyName, Value: string);

    function CheckExists: Boolean;
    function IsEmpty: boolean; virtual; abstract;
    procedure Update;

    class function IsIniValueEmpty(const Value: string): boolean;
  end;

implementation

const
  sIniFileExt = '.conf';
  sBackupIniFileExt = '.bconf';

{ TAppSettings }

procedure TAppSettings.init;
begin
  FIniSettingsReader.Load;
end;

procedure TAppSettings.DefaultValues;
begin
  //
end;

constructor TAppSettings.Create;
begin
  inherited Create;
  FIniSettingsReader := TIniSettingsReader.Create;
  init;
  DefaultValues;
end;

destructor TAppSettings.Destroy;
begin
  FIniSettingsReader.Free;
  inherited Destroy;
end;

function TAppSettings.RegisterIniSection(const aIniSection: string): TSettingsClass;
begin
  result := FIniSettingsReader.RegisterIniSection(aIniSection)
end;

function TAppSettings.GetSettingsByIniSection(const aIniSection: string): TSettingsClass;
begin
  result := FIniSettingsReader.GetSettingsByIniSection(aIniSection)
end;

function TAppSettings.GetIniValue(const aIniSection, KeyName: string): string;
begin
  result := GetSettingsByIniSection(aIniSection).GetIniValue(KeyName);
end;

procedure TAppSettings.SetIniValue(const aIniSection, KeyName, Value: string);
begin
  GetSettingsByIniSection(aIniSection).SetIniValue(KeyName, Value);
end;

function TAppSettings.CheckExists: Boolean;
begin
  result := FIniSettingsReader.CheckExists;
end;

procedure TAppSettings.Update;
begin
  FIniSettingsReader.Update;
end;

class function TAppSettings.IsIniValueEmpty(const Value: string): boolean;
begin
  result := Value = sNoValue
end;

{ TIniSettingsReader }

function TIniSettingsReader.GetIniFile: TMemIniFile;
begin
  if not Assigned(FIniFile) then
    try
      finifile := TMemIniFile.Create(SourcePath);
    except
      Result := nil;
      raise Exception.Create('error in TIniSettingsReader.GetIniFile!');
    end;
  result := FIniFile;
end;

function TIniSettingsReader.CheckExists: boolean;
begin
  Result := FileExists(SourcePath);
end;

function TIniSettingsReader.Load: Boolean;
var
  i, j: Integer;
  IniSection,
  KeyName,
  KeyValue,
  DefaultValue: string;
  lsc: TSettingsClass;
begin
  Result := inherited Load;
  if not result then
    Exit;
  try
    with IniFile do
    begin
      for i := 0 to SettingsList.Count-1 do
      begin
        lsc := (SettingsList.Items[i] as TSettingsClass);
        IniSection := lsc.IniSection;
        for j := 0 to lsc.IniKeys.Count-1 do
        begin
          KeyName := lsc.IniKeys.Names[j];
          DefaultValue := lsc.IniKeys.ValueFromIndex[j];
          KeyValue := ReadString(IniSection,KeyName,DefaultValue);
          if Trim(KeyValue) = sNoValue then
            KeyValue := DefaultValue;
          lsc.IniKeys.ValueFromIndex[j] := KeyValue;
        end;
      end;
      Result := True;
    end;
  except
    Result := False;
    raise Exception.Create('Error on TIniSettingsReader.Load!');
  end;
end;

function TIniSettingsReader.Update: Boolean;
var
  i, j: Integer;
  lsc: TSettingsClass;
  IniSection,
  KeyName,
  ActualValue: string;
begin
  BackupFile;
  try
    with IniFile do
    begin
      for I := 0 to SettingsList.Count-1 do
      begin
        lsc := SettingsList.Items[i] as TSettingsClass;
        IniSection := lsc.IniSection;
        for j := 0 to lsc.IniKeys.Count-1 do
        begin
          KeyName := lsc.IniKeys.Names[j];
          ActualValue := lsc.IniKeys.ValueFromIndex[j];
          WriteString(IniSection,KeyName,ActualValue);
        end;
      end;
      UpdateFile;
    end;
    Result := True;
  except
    result := False;
    raise Exception.Create('Error on TIniSettingsReader.Update!');
  end;
end;

procedure TIniSettingsReader.BackupFile;
var
  backup_fn: TFileName;
begin
  if not CheckExists then Exit;
  backup_fn := ChangeFileExt(ParamStr(0), sBackupIniFileExt);
  try
    if FileExists(backup_fn) then
      DeleteFile(backup_fn);
    IniFile.Rename(backup_fn, False);
    IniFile.UpdateFile;
    DeleteFile(SourcePath);
    IniFile.Rename(SourcePath, false);
    IniFile.UpdateFile;
  except
    raise exception.Create('Error on TIniSettingsReader.Backup!');
  end;
end;

constructor TIniSettingsReader.Create;
begin
  inherited Create;
  SourcePath := ChangeFileExt(ParamStr(0), sIniFileExt);
end;

destructor TIniSettingsReader.Destroy;
begin
  if IsModified then Update;

  FIniFile.Free;

  inherited Destroy;
end;

{ TSettingsHolder }

function TSettingsHolder.IniSectionExists(const aIniSection: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to FSettingsList.Count-1 do
    if SameText(aIniSection, (SettingsList.Items[i] as TSettingsClass).IniSection) then
    begin
      Result := True;
      Break;
    end;
end;

function TSettingsHolder.RegisterIniSection(const aIniSection: string): TSettingsClass;
begin
  if not IniSectionExists(aIniSection) then
  begin
    result := TSettingsClass.Create(aIniSection);
    SettingsList.Add(result);
  end
  else
    raise Exception.Create(aIniSection +'  is aready registered!');
end;

function TSettingsHolder.GetSettingsByIniSection(const aIniSection: string): TSettingsClass;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to SettingsList.Count - 1 do
    if SameText(aIniSection, (FSettingsList.Items[i] as TSettingsClass).IniSection) then
    begin
      result := SettingsList.Items[i] as TSettingsClass;
      Break;
    end;
  if result = nil then
    raise Exception.Create('Section '+aIniSection+' is not registered');
end;

function TSettingsHolder.Load: Boolean;
begin
  Result := CheckExists;
end;

function TSettingsHolder.IsModified: boolean;
var
  i: integer;
begin
  result := false;
  for i := 0 to FSettingsList.Count-1 do
    if (FSettingsList.Items[i] as TSettingsClass).Modified then
    begin
      result := true;
      break;
    end;
end;

constructor TSettingsHolder.Create;
begin
  inherited Create;
  FSettingsList := TObjectList.Create;
  FSettingsList.OwnsObjects := True;
end;

destructor TSettingsHolder.Destroy;
begin
  FSettingsList.Free;
  inherited Destroy;
end;

{ TSettingsClass }

function TSettingsClass.CheckKeyName(const KeyName: string): Boolean;
begin
  Result := (IniKeys.IndexOfName(KeyName)>=0);
  if not Result then
    raise Exception.Create('['+Self.IniSection+']'+KeyName+' not registered!' + ' -GetIniValue');
end;

procedure TSettingsClass.RegisterIniKey(const KeyName: string;
  const DefaultValue: string);
begin
  IniKeys.Add(KeyName + '=' + DefaultValue);
end;

function TSettingsClass.GetIniValue(const KeyName: string): string;
begin
  result := sNoValue;
  if CheckKeyName(KeyName) then
    result := Trim(IniKeys.Values[KeyName])
  else
    raise Exception.Create('No such Keyname '+KeyName);
end;

procedure TSettingsClass.SetIniValue(const KeyName, Value: string);
var
  LOldValue: string;
begin
  if CheckKeyName(KeyName) then
  begin
    LOldValue := GetIniValue(KeyName);
    if LOldValue <> Value then
    begin
      IniKeys.Values[KeyName] := Value;
      FModified := True;
    end;
  end;
end;

constructor TSettingsClass.Create(const aIniSection: string);
begin
  inherited Create;

  FModified := False;
  FIniSection := aIniSection;
  FIniKeys := TStringList.Create;
  FIniKeys.CaseSensitive := False;
end;

destructor TSettingsClass.Destroy;
begin
  FIniKeys.Free;

  inherited Destroy;
end;

end.

