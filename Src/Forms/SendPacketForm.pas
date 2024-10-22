unit SendPacketForm;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, IdHTTP, IdSSLOpenSSL,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls;
type
  TfrmSendPacket = class(TForm)
    memPacket: TMemo;
    edtNick: TEdit;
    btnSendPacket: TButton;
    lblPacket: TLabel;
    Label1: TLabel;
    btncloseserver: TButton;
    edtClientID: TEdit;
    Label2: TLabel;
    btnSendByClientID: TButton;
    gbServerOperation: TGroupBox;
    btnSendMsg: TButton;
    edtMsg: TEdit;
    Label3: TLabel;
    btnResetServer: TButton;
    btnClearMsg: TButton;
    cbServerInfo: TGroupBox;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lblCpu: TLabel;
    lblRam: TLabel;
    lblActivePlayers: TLabel;
    TimerServerInfo: TTimer;
    GroupBox1: TGroupBox;
    Label7: TLabel;
    lblChannels: TLabel;
    PgControladora: TPageControl;
    Server: TTabSheet;
    accCreate: TTabSheet;
    GroupBox2: TGroupBox;
    lblUsuario: TLabel;
    lblSenha: TLabel;
    lblTupoConta: TLabel;
    edtNewUsername: TEdit;
    edtNewPassword: TEdit;
    btnCreateAccount: TButton;
    cbTypeAccount: TComboBox;
    dbSendItem: TTabSheet;
    GroupBoxItemSend: TGroupBox;
    lblPlayerID: TLabel;
    edtPlayerID: TEdit;
    lblItemID: TLabel;
    edtItemID: TEdit;
    lblAmount: TLabel;
    edtAmount: TEdit;
    btnSendItem: TButton;
    GroupBoxBDI: TGroupBox;
    btnBuscarItem: TButton;
    edtBuscarItem: TEdit;
    lvItens: TListView;
    gbPacket: TGroupBox;
    gbUserOn: TGroupBox;
    lvPlayersOnline: TListView;
    btnAtualizarPlayers: TButton;
    procedure btnSendPacketClick(Sender: TObject);
    procedure btncloseserverClick(Sender: TObject);
    procedure btnSendByClientIDClick(Sender: TObject);
    procedure btnSendMsgClick(Sender: TObject);
    procedure btnResetServerClick(Sender: TObject);
    procedure btnClearMsgClick(Sender: TObject);
    procedure TimerServerInfoTimer(Sender: TObject);
    procedure btnCreateAccountClick(Sender: TObject);
    procedure btnSendItemClick(Sender: TObject);
    procedure btnBuscarItemClick(Sender: TObject);
    procedure lvItensDblClick(Sender: TObject);
    procedure btnAtualizarPlayersClick(Sender: TObject);
  private
    procedure lvPlayersOnlineDblClick(Sender: TObject);
    { Private declarations }
  public
    { Public declarations }
    procedure UpdateCaption(Content: String);
  end;
var
  frmSendPacket: TfrmSendPacket;
implementation
{$R *.dfm}
uses
  GlobalDefs, Functions, Packets, Log, Player, PlayerData, Load, PacketHandlers,
  ItemFunctions, FilesData ;
type
  TByteArray = record
    Content: ARRAY OF BYTE;
  end;

{$REGION 'Envio Msg'}
procedure TfrmSendPacket.UpdateCaption(Content: String);
begin
  Self.Caption := Content;
end;


procedure TfrmSendPacket.btnClearMsgClick(Sender: TObject);
begin
  edtMsg.Text := '';
end;

procedure TfrmSendPacket.btnSendMsgClick(Sender: TObject);
var
  i: Integer;
begin
  if (edtMsg.Text = '') then
  begin
    MessageBox(0, 'Você não pode deixar o campo mensagem em branco', 'Erro', 0);
    Exit;
  end;
  for i := Low(Servers) to High(Servers) do
  begin
    Servers[i].SendServerMsg(AnsiString('[SERVER] ' + edtMsg.Text), 32, 16);
  end;
end;

{$ENDREGION}

{$REGION 'Resete e Fechamento'}
procedure TfrmSendPacket.btncloseserverClick(Sender: TObject);
var
  i: Integer;
