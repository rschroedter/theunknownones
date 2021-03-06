unit uch2Main;

interface

uses
  Classes,
  SysUtils,
  StrUtils,
  HelpIntfs,
  Windows,
  Menus,
  Dialogs,
  Registry,
  ToolsAPI,
  uTUOCommonIntf,
  ComCtrls,
  ShellAPI,
  Controls,
  Graphics,
  ExtCtrls,
  Forms;

{$I ..\..\Common\Jedi\Jedi.inc}

type
  Tch2HelpItemFlag = (ifSaveStats,
                      ifProvidesHelp);
  Tch2HelpItemFlags = set of Tch2HelpItemFlag;

  Tch2HelpItemDecoration = record
    TextColor,
    BackColor : TColor;
    FontStyles : TFontStyles;

    procedure SaveToRegistry(ARegistry : TRegistry; AKey : String = '');
    procedure LoadFromRegistry(ARegistry : TRegistry; AKey : String = '');
  end;
  Pch2HelpItemDecoration = ^Tch2HelpItemDecoration;

  Ich2HelpItem = interface
    ['{D64EBC33-3A57-48F0-BA6E-E9770507A770}']
    function GetGUID : TGUID; //used to store stats (expanded, position, ...)
    function GetCaption : String;
    function GetDescription : String;
    function GetDecoration : Tch2HelpItemDecoration;
    function GetFlags : Tch2HelpItemFlags;
    function GetPriority : Integer;
    procedure ShowHelp;
  end;

  Ich2GUI = interface
    ['{99A8E48B-A998-42D7-A7C0-DC444BEC2467}']
    function GetName : String;
    function GetDescription : String;
    function GetGUID : TGUID;

    procedure Show(const AHelpString : String; const Ach2Keywords : TStringList);

    function AddHelpItem(AHelpItem : Ich2HelpItem; AParent : Pointer = nil) : Pointer;
  end;

  Ich2Provider = interface
    ['{AA0B05F4-53E5-4CCD-8566-055B6AF0D24D}']
    function GetGUID : TGUID;
    function GetDescription : String;
    function GetName : String;

    procedure ProvideHelp(AKeyword : String; AGUI : Ich2GUI);
    procedure Configure;

    function GetPriority : Integer;
    procedure SetPriority(ANewPriority : Integer);
  end;

  Ich2HelpViewer = interface(ICustomHelpViewer)
    ['{8E664AF2-D423-4F97-B2E1-4E3F43468B05}']
    function GetID: Integer;
    property ID : Integer read GetID;
  end;

  Tch2HelpViewer = class(TInterfacedObject, ICustomHelpViewer, Ich2HelpViewer)
  private
    FID : Integer;
  public
    {$REGION 'Ich2HelpViewer'}
    function GetID: Integer;
    {$ENDREGION}
    {$REGION 'ICustomHelpViewer'}
    function  GetViewerName: string;
    function  UnderstandsKeyword(const HelpString: string): Integer;
    function  GetHelpStrings(const HelpString: string): TStringList;
    function  CanShowTableOfContents : Boolean;
    procedure ShowTableOfContents;
    procedure ShowHelp(const HelpString: string);
    procedure NotifyID(const ViewerID: Integer);
    procedure SoftShutDown;
    procedure ShutDown;
    {$ENDREGION}
  public
    destructor Destroy; override;
    property ID : Integer read FID;
  end;

  Tch2URLOpenLocation = (olWelcomePage,
                         olMSDocExplorer,
                         olDefaultBrowser);

  Tch2HelpSelector = class(TInterfacedObject, IHelpSelector, IHelpSelector2)
  public
    {$REGION 'IHelpSelector'}
    function SelectKeyword(Keywords: TStrings) : Integer;
    function TableOfContents(Contents: TStrings): Integer;
    {$ENDREGION}

    {$REGION 'IHelpSelector2'}
    function SelectContext(Viewers: TStrings): Integer;
    {$ENDREGION}
  end;

  {$IFNDEF DELPHI2009_UP}
  IInterfaceListEx = interface(IInterfaceList)
    ['{FDB39D70-65B9-4995-9436-6084ACA05DB3}']
    function GetEnumerator: TInterfaceListEnumerator;
  end;

  TInterfaceList = class(Classes.TInterfaceList, IInterfaceListEx)
  end;
  {$ENDIF}

  Tch2Main = class
  private
    FHelpViewer : Ich2HelpViewer;
    FHelpManager : IHelpManager;

    FMenuItemConfig : TMenuItem;
    FProviders: IInterfaceListEx;
    FKeywords: TStringList;
    FHelpString: String;

    FCurrentGUIGUID : String;
    FCurrentGUI : Ich2GUI;
    FGUIs: IInterfaceListEx;

    FWPTimer : TTimer;
    FWPURL : String;

    procedure OnWPTimer(Sender : TObject);

    procedure AttachToIDE;
    procedure DetachFromIDE;

    procedure AddKeyword(AKeyword : String);

    procedure OnConfigure(Sender : TObject);

    procedure LoadSettings;
    procedure SaveSettings;

    function GetRegRootKey: String;
    function GetGUI(AIndex: Integer): Ich2GUI;
    function GetProvider(AIndex: Integer): Ich2Provider;
    function GetCurrentGUI: Ich2GUI;
    function GetRegRootKeyProvider(AGUID : TGUID): String;
    function GetRegRootKeyGUI(AGUID : TGUID): String;
    procedure SetCurrentGUI(const Value: Ich2GUI);

    procedure QuickSortProviderList(ALeft, ARight : Integer);
    procedure SortProviderList;

    function GetNextFreePriority(ACurrentPriority : Integer) : Integer;
  public
    constructor Create();
    destructor Destroy; override;

    procedure ShowInWelcomePage(AURL : String);
    procedure ShellOpen(APath : String); overload;
    procedure ShellOpen(APath : String; AParams : String); overload;
    procedure ShowInMSDocExplorer(AURL : String);
    procedure ShowURL(AURL : String; ALocation : Tch2URLOpenLocation);

    procedure ShowHelp;

    procedure RegisterGUI(const AGUI : Ich2GUI);
    procedure RegisterProvider(const AProvider : Ich2Provider);

    property HelpViewer : Ich2HelpViewer read FHelpViewer;
    property HelpManager : IHelpManager read FHelpManager;

    property RegRootKey : String read GetRegRootKey;
    property RegRootKeyProvider[AGUID : TGUID] : String read GetRegRootKeyProvider;
    property RegRootKeyGUI[AGUID : TGUID] : String read GetRegRootKeyGUI;

    property Providers : IInterfaceListEx read FProviders;
    property Provider[AIndex : Integer] : Ich2Provider read GetProvider;
    property GUIs : IInterfaceListEx read FGUIs;
    property GUI[AIndex : Integer] : Ich2GUI read GetGUI;

    property CurrentGUI : Ich2GUI read GetCurrentGUI write SetCurrentGUI;
  end;

