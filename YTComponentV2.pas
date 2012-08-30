unit YTComponentV2;

interface

uses
  System.SysUtils, System.Classes, FMX.Forms, IdHTTP, IdSSLOpenSSL, IdURI,
  Xml.adomxmldom, Xml.XMLDoc, Xml.XMLIntf, Xml.xmldom, FMX.Types,
  X_Helper_Classes, YT_Helper_Classes;

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
    FUseHTTPS: Boolean;
    FDebugMode: Boolean;

    FYT_DeveloperKey: String;
    FYT_ClientID: String;
    FYT_ClientSecret: String;
    FYT_Scope: String;
    FYT_AccessToken: String;
    FYT_ExpiresIn: String;
    FYT_RefreshToken: String;
    FYT_ResponseCode: String;

    FProxySettings: TProxySettings;

    URLScheme: String;

    procedure SetHTTPS(Value: Boolean);
    procedure SetDebugMode(Value: Boolean);

    function HTTPMethod(AURL: string; AMethod: TMethodType; AParams: TStrings; ABody: TStream; AMime: string = DefaultMime): string;
    function GETCommand(URL: string; Params: TStrings): RawBytestring;
    function POSTCommand(URL: string; Params: TStrings; Body: TStream; Mime: string): RawBytestring;
    function PUTCommand(URL: string; Body: TStream; Mime: string): RawBytestring;
    procedure DELETECommand(URL: string);
  protected
    { Protected-Deklarationen }
    procedure SetProxySettings(const Value: TProxySettings);
  public
    { Public-Deklarationen }
    LastError: String;
    LastErrorCode: Integer;

    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function AccessURL: String;
    function GetAccessToken: String;
    function RefreshToken: String;

    function Get_YTVideoCategories(LanguageID: String): TYT_VideoCategories;
    function Get_YTChannelCategories(LanguageID: String): TYT_ChannelCategories;
    function Get_UserProfile(User: String): TYT_UserInfo;

  published
    { Published-Deklarationen }
    property UseHTTPS: Boolean read FUseHTTPS write SetHTTPS default True;
    property DebugMode: Boolean read FDebugMode write SetDebugMode default False;
    property YT_DeveloperKey: String read FYT_DeveloperKey write FYT_DeveloperKey;
    property YT_ClientID: String read FYT_ClientID write FYT_ClientID;
    property YT_ClientSecret: String read FYT_ClientSecret write FYT_ClientSecret;
    property YT_Scope: String read FYT_Scope write FYT_Scope;
    property YT_ResponseCode: String read FYT_ResponseCode write FYT_ResponseCode;
    property YT_ExpiresIn: String read FYT_ExpiresIn write FYT_ExpiresIn;
    property YT_RefreshToken: String read FYT_RefreshToken write FYT_RefreshToken;
    property Proxy: TProxySettings read FProxySettings write SetProxySettings;

  end;

var IdHTTP1: TIdHTTP;
    IdSSLIOHandler1: TIdSSLIOHandlerSocketOpenSSL;
    XMLDocument1: TXMLDocument;

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
  XMLDocument1:=TXMLDocument.Create(Self);
  XMLDocument1.DOMVendor:=GetDOMVendor('ADOM XML v4');

  FProxySettings:=TProxySettings.Create(Self);
end;

destructor TYouTubeV2.Destroy;
begin
  XMLDocument1.Free;
  IdSSLIOHandler1.Destroy;
  IdHTTP1.Destroy;
  inherited;
end;

procedure TYouTubeV2.SetProxySettings(const Value: TProxySettings);
begin
  FProxySettings.Assign(Value);
end;

procedure TYouTubeV2.SetHTTPS(Value: Boolean);
begin
  FUseHTTPS:=Value;
  case Value of
  True: URLScheme:='https';
  False: URLScheme:='http';
  end;
end;

procedure TYouTubeV2.SetDebugMode(Value: Boolean);
begin
  FDebugMode:=Value;
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

//--> YouTube functions

