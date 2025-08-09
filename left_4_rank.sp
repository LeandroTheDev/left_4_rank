#include <sourcemod>

public Plugin myinfo =
{
    name        = "Left 4 Rank",
    author      = "LeandroTheDev",
    description = "Player rank system",
    version     = "1.0",
    url         = "https://github.com/LeandroTheDev/left_4_rank"
};

float playersScores[MAXPLAYERS];

// Configurations
float playerScoreLoseOnRoundLose      = 5.0;
float playerScoreEarnOnMarker         = 2.0;
float playerScoreEarnOnRoundWin       = 2.0;
float playerScoreEarnPerSurvivorHurt  = 0.02;
float playerScoreEarnPerSpecialKill   = 0.2;
float playerScoreEarnPerRevive        = 0.5;
float playerScoreLosePerIncapacitated = 0.5;
float playerScoreEarnPerIncapacitated = 0.5;

int   rankCount                       = 7;
int   rankThresholds[99];
char  rankNames[99][128];

bool  shouldDebug = false;

public void OnPluginStart()
{
    char commandLine[512];
    if (GetCommandLine(commandLine, sizeof(commandLine)))
    {
        if (StrContains(commandLine, "-debug") != -1)
        {
            PrintToServer("[Left 4 Rank] Debug is enabled");
            shouldDebug = true;
        }
    }

    char path[PLATFORM_MAX_PATH] = "addons/sourcemod/configs/left_4_rank.cfg";

    if (!FileExists(path))
    {
        Handle file = OpenFile(path, "w");
        if (file != null)
        {
            WriteFileLine(file, "\"Left4Rank\"");
            WriteFileLine(file, "{");

            WriteFileLine(file, "    \"playerScoreLoseOnRoundLose\"       \"5.0\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreEarnOnMarker\"       \"2.0\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreEarnOnRoundWin\"       \"2.0\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreEarnPerSurvivorHurt\"       \"0.02\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreEarnPerSpecialKill\"       \"0.2\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreEarnPerRevive\"       \"0.5\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreLosePerIncapacitated\"       \"0.5\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreEarnPerIncapacitated\"       \"0.5\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"rankCount\"       \"7\"");
            WriteFileLine(file, "");

            WriteFileLine(file, "    \"rankThresholds\"");
            WriteFileLine(file, "    {");
            WriteFileLine(file, "        \"0\"  \"0\"");
            WriteFileLine(file, "        \"1\"  \"100\"");
            WriteFileLine(file, "        \"2\"  \"200\"");
            WriteFileLine(file, "        \"3\"  \"300\"");
            WriteFileLine(file, "        \"4\"  \"400\"");
            WriteFileLine(file, "        \"5\"  \"500\"");
            WriteFileLine(file, "        \"6\"  \"600\"");
            WriteFileLine(file, "    }");
            WriteFileLine(file, "");

            WriteFileLine(file, "    \"rankNames\"");
            WriteFileLine(file, "    {");
            WriteFileLine(file, "        \"0\"  \"Bronze\"");
            WriteFileLine(file, "        \"1\"  \"Silver\"");
            WriteFileLine(file, "        \"2\"  \"Gold\"");
            WriteFileLine(file, "        \"3\"  \"Platinum\"");
            WriteFileLine(file, "        \"4\"  \"Diamond\"");
            WriteFileLine(file, "        \"5\"  \"Grand Master\"");
            WriteFileLine(file, "        \"6\"  \"Challenger\"");
            WriteFileLine(file, "    }");
            WriteFileLine(file, "}");
            CloseHandle(file);
            PrintToServer("[Left 4 Rank] Configuration file created: %s", path);
        }
        else
        {
            PrintToServer("[Left 4 Rank] Cannot create default file.");
            return;
        }
    }

    KeyValues kv = new KeyValues("Left4Rank");
    if (!kv.ImportFromFile(path))
    {
        delete kv;
        PrintToServer("[Left 4 Rank] Cannot load configuration file: %s", path);
    }
    // Loading from file
    else {
        playerScoreLoseOnRoundLose      = kv.GetFloat("playerScoreLoseOnRoundLose", 5.0);
        playerScoreEarnOnMarker         = kv.GetFloat("playerScoreEarnOnMarker", 2.0);
        playerScoreEarnOnRoundWin       = kv.GetFloat("playerScoreEarnOnRoundWin", 2.0);
        playerScoreEarnPerSurvivorHurt  = kv.GetFloat("playerScoreEarnPerSurvivorHurt", 0.02);
        playerScoreEarnPerSpecialKill   = kv.GetFloat("playerScoreEarnPerSpecialKill", 0.2);
        playerScoreEarnPerRevive        = kv.GetFloat("playerScoreEarnPerRevive", 0.5);
        playerScoreLosePerIncapacitated = kv.GetFloat("playerScoreLosePerIncapacitated", 0.5);
        playerScoreEarnPerIncapacitated = kv.GetFloat("playerScoreEarnPerIncapacitated", 0.5);
        rankCount                       = kv.GetNum("rankCount", 7);
        if (kv.JumpToKey("rankThresholds"))
        {
            for (int i = 0; i < rankCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                rankThresholds[i] = kv.GetNum(key, 0);
            }
            kv.GoBack();
            PrintToServer("[Left 4 Rank] rankThresholds Loaded!");
        }
        if (kv.JumpToKey("rankNames"))
        {
            for (int i = 0; i < rankCount; i++)
            {
                char key[8];
                Format(key, sizeof(key), "%d", i);
                kv.GetString(key, rankNames[i], 128);
            }
            kv.GoBack();
            PrintToServer("[Left 4 Rank] rankNames Loaded!");
        }
    }

    HookEventEx("versus_round_start", RoundStart, EventHookMode_Post);

    HookEventEx("versus_marker_reached", MarkerReached, EventHookMode_Post);

    HookEventEx("round_end", RoundEnd, EventHookMode_Post);

    HookEventEx("player_team", OnPlayerChangeTeam, EventHookMode_Post);

    HookEventEx("player_hurt", OnPlayerHurt, EventHookMode_Post);

    HookEventEx("player_incapacitated", OnPlayerIncapacitated, EventHookMode_Post);

    HookEventEx("revive_success", OnPlayerRevive, EventHookMode_Post);

    HookEventEx("witch_killed", OnSpecialKill, EventHookMode_Post);

    HookEventEx("tank_killed", OnSpecialKill, EventHookMode_Post);

    HookEventEx("charger_killed", OnSpecialKill, EventHookMode_Post);

    HookEventEx("spitter_killed", OnSpecialKill, EventHookMode_Post);

    HookEventEx("jockey_killed", OnSpecialKill, EventHookMode_Post);

    // Missing Smoker and Hunter, because there is not event for some reason

    RegConsoleCmd("rank", CommandViewRank, "View your rank");

    PrintToServer("[Left 4 Rank] Initialized");
}

