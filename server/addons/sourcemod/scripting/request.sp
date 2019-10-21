#pragma semicolon 1

#include <sourcemod>
#include <multicolors>
#undef REQUIRE_PLUGIN
#include <ASteambot>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define MAX_COMMANDS 4
#define MAX_CHARS_PER_CMD 12
#define MAX_ADMINS 4

ConVar g_cvDelay = null;
ConVar g_cvMessageDelay = null;
ConVar g_cvUseDatabase = null;
ConVar g_cvAdmins = null;
Handle g_hTimerAd = null;
Database g_dDbConn = null;
bool g_bUseASteambot = false;
bool g_bIsDatabaseActive = false;
bool g_bIsASteambotLoaded = false;
char g_cError[256] = "\0";
char Prefix[] = "{green}[Request] {default}";
char g_cCommands[MAX_CHARS_PER_CMD * MAX_COMMANDS + 4] = "\0";
float g_fLastRequested[MAXPLAYERS + 1] = {0.00, ...};
float g_fRequestDelay = 0.00;
DBStatement g_hStmt = null;
ArrayList g_aCommands = null;
ArrayList g_aAdmins = null;

public Plugin myinfo =
{
	name = "Player Request",
	author = "Arkarr",
	description = "Players can send request.",
	version = "3.0",
	url = "http://www.sourcemod.net"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error,int err_max) {
    MarkNativeAsOptional("ASteambot_IsConnected");
    MarkNativeAsOptional("ASteambot_SendMessage");
    MarkNativeAsOptional("ASteambot_RegisterModule");
    MarkNativeAsOptional("ASteambot_RemoveModule");
    return APLRes_Success;
}  

public void OnAllPluginsLoaded()
{
    if (LibraryExists("ASteambot")) {
    	g_bIsASteambotLoaded = true;
    	ASteambot_RegisterModule("Arkarr_Request");
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "ASteambot"))
	{
		g_bIsASteambotLoaded = false;
	}
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "ASteambot"))
	{
		g_bIsASteambotLoaded = true;
	}
}

public void OnPluginEnd()
{
	if(g_bIsASteambotLoaded)
		ASteambot_RemoveModule();
}

public void OnPluginStart()
{
	char commands[MAX_COMMANDS][MAX_CHARS_PER_CMD];
	int totalCommands = 0;
	g_aCommands = new ArrayList(MAX_CHARS_PER_CMD, MAX_COMMANDS);
	
	g_cvDelay = CreateConVar("sm_time_before_request","30.0","Time before a player can do another request.", _, true, 0.1);
	g_cvMessageDelay = CreateConVar("sm_request_message_delay","45.0","Display the advertissmenet message every X seconds", _, true, 0.0);
	g_cvUseDatabase = CreateConVar("sm_use_database", "1", "Set if the plugin should save request in a database. Takes effect only on map restart!");
	CreateConVar("sm_custom_command","feedback,request,ask,rq", "What should be the command for the plugin ?").GetString(g_cCommands, sizeof g_cCommands);
	g_bUseASteambot = CreateConVar("sm_request_use_asteambot", "0", "Use ASteambot to send the request to the admin.").BoolValue;
	g_cvAdmins = CreateConVar("sm_request_asteambot_admins","STEAM_1:1:1234567,STEAM_1:0:56789012", "Which admins should the requests be sent to? Separated by a comma (they must be friends with bot).");
	
	totalCommands = ExplodeString(g_cCommands, ",", commands, sizeof commands, sizeof commands[]);
	
	if(!totalCommands)
		SetFailState("\"sm_custom_command\" Cannot be empty.");
	
	for (int i = 0; i < totalCommands; i++)
	{
		g_aCommands.SetString(i, commands[i]);
	
	}
	// @todo delete commands

	g_fRequestDelay = g_cvDelay.FloatValue;
	g_cvDelay.AddChangeHook(OnDelayChange);
	g_cvMessageDelay.AddChangeHook(OnTimerTimeChange);
	
	//HookEvent("player_say", OnChatMessage);
	
	AutoExecConfig(true, "request");
	GetDatabase();
	LoadTranslations("request.phrases");
}

public void GetDatabase()
{
	char error[1028] = "";
	if (g_cvUseDatabase.IntValue == 1)
	{
		g_bIsDatabaseActive = true;
		Database.Connect(GotDatabase, "request", _);
	}
	else
	{
		Database db = SQLite_UseDatabase("requests", error, sizeof error);
		g_bIsDatabaseActive = false;
		GotDatabase(db, error, false);
	}
}