function DebugSave(XML: TXMLDocument; Name: String): String;
begin
  ForceDirectories(ExtractFilePath(ParamStr(0))+'Debug\');
  XML.SaveToFile((ExtractFilePath(ParamStr(0))+'\Debug\'+Name+'.xml'));
end;

function TYouTubeV2.Get_YTVideoCategories(LanguageID: String): TYT_VideoCategories;
var MS: TMemoryStream;
    I: Integer;
    Node: IXMLNode;
begin
  try
    MS:=TMemoryStream.Create;
    IdHTTP1.Get(URLScheme+'://gdata.youtube.com/schemas/2007/categories.cat?hl='+LanguageID, MS);

    XMLDocument1.Active:=False;
    XMLDocument1.LoadFromStream(MS);
    XMLDocument1.Active:=True;
    if FDebugMode=True then DebugSave(XMLDocument1, '_videocategories_'+LanguageID);
    SetLength(Result, 0);
    for I := 0 to XMLDocument1.DocumentElement.ChildNodes.Count-1 do
        begin
          Node:=XMLDocument1.DocumentElement.ChildNodes.Get(I);
          SetLength(Result, Length(Result)+1);
          Result[Length(Result)-1].Category_LanguageID:=Node.AttributeNodes.FindNode('lang', XMLDocument1.DocumentElement.FindNamespaceURI('xml')).Text;
          Result[Length(Result)-1].Category_Label:=StringReplace(Node.Attributes['label'], '&amp;', '&', [rfReplaceAll]);
          Result[Length(Result)-1].Category_Term:=Node.Attributes['term'];
          if Node.ChildNodes.FindNode('assignable', XMLDocument1.DocumentElement.FindNamespaceURI('yt'))<>nil then
             Result[Length(Result)-1].Assignable:=True
             else
             Result[Length(Result)-1].Assignable:=False;
          if Node.ChildNodes.FindNode('browsable', XMLDocument1.DocumentElement.FindNamespaceURI('yt'))<>nil then
             Result[Length(Result)-1].Category_Regions:=Node.ChildNodes.FindNode('browsable', XMLDocument1.DocumentElement.FindNamespaceURI('yt')).Attributes['regions'];
        end;
    XMLDocument1.Active:=False;
    FreeAndNil(MS);
  except
    on E: Exception do
       begin
         LastError:=E.Message;
         LastErrorCode:=ExitCode;
         Result:=nil;
         XMLDocument1.Active:=False;
         FreeAndNil(MS);
       end;
  end;
end;

function TYouTubeV2.Get_YTChannelCategories(LanguageID: String): TYT_ChannelCategories;
var MS: TMemoryStream;
    I: Integer;
    Node: IXMLNode;
begin
  try
    MS:=TMemoryStream.Create;
    IdHTTP1.Get(URLScheme+'://gdata.youtube.com/schemas/2007/channeltypes.cat?hl='+LanguageID, MS);

    XMLDocument1.Active:=False;
    XMLDocument1.LoadFromStream(MS);
    XMLDocument1.Active:=True;
    if FDebugMode=True then DebugSave(XMLDocument1, '_channelcategories_'+LanguageID);
    SetLength(Result, 0);
    for I := 0 to XMLDocument1.DocumentElement.ChildNodes.Count-1 do
        begin
          Node:=XMLDocument1.DocumentElement.ChildNodes.Get(I);
          SetLength(Result, Length(Result)+1);
          Application.ProcessMessages;
          Result[Length(Result)-1].CategoryLabel:=Node.Attributes['label'];
          Result[Length(Result)-1].CategoryTerm:=Node.Attributes['term'];
        end;
  except
    on E: Exception do
       begin
         LastError:=E.Message;
         LastErrorCode:=ExitCode;
         Result:=nil;
         XMLDocument1.Active:=False;
         FreeAndNil(MS);
       end;
  end;
end;

function TYouTubeV2.Get_UserProfile(User: String): TYT_UserInfo;
var ResponseContent: TStringStream;
    I: Integer;
    MainNode: IXMLNode;
    ImageStream: TMemoryStream;
begin
  try
    ResponseContent:=TStringStream.Create;
    IdHTTP1.Request.Clear;
    IdHTTP1.Request.CustomHeaders.Clear;
    IdHTTP1.Request.Host:='gdata.youtube.com';
    IdHTTP1.Request.CustomHeaders.AddValue('Authorization','Bearer '+FYT_AccessToken);
    IdHTTP1.Request.CustomHeaders.AddValue('GData-Version','2');
    IdHTTP1.Request.CustomHeaders.AddValue('X-GData-Key','key='+FYT_DeveloperKey);
    IdHTTP1.Get(URLScheme+'://gdata.youtube.com/feeds/api/users/'+User+'?v=2', ResponseContent);

    XMLDocument1.Active:=False;
    XMLDocument1.LoadFromStream(ResponseContent, TXMLEncodingType.xetUTF_8);
    XMLDocument1.Active:=True;
    if FDebugMode=True then DebugSave(XMLDocument1, '_userprofile');

    MainNode:=XMLDocument1.DocumentElement;

    for I := 0 to MainNode.ChildNodes.Count-1 do
        begin
          if MainNode.ChildNodes[I].NodeName='published' then
             Result.Channel_Created_Date:=
               EncodeDate(StrToInt(Copy(MainNode.ChildNodes[I].Text, 0, 4)), StrToInt(Copy(MainNode.ChildNodes[I].Text, 6, 2)), StrToInt(Copy(MainNode.ChildNodes[I].Text, 9, 2)))+
               EncodeTime(StrToInt(Copy(MainNode.ChildNodes[I].Text, 12, 2)), StrToInt(Copy(MainNode.ChildNodes[I].Text, 15, 2)), StrToInt(Copy(MainNode.ChildNodes[I].Text, 18, 2)), 0);

          if MainNode.ChildNodes[I].NodeName='updated' then
             Result.Channel_Modified_Date:=
               EncodeDate(StrToInt(Copy(MainNode.ChildNodes[I].Text, 0, 4)), StrToInt(Copy(MainNode.ChildNodes[I].Text, 6, 2)), StrToInt(Copy(MainNode.ChildNodes[I].Text, 9, 2)))+
               EncodeTime(StrToInt(Copy(MainNode.ChildNodes[I].Text, 12, 2)), StrToInt(Copy(MainNode.ChildNodes[I].Text, 15, 2)), StrToInt(Copy(MainNode.ChildNodes[I].Text, 18, 2)), 0);

          if MainNode.ChildNodes[I].NodeName='category' then
             begin
               if MainNode.ChildNodes[I].Attributes['scheme']='http://gdata.youtube.com/schemas/2007/channeltypes.cat' then
                  Result.Channel_Category:=MainNode.ChildNodes[I].Attributes['term'];
             end;

          if MainNode.ChildNodes[I].NodeName='title' then
             Result.Channel_Title:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='summary' then
             Result.Channel_Description:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='link' then
             begin
               if MainNode.ChildNodes[I].Attributes['rel']='alternate' then
                  Result.Channel_AlternativeChannelLink:=MainNode.ChildNodes[I].Attributes['href']
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#insight.views' then
                  Result.Channel_InsightLink:=MainNode.ChildNodes[I].Attributes['href']
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='self' then
                  Result.Channel_InfoLink:=MainNode.ChildNodes[I].Attributes['href']
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='edit' then
                  Result.Channel_EditLink:=MainNode.ChildNodes[I].Attributes['href']
             end;

          if MainNode.ChildNodes[I].NodeName='author' then
             begin
               Result.Channel_Author_Name:=MainNode.ChildNodes[I].ChildNodes.FindNode('name').Text;
               Result.Channel_Author_UserID:=MainNode.ChildNodes[I].ChildNodes.FindNode('userId', XMLDocument1.DocumentElement.FindNamespaceURI('yt')).Text;
             end;

          if MainNode.ChildNodes[I].NodeName='yt:age' then
             Result.User_Age:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:company' then
             Result.User_Company:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='gd:feedLink' then
             begin
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.watchhistory' then
                  Result.Links_WatchHistory:=MainNode.ChildNodes[I].Attributes['href']
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.liveevent' then
                  begin
                    Result.Links_LiveEvents:=MainNode.ChildNodes[I].Attributes['href'];
                    Result.Links_LiveEvents_Count:=MainNode.ChildNodes[I].Attributes['countHint'];
                  end
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.favorites' then
                  begin
                    Result.Links_Favorites:=MainNode.ChildNodes[I].Attributes['href'];
                    Result.Links_Favorites_Count:=MainNode.ChildNodes[I].Attributes['countHint'];
                    Result.Statistics_Favorites:=StrToInt(MainNode.ChildNodes[I].Attributes['countHint']);
                  end
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.contacts' then
                  begin
                    Result.Links_Contacts:=MainNode.ChildNodes[I].Attributes['href'];
                    Result.Links_Contacts_Count:=MainNode.ChildNodes[I].Attributes['countHint'];
                    Result.Statistics_Contacts:=StrToInt(MainNode.ChildNodes[I].Attributes['countHint']);
                  end
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.inbox' then
                  begin
                    Result.Links_Inbox:=MainNode.ChildNodes[I].Attributes['href'];
                    Result.Links_Inbox_Count:=MainNode.ChildNodes[I].Attributes['countHint'];
                    Result.Statistics_Inbox:=StrToInt(MainNode.ChildNodes[I].Attributes['countHint']);
                  end
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.playlists' then
                  Result.Links_Playlists:=MainNode.ChildNodes[I].Attributes['href']
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.watchlater' then
                  begin
                    Result.Links_WatchLater:=MainNode.ChildNodes[I].Attributes['href'];
                    Result.Links_WatchLater_Count:=MainNode.ChildNodes[I].Attributes['countHint'];
                    Result.Statistics_WatchLater:=StrToInt(MainNode.ChildNodes[I].Attributes['countHint']);
                  end
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.subscriptions' then
                  begin
                    Result.Links_Subscriptions:=MainNode.ChildNodes[I].Attributes['href'];
                    Result.Links_Subscriptions_Count:=MainNode.ChildNodes[I].Attributes['countHint'];
                    Result.Statistics_Subscriptions:=StrToInt(MainNode.ChildNodes[I].Attributes['countHint']);
                  end
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.uploads' then
                  begin
                    Result.Links_Uploads:=MainNode.ChildNodes[I].Attributes['href'];
                    Result.Links_Uploads_Count:=MainNode.ChildNodes[I].Attributes['countHint'];
                    Result.Statistics_Uploads:=StrToInt(MainNode.ChildNodes[I].Attributes['countHint']);
                  end
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.newsubscriptionvideos' then
                  Result.Links_NewSubscriptionVideos:=MainNode.ChildNodes[I].Attributes['href']
                  else
               if MainNode.ChildNodes[I].Attributes['rel']='http://gdata.youtube.com/schemas/2007#user.recentactivity' then
                  Result.Links_RecentActivity:=MainNode.ChildNodes[I].Attributes['href']
             end;

          if MainNode.ChildNodes[I].NodeName='yt:firstName' then
             Result.User_FirstName:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:lastName' then
             Result.User_LastName:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:aboutMe' then
             Result.User_About:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:age' then
             Result.User_Age:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:books' then
             Result.User_Books:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:gender' then
             Result.User_Gender:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:company' then
             Result.User_Company:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:hobbies' then
             Result.User_Hobbies:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:hometown' then
             Result.User_Hometown:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:location' then
             Result.User_Location:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:maxUploadDuration' then
             Result.Channel_MaxUploadDuration:=StrToInt(MainNode.ChildNodes[I].Attributes['seconds']);

          if MainNode.ChildNodes[I].NodeName='yt:movies' then
             Result.User_Movies:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:music' then
             Result.User_Music:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:relationship' then
             Result.User_Relationship:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:occupation' then
             Result.User_Occupation:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:school' then
             Result.User_School:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:statistics' then
             begin
               Result.Statistics_VideoViews:=StrToInt(MainNode.ChildNodes[I].Attributes['totalUploadViews']);
               Result.Statistics_ChannelViews:=StrToInt(MainNode.ChildNodes[I].Attributes['viewCount']);
               Result.Statistics_WatchedVideos:=StrToInt(MainNode.ChildNodes[I].Attributes['videoWatchCount']);
               Result.Statistics_Subscribers:=StrToInt(MainNode.ChildNodes[I].Attributes['subscriberCount']);
             end;

          if MainNode.ChildNodes[I].NodeName='media:thumbnail' then
             begin
               Result.Channel_AvatarLink:=MainNode.ChildNodes[I].Attributes['url'];
               ImageStream:=TMemoryStream.Create;
               IdHTTP1.Get(Result.Channel_AvatarLink, ImageStream);
//               Result.Channel_AvatarBitmap.LoadFromStream(ImageStream);
               Result.Channel_AvatarBitmap:=FMX.Types.TBitmap.CreateFromStream(ImageStream);
               ImageStream.Free;
             end;

          if MainNode.ChildNodes[I].NodeName='yt:userId' then
             Result.Channel_YTUserID:=MainNode.ChildNodes[I].Text;

          if MainNode.ChildNodes[I].NodeName='yt:username' then
             Result.Channel_YTUsername:=MainNode.ChildNodes[I].Attributes['display'];
        end;
    XMLDocument1.Active:=False;
    ResponseContent.Free;
  except
    on E: Exception do
       begin
         LastError:=E.Message;
         LastErrorCode:=ExitCode;
         XMLDocument1.Active:=False;
         ResponseContent.Free;
       end;
  end;
end;

//<-- YouTube functions


end.