begin
  Logger.Write('Fechando o servidor, aguarde...', TLogType.ConnectionsTraffic);
  try
    TFunctions.SaveGuilds;
  except
  end;
  try
    for i := Low(Nations) to High(Nations) do
    begin
      Nations[i].SaveNation;
    end;
  except
  end;
  for i := Low(Servers) to High(Servers) do
  begin
    Servers[i].CloseServer;
  end;
  xServerClosed := True;
  Logger.Write('Server Closed Succesfully!', TLogType.ServerStatus);
  Logger.Write('Feche a janela deste console. Tudo foi salvo!',
    TLogType.ConnectionsTraffic);
  ServerHasClosed := True;
  {while(StrToInt(Self.lblActivePlayers.Caption) > 0) do
    Sleep(10);
  Application.Terminate;
  keybd_event(VK_CONTROL, 0, 0, 0);
  keybd_event(Ord('C'), 0, 0, 0);
  keybd_event(Ord('C'), 0, KEYEVENTF_KEYUP, 0);
  keybd_event(VK_CONTROL, 0, KEYEVENTF_KEYUP, 0);}
  //Self.Close;
end;

procedure TfrmSendPacket.btnResetServerClick(Sender: TObject);
var
  i: Integer;
begin
  Logger.Write('Resetando o servidor, aguarde...', TLogType.ConnectionsTraffic);
  InstantiatedChannels := 0;
  TFunctions.SaveGuilds;
  for i := Low(Nations) to High(Nations) do
  begin
    Nations[i].SaveNation;
  end;
  for i := Low(Servers) to High(Servers) do
  begin
    Servers[i].CloseServer;
  end;
  Logger.Write('Server Closed Succesfully!', TLogType.ConnectionsTraffic);
  TLoad.InitServers;
  Logger.Write('O servidor foi reiniciado com sucesso.',
    TLogType.ConnectionsTraffic);
end;

procedure TfrmSendPacket.TimerServerInfoTimer(Sender: TObject);
var
  Ram, Ram2, ActivePlayers, ActivePlayersIsolated: Integer;
  Cpu: Single;
  i, j, k: Integer;
begin
  Cpu := TFunctions.GetCPUUsage;
  //Ram := Round(TFunctions.GetMemoryUsed / (1048576));
  //Ram := TFunctions.GetMemoryUsed;
  ActivePlayers:= 0;
  Ram := 0;
  for I := Low(Servers) to High(Servers) do
  begin
    ActivePlayersIsolated := 0;
    for j := Low(Servers[i].Players) to High(Servers[i].Players) do
    begin
      if(Servers[i].Players[j].Status >= CharList) then
      begin
        inc(ActivePlayers);
        inc(ActivePlayersIsolated);
      end;
    end;
    Servers[i].ActiveReliquaresOnTemples := 0;
    for j := Low(Servers[i].Devires) to High(Servers[i].Devires) do
    begin
      if(Servers[i].Devires[j].DevirId = 0) then
        Continue;

      for k := 0 to 4 do
      begin
        if(Servers[i].Devires[j].Slots[k].ItemID > 0) then
          Inc(Servers[i].ActiveReliquaresOnTemples, 1);
      end;
    end;

    Servers[i].ActivePlayersNowHere := ActivePlayersIsolated;
    Ram := Ram + 630;
  end;
  ActivePlayersNow := ActivePlayers;
  Self.lblCpu.Font.Size := 8;
  case Round(Cpu) of
    0 .. 20:
      Self.lblCpu.Font.Color := clLime;
    21 .. 40:
      Self.lblCpu.Font.Color := clYellow;
    41 .. 60:
      Self.lblCpu.Font.Color := clMaroon;
    61 .. 80:
      Self.lblCpu.Font.Color := clRed;
    81 .. 100:
      begin
        Self.lblCpu.Font.Color := clRed;
        Self.lblCpu.Font.Size := 10;
      end;
  end;
  Ram2 := Round(Ram / 10);
  Self.lblRam.Font.Size := 8;
  case Ram2 of
    0 .. 50:
      Self.lblRam.Font.Color := clLime;
    51 .. 100:
      Self.lblRam.Font.Color := clYellow;
    101 .. 150:
      Self.lblRam.Font.Color := clRed;
  else
    begin
      Self.lblRam.Font.Color := clRed;
      Self.lblRam.Font.Size := 10;
    end;
  end;
  Self.lblCpu.Caption := FormatFloat('0.00 %', Cpu);
  Self.lblRam.Caption := FormatFloat('0.0 MB', Ram);
  Self.lblActivePlayers.Font.Color := clWhite;
  Self.lblChannels.Font.Color := clWhite;
  Self.lblActivePlayers.Caption := ActivePlayers.ToString;
  Self.lblChannels.Caption := InstantiatedChannels.ToString;