function ch2Main : Tch2Main;

const
  CH2HelpViewerName = 'CustomHelp2Viewer (TUO)';

  ch2URLOpenLocationTexts : array[Tch2URLOpenLocation] of String =
                            ('Delphi''s WelcomPage',
                             'MS Document Explorer',
                             'Systems Default Browser');

implementation

uses uch2GUIDefault,
     uch2Configure,
     WebBrowserEx,
     ActnList;

const
  HelpKeywordGUID = '{9451A4D8-A0C8-451D-ADE1-4B79CD82CAA6}';

  Settings_Value_CurrentGUI = 'CurrentGUI';

  Settings_Value_HelpItemDecoration = 'Decoration';

var
  Fch2Main : Tch2Main;

function ch2Main : Tch2Main;
begin
  if not Assigned(Fch2Main) then
    Fch2Main := Tch2Main.Create;

  Result := Fch2Main;
end;

{$R Images.res}

var
  bmp: TBitmap;

procedure AddSplashBitmap;
begin
  bmp := TBitmap.Create;
  bmp.LoadFromResourceName(hinstance, 'Splash');
  SplashScreenServices.AddPluginBitmap(
    'Custom Help 2',
    bmp.Handle,
    False,
    'Free and OpenSource',
    'by TheUnknownOnes');
