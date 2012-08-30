unit X_Helper_Classes;

interface

uses Classes;

type
  TProxySettings = class(TPersistent)
  private
    FUseProxy: Boolean;
    FProxyServer: String;
    FProxyPort: Integer;
    FProxyUsername: String;
    FProxyPassword: String;

    procedure SetUseProxy(Value: Boolean);
    procedure SetProxyServer(Value: String);
    procedure SetProxyPort(Value: Integer);
    procedure SetProxyUsername(Value: String);
    procedure SetProxyPassword(Value: String);
  published
    property UseProxy: Boolean read FUseProxy write SetUseProxy default False;
    property ProxyServer: String read FProxyServer write SetProxyServer;
    property ProxyPort: Integer read FProxyPort write SetProxyPort default 0;
    property ProxyUsername: String read FProxyUsername write SetProxyUsername;
    property ProxyPassword: String read FProxyPassword write SetProxyPassword;
  public
    constructor Create(AOwner : TComponent);
    destructor Destroy; override;
    procedure Assign(Source : TPersistent); override;
  end;

implementation

uses YTComponentV2;

constructor TProxySettings.Create(AOwner : TComponent);
begin
  inherited Create;
end;

destructor TProxySettings.Destroy;
begin
  inherited;
end;

procedure TProxySettings.Assign(Source: TPersistent);
begin
  if Source is TProxySettings then
     with TProxySettings(Source) do
          begin
//          Self.BackgroundStyle := BackgroundStyle;
//          Self.BackgroundColor := BackgroundColor;
          end
          else
          inherited;
end;

procedure TProxySettings.SetUseProxy(Value: Boolean);
begin
  FUseProxy:=Value;
  case Value of
  True: begin
          YTComponentV2.IdHTTP1.ProxyParams.ProxyServer:=FProxyServer;
          IdHTTP1.ProxyParams.ProxyPort:=FProxyPort;
          IdHTTP1.ProxyParams.ProxyUsername:=FProxyUsername;
          IdHTTP1.ProxyParams.ProxyPassword:=FProxyPassword;
        end;
  False: begin
           IdHTTP1.ProxyParams.ProxyServer:='';
           IdHTTP1.ProxyParams.ProxyPort:=0;
           IdHTTP1.ProxyParams.ProxyUsername:='';
           IdHTTP1.ProxyParams.ProxyPassword:='';
         end;
  end;
end;

procedure TProxySettings.SetProxyServer(Value: String);
begin
  FProxyServer:=Value;
  IdHTTP1.ProxyParams.ProxyServer:=FProxyServer;
end;

procedure TProxySettings.SetProxyPort(Value: Integer);
begin
  FProxyPort:=Value;
  IdHTTP1.ProxyParams.ProxyPort:=FProxyPort;
end;

procedure TProxySettings.SetProxyUsername(Value: String);
begin
  FProxyUsername:=Value;
  IdHTTP1.ProxyParams.ProxyUsername:=FProxyUsername;
end;

procedure TProxySettings.SetProxyPassword(Value: String);
begin
  FProxyPassword:=Value;
  IdHTTP1.ProxyParams.ProxyPassword:=FProxyPassword;
end;

end.
