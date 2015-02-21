{$ifndef Package_Build}
{$ifdef systest}
  {$I ..\Conditionals.inc}
{$else}
  {$I Conditionals.inc}
{$endif}
{$endif}
unit DAP_Inspector;

interface

uses Windows, Messages, SysUtils, Classes, DAPIO32;

type
  {$IFDEF DELPHIXE}
  // When in DelphiXE or any unicode style IDE ANSI types must be used.
  TPChar = PANSIChar;
  TChar = ANSIChar;
  TString = ANSIString;
  {$ELSE}
  // When in Delphi 3 standard types are OK to use.
  TPChar = PChar;
  TChar = Char;
  TString = String;
  {$ENDIF}

  TQueryError = procedure(Sender : TObject; ErrorMsg : String) of Object;

  TQuery_Result_Type = (DAP_String,DAP_DWord);
  TDAPHandle_Cmd = (D_DapName,D_DapModel,D_DapOs,D_DapSerial,D_DapMemFree,D_DapMemTotal);
  TServerHandle_Cmd = (S_DapEnumerate,S_IsRemote,S_ServerName,S_ServerOs,S_ServerVersion);
  TNullHandle_Cmd = (N_ClientVersion,N_ServerEnumerate);

  TData_Buffer = Array[0..1023] of Char;

  TInspector_Base = class(TComponent)
  private
    FQueryError : TQueryError;
  protected
    procedure DAP_QueryCreate(Var QueryStruct : TDapHandleQueryA; QueryKey : TPChar; QueryResultPtr : Pointer; Size : LongInt; Result_Type : TQuery_Result_Type);
    function Handle_QueryString(ObjectHandle : TDapHandle; QueryItem : TPChar; Var Cmd_Success : Boolean) : String;
    function Handle_QueryDWord(ObjectHandle : TDapHandle; QueryItem : TPChar; Var Cmd_Success : Boolean; Var ErrorMsg : ShortString) : DWord;
    function Null_QueryString(QueryItem : TPChar; Var Cmd_Success : Boolean) : String;
    function Null_QueryDWord(QueryItem : TPChar; Var Cmd_Success : Boolean; Var ErrorMsg : ShortString) : DWord;
  public
    constructor Create(AOwner : TComponent); Override;
    destructor Destroy; Override;
  published
    property OnQueryError : TQueryError read FQueryError write FQueryError;
  end; // TDAP_Base

  TServer_Query = class(TInspector_Base)
  private
    FServerLocation : String;
    FServerQuery_Handle : TDAPHandle;
  protected
    function DAPIO32_Version : DWord;
    function Local_ServerFound : TDapHandle;
    function Find_DAPServers : TStringList;
    function Find_DAPsOnServer(DAPServerUNCName : String) : TStringList;
    function Server_IsRemote(UNC_SeverLocation : String; Var Cmd_Success : Boolean; Var Cmd_ErrorMsg : ShortString) : Boolean;
    function Server_Name(UNC_ServerLocation : String) : String;
    function Server_OS(UNC_ServerLocation : String) : String;
    function Server_Version(UNC_ServerLocation : String; Var Cmd_Success : Boolean; Var ErrorMsg : ShortString) : DWord;
    procedure SetServerLocation(Value : String);
    function GetLocalServerActive : Boolean;
    function GetDAPServers : TStringList;
    function GetDAPs : TStringList;
    function GetIsRemote : Boolean;
    function GetServerName : String;
    function GetServerOS : String;
    function GetServerVersion : DWord;
    function GetClientVersion : DWord;
  public
    constructor Create(AOwner : TComponent); Override;
    destructor Destroy; Override;
    property ServerLocation : String read FServerLocation write SetServerLocation;
    property LocalServerActive : Boolean read GetLocalServerActive;
    property ListDAPServers : TStringList read GetDAPServers;
    property ListDAPSOnServer : TSTringList read GetDAPs;
    property IsRemote : Boolean read GetIsRemote;
    property ServerName : String read GetServerName;
    property ServerOS : String read GetServerOS;
    property ServerVerstion : DWord read GetServerVersion;
    property ClientVersion : DWord read GetClientVersion;
  end; // TServer_Query

  TDAP_Query = class; // Defined later in code...

  TDapMemThread = class(TThread)
    private
      FEnabled : Boolean;
      FReadDelay : DWord;
      FDapMemFree : DWord;
      FDapMemTotal : DWord;
      FDapMemWarningLevel : Single;
      FQueryDAP : TDAP_Query;
    protected
      procedure SetEnabled(Value : Boolean);
      procedure SetDapMemWarningLevel(Value : Single);
      procedure DoGetDapMemFree;
      procedure Execute; Override;
    public
      constructor Create(CreateSuspended : Boolean);
      property Enabled : Boolean read FEnabled write SetEnabled;
      property ReadDelay : DWord read FReadDelay write FReadDelay;
      property DapMemTotal : DWord write FDapMemTotal;
      property MemoryLowWarningLevel : Single read FDapMemWarningLevel write SetDapMemWarningLevel;
      property QueryDAP : TDAP_Query write FQueryDAP;
  end; // TQueryDAPThread

  TDapMemFreeEvent = procedure(Sender : TObject; MemFree : DWord) of Object;

  TDAP_Query = class(TInspector_Base)
  private
    FDapMemWarning : TNotifyEvent;
    FDapMemFree : TDapMemFreeEvent;
    FDAPLocation : String;
    FDAPQuery_Handle : TDAPHandle;
    FDapMemThread : TDapMemThread;
    FDapMemMonitoring : Boolean;
    FDAPMemUsageReadDelay : DWord;
    FDapMemWarningLevel : Single;
  protected
    function Local_DAPFound : TDapHandle;
    function DAP_Name(UNC_DAPLocation : String) : String;
    function DAP_SerialNum(UNC_DAPLocation : String) : String;
    function DAP_Model(UNC_DAPLocation : String) : String;
    function DAP_OS(UNC_DAPLocation : String) : String;
    function DAP_MemFree(UNC_DAPLocation : String) : DWord;
    function DAP_MemTotal(UNC_DAPLocation : String) : DWord;
    procedure SetDAPLocation(Value : String);
    function GetLocalDAPActive : Boolean;
    function GetDAPName : String;
    function GetDAPSerialNum : String;
    function GetDAPModel : String;
    function GetDAPOS : String;
    function GetDAPMemFree : DWord;
    function GetDAPMemTotal : DWord;
    procedure SetDapMemMonitoring(Value : Boolean);
    function GetDAPMemMonitoring : Boolean;
    procedure SetMemUsageReadDelay(Value : DWord);
    function GetMemUsageReadDelay : DWord;
    procedure SetMemLowWarningLevel(Value : Single);
    function GetMemLowWarningLevel : Single;
    procedure DoNotifyDapMemWarning;
    procedure DoDapMemFree(FreeMem : DWord);
  public
    constructor Create(AOwner : TComponent); Override;
    destructor Destroy; Override;
    property DAPLocation : String read FDAPLocation write SetDAPLocation;
    property LocalDAPFound : Boolean read GetLocalDAPActive;
    property DAPName : String read GetDAPName;
    property DAPSeralNum : String read GetDAPSerialNum;
    property DAPModel : String read GetDAPModel;
    property DAPOS : String read GetDAPOS;
    property DAPMemFree : DWord read GetDAPMemFree;
    property DAPMemTotal : DWord read GetDAPMemTotal;
    property MonitorMemoryUsage : Boolean read GetDAPMemMonitoring write SetDapMemMonitoring;
    property MemUsageReadDelay : DWord read GetMemUsageReadDelay write SetMemUsageReadDelay;
    property MemLowWarningLevel : Single read GetMemLowWarningLevel write SetMemLowWarningLevel;
    property OnDAPMemOverFlow : TNotifyEvent read FDapMemWarning write FDapMemWarning;
    property OnDAPMemFree : TDapMemFreeEvent read FDapMemFree write FDapMemFree;
  end; // TDAP_Query

  TDAP_Inspector = class(TComponent)
  private
    FServerQuery : TServer_Query;
    FServerQueryError : TQueryError;
    FDAPQuery : TDAP_Query;
    FDAPQueryError : TQueryError;
    FDAPMemFree : TDapMemFreeEvent;
    FDAPMemWarning : TNotifyEvent;
    FDAPMemMonitoring : Boolean;
    FDAPMemWarningLevel : Single;
    FDAPMemPollingInterval : DWord;
  protected
    procedure ServerQueryError(Sender : TObject; ErrorMsg : String);
    procedure DAPQueryError(Sender : TObject; ErrorMsg : String);
    procedure SetServerLocation(Value : String);
    function GetServerLocation : String;
    function GetLocalServerActive : Boolean;
    function GetDAPServers : TStringList;
    function GetDAPsOnServer : TStringList;
    function GetIsRemote : Boolean;
    function GetServerName : String;
    function GetServerOS : String;
    function GetServerVersion : DWord;
    function GetClientVersion : DWord;
    procedure SetDAPLocation(Value : String);
    function GetDAPLocation : String;
    function GetLocalDAPActive : Boolean;
    function GetDAPName : String;
    function GetDAPSerialNum : String;
    function GetDAPModel : String;
    function GetDAPOS : String;
    function GetDAPMemFree : DWord;
    function GetDAPMemTotal : DWord;
    procedure SetDapMemMonitoring(Value : Boolean);
    function GetDAPMemMonitoring : Boolean;    
    procedure SetPollDapMemUsageInterval(Value : DWord);
    function GetPollDAPMemUsageInterval : DWord;
    procedure SetMemWarningLevel(Value : Single);
    function GetMemWarningLevel : Single;
    procedure DapMemFreeEvent(Sender : TObject; MemFree : DWord);
    procedure DapMemWarningEvent(Sender : TObject);
  public
    constructor Create(AOwner : TComponent); Override;
    destructor Destroy; Override;
  published
    property ServerLocation : String read GetServerLocation write SetServerLocation;
    property LocalServerActive : Boolean read GetLocalServerActive;
    property ListDAPServers : TStringList read GetDAPServers;
    property ListDAPsOnServer : TStringList read GetDAPsOnServer;
    property IsRemote : Boolean read GetIsRemote;
    property ServerName : String read GetServerName;
    property ServerOS : String read GetServerOS;
    property ServerVersion : DWord read GetServerVersion;
    property ClientVersion : DWord read GetClientVersion;
    property DAPLocation : String read GetDAPLocation write SetDAPLocation;
    property LocalDAPActive : Boolean read GetLocalDAPActive;
    property DAPName : String read GetDAPName;
    property DAPSerialNum : String read GetDAPSerialNum;
    property DAPModel : String read GetDAPModel;
    property DAPOS : String read GetDAPOS;
    property DAPMemFree : DWord read GetDAPMemFree;
    property DAPMemTotal : DWord read GetDAPMemTotal;
    property MonitorDAPMemoryUsage : Boolean read GetDAPMemMonitoring write SetDapMemMonitoring;
    property PollDapMemoryUsageInterval : DWord read GetPollDAPMemUsageInterval write SetPollDapMemUsageInterval;
    property DapMemWarningLevel : Single read GetMemWarningLevel write SetMemWarningLevel;
  published
    property OnServerQueryError : TQueryError read FServerQueryError write FServerQueryError;
    property OnDAPQueryError : TQueryError read FDAPQueryError write FDAPQueryError;
    property OnDAPMemOverFlow : TNotifyEvent read FDapMemWarning write FDapMemWarning;
    property OnDAPMemFree : TDapMemFreeEvent read FDapMemFree write FDapMemFree;
  end; // TDAP_Inpsector