end;

type
  IURLModule = interface
    ['{9D215B02-6073-45DC-B007-1A2DBCE2D693}']
    procedure Close;
    function GetURL: string;                             // tested
    procedure SetURL(const AURL: string);                // tested
    procedure SourceActivated;
    function GetWindowClosingEvent: TWindowClosingEvent; // WARNING!!! do NOT CALL!!!
    procedure Proc1;
    procedure Proc2;
    procedure Proc3;
    procedure Proc4;
    procedure Proc5;
    property URL: string read GetURL write SetURL;
  end;

  IDocModule = interface
    ['{60AE6F18-62AD-4E39-A999-29504CF2632A}']
    procedure AddToProject;
    function GetFileName: string;
    procedure GetIsModified;
    function GetModuleName: string;
    procedure Save;
    procedure Show;  // doesn't seem to work properly...
    procedure ShowEditor(Visible: Boolean; const Filename: string);
    procedure GetProjectCount;
    procedure GetProject;
    procedure GetActiveProject;
    property Filename: string read GetFilename;
    property ModuleName: string read GetModuleName;
  end;

{ Tch2HelpViewer }

function Tch2HelpViewer.CanShowTableOfContents: Boolean;
begin
  Result := false;
end;

destructor Tch2HelpViewer.Destroy;
begin
  inherited;
end;

function Tch2HelpViewer.GetHelpStrings(const HelpString: string): TStringList;
begin
  Result := TStringList.Create;
  Result.Add(HelpKeywordGUID);
end;

function Tch2HelpViewer.GetID: Integer;
begin
  Result:=FID;
end;

function Tch2HelpViewer.GetViewerName: string;
begin
  Result := CH2HelpViewerName;
end;

procedure Tch2HelpViewer.NotifyID(const ViewerID: Integer);
begin
  FID := ViewerID;
end;

procedure Tch2HelpViewer.ShowHelp(const HelpString: string);
begin
  ch2Main.ShowHelp;
end;

procedure Tch2HelpViewer.ShowTableOfContents;
begin
end;

procedure Tch2HelpViewer.ShutDown;
begin

end;

procedure Tch2HelpViewer.SoftShutDown;
begin

end;

function Tch2HelpViewer.UnderstandsKeyword(const HelpString: string): Integer;
var
  hs : IHelpSystem;
  Editor : IOTAEditor;
  SourceEditor : IOTASourceEditor70;
  EditView : IOTAEditView;
  s : String;
begin
  Result := 1;

  ch2Main.FHelpString := HelpString;
  
  ch2Main.FKeywords.Clear;
  ch2Main.AddKeyword(HelpString);

  if Assigned((BorlandIDEServices as IOTAModuleServices).CurrentModule) then
  begin
    Editor:=(BorlandIDEServices as IOTAModuleServices).CurrentModule.CurrentEditor;

    if Supports(Editor, IOTASourceEditor70, SourceEditor) then
    begin
      EditView:=SourceEditor.EditViews[0];
      
      s := EditView.Position.RipText(['_','.'],rfBackward or rfIncludeAlphaChars or rfIncludeNumericChars)+
           EditView.Position.RipText(['_','.'],rfIncludeAlphaChars or rfIncludeNumericChars);

      ch2Main.AddKeyword(s);
    end;
  end;

  if GetHelpSystem(hs) then
  begin
    hs.AssignHelpSelector(nil);
    hs.AssignHelpSelector(Tch2HelpSelector.Create as IHelpSelector2);
  end;
end;

{ Tch2Main }