/// REGION EVENTS
public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[Left 4 Rank] Round start");

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        RegisterPlayer(client);
    }

    ClearPlayerScores();
}

public void MarkerReached(Event event, const char[] name, bool dontBroadcast)
{
    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;
        if (GetClientTeam(client) != 2 || !IsPlayerAlive(client)) continue;

        playersScores[client] += playerScoreEarnOnMarker;

        if (shouldDebug)
            PrintToServer("[Left 4 Rank] %d updated score: %d", client, playersScores[client]);
    }
}

public void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    int winner = event.GetInt("winner");
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Scenario Restart
    if (reason == 0) return;

    // Chapter ended
    if (reason == 6) return;

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    winner = 3;
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        // 2 Survival - 3 Zombie
        int team = GetClientTeam(client);

        if (team == 2)
        {
            // Check if a player survivor is alive
            if (!(GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0) && IsPlayerAlive(client))
            {
                // Yes it is, so we can say that the winner team is survivor
                winner = 2;
                break;
            }
        }
    }

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        int team = GetClientTeam(client);
        if (team == winner) playersScores[client] += playerScoreEarnOnRoundWin;
        else playersScores[client] -= playerScoreLoseOnRoundLose;
        PrintToServer("[Left 4 Rank] Player: %d, team: %d, score: %d", client, team, playersScores[client]);

        UploadMMR(client, playersScores[client]);
    }

    ClearPlayerScores();
}

