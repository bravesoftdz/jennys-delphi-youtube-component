unit YTComponentV2;

interface

uses
  System.SysUtils, System.Classes, FMX.Forms, IdHTTP, IdSSLOpenSSL, IdURI;

type TMethodType = (tmGET, tmPOST, tmPUT, tmDELETE);

const
  redirect_uri='urn:ietf:wg:oauth:2.0:oob';
  oauth_url = 'https://accounts.google.com/o/oauth2/auth?client_id=%s&redirect_uri=%s&scope=%s&response_type=code';
  tokenurl='https://accounts.google.com/o/oauth2/token';
  tokenparams = 'client_id=%s&client_secret=%s&code=%s&redirect_uri=%s&grant_type=authorization_code';
  crefreshtoken = 'client_id=%s&client_secret=%s&refresh_token=%s&grant_type=refresh_token';

  AuthHeader = 'Authorization: OAuth %s';
  StripChars: set of char = ['"', ':', ','];
  DefaultMime = 'application/json; charset=UTF-8';

type
  TYouTubeV2 = class(TComponent)
  private
    { Private-Deklarationen }
    FUseProxy: Boolean;
    FProxyServer: String;
    FProxyPort: Integer;
    FProxyUsername: String;
    FProxyPassword: String;
    FUseHTTPS: Boolean;

    FYT_DeveloperKey: String;
    FYT_ClientID: String;
    FYT_ClientSecret: String;
    FYT_Scope: String;
    FYT_AccessToken: String;
    FYT_ExpiresIn: String;
    FYT_RefreshToken: String;
    FYT_ResponseCode: String;

    procedure SetUseProxy(Value: Boolean);
    procedure SetProxyServer(Value: String);
    procedure SetProxyPort(Value: Integer);
    procedure SetProxyUsername(Value: String);
    procedure SetProxyPassword(Value: String);
    procedure SetHTTPS(Value: Boolean);

    function HTTPMethod(AURL: string; AMethod: TMethodType;
                        AParams: TStrings; ABody: TStream; AMime: string = DefaultMime): string;
    function GETCommand(URL: string; Params: TStrings): RawBytestring;
    procedure DELETECommand(URL: string);
    function POSTCommand(URL: string; Params: TStrings; Body: TStream;
                         Mime: string): RawBytestring;
    function PUTCommand(URL: string; Body: TStream; Mime: string): RawBytestring;
  protected
    { Protected-Deklarationen }
//    FOAuthv2: TOAuth;
  public
    { Public-Deklarationen }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function Activate(out NewAccessToken: String): Boolean;
    function AccessURL: String;
    function GetAccessToken: String;
    function RefreshToken: String;


  published
    { Published-Deklarationen }
    property UseProxy: Boolean read FUseProxy write SetUseProxy default False;
    property ProxyServer: String read FProxyServer write SetProxyServer;
    property ProxyPort: Integer read FProxyPort write SetProxyPort default 0;
    property ProxyUsername: String read FProxyUsername write SetProxyUsername;
    property ProxyPassword: String read FProxyPassword write SetProxyPassword;
    property UseHTTPS: Boolean read FUseHTTPS write SetHTTPS default True;
    property YT_DeveloperKey: String read FYT_DeveloperKey write FYT_DeveloperKey;
    property YT_ClientID: String read FYT_ClientID write FYT_ClientID;
    property YT_ClientSecret: String read FYT_ClientSecret write FYT_ClientSecret;
    property YT_Scope: String read FYT_Scope write FYT_Scope;
    property YT_ResponseCode: String read FYT_ResponseCode write FYT_ResponseCode;
    property YT_ExpiresIn: String read FYT_ExpiresIn write FYT_ExpiresIn;
    property YT_RefreshToken: String read FYT_RefreshToken write FYT_RefreshToken;

  end;

var IdHTTP1: TIdHTTP;
    IdSSLIOHandler1: TIdSSLIOHandlerSocketOpenSSL;

resourcestring
  rsRequestError = 'Request failed: %d - %s';
  rsUnknownError = 'unknown error';
//    OAuth: TOAuth;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('Jennys stuff', [TYouTubeV2]);
end;

constructor TYouTubeV2.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  IdHTTP1 := TIdHTTP.Create(nil);
  IdSSLIOHandler1 := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  IdHTTP1.IOHandler := IdSSLIOHandler1;
  IdHTTP1.ConnectTimeout := 15000;
  IdHTTP1.ReadTimeout := 0;
end;

destructor TYouTubeV2.Destroy;
begin
  IdSSLIOHandler1.Destroy;
  IdHTTP1.Destroy;
  inherited;
end;

function TYouTubeV2.Activate(out NewAccessToken: String): Boolean;
begin

//  NewAccessToken:=GetAccessToken;
//  FOAuthv2.ClientID:=FYT_ClientID;
//  FOAuthv2.ClientSecret:=FYT_ClientSecret;
//  FOAuthv2.Scope:=FYT_Scope;


//  if FUseBuiltInFormular=True then
//     begin
//
//     end
//     else
//     begin
//
//     end;
////  FOAuthv2.Access_token:=AccessToken;
//
//  FOAuthv2.Refresh_token:=RefreshToken;
////  FYT_DeveloperKey:=YT_DeveloperKey;
//  NewAccessToken:=FOAuthv2.RefreshToken;
//  if NewAccessToken<>'' then Result:=True else Result:=False;
end;

procedure TYouTubeV2.SetUseProxy(Value: Boolean);
begin
  FUseProxy:=Value;
  case Value of
  True: begin
          IdHTTP1.ProxyParams.ProxyServer:=FProxyServer;
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