procedure Tch2Main.AddKeyword(AKeyword: String);
var
  slSplit : TStringList;
  idx : Integer;
  cls : TClass;
  clsname : String;

  function WordsFromSplitList(ACount : Integer; AReverse : Boolean) : String;
  var
    idxWord : Integer;
  begin
    Result := '';

    if not AReverse then
    begin
      for idxWord := 0 to ACount - 1 do
      begin
        if idxWord > 0 then
          Result := Result + slSplit.Delimiter;
        Result := Result + slSplit[idxWord];
      end;
    end
    else
    begin
      for idxWord := 1 to ACount do
      begin
        if idxWord > 1 then
          Result := slSplit.Delimiter + Result;
        Result := slSplit[slSplit.Count - idxWord] + Result;
      end;
    end;
  end;

  procedure AddSplitContent;
  var
    idxSplit : Integer;
  begin
    for idxSplit := 1 to slSplit.Count do
      FKeywords.Add(WordsFromSplitList(idxSplit, false));

    for idxSplit := 1 to slSplit.Count do
      FKeywords.Add(WordsFromSplitList(idxSplit, true));

    for idxSplit := 0 to slSplit.Count - 1 do
      FKeywords.Add(slSplit[idxSplit]);
  end;
begin
  AKeyword := Trim(AKeyword);
  if AKeyword = EmptyStr then
    exit;

  slSplit := TStringList.Create;
  try
    slSplit.Delimiter := '.';
    slSplit.StrictDelimiter := true;

    slSplit.DelimitedText := AKeyword;
    AddSplitContent;
  finally
    slSplit.Free;
  end;

  for idx := 0 to FKeywords.Count - 1 do
  begin
    cls := GetClass(FKeywords[idx]);
    while Assigned(cls) do
    begin
      clsname := cls.ClassName;
      if FKeywords.IndexOf(clsname) = -1 then
        AddKeyword(clsname);
      cls := cls.ClassParent;
    end;
  end;
end;

procedure Tch2Main.AttachToIDE;
begin
  FMenuItemConfig := TMenuItem.Create(nil);
  FMenuItemConfig.Caption := 'Configure CustomHelp2';
  FMenuItemConfig.OnClick := OnConfigure;

  with GetTUOCommon do
  begin
    ToolsMenuItem.Add(FMenuItemConfig);
  end;
end;

constructor Tch2Main.Create;
begin
  Fch2Main := Self;

  FKeywords := TStringList.Create;
  FKeywords.Sorted := true;
  FKeywords.Duplicates := dupIgnore;
  FKeywords.CaseSensitive := false;

  FHelpViewer := Tch2HelpViewer.Create;

  RegisterViewer(FHelpViewer, FHelpManager);

  AttachToIDE;

  FProviders := TInterfaceList.Create;
  FGUIs := TInterfaceList.Create;

  LoadSettings;

  FWPTimer := TTimer.Create(nil);
  FWPTimer.Enabled := false;
  FWPTimer.Interval := 100;
  FWPTimer.OnTimer := OnWPTimer;
end;

destructor Tch2Main.Destroy;
var
  hs : IHelpSystem;
begin
  HelpManager.Release(FHelpViewer.ID);

  DetachFromIDE;

  SaveSettings;

  FKeywords.Free;

  inherited;
end;

procedure Tch2Main.DetachFromIDE;
begin
  FMenuItemConfig.Free;
end;

function Tch2Main.GetCurrentGUI: Ich2GUI;
begin
  if not Assigned(FCurrentGUI) then
  begin
    if FGUIs.Count = 0 then
      raise Exception.Create('No CustomHelp2-GUI available')
    else
      FCurrentGUI := GUI[0];
  end;

  Result := FCurrentGUI;
end;

function Tch2Main.GetGUI(AIndex: Integer): Ich2GUI;
begin
  if not Supports(FGUIs[AIndex], Ich2GUI, Result) then
    Result := nil;
end;

function Tch2Main.GetNextFreePriority(ACurrentPriority : Integer): Integer;

  function PriorityInUse(APriority : Integer) : Boolean;
  var
    P : IInterface;
    Prov : Ich2Provider absolute p;
  begin
    Result := false;

    for p in FProviders do
    begin
      Result := Prov.GetPriority = APriority;

      if Result then
        break;
    end;
  end;

begin
  for Result := ACurrentPriority to MaxInt do
  begin
    if not PriorityInUse(Result) then
      break;
  end;
end;

function Tch2Main.GetProvider(AIndex: Integer): Ich2Provider;
begin
  if not Supports(FProviders[AIndex], Ich2Provider, Result) then
    Result := nil;
end;

