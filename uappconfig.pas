unit uAppConfig;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uIniSettings;

{ TAppConfig }

type
  TAppConfig = class(TAppSettings)
  private
    function GetHTTPPort: integer;
    function GetXPIDir: string;
  protected
    procedure init; override;
    //procedure DefaultValues; override;
  public
    function IsEmpty: boolean; override;

    property HTTPPort: integer read GetHTTPPort;
    property XPIDir: string read GetXPIDir;
  end;

function AppConfig: TAppConfig;

implementation

const
  // Section HTTP
  sSectHTTP = 'HTTP';
  // Keys
  sKeyPort = 'Port';

  // Section XPI
  sSectXPI = 'XPI';
  // Keys
  sKeyXPIDir = 'Dir';


var
  LAppConfig: TAppConfig;

function AppConfig: TAppConfig;
begin
  result := LAppConfig;
end;

{ TAppConfig }

function TAppConfig.GetHTTPPort: integer;
begin
  result := StrToIntDef(
    GetIniValue(sSectHTTP, sKeyPort),
    0
  )
end;

function TAppConfig.GetXPIDir: string;
begin
  result := GetIniValue(sSectXPI, sKeyXPIDir)
end;

procedure TAppConfig.init;
begin
  // HTTP
  with RegisterIniSection(sSectHTTP) do
  begin
    RegisterIniKey(sKeyPort);
  end;
  // XPI
  with RegisterIniSection(sSectXPI) do
  begin
    RegisterIniKey(sKeyXPIDir);
  end;

  inherited Init;
end;

function TAppConfig.IsEmpty: boolean;
begin
  result :=
    (HTTPPort <= 0) or
    IsIniValueEmpty(XPIDir)
end;

initialization
  LAppConfig := TAppConfig.Create;

finalization
  LAppConfig.Free;

end.