end;

{$ENDREGION}

{$REGION 'Pacotes'}

procedure TfrmSendPacket.btnSendByClientIDClick(Sender: TObject);
var
  i: Integer;
  Len: Integer;
  Buffer: ARRAY [0 .. 8091] OF BYTE;
  MPlayer: PPlayer;
begin
  ZeroMemory(@Buffer, 8092);
  if (memPacket.Text <= '') or (edtClientID.Text <= '') then
    Exit;
  for i := 0 to Length(Servers) - 1 do
  begin
    MPlayer := Servers[i].GetPlayer(StrToInt(edtClientID.Text));
    if (MPlayer.Status >= Playing) then
    begin
      Len := TFunctions.StrToArray(memPacket.Text, Buffer);
      if Len > 1 then
        Servers[i].Players[MPlayer.Base.ClientId].SendPacket(Buffer, Len);
      Break;
    end;
  end;
end;


procedure TfrmSendPacket.btnSendPacketClick(Sender: TObject);
var
  i: Integer;
  ClientId: Integer;
  Len: Integer;
  Buffer: ARRAY [0 .. 8091] OF BYTE;
begin
  ZeroMemory(@Buffer, 8092);
  if (memPacket.Text <= '') or (edtNick.Text <= '') then
    Exit;
  for i := 0 to Length(Servers) - 1 do
  begin
    ClientId := Servers[i].GetPlayerByName(edtNick.Text);
    if ClientId > 0 then
    begin
      Len := TFunctions.StrToArray(memPacket.Text, Buffer);
      if Len > 1 then
        Servers[i].Players[ClientId].SendPacket(Buffer, Len);
      Break;
    end;
  end;
end;

{$ENDREGION}

{$REGION 'Banco de Dados Itens'}
procedure TfrmSendPacket.btnSendItemClick(Sender: TObject);
var
  PlayerID, ItemID, Amount: Integer;
  Player: PPlayer;
  i: Integer;
begin
  // Validação dos campos
  if (edtPlayerID.Text = '') or (edtItemID.Text = '') or (edtAmount.Text = '') then
  begin
    ShowMessage('Por favor, preencha todos os campos.');
    Exit;
  end;

  try
    PlayerID := StrToInt(edtPlayerID.Text);
    ItemID := StrToInt(edtItemID.Text);
    Amount := StrToInt(edtAmount.Text);

    // Validação adicional para quantidades válidas
    if Amount <= 0 then
    begin
      ShowMessage('A quantidade deve ser maior que zero.');
      Exit;
    end;

    // Localizando o jogador pelo PlayerID
    Player := nil;
    for i := Low(Servers) to High(Servers) do
    begin
      Player := Servers[i].GetPlayer(PlayerID);
      if Player <> nil then
        Break;
    end;

    // Se o jogador não for encontrado
    if Player = nil then
    begin
      ShowMessage('Jogador não encontrado. Verifique o ID e tente novamente.');
      Exit;
    end;

    // Verificando se o item é permitido (conforme o exemplo das outras funções)
    {case ItemID of
      20051, 20052, 20053, 20054:
      begin
        ShowMessage('Item banido. Não é possível enviar este item.');
        Exit;
      end;
    end;}

    // Adicionando o item ao jogador diretamente
    TItemFunctions.PutItem(Player^, ItemID, Amount);

    ShowMessage('Item enviado com sucesso!');
  except
    on E: Exception do
    begin
      ShowMessage('Erro ao processar os dados: ' + E.Message);
    end;
  end;
end;

procedure TfrmSendPacket.lvItensDblClick(Sender: TObject);
var
  ItemSelecionado: TListItem;
begin
  if lvItens.Selected = nil then
    Exit;

  ItemSelecionado := lvItens.Selected;

  // Passa o ID do item selecionado para o campo edtItemID
  edtItemID.Text := ItemSelecionado.Caption;
end;




procedure TfrmSendPacket.btnBuscarItemClick(Sender: TObject);
var
  i: Integer;
  NomeBusca: string;
  Item: TItemFromList;
  ListItem: TListItem;