function Tch2Main.GetRegRootKey: String;
begin
  Result := GetTUOCommon.RegistryRootKey + '\CustomHelp2';
end;

function Tch2Main.GetRegRootKeyGUI(AGUID : TGUID): String;
begin
  Result := RegRootKey + '\GUI\' + GUIDToString(AGUID);
end;

function Tch2Main.GetRegRootKeyProvider(AGUID : TGUID): String;
begin
  Result := RegRootKey + '\Provider\' + GUIDToString(AGUID);
end;

procedure Tch2Main.SortProviderList();
begin
  if FProviders.Count > 1 then
    QuickSortProviderList(0, FProviders.Count - 1);
end;

procedure Tch2Main.LoadSettings;
var
  Reg : TRegistry;
begin
  Reg := TRegistry.Create(KEY_ALL_ACCESS);
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    if Reg.OpenKey(RegRootKey, true) then
    begin
      if Reg.ValueExists(Settings_Value_CurrentGUI) then
        FCurrentGUIGUID := Reg.ReadString(Settings_Value_CurrentGUI)
      else
        FCurrentGUIGUID := EmptyStr;
      Reg.CloseKey;
    end;

  finally
    Reg.Free;
  end;
end;

procedure Tch2Main.OnConfigure(Sender: TObject);
begin
  if Tch2FormConfigure.Execute then
    SaveSettings;

  SortProviderList;
end;

procedure Tch2Main.OnWPTimer(Sender: TObject);

  function HasWP : Boolean;
  begin
    Result := (GetModuleHandle('startpageide100.bpl') > 0) or
              (GetModuleHandle('startpageide120.bpl') > 0) or
              (GetModuleHandle('startpageide140.bpl') > 0);
  end;

  procedure ShowWP;
  var
    IDEService: INTAServices;
    actList:    TCustomActionList;
    idx:        Integer;
    act:        TContainedAction;
  begin
    IDEService := (BorlandIDEServices as INTAServices);
    actList    := IDEService.ActionList;

    for idx := 0 to actList.ActionCount - 1 do
    begin
      act := actList.Actions[idx];

      if act.Name = 'ViewWelcomePageCommand' then
        act.Execute;
    end;
  end;

var
  ModuleServices: IOTAModuleServices;
  Module:    IOTAModule;
  I:         Integer;
  mIdx:      Integer;
  URLModule: IURLModule;
  DocModule: IDocModule;
begin
  FWPTimer.Enabled := False;
  ShowWP;

  mIdx           := -1;
  ModuleServices := BorlandIDEServices as IOTAModuleServices;
  for I := 0 to ModuleServices.ModuleCount - 1 do
  begin
    Module := ModuleServices.Modules[I];
    if Supports(Module, IURLModule, URLModule) then
    begin
      if Supports(Module, IDocModule, DocModule) then
      begin
        URLModule.URL := FWPURL;
        mIdx          := i;
        Break;
      end;
    end;
  end;

  if (mIdx > -1) and (mIdx < ModuleServices.ModuleCount) then
    ModuleServices.Modules[mIdx].Show;
end;


procedure Tch2Main.QuickSortProviderList(ALeft, ARight: Integer);
var
   Lo, Hi : Integer;
   Pivot : Ich2Provider;
 begin
   Lo := ALeft;
   Hi := ARight;

   Pivot := Provider[(Lo + Hi) div 2];
   repeat
     while Provider[Lo].GetPriority > Pivot.GetPriority do
      Inc(Lo);
     while Provider[Hi].GetPriority < Pivot.GetPriority do
      Dec(Hi);

     if Lo <= Hi then
     begin
       FProviders.Exchange(Lo, Hi);
       Inc(Lo) ;
       Dec(Hi) ;
     end;
   until Lo > Hi;

   if Hi > ALeft then QuickSortProviderList(ALeft, Hi) ;
   if Lo < ARight then QuickSortProviderList(Lo, ARight) ;
 end;


procedure Tch2Main.RegisterGUI(const AGUI: Ich2GUI);
begin
  GUIs.Add(AGUI);

  if SameText(FCurrentGUIGUID, GUIDToString(AGUI.GetGUID)) then
    FCurrentGUI := AGUI;