procedure TYouTubeV2.SetProxyServer(Value: String);
begin
  FProxyServer:=Value;
  IdHTTP1.ProxyParams.ProxyServer:=FProxyServer;
end;

procedure TYouTubeV2.SetProxyPort(Value: Integer);
begin
  FProxyPort:=Value;
  IdHTTP1.ProxyParams.ProxyPort:=FProxyPort;
end;

procedure TYouTubeV2.SetProxyUsername(Value: String);
begin
  FProxyUsername:=Value;
  IdHTTP1.ProxyParams.ProxyUsername:=FProxyUsername;
end;

procedure TYouTubeV2.SetProxyPassword(Value: String);
begin
  FProxyPassword:=Value;
  IdHTTP1.ProxyParams.ProxyPassword:=FProxyPassword;
end;

procedure TYouTubeV2.SetHTTPS(Value: Boolean);
begin
  FUseHTTPS:=Value;
end;

//--> modified version from http://www.webdelphi.ru ----------------------------

function ParamValue(ParamName, JSONString: string): string;
var
  i, j: integer;
begin
  i := pos(ParamName, JSONString);
  if i > 0 then
  begin
    for j := i + Length(ParamName) to Length(JSONString) - 1 do
      if not(JSONString[j] in StripChars) then
        Result := Result + JSONString[j]
      else if JSONString[j] = ',' then
        break;
  end
  else
    Result := '';
end;

function PrepareParams(Params: TStrings): string;
var
  S: string;
begin
  if Assigned(Params) then
    if Params.Count > 0 then
    begin
      for S in Params do
        Result := Result + TIdURI.URLEncode(S) + '&';
      Delete(Result, Length(Result), 1);
      Result := '?' + Result;
      Exit;
    end;
  Result := '';
end;

function TYouTubeV2.HTTPMethod(AURL: string; AMethod: TMethodType;
  AParams: TStrings; ABody: TStream; AMime: string = DefaultMime): string;
var Response: TStringStream;
    ParamString: string;
begin
  if Assigned(AParams)and(AParams.Count>0) then
    ParamString:=PrepareParams(AParams);
  try
    Response:=TStringStream.Create;
    IdHTTP1.Request.CustomHeaders.Add(Format(AuthHeader, [FYT_AccessToken]));
    try
      case AMethod of
        tmGET: begin
                 IdHTTP1.Get(AURL + ParamString, Response);
               end;
        tmPOST:begin
                 IdHTTP1.Request.ContentType:=AMime;
                 IdHTTP1.Post(AURL+ParamString,ABody,Response);
               end;
        tmPUT: begin
                 IdHTTP1.Request.ContentType:=AMime;
                 IdHTTP1.Put(AURL,ABody,Response);
               end;
        tmDELETE: begin
                   IdHTTP1.Delete(AURL);
                 end;
      end;
      if AMethod<>tmDELETE then
        Result:=Response.DataString;
    except
      on E: EIdHTTPProtocolException do
        raise E.CreateFmt(rsRequestError, [E.ErrorCode, E.ErrorMessage])
      else
        raise Exception.Create(rsUnknownError);
    end;
  finally
    Response.Free
  end;
end;

function TYouTubeV2.GETCommand(URL: string; Params: TStrings): RawBytestring;
begin
  Result:=HTTPMethod(URL,tmGET,Params,nil);
end;

procedure TYouTubeV2.DELETECommand(URL: string);
begin
  HTTPMethod(URL,tmDELETE,nil,nil);
end;

function TYouTubeV2.POSTCommand(URL: string; Params: TStrings; Body: TStream;
  Mime: string): RawBytestring;
begin
   Result:=HTTPMethod(URL, tmPOST,Params,Body,Mime);
end;

function TYouTubeV2.PUTCommand(URL: string; Body: TStream; Mime: string)
  : RawBytestring;
begin
  Result:=HTTPMethod(URL, tmPUT,nil,Body,Mime)
end;


function TYouTubeV2.AccessURL: String;
begin
  Result := Format(oauth_url, [FYT_ClientID, redirect_uri, FYT_Scope]);
end;

function TYouTubeV2.GetAccessToken: String;
var
  Params: TStringStream;
  Response: string;
begin
  Params := TStringStream.Create(Format(tokenparams, [FYT_ClientID, FYT_ClientSecret,
    FYT_ResponseCode, redirect_uri]));
  try
    Response := POSTCommand(tokenurl, nil, Params,
      'application/x-www-form-urlencoded');
    FYT_AccessToken := ParamValue('access_token', Response);
    FYT_ExpiresIn := ParamValue('expires_in', Response);
    FYT_RefreshToken := ParamValue('refresh_token', Response);
    Result := FYT_AccessToken;
  finally
    Params.Free;
  end;
end;

function TYouTubeV2.RefreshToken: String;
var
  Params: TStringStream;
  Response: string;
begin
  Params := TStringStream.Create(Format(crefreshtoken, [FYT_ClientID, FYT_ClientSecret,
    FYT_RefreshToken]));
  try
    Response := POSTCommand(tokenurl, nil, Params,
      'application/x-www-form-urlencoded');
    FYT_AccessToken := ParamValue('access_token', Response);
    FYT_ExpiresIn := ParamValue('expires_in', Response);
    Result := FYT_AccessToken;
  finally
    Params.Free;
  end;
end;

//<-- modified version from http://www.webdelphi.ru ----------------------------

end.