begin
  NomeBusca := Trim(edtBuscarItem.Text);
  lvItens.Items.Clear;

  if NomeBusca.IsEmpty then
  begin
    ShowMessage('Por favor, digite um nome para buscar.');
    Exit;
  end;

  // Itera sobre a lista de itens e adiciona itens que correspondem ao nome de busca
  for i := Low(ItemList) to High(ItemList) do
  begin
    Item := ItemList[i];
    if Pos(UpperCase(NomeBusca), UpperCase(String(Item.Name))) > 0 then
    begin
      ListItem := lvItens.Items.Add;
      ListItem.Caption := IntToStr(i); // ID do item
      ListItem.SubItems.Add(String(Item.Name));
      ListItem.SubItems.Add(String(Item.Descrition));
    end;
  end;

  if lvItens.Items.Count = 0 then
  begin
    ShowMessage('Nenhum item encontrado.');
  end;
end;

{$ENDREGION}

{$REGION 'Lista de Jogadores Online}
procedure TfrmSendPacket.lvPlayersOnlineDblClick(Sender: TObject);
var
  ItemSelecionado: TListItem;
begin
  if lvPlayersOnline.Selected = nil then
    Exit;

  ItemSelecionado := lvPlayersOnline.Selected;

  // Passa o ID do jogador selecionado para o campo edtPlayerID
  edtPlayerID.Text := ItemSelecionado.Caption;
end;

procedure TfrmSendPacket.btnAtualizarPlayersClick(Sender: TObject);
var
  i, j: Integer;
  Player: PPlayer;
  ListItem: TListItem;
begin
  lvPlayersOnline.Items.Clear;

  // Itera sobre todos os servidores e jogadores conectados para preencher a lista
  for i := Low(Servers) to High(Servers) do
  begin
    for j := Low(Servers[i].Players) to High(Servers[i].Players) do
    begin
      Player := @Servers[i].Players[j];
      if Player.Status >= Playing then
      begin
        ListItem := lvPlayersOnline.Items.Add;
        ListItem.Caption := IntToStr(Player.Base.ClientID);  // ID do jogador
        ListItem.SubItems.Add(String(Player.Base.Character.Name));  // Nome do jogador
        ListItem.SubItems.Add(IntToStr(Player.Base.Character.Level));  // Level do jogador
      end;
    end;
  end;

  if lvPlayersOnline.Items.Count = 0 then
  begin
    ShowMessage('Nenhum jogador está online no momento.');
  end;
end;
{$ENDREGION}

{$REGION 'Contas'}

procedure TfrmSendPacket.btnCreateAccountClick(Sender: TObject);
var
  HTTP: TIdHTTP;
  SSL: TIdSSLIOHandlerSocketOpenSSL;
  URL, Response: string;
  Params: TStringList;
  NewUsername, NewPassword: string;
  AccountType: Integer;
begin
  // Pegando os valores dos campos de entrada
  NewUsername := edtNewUsername.Text;
  NewPassword := edtNewPassword.Text;
  AccountType := cbTypeAccount.ItemIndex; // Pega o índice selecionado no ComboBox

  // Verificar campos vazios
  if (Trim(NewUsername).IsEmpty) or (Trim(NewPassword).IsEmpty) then
  begin
    ShowMessage('Por favor, preencha todos os campos para criar uma conta.');
    Response := '400';
    Exit;
  end;

  // Montando a URL com os parâmetros inseridos
  URL := Format('https://localhost:8090/member/aika_create_account.asp?id=%s&pw=%s&acctype=%d',
                [NewUsername, NewPassword, AccountType]);

  // Inicializando o HTTP e SSL
  HTTP := TIdHTTP.Create(nil);
  SSL := TIdSSLIOHandlerSocketOpenSSL.Create(nil);
  try
    HTTP.IOHandler := SSL;
    SSL.SSLOptions.Method := sslvTLSv1_2; // Configura SSL para conexões seguras
    SSL.SSLOptions.Mode := sslmClient;

    // Parâmetros da requisição POST (se houver necessidade de enviar via POST)
    Params := TStringList.Create;
    try
      Params.Add('id=' + NewUsername);
      Params.Add('pw=' + NewPassword);
      Params.Add('acctype=' + IntToStr(AccountType));

      // Envia o pedido para a API
      try
        Response := HTTP.Post(URL, Params);
        if Response = '-3' then
        begin
          ShowMessage('Conta já existe.');
          Exit;
        end
        else
          ShowMessage('Conta criada com sucesso! Resposta: ' + Response);
      except
        on E: Exception do
          ShowMessage('Erro ao criar conta: ' + E.Message);
      end;
    finally
      Params.Free;
    end;
  finally
    HTTP.Free;
    SSL.Free;
  end;
end;


{$ENDREGION}


end.