end;

procedure Tch2Main.RegisterProvider(const AProvider: Ich2Provider);
begin
  AProvider.SetPriority(GetNextFreePriority(AProvider.GetPriority));
  Providers.Add(AProvider);
  SortProviderList;
end;

procedure Tch2Main.SaveSettings;
var
  Reg : TRegistry;
begin
  Reg := TRegistry.Create(KEY_ALL_ACCESS);
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    if Reg.OpenKey(RegRootKey, true) then
    begin
      Reg.WriteString(Settings_Value_CurrentGUI, FCurrentGUIGUID);

      Reg.CloseKey;
    end;

  finally
    Reg.Free;
  end;
end;

procedure Tch2Main.SetCurrentGUI(const Value: Ich2GUI);
begin
  FCurrentGUIGUID := GUIDToString(Value.GetGUID);
  FCurrentGUI := Value;
end;

procedure Tch2Main.ShellOpen(APath: String);
begin
  ShellOpen(APath, '');
end;

procedure Tch2Main.ShellOpen(APath, AParams: String);
begin
  ShellExecute(0, 'open', Pchar(APath), PChar(AParams), nil, SW_SHOW);
end;

procedure Tch2Main.ShowHelp;
var
  idx : Integer;
begin
  idx := FKeywords.IndexOf(HelpKeywordGUID);
  if idx > -1 then
    FKeywords.Delete(idx);

  CurrentGUI.Show(FHelpString, FKeywords);
end;

procedure Tch2Main.ShowInMSDocExplorer(AURL: String);
var
  hs : IHelpSystem;
begin
  if GetHelpSystem(hs) then
    hs.ShowTopicHelp(AURL, '');
end;

procedure Tch2Main.ShowInWelcomePage(AURL: String);
begin
  FWPURL := AURL;
  FWPTimer.Enabled := true;
end;

procedure Tch2Main.ShowURL(AURL: String; ALocation: Tch2URLOpenLocation);
begin
  case ALocation of
    olWelcomePage: ShowInWelcomePage(AURL);
    olMSDocExplorer: ShowInMSDocExplorer(AURL);
    olDefaultBrowser: ShellOpen(AURL);
  end;
end;

{ Tch2HelpSelector }

function Tch2HelpSelector.SelectContext(Viewers: TStrings): Integer;
begin
  Result := Viewers.IndexOf(CH2HelpViewerName);
end;

function Tch2HelpSelector.SelectKeyword(Keywords: TStrings): Integer;
begin
  Result := Keywords.IndexOf(HelpKeywordGUID);
end;

function Tch2HelpSelector.TableOfContents(Contents: TStrings): Integer;
begin
  Result := 0;
end;

{ Tch2HelpItemDecoration }

procedure Tch2HelpItemDecoration.LoadFromRegistry(ARegistry: TRegistry;
  AKey: String);
var
  OpenCloseKey : Boolean;
begin
  OpenCloseKey := AKey <> '';
  try
    if OpenCloseKey then
      ARegistry.OpenKey(AKey, true);

    if ARegistry.ValueExists(Settings_Value_HelpItemDecoration) then
      ARegistry.ReadBinaryData(Settings_Value_HelpItemDecoration, Self, SizeOf(Self))
    else
    begin
      FontStyles := [];
      TextColor := clDefault;
      BackColor := clDefault;
    end;

  finally
    if OpenCloseKey then
      ARegistry.CloseKey;
  end;
end;

procedure Tch2HelpItemDecoration.SaveToRegistry(ARegistry: TRegistry;
  AKey: String);
var
  OpenCloseKey : Boolean;
begin
  OpenCloseKey := AKey <> '';
  try
    if OpenCloseKey then
      ARegistry.OpenKey(AKey, true);

    ARegistry.WriteBinaryData(Settings_Value_HelpItemDecoration, Self, SizeOf(Self));

  finally
    if OpenCloseKey then
      ARegistry.CloseKey;
  end;
end;

initialization
  AddSplashBitmap;

finalization
  ch2Main.Free;

  if Assigned(bmp) then
    bmp.Free;

end.