public void OnConfigsExecuted()
{
	if (g_bUseASteambot && !g_bIsASteambotLoaded) {
		SetFailState(
		"[Request] To able to send requests to admins using ASteambot, \
		it must be installed and running. See https://forums.alliedmods.net/showthread.php?t=273091"
		);
		return;
	}
	g_hTimerAd = CreateTimer(g_cvMessageDelay.FloatValue, AdTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void GotDatabase(Database db, const char[] error, any data)
{
	if (db == null)
	{
		SetFailState("[Request] Error with database: %s", error);
		return;
	}
	
	PrintToServer("[Request] Successfully connected to the database!");
	g_dDbConn = db;
	g_hStmt = SQL_PrepareQuery(
		g_dDbConn, 
		"INSERT INTO request (`steamid`, `playername`, `date_creation`, `request`) VALUES (?, ?, ?, ?)", 
		g_cError, 
		sizeof g_cError
	);
	if(strlen(g_cError)){
		SetFailState("[Request] error creating an STMT. More: %s", g_cError);
		return;
	}
	if(g_bIsDatabaseActive)
		ExecuteQuery(g_dDbConn, "CREATE TABLE IF NOT EXISTS request (id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY, playername VARCHAR(24) NOT NULL, steamid VARCHAR(24) NOT NULL, date_creation VARCHAR(24) NOT NULL , request VARCHAR(256) NOT NULL)");
	else
		ExecuteQuery(g_dDbConn, "CREATE TABLE IF NOT EXISTS request (id INTEGER PRIMARY KEY AUTOINCREMENT, playername VARCHAR(24) NOT NULL, steamid VARCHAR(24) NOT NULL, date_creation VARCHAR(24) NOT NULL , request VARCHAR(256) NOT NULL)");
}

public void OnTimerTimeChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{	
	g_fRequestDelay = cvar.FloatValue;
}

public void OnDelayChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (g_hTimerAd != INVALID_HANDLE)
	{
		KillTimer(g_hTimerAd);
		g_hTimerAd = INVALID_HANDLE;
	}
	
	g_hTimerAd = CreateTimer(cvar.FloatValue, AdTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{
	g_fLastRequested[client] = GetGameTime();
}

public Action OnClientSayCommand(int client, const char[] command, const char[] _message)
{
	if (g_fLastRequested[client] + g_fRequestDelay < GetGameTime())
	{
		char message[MAX_MESSAGE_LENGTH], chatCmd[1][30];
		
		strcopy(message, sizeof message, _message[1]);
		ExplodeString(message, " ", chatCmd, sizeof chatCmd, sizeof chatCmd[]);
	
		if (
			g_aCommands.FindString(chatCmd[0]) != -1
		)
		{
			ProcessRequest(client, message[strlen(chatCmd[0])+1], g_bIsDatabaseActive);
		}
	}

	if (_message[0] == '/')
		return Plugin_Handled;
	return Plugin_Continue;	
}

public Action AdTimer(Handle timer, any user)  
{
	CPrintToChatAll("%t", "Ad", "Prefix", g_cCommands);
}

stock bool ProcessRequest(int client, const char[] request, bool UseDatabase)
{
	if (!IsValidClient(client))
		return false;
		
	if (g_hStmt == INVALID_HANDLE) {
		SetFailState("[Request] invalid database stmt.");
		return false;
	}
	
	char playername[MAX_NAME_LENGTH], steamid[24], datetime[24];
	
	GetClientName(client, playername, sizeof playername);
	GetClientAuthId(client, AuthId_Engine, steamid, sizeof steamid);
	FormatTime(datetime, sizeof datetime, "%Y-%m-%dT%H:%M:%S");
	
	g_hStmt.BindString(0, steamid, false);
	g_hStmt.BindString(1, playername, false);
	g_hStmt.BindString(2, datetime, false);
	g_hStmt.BindString(3, request, false);
	
	if (!SQL_Execute(g_hStmt)) 
	{
		LogError("[Request] Error saving request (From %s - Text: %s). Error: %s.", steamid, request, g_cError);
		return false;
	}

	//#if defined _INCLUDE_ASteambot
	SendRequestToBot(steamid, playername, request);
	//#endif
	g_fLastRequested[client] = GetGameTime();
	CPrintToChat(client, "%t", "Successful", "Prefix", playername);
	return true;
}

public void SendRequestToBot(const char[] steamid, const char[] playername, const char[] request)
{
	if(!g_bUseASteambot)
		return;
	if (!ASteambot_IsConnected())
	{
		SetFailState("[Request] ASteambot is not connected.");
		return;
	}
	if(g_aAdmins == null)
	{
		g_aAdmins = new ArrayList(24, MAX_ADMINS);
		char temp[MAX_ADMINS * 24] = "\0", tempAdmins[MAX_ADMINS][24];
		int total = 0;
		g_cvAdmins.GetString(temp, sizeof temp);
		total = ExplodeString(temp, ",", tempAdmins, sizeof tempAdmins, sizeof tempAdmins[]);
		for (int i = 0; i < total; i++)
		{
			g_aAdmins.SetString(i, tempAdmins[i]);
		}
	}
	char message[2084] = "\0";
	char adminSteamid[24];
	for (int i = 0; i < g_aAdmins.Length; i++)
	{
		g_aAdmins.GetString(i, adminSteamid, sizeof adminSteamid);
		Format(message, sizeof message, "%s/\nNew request!\nFrom: %s (%s)\nRequest:\n %s\n", adminSteamid, playername, steamid, request);
		ASteambot_SendMessage(AS_SIMPLE, message);
	}
}

stock bool ExecuteQuery(Database db, const char[] query)
{
	if (!SQL_FastQuery(db, query))
	{
		char error[255];
		SQL_GetError(db, error, sizeof error);
		PrintToServer("[Request] ERROR: %s", error);
		return false;
	}
	return true;
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