public void OnPlayerChangeTeam(Event event, const char[] name, bool dontBroadcast)
{
    bool disconnected = event.GetBool("disconnect");
    if (disconnected) return;

    int userid  = event.GetInt("userid");
    int team    = event.GetInt("team");
    int oldTeam = event.GetInt("oldteam");

    int client  = GetClientOfUserId(userid);
    if (!IsValidClient(client))
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] Fake client %d, ignoring team change, %d", userid, shouldDebug);
        return;
    }

    PrintToServer("[Left 4 Rank] %d changed their team: %d, previously: %d", client, team, oldTeam);

    if (oldTeam == 0)
    {
        PrintToServer("[Left 4 Rank] Player started playing %d", client);

        RegisterPlayer(client);
        ShowRankMenu(client);
    }
}

public void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    // Infected to Survivor
    {
        int survivorClient = GetClientOfUserId(event.GetInt("userid"));
        int infectedClient = GetClientOfUserId(event.GetInt("attacker"));

        // Valid client detection
        if (!IsValidClient(infectedClient))
        {
            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [OnPlayerHurt] Ignored: Attacker client not valid");
            return;
        }

        // Check if attacker is from infected team
        if (GetClientTeam(infectedClient) != 3)
        {
            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [OnPlayerHurt] Ignored: Attacker client is not on infected team");
            return;
        }

        // Check if client beenn attacked is a survivor
        if (GetClientTeam(survivorClient) != 2)
        {
            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [OnPlayerHurt] Ignored: Infected client is attacking a non survivor");
            return;
        }

        int   totalDamage = event.GetInt("dmg_health");
        float earnedMMR   = playerScoreEarnPerSurvivorHurt * totalDamage;

        playersScores[infectedClient] += earnedMMR;

        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnPlayerHurt] %d infected deal: %d damage to %d survivor, earned mmr: %f, total mmr: %f", infectedClient, totalDamage, survivorClient, earnedMMR, playersScores[infectedClient]);
    }
}

public void OnPlayerIncapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int survivorIncapacitated = GetClientOfUserId(event.GetInt("userid"));
    int infectedClient        = GetClientOfUserId(event.GetInt("attacker"));

    // Player reducer MMR
    if (GetClientTeam(survivorIncapacitated) == 2)
    {
        // Check if is valid client and the attacker is not a friendly fire
        if (IsValidClient(survivorIncapacitated) && GetClientTeam(infectedClient) != 2)
        {
            playersScores[survivorIncapacitated] -= playerScoreLosePerIncapacitated;
            PrintToServer("[Left 4 Rank] [OnPlayerIncapacitated] %d was incapacitated and lose: %f MMR, total: %f", survivorIncapacitated, playerScoreLosePerIncapacitated, playersScores[survivorIncapacitated]);
        }
        else
            PrintToServer("[Left 4 Rank] [OnPlayerIncapacitated] Ignored mmr change: Invalid client or friendly fire");
    }
    else {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnPlayerIncapacitated] Ignored mmr change: Not a survivor");
        return;
    }

    if (!IsValidClient(infectedClient))
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnPlayerIncapacitated] Ignored mmr change: Invalid client zombie");
        return;
    }

    if (GetClientTeam(infectedClient) == 2)
    {
        playersScores[infectedClient] += playerScoreEarnPerIncapacitated;
        PrintToServer("[Left 4 Rank] [OnPlayerIncapacitated] %d incapacitated someone and earn: %f MMR, total: %f", infectedClient, playerScoreEarnPerIncapacitated, playersScores[infectedClient]);
    }
    else {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnPlayerIncapacitated] Ignored mmr change: Not a zombie");
    }
}

