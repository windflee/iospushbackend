unit APNSAction3;

interface

uses
  System.SysUtils, System.Variants, Curl.Lib, IniFiles, IOUtils, StrUtils;



function APNSPushMsg(deviceid: string; title: string; badge: Integer; extinfo: string =''; sound: string = '' ): Boolean;

implementation

const
  DevelopmentURL = 'https://api.development.push.apple.com/3/device/';
  ProductionURL = 'https://api.push.apple.com/3/device/';

var
  certfile: string;  //证书路径
  bundleId: string;  //ios app包名

function APNSPushMsg(deviceid: string; title: string; badge: Integer; extinfo: string; sound: string): Boolean;
var
  curl : HCurl;
  res : TCurlCode;
  code : longint;
  headers, h2 : PCurlSList;
  msg, url, topic, cafile: ansistring;
  s, err: string;
begin

  Result := False;
  if certfile = '' then
  begin
    with TIniFile.Create(ChangeFileExt(ParamStr(0), '.ini')) do
    begin
      try
        certfile := ReadString('APNS','certfile', '');
        bundleId := ReadString('APNS','bundle', '');
      finally
        Free;
      end;
    end;
  end;

  if not FileExists(certfile) then Exit;
  if bundleId = '' then Exit;


  curl := curl_easy_init;
  if curl <> nil then
  begin
    {$IFDEF DEBUG}
      url := DevelopmentURL + deviceid;
    {$ELSE}
      url := ProductionURL + deviceid;
    {$ENDIF}

    curl_easy_setopt(curl, CURLOPT_URL, url);
    curl_easy_setopt(curl, CURLOPT_FOLLOWLOCATION, true);
    curl_easy_setopt(curl, CURLOPT_HTTP_VERSION, 20);
    curl_easy_setopt(curl, CURLOPT_POST, true);
    curl_easy_setopt(curl, CURLOPT_SSL_VERIFYPEER, false);
    curl_easy_setopt(curl, CURLOPT_PORT, 443);
    curl_easy_setopt(curl, CURLOPT_HEADER, 1);
    curl_easy_setopt(curl, CURLOPT_TIMEOUT, 30);



    cafile := certfile;
    curl_easy_setopt(curl, CURLOPT_SSLCERT, cafile);

    s := '{"aps":{"alert":"' + title + '","sound":"' + ifthen(sound <> '',sound, 'default') +
         '","content-available":1,"badge":' + '3}';
    if extinfo <> '' then
      s := s + ', "ext":"' + extinfo + '"';
    s := s + '}';
    msg := utf8encode(s);
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, PAnsiChar(msg));

    topic := 'apns-topic: ' + bundleId;
    new(headers);
    headers.Data := PAnsiChar(topic);
    new(h2);
    h2.Data := 'User-Agent: libcurl';
    headers.next := h2;
    curl_easy_setopt(curl, CURLOPT_HTTPHEADER, headers);

    res := curl_easy_perform(curl);
    if (res = CURLE_OK) then
    begin
      curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, code);
      if code = 200 then
        Result := True;
    end else
    begin
      err := curl_easy_strerror(res);
    end;
    curl_easy_cleanup(curl);

  end;


end;


initialization
curl_global_init(CURL_GLOBAL_DEFAULT);


finalization
curl_global_cleanup;

end.