const
  DAP_Commands : Array[0..5] of TPChar = ('DapName','DapModel','DapOs','DapSerial','DaplMemFree','DaplMemTotal');
  Server_Commands : Array[0..4] of TPChar = ('DapEnumerate','IsRemote','ServerName','ServerOs','ServerVersion');
  Null_Commands : Array[0..1] of TPChar = ('ClientVersion','ServerEnumerate');


procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('TMSI', [TServer_Query,TDAP_Query,TDAP_Inspector]);
end;

constructor TInspector_Base.Create(AOwner : TComponent);
begin
  inherited Create(Aowner);
end; // TInspector_Base.Create

destructor TInspector_Base.Destroy;
begin
  inherited Destroy;
end; // TInspector_Base.Destroy

procedure TInspector_Base.DAP_QueryCreate(Var QueryStruct : TDapHandleQueryA; QueryKey : TPChar; QueryResultPtr : Pointer; Size : LongInt; Result_Type : TQuery_Result_Type);
begin
  FillChar(QueryStruct,SizeOf(QueryStruct),#0);
  with QueryStruct do
  begin
    iInfoSize := SizeOf(TDapHandleQueryA);
    pszQueryKey := QueryKey;
    if (Result_Type = DAP_String) then
    begin
      QueryResult.psz := QueryResultPtr;
      iBufferSize := Size;
    end
    else
    begin
      iBufferSize := 0;
    end; // If
  end; // With
end; // TInspector_Base.DAP_QueryCreate

function TInspector_Base.Handle_QueryString(ObjectHandle : TDapHandle; QueryItem : TPChar; Var Cmd_Success : Boolean) : String;
var
  Query : TDapHandleQueryA;
  QueryResult : TData_Buffer;
  DAPError : ShortString;
  i : LongInt;
  SP : LongInt;
begin
  DAP_QueryCreate(Query,QueryItem,@QueryResult,1024,DAP_String);
  Cmd_Success := DAPHandleQuery(ObjectHandle,Query);
  if Cmd_Success then
  begin
    Result := '';
    SP := 1;
    for i := 1 to Length(Query.QueryResult.psz) do
    begin
      if (i <> Length(Query.QueryResult.psz)) then
      begin
        if (Query.QueryResult.psz[i] = #0) then
        begin
          Result := Result + Copy(Query.QueryResult.psz,SP,(i - (SP - 1))) + ';';
          SP := i + 2;
        end; // If
      end
      else
      begin
        Result := Result + Copy(Query.QueryResult.psz,SP,(i - SP) + 1);
      end; // If
    end; // For i
  end
  else
  begin
    Result := DapLastErrorTextGet(@DAPError,SizeOf(DAPError))
  end; // If
end; // TInspector_Base.Handle_QueryString

function TInspector_Base.Handle_QueryDWord(ObjectHandle : TDapHandle; QueryItem : TPChar; Var Cmd_Success : Boolean; Var ErrorMsg : ShortString) : DWord;
var
  Query : TDapHandleQueryA;
  QueryResult : TData_Buffer;
begin
  Result := 0;
  DAP_QueryCreate(Query,QueryItem,@QueryResult,1024,DAP_DWord);
  Cmd_Success := DAPHandleQuery(ObjectHandle,Query);
  if Cmd_Success then
    Result := Query.QueryResult.dw
  else
    ErrorMsg := DapLastErrorTextGet(@ErrorMsg,SizeOf(ErrorMsg));
end; // TInspector_Base.Handle_QueryDWord

function TInspector_Base.Null_QueryString(QueryItem : TPChar; Var Cmd_Success : Boolean) : String;
begin
  Result := Handle_QueryString(0,QueryItem,Cmd_Success);
end; // TInspector_Base.Null_QueryString

function TInspector_Base.Null_QueryDWord(QueryItem : TPChar; Var Cmd_Success : Boolean; Var ErrorMsg : ShortString) : DWord;
begin
  Result := Handle_QueryDWord(0,QueryItem,Cmd_Success,ErrorMsg);
end; // TInspector_Base.Null_QueryDWord

constructor TServer_Query.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  SetServerLocation('\\.');
end; // TServer_Query.Create

destructor TServer_Query.Destroy;
begin
  inherited Destroy;
end; // TServer_Query.Destroy

function TServer_Query.DAPIO32_Version : DWord;
var
  Cmd_OK : Boolean;
  Cmd_ErrorMsg : ShortString;
  Cmd_Result : DWord;
begin
  Cmd_Result := Null_QueryDWord(Null_Commands[Ord(N_ClientVersion)],Cmd_OK,Cmd_ErrorMsg);
  if Cmd_OK then
    Result := Cmd_Result
  else
    Result := 0;
end; // TInspector_Base.DAPIO32_Version

function TServer_Query.Local_ServerFound : TDapHandle;
begin
  Result := DapHandleOpen('\\.',DAPOPEN_QUERY);
  DapHandleClose(Result);
end; // TServer_Query/Local_ServerFound

function TDAP_Query.Local_DAPFound : TDapHandle;
begin
  Result := DapHandleOpen('\\.\Dap0',DAPOPEN_QUERY);
  DapHandleClose(Result);
end; // TDAP_Query.Local_DAPFound

function TServer_Query.Server_IsRemote(UNC_SeverLocation : String; Var Cmd_Success : Boolean; Var Cmd_ErrorMsg : ShortString) : Boolean;
begin
  if (FServerQuery_Handle <> 0) then
  begin
    Result := Ord(Handle_QueryDWord(FServerQuery_Handle,Server_Commands[Ord(S_IsRemote)],Cmd_Success,Cmd_ErrorMsg)) = 1;
  end
  else
  begin
    Cmd_ErrorMsg := 'No Handle to Server.';
    Result := False;
  end; // If
end; // TServer_Query.Server_IsRemote

function TServer_Query.Server_Name(UNC_ServerLocation : String) : String;
var
  Cmd_OK : Boolean;
begin
  if (FServerQuery_Handle > 0) then
    Result := Handle_QueryString(FServerQuery_Handle,Server_Commands[Ord(S_ServerName)],Cmd_OK)
  else
    Result := 'No Handle to Server.';
end; // TServer_Query.Server_Name

function TServer_Query.Server_OS(UNC_ServerLocation : String) : String;
var
  Cmd_OK : Boolean;
begin
  if (FServerQuery_Handle > 0) then
    Result := Handle_QueryString(FServerQuery_Handle,Server_Commands[Ord(S_ServerOs)],Cmd_OK)
  else
    Result := 'No Handle to Server.';
end; // TServer_Query.Server_OS

function TServer_Query.Server_Version(UNC_ServerLocation : String; Var Cmd_Success : Boolean; Var ErrorMsg : ShortString) : DWord;
begin
  if (FServerQuery_Handle <> 0) then
  begin
    Result := Handle_QueryDWord(FServerQuery_Handle,Server_Commands[Ord(S_ServerVersion)],Cmd_Success,ErrorMsg);
  end
  else
  begin
    ErrorMsg := 'No Handle to Server.';
    Result := 0;
  end; // If
end; // TServer_Query.Server_Version

function TServer_Query.Find_DAPServers : TStringList;
var
  DAPServers : TStringList;
  i : LongInt;
  SP : LongInt;
  ResultStr : String;
  TempServer : String;
  Cmd_OK : Boolean;
begin
  DAPServers := TStringList.Create;
  ResultStr := Null_QueryString(Null_Commands[Ord(N_ServerEnumerate)],Cmd_OK);
  if Cmd_OK then
  begin
    SP := 1;
    for i := 1 to Length(ResultStr) do
    begin
      if (i <> Length(ResultStr)) then
      begin
        if (ResultStr[i] = ';') then
        begin
          TempServer := Copy(ResultStr,SP,(i - SP));
          DAPServers.Add(TempServer);
          SP := i + 1;
        end; // If
      end
      else
      begin
        TempServer := Copy(ResultStr,SP,(i - SP) + 1);
        DAPServers.Add(TempServer);
      end; // If
    end; // For i
  end; // If
  Result := DAPServers;
end; // TServer_Query.Find_DAPServers

function TServer_Query.Find_DAPsOnServer(DAPServerUNCName : String) : TStringList;
var
  DAPs : TStringList;
  Cmd_OK : Boolean;
  i : LongInt;
  SP : LongInt;
  TempDap : String;
  ResultStr : String;
begin
  DAPs := TStringList.Create;
  if (FServerQuery_Handle <> 0) then
  begin
    ResultStr := Handle_QueryString(FServerQuery_Handle,Server_Commands[Ord(S_DapEnumerate)],Cmd_OK);
    if Cmd_OK then
    begin
      SP := 1;
      for i := 1 to Length(ResultStr) do
      begin
        if (i <> Length(ResultStr)) then
        begin
          if (ResultStr[i] = ';') then
          begin
            TempDap := Copy(ResultStr,SP,(i - SP));
            DAPs.Add(TempDap);
            SP := i + 1;
          end; // If
        end
        else
        begin
          TempDap := Copy(ResultStr,SP,(i - SP) + 1);
          DAPs.Add(TempDap);
        end; // If
      end; // For i
    end; // if
  end; // If
  Result := DAPs;
end; // TServer_Query.Find_DAPsOnServer

procedure TServer_Query.SetServerLocation(Value : String);
begin
  if Not (csDesigning in ComponentState) then
  begin
    if (Value <> FServerLocation) then
    begin
      if (FServerQuery_Handle > 0) then
        DapHandleClose(FServerQuery_Handle);
      FServerLocation := Value;
      FServerQuery_Handle := DapHandleOpen(TPChar(TString(FServerLocation)),DAPOPEN_QUERY);
    end; // If
  end
  else
  begin
    FServerLocation := Value;
  end; // If
end; // TServer_Query.SetServerLocation

function TServer_Query.GetLocalServerActive : Boolean;
var
  Server_Handle : TDapHandle;
begin
  if Not (csDesigning in ComponentState) then
  begin
    Server_Handle := Local_ServerFound;
    Result := (Server_Handle > 0);
    DapHandleClose(Server_Handle);
    if Not Result then
    begin
      if Assigned(FQueryError) then
        FQueryError(Self,DapLastErrorGet);
    end;
  end
  else
    Result := False;
end; // TServer_Query.GetLocalServerActive

function TServer_Query.GetDAPServers : TStringList;
var
  TempList : TStringList;
begin
  if Not (csDesigning in ComponentState) then
  begin
    Result := Find_DAPServers;
  end
  else
  begin
    TempList := TStringList.Create;
    Result := TempList;
  end; // if
end; // TServer_Query.GetDAPServers

function TServer_Query.GetDAPs : TStringList;
var
  TempList : TStringList;
begin
  if Not (csDesigning in ComponentState) then
  begin
    Result := Find_DAPsOnServer(FServerLocation)
  end
  else
  begin
    TempList := TStringList.Create;
    Result := TempList;
  end; // if
end; // TServer_Query.GetDAPs

function TServer_Query.GetIsRemote : Boolean;
var
  Cmd_OK : Boolean;
  Cmd_ErrorMsg : ShortString;
begin
  if Not (csDesigning in ComponentState) then
  begin
    Result := Server_IsRemote(FServerLocation,Cmd_OK,Cmd_ErrorMsg);
    if Not Cmd_OK then
    begin
      if Assigned(FQueryError) then
        FQueryError(Self,Cmd_ErrorMsg);
    end; // If
  end
  else
  begin
    Result := False;
  end; // If
end; // TServer_Query.GetIsRemote

function TServer_Query.GetServerName : String;
begin
  if Not (csDesigning in ComponentState) then
    Result := Server_Name(FServerLocation)
  else
    Result := '\\.';
end; // TServer_Query.GetServerName

function TServer_Query.GetServerOS : String;
begin
  if Not (csDesigning in ComponentState) then
    Result := Server_OS(FServerLocation)
  else
    Result := '';
end; // TServer_Query.GetServerOS

function TServer_Query.GetServerVersion : DWord;
var
  Cmd_OK : Boolean;
  Cmd_ErrorMsg : ShortString;
begin
  if Not (csDesigning in ComponentState) then
  begin
    Result := Server_Version(FServerLocation,Cmd_OK,Cmd_ErrorMsg);
    if Not Cmd_OK then
    begin
      if Assigned(FQueryError) then
        FQueryError(Self,Cmd_ErrorMsg);
    end; // If
  end
  else
  begin
    Result := 0;
  end; // If
end; // TServer_Query.GetServerVersion

function TServer_Query.GetClientVersion : DWord;
begin
  if Not (csDesigning in ComponentState) then
    Result := DAPIO32_Version
  else
    Result := 0;
end; // TServer_Query.GetClientVerson

constructor TDAP_Query.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  SetDAPLocation('\\.\Dap0');
  FDapMemMonitoring := False;
  FDapMemWarningLevel := 90;
  FDAPMemUsageReadDelay := 1000;
  if Not (csDesigning in ComponentState) then
  begin
    FDapMemThread := TDapMemThread.Create(True);
    FDapMemThread.QueryDAP := Self;
  end; // If
end; // TDAP_Query.Create

destructor TDAP_Query.Destroy;
begin
  if Not (csDesigning in ComponentState) then
  begin
    FDapMemThread.Terminate;
    FDapMemThread.Free;
  end; // If
  inherited Destroy;
end; // TDAP_Query.Destroy

function TDAP_Query.DAP_Name(UNC_DAPLocation : String) : String;
var
  Cmd_OK : Boolean;
begin
  if (FDAPQuery_Handle > 0) then
    Result := Handle_QueryString(FDAPQuery_Handle,DAP_Commands[Ord(D_DapName)],Cmd_OK);
  if Not Cmd_OK then
  begin
    if Assigned(FQueryError) then
      FQueryError(Self,'No Handle to DAP.');
  end; // If
end; // TDAP_Query.DAP_Name

function TDAP_Query.DAP_SerialNum(UNC_DAPLocation : String) : String;
var
  Cmd_OK : Boolean;
begin
  if (FDAPQuery_Handle <> 0) then
    Result := Handle_QueryString(FDAPQuery_Handle,Dap_Commands[Ord(D_DapSerial)],Cmd_OK);
  if Not Cmd_OK then
  begin
    if Assigned(FQueryError) then
      FQueryError(Self,'No Handle to DAP.');
  end; // If
end; // TDAP_Query.DAP_SerialNum

function TDAP_Query.DAP_Model(UNC_DAPLocation : String) : String;
var
  Cmd_OK : Boolean;
begin
  if (FDAPQuery_Handle <> 0) then
    Result := Handle_QueryString(FDAPQuery_Handle,Dap_Commands[Ord(D_DapModel)],Cmd_OK);
  if Not Cmd_OK then
  begin
    if Assigned(FQueryError) then
      FQueryError(Self,'No Handle to DAP.');
  end; // If
end; // TDAP_Query.DAP_Model

function TDAP_Query.DAP_OS(UNC_DAPLocation : String) : String;
var
  Cmd_OK : Boolean;
begin
  if (FDAPQuery_Handle <> 0) then
    Result := Handle_QueryString(FDAPQuery_Handle,Dap_Commands[Ord(D_DapOs)],Cmd_OK);
  if Not Cmd_OK then
  begin
    if Assigned(FQueryError) then
      FQueryError(Self,'No Handle to DAP.');
  end; // If
end; // TDAP_Query.DAP_OS

function TDAP_Query.DAP_MemFree(UNC_DAPLocation : String) : DWord;
var
  Cmd_OK : Boolean;
  Err_Msg : ShortString;
begin
  Result := 0;
  if (FDAPQuery_Handle <> 0) then
    Result := Handle_QueryDWord(FDAPQuery_Handle,Dap_Commands[Ord(D_DapMemFree)],Cmd_OK,Err_Msg);
  if Not Cmd_OK then
  begin
    if Assigned(FQueryError) then
      FQueryError(Self,'No Handle to DAP.');
  end; // If
end; // TDAP_Query.DAP_MemFree

function TDAP_Query.DAP_MemTotal(UNC_DAPLocation : String) : DWord;
var
  Cmd_OK : Boolean;
  Err_Msg : ShortString;
begin
  Result := 0;
  if (FDAPQuery_Handle <> 0) then
    Result := Handle_QueryDWord(FDAPQuery_Handle,Dap_Commands[Ord(D_DapMemTotal)],Cmd_OK,Err_Msg);
  if Not Cmd_OK then
  begin
    if Assigned(FQueryError) then
      FQueryError(Self,'No Handle to DAP.');
  end
  else
    FDapMemThread.DapMemTotal := Result;
end; // TDAP_Query.DAP_MemTotal

procedure TDAP_Query.SetDAPLocation(Value : String);
begin
  if Not (csDesigning in ComponentState) then
  begin
    if (Value <> FDAPLocation) then
    begin
      if (FDAPQuery_Handle > 0) then
        DapHandleClose(FDAPQuery_Handle);
      FDAPLocation := Value;
      FDAPQuery_Handle := DapHandleOpen(TPChar(TString(FDAPLocation)),DAPOPEN_QUERY);
    end; // If
  end
  else
  begin
    FDAPLocation := Value;
  end; // If
end; // TDAP_Query.SetDAPLocation

function TDAP_Query.GetLocalDAPActive : Boolean;
var
  DAP_Handel : TDAPHandle;
begin
  if Not (csDesigning in ComponentState) then
  begin
    DAP_Handel := Local_DAPFound;
    Result := DAP_Handel > 0;
    DapHandleClose(DAP_Handel);
  end
  else
  begin
    Result := False;
  end; // If
end; // TDAP_Query.GetLocalDAPActive

function TDAP_Query.GetDAPName : String;
begin
  if Not (csDesigning in ComponentState) then
    Result := DAP_Name(FDAPLocation)
  else
    Result := '\\.\Dap0';
end; // TDAP_Query.GetDAPName

function TDAP_Query.GetDAPSerialNum : String;
begin
  if Not (csDesigning in ComponentState) then
    Result := DAP_SerialNum(FDAPLocation)
  else
    Result := '';
end; // TDAP_Query.GetDAPSerialNum

function TDAP_Query.GetDAPModel : String;
begin
  if Not (csDesigning in ComponentState) then
    Result := DAP_Model(FDAPLocation)
  else
    Result := '';
end; // TDAP_Query.GetDAPModel

function TDAP_Query.GetDAPOS : String;
begin
  if Not (csDesigning in ComponentState) then
    Result := DAP_OS(FDAPLocation)
  else
    Result := '';
end; // TDAP_Query.GetDAPOS

function TDAP_Query.GetDAPMemFree : DWord;
begin
  if Not (csDesigning in ComponentState) then
    Result := DAP_MemFree(FDAPLocation)
  else
    Result := 0;
end; // TDAP_Query.GetDAPMemFree

function TDAP_Query.GetDAPMemTotal : DWord;
begin
  if Not (csDesigning in ComponentState) then
    Result := DAP_MemTotal(FDAPLocation)
  else
    Result := 0;
end; // TDAP_Query.GetDAPMemTotal

procedure TDAP_Query.SetDapMemMonitoring(Value : Boolean);
begin
  FDapMemMonitoring := Value;
  if Not (csDesigning in ComponentState) then
    FDapMemThread.Enabled := FDapMemMonitoring;
end; // TDAP_Query.SetDapMemMonitoring

function TDAP_Query.GetDAPMemMonitoring : Boolean;
begin
  if AssigneD(FDAPMemThread) then
    Result := FDAPmemThread.Enabled
  else
    Result := FDapMemMonitoring;
end; // TDAP_Query.GetDAPMemMonitoring

procedure TDAP_Query.SetMemUsageReadDelay(Value : DWord);
begin
  FDAPMemUsageReadDelay := Value;
  if Not (csDesigning in ComponentState) then
    FDapMemThread.ReadDelay := FDAPMemUsageReadDelay;
end; // TDAP_Query.SetMemUsgeReadDelay

function TDAP_Query.GetMemUsageReadDelay : DWord;
begin
  if Not (csDesigning in ComponentState) then
    Result := FDapMemThread.ReadDelay
  else
    Result := FDAPMemUsageReadDelay;
end; // TDAP_Query.GetMemUsageReadDelay

procedure TDAP_Query.SetMemLowWarningLevel(Value : Single);
begin
  FDapMemWarningLevel := Value;
  if Not (csDesigning in ComponentState) then
    FDapMemThread.MemoryLowWarningLevel := FDapMemWarningLevel;
end; // TDAP_Query.SetMemLowWarningLevel

function TDAP_Query.GetMemLowWarningLevel : Single;
begin
  if Not (csDesigning in ComponentState) then
    Result := (FDapMemThread.MemoryLowWarningLevel * 100)
  else
    Result := FDapMemWarningLevel;
end; // TDAP_Query.GetMemLowWarningLevel

procedure TDAP_Query.DoNotifyDapMemWarning;
begin
  if Assigned(FDapMemWarning) then
    FDapMemWarning(Self);
end; // TDAP_Query.DoNotifyDapMemWarning

procedure TDAP_Query.DoDapMemFree(FreeMem : DWord);
begin
  if Assigned(FDapMemFree) then
    FDapMemFree(Self,FreeMem);
end; // TDAP_Query.DoDapMemFree

constructor TDapMemThread.Create(CreateSuspended : Boolean);
begin
  inherited Create(CreateSuspended);
  FEnabled := False;
  FReadDelay := 1000;
  FDapMemFree := 0;
  FDapMemTotal := 0;
  FDapMemWarningLevel := 90;
end; // TDAP_Query.Create

procedure TDapMemThread.SetEnabled(Value : Boolean);
begin
  if (Value <> FEnabled)  then
  begin
    FEnabled := Value;
    if FEnabled then
      Start
    else
      Terminate;
  end; // If
end; // TDapMemThread.SetEnabled

procedure TDapMemThread.SetDapMemWarningLevel(Value : Single);
begin
  if (Value > 100) then
    Value := 100;
  if (Value < 0) then
    Value := 1;
  FDapMemWarningLevel := (Value / 100)
end; // TDapMemThread.SetDapMemWarningLevel

procedure TDapMemThread.DoGetDapMemFree;
begin
  if Assigned(FQueryDAP) then
  begin
    FDapMemFree := FQueryDAP.DAPMemFree;
    FQueryDAP.DoDapMemFree(FDapMemFree);
  end; // If
  if (FDapMemTotal > 0) then
  begin
    if (((FDapMemTotal - FDapMemFree) / FDapMemTotal) > FDapMemWarningLevel) then
      FQueryDAP.DoNotifyDapMemWarning;
  end; // If
end; // TDapMemThread.DoGetDapMemFree

procedure TDapMemThread.Execute;
begin
  repeat
    Synchronize(DoGetDapMemFree);
    if Not Terminated then
      Sleep(FReadDelay);
  until Terminated or Not FEnabled;
end; // TDapMemThread.Execute

constructor TDAP_Inspector.Create(AOwner : TComponent);
begin
  inherited Create(AOwner);
  FDAPMemMonitoring := False;
  FDAPMemWarningLevel := 90;
  FDAPMemPollingInterval := 1000;
  FServerQuery := TServer_Query.Create(Self);
  FServerQuery.OnQueryError := ServerQueryError;
  FDAPQuery := TDAP_Query.Create(Self);
  FDAPQuery.OnQueryError := DAPQueryError;
  FDapQuery.OnDAPMemOverFlow := DapMemWarningEvent;
  FDAPQuery.OnDAPMemFree := DapMemFreeEvent;
end; // TDAP_Inspector.Create

destructor TDAP_Inspector.Destroy;
begin
  FServerQuery.Free;
  FDAPQuery.Free;
  inherited Destroy;
end; // TDAP_Inspector.Destroy

procedure TDAP_Inspector.SetServerLocation(Value : String);
begin
  FServerQuery.Server_Name(Value);
end; // TDAP_Inspector.SetServerLocation

function TDAP_Inspector.GetServerLocation : String;
begin
  if Not (csDesigning in ComponentState) then
    Result := FServerQuery.ServerLocation
  else
    Result := '\\.';
end; // TDAP_Inspector.GetServerLocation

function TDAP_Inspector.GetLocalServerActive : Boolean;
begin
  Result := FServerQuery.LocalServerActive;
end; // TDAP_Inspector.GetLocalServerActive

function TDAP_Inspector.GetDAPServers : TStringList;
begin
  Result := FServerQuery.ListDAPServers;
end; // TDAP_Inspector.GetDAPServers

function TDAP_Inspector.GetDAPsOnServer : TStringList;
var
  TempList : TStringList;
begin
  if Not (csDesigning in ComponentState) then
  begin
    Result := FServerQuery.Find_DAPsOnServer(FServerQuery.ServerLocation);
  end
  else
  begin
    TempList := TStringList.Create;
    Result := TempList;
  end; // if
end; // TDAP_Inspector.GetDAPsOnServer

function TDAP_Inspector.GetIsRemote : Boolean;
begin
  Result := FServerQuery.IsRemote;
end; // TDAP_Inspector.GetIsRemote

function TDAP_Inspector.GetServerName : String;
begin
  Result := FServerQuery.ServerName;
end; // TDAP_Inspector.GetServerName

function TDAP_Inspector.GetServerOS : String;
begin
  Result := FServerQuery.ServerOS;
end; // TDAP_Inspector.GetServerOS

function TDAP_Inspector.GetServerVersion : DWord;
begin
  Result := FServerQuery.ServerVerstion;
end; // TDAP_Inspector.GetServerVersion

function TDAP_Inspector.GetClientVersion : DWord;
begin
  Result := FServerQuery.ClientVersion;
end; // TDAP_Inspector.GetClientVersion

procedure TDAP_Inspector.SetDAPLocation(Value : String);
begin
  FDAPQuery.DAPLocation := Value;
end; // TDAP_Inspector.SetDAPLocaiton

function TDAP_Inspector.GetDAPLocation : String;
begin
  if Not (csDesigning in ComponentState) then
    Result := FDAPQuery.DAPLocation
  else
    Result := '\\.\Dap0';
end; // TDAP_Inspector.GetDAPLocation

function TDAP_Inspector.GetLocalDAPActive : Boolean;
begin
  Result := FDAPQuery.LocalDAPFound;
end; // TDAP_Inspector.GetLocalDAPActive

function TDAP_Inspector.GetDAPName : String;
begin
  Result := FDAPQuery.DAPName;
end; // TDAP_Inspector.GetDAPName

function TDAP_Inspector.GetDAPSerialNum : String;
begin
  Result := FDAPQuery.DAPSeralNum;
end; // TDAP_Inspector.GetDAPSerialNum

function TDAP_Inspector.GetDAPModel : String;
begin
  Result := FDAPQuery.DAPModel;
end; // TDAP_Inspector.GetDAPModel

function TDAP_Inspector.GetDAPOS : String;
begin
  Result := FDAPQuery.DAPOS;
end; // TDAP_Inspector.GetDAPOS

function TDAP_Inspector.GetDAPMemFree : DWord;
begin
  Result := FDAPQuery.DAPMemFree;
end; // TDAP_Inspector.GetDAPMemFree

function TDAP_Inspector.GetDAPMemTotal : DWord;
begin
  Result := FDAPQuery.DAPMemTotal;
end; // TDAP_Inspector.GetDAPMemTotal

procedure TDAP_Inspector.SetDapMemMonitoring(Value : Boolean);
begin
  FDAPMemMonitoring := Value;
  if Assigned(FDAPQuery) then
    FDAPQuery.MonitorMemoryUsage := FDAPMemMonitoring;
end; // TDAP_Inspector.SetDapMemMonitoring

function TDAP_Inspector.GetDAPMemMonitoring : Boolean;
begin
  if Assigned(FDAPQuery) then
    Result := FDAPQuery.MonitorMemoryUsage
  else
    Result := FDAPMemMonitoring;
end; // TDAP_Inspector.GetDAPMemMonitoring

procedure TDAP_Inspector.SetPollDapMemUsageInterval(Value : DWord);
begin
  FDAPMemPollingInterval := Value;
  if Assigned(FDAPQuery) then
    FDAPQuery.MemUsageReadDelay := FDAPMemPollingInterval;
end; // TDAP_Inspector.SetPollDapMemUsageInterval

function TDAP_Inspector.GetPollDAPMemUsageInterval : DWord;
begin
  if Assigned(FDAPQuery) then
    Result := FDAPQuery.MemUsageReadDelay
  else
    Result := FDAPMemPollingInterval;
end; // TDAP_Inspector.GetPollDAPMemUsageInterval

procedure TDAP_Inspector.SetMemWarningLevel(Value : Single);
begin
  FDAPMemWarningLevel := Value;
  if AssigneD(FDAPQuery) then
    FDAPQuery.MemLowWarningLevel := Value;
end; // TDAP_Inspector.SetMemWarningLevel

function TDAP_Inspector.GetMemWarningLevel : Single;
begin
  if Assigned(FDAPQuery) then
    Result := FDAPQuery.MemLowWarningLevel
  else
    Result := FDAPMemWarningLevel;
end; // TDAP_Inspector.GetMemWarningLevel

procedure TDAP_Inspector.DapMemFreeEvent(Sender : TObject; MemFree : DWord);
begin
  if Assigned(FDapMemFree) then
    FDapMemFree(Self,MemFree);
end; // TDAP_Inspector.DapMemFreeEvent;

procedure TDAP_Inspector.DapMemWarningEvent(Sender : TObject);
begin
  if Assigned(FDapMemWarning) then
    FDapMemWarning(Self);
end; // TDAP_Inspector.DapMemWarningEvent

procedure TDAP_Inspector.ServerQueryError(Sender : TObject; ErrorMsg : String);
begin
  if Assigned(FServerQueryError) then
    FServerQueryError(Self,ErrorMsg);
end; // TDAP_Inspector.ServerQueryError

procedure TDAP_Inspector.DAPQueryError(Sender : TObject; ErrorMsg : String);
begin
  if Assigned(FDAPQueryError) then
    FDAPQueryError(Self,ErrorMsg);
end; // TDAP_Inspector.DAPQueryError

end.