public void OnPlayerRevive(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsValidClient(client))
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnPlayerRevive] Ignored: invalid client");
        return;
    }

    if (GetClientTeam(client) == 2)
    {
        playersScores[client] += playerScoreEarnPerRevive;
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnPlayerRevive] %d revived and earned: %f MMR, total: %f", client, playerScoreEarnPerRevive, playersScores[client]);
    }
    else {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnPlayerRevive] Ignored: invalid team");
    }
}

public void OnSpecialKill(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsValidClient(client) && GetClientTeam(client) == 2)
    {
        playersScores[client] += playerScoreEarnPerSpecialKill;
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnSpecialKill] %d killed special: %f MMR, total: %f", client, playerScoreEarnPerSpecialKill, playersScores[client]);
    }
    else {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnSpecialKill] Ignored because client is not valid or not from survivors team");
    }
}

/// REGION Commands
public Action CommandViewRank(int client, int args)
{
    if (shouldDebug)
        PrintToServer("[Left 4 Rank] %d requested rank menu", client);

    ShowRankMenu(client);

    return Plugin_Handled;
}

/// REGION Utils

stock void GetOnlinePlayers(int[] onlinePlayers, int playerSize)
{
    int arrayIndex = 0;
    for (int i = 1; i < MaxClients; i += 1)
    {
        if (arrayIndex >= playerSize)
        {
            break;
        }

        int client = i;

        if (!IsValidClient(client))
        {
            continue;
        }

        onlinePlayers[arrayIndex] = client;
        arrayIndex++;
    }
}

stock bool IsValidClient(client)
{
    if (client <= 0 || client > MaxClients || !IsClientConnected(client) || IsFakeClient(client))
    {
        return false;
    }
    return IsClientInGame(client);
}

stock void ClearPlayerScores()
{
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        playersScores[i] = 0.0;
    }

    PrintToServer("[Left 4 Rank] Scores cleared");
}

void GetRankNameFromRank(int rank, char[] output, int maxlen)
{
    for (int i = rankCount - 1; i >= 0; i--)
    {
        if (rank >= rankThresholds[i])
        {
            strcopy(output, maxlen, rankNames[i]);
            return;
        }
    }

    strcopy(output, maxlen, "Unranked");
}

stock void UploadMMR(int client, float mmrfloat)
{
    int mmr = RoundToNearest(mmrfloat);

    if (mmr > 100)
    {
        PrintToServer("[Left 4 Rank] INVALID MMR TOO HIGH: %d, MMR: %d", client, mmr);
        return;
    }

    if (!IsValidClient(client)) return;

    int steamid = GetSteamAccountID(client);

    if (steamid == 0)
    {
        PrintToServer("[Left 4 Rank] Invalid client when uploading MMR");
        return;
    }

    Database database = CreateDatabaseConnection();
    if (database == null) return;

    char game[64];
    GetGameFolderName(game, sizeof(game));

    char query[256];
    Format(query, sizeof(query), "UPDATE `%s` SET rank = GREATEST(rank + ?, 0) WHERE uniqueid = ?", game);

    char        statementError[456];
    DBStatement statement = SQL_PrepareQuery(database, query, statementError, sizeof(statementError));

    SQL_BindParamInt(statement, 0, mmr);
    SQL_BindParamInt(statement, 1, steamid);

    if (shouldDebug)
        PrintToServer("[Left 4 Rank] Query: UPDATE `%s` SET rank = GREATEST(rank + %d, 0) WHERE uniqueid = %d", game, mmr, steamid);

    if (!SQL_Execute(statement))
    {
        char databaseError[456];
        SQL_GetError(database, databaseError, sizeof(databaseError));
        PrintToServer("[Left 4 Rank] Database error: %s", databaseError);
        PrintToServer("[Left 4 Rank] Statement error: %s", statementError);
    }
    else {
        PrintToServer("[Left 4 Rank] Updated %d mmr to: %d", client, mmr);
        PrintToChat(client, "[Rank] %d MMR", mmr);
    }

    statement.Close();
    database.Close();
}

stock void RegisterPlayer(const int client)
{
    if (!IsValidClient(client))
    {
        return;
    }

    int steamid = GetSteamAccountID(client);

    if (steamid == 0)
    {
        PrintToServer("[Left 4 Rank] Invalid client when registering player");
        return;
    }

    Database database = CreateDatabaseConnection();
    if (database == null) return;

    char game[64];
    GetGameFolderName(game, sizeof(game));

    char query[256];
    Format(query, sizeof(query), "INSERT INTO `%s` (uniqueid) VALUES (?)", game, steamid);

    char        statementError[456];
    DBStatement statement = SQL_PrepareQuery(database, query, statementError, sizeof(statementError));

    SQL_BindParamInt(statement, 0, steamid);

    if (shouldDebug)
        PrintToServer("[Left 4 Rank] Query: INSERT INTO `%s` (uniqueid) VALUES (%d)", game, steamid);

    if (!SQL_Execute(statement))
    {
        char databaseError[456];
        SQL_GetError(database, databaseError, sizeof(databaseError));

        // Ignore prints if the error is from duplicate entry
        if (StrContains(databaseError, "Duplicate entry", false) == -1)
        {
            PrintToServer("[Left 4 Rank] Database error: %s", databaseError);
            PrintToServer("[Left 4 Rank] Statement error: %s", statementError);
        }
    }

    statement.Close();
    database.Close();
}

public void ShowRankMenu(const int client)
{
    if (!IsValidClient(client))
    {
        return;
    }

    int steamid = GetSteamAccountID(client);

    if (steamid == 0)
    {
        PrintToServer("[Left 4 Rank] Invalid client when show rank menu");
        return;
    }

    Database database = CreateDatabaseConnection();
    if (database == null) return;

    char game[64];
    GetGameFolderName(game, sizeof(game));

    char query[256];
    Format(query, sizeof(query), "SELECT rank FROM `%s` WHERE uniqueid = ?", game);

    char        statementError[456];
    DBStatement statement = SQL_PrepareQuery(database, query, statementError, sizeof(statementError));

    SQL_BindParamInt(statement, 0, steamid);

    if (shouldDebug)
        PrintToServer("[Left 4 Rank] Query: SELECT rank FROM `%s` WHERE uniqueid = %d", game, steamid);

    if (!SQL_Execute(statement))
    {
        char databaseError[456];
        SQL_GetError(database, databaseError, sizeof(databaseError));
        PrintToServer("[Left 4 Rank] Database error: %s", databaseError);
        PrintToServer("[Left 4 Rank] Statement error: %s", statementError);
    }

    if (SQL_HasResultSet(statement))
    {
        while (SQL_FetchRow(statement))
        {
            char rank[128];
            SQL_FetchString(statement, 0, rank, sizeof(rank));

            Menu menu = new Menu(MenuHandler);
            char rankName[128];
            GetRankNameFromRank(StringToInt(rank), rankName, sizeof(rankName));

            menu.SetTitle("Your Current Rank: %s, Total MMR: %s", rankName, rank);
            menu.AddItem("0", "OK");
            menu.Display(client, 4);
        }
    }

    statement.Close();
    database.Close();
}

stock int MenuHandler(Menu menu, MenuAction action, int client, int param)
{
    return 0;
}

// Starts the database connection
stock Database CreateDatabaseConnection()
{
    char     error[256];
    Database database = SQL_Connect("left4rank", true, error, sizeof(error));

    if (database == null)
    {
        PrintToServer("[Left 4 Rank] ERROR: Cannot connect to the database: %s", error);
        return null;
    }
    else {
        return database;
    }
}