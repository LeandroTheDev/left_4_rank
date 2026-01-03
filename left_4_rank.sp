#include <sourcemod>

public Plugin myinfo =
{
    name        = "Left 4 Rank",
    author      = "LeandroTheDev",
    description = "Player rank system",
    version     = "1.3",
    url         = "https://github.com/LeandroTheDev/left_4_rank"
};

float  playersScores[MAXPLAYERS];
int    playerSpecialInfectedKilled[MAXPLAYERS];

// Configurations
float  playerMaxScore                           = 10.0;
float  playerScoreLoseOnRoundLose               = 5.0;
float  playerScoreEarnOnMarker                  = 2.0;
float  playerScoreEarnOnRoundWin                = 2.0;
float  playerScoreEarnPerSurvivorHurt           = 0.02;
float  playerScoreEarnPerSpecialKill            = 0.2;
float  playerScoreEarnPerRevive                 = 0.5;
float  playerScoreLosePerIncapacitated          = 0.5;
float  playerScoreEarnPerIncapacitated          = 0.5;

float  playerScoreStartSurvival                 = -3.0;
float  playerScoreEarnSurvivalPerSecond         = 0.01;
float  playerScoreInfectedStartSurvival         = 6.0;
float  playerScoreInfectedLoseSurvivalPerSecond = 0.01;

int    rankCount                                = 7;
int    rankThresholds[99];
char   rankNames[99][128];

int    timeStampSurvived;
Handle timeStampSurvivedTimer = INVALID_HANDLE;

bool   shouldDebug            = false;
bool   shouldDisplayMenu      = true;

#define MVP_COUNT 3

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

        if (StrContains(commandLine, "-rankDisableAutoMenu") != -1)
        {
            PrintToServer("[Left 4 Rank] Menu is disabled");
            shouldDisplayMenu = false;
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

            WriteFileLine(file, "    \"playerMaxScore\"       \"10.0\"");
            WriteFileLine(file, "");
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
            WriteFileLine(file, "    \"playerScoreStartSurvival\"       \"-3.0\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreEarnSurvivalPerSecond\"       \"0.01\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreInfectedStartSurvival\"       \"6.0\"");
            WriteFileLine(file, "");
            WriteFileLine(file, "    \"playerScoreInfectedLoseSurvivalPerSecond\"       \"0.01\"");
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
        playerMaxScore                  = kv.GetFloat("playerMaxScore", 10.0);
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

    char gamemode[64];
    GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
    if (StrEqual(gamemode, "versus"))
    {
        PrintToServer("[Left 4 Rank] versus detected");
        HookEventEx("player_hurt", OnPlayerHurt, EventHookMode_Post);
        HookEventEx("player_death", OnSpecialKill, EventHookMode_Post);
        HookEventEx("versus_round_start", RoundStartVersus, EventHookMode_Post);
        HookEventEx("round_end", RoundEndVersus, EventHookMode_Post);
        HookEventEx("versus_marker_reached", MarkerReached, EventHookMode_Post);
    }
    else if (StrEqual(gamemode, "mutation15")) {
        PrintToServer("[Left 4 Rank] survival versus detected");
        HookEventEx("player_hurt", OnPlayerHurt, EventHookMode_Post);
        HookEventEx("player_death", OnSpecialKill, EventHookMode_Post);
        HookEventEx("survival_round_start", RoundStartSurvivalVersus, EventHookMode_Post);
        HookEventEx("round_end", RoundEndSurvivalVersus, EventHookMode_Post);
    }
    else if (StrEqual(gamemode, "survival")) {
        PrintToServer("[Left 4 Rank] survival detected");
        HookEventEx("player_death", OnSpecialKill, EventHookMode_Post);
        HookEventEx("survival_round_start", RoundStartSurvivalVersus, EventHookMode_Post);
        HookEventEx("round_end", RoundEndSurvivalVersus, EventHookMode_Post);
    }
    else if (StrEqual(gamemode, "coop")) {
        PrintToServer("[Left 4 Rank] coop detected");
        HookEventEx("map_transition", RoundEndCoop, EventHookMode_Post);
        HookEventEx("mission_lost", RoundEndLoseCoop, EventHookMode_Post);
    }
    else
        PrintToServer("[Left 4 Rank] Unsuported gamemode: %s", gamemode);

    HookEventEx("player_team", OnPlayerChangeTeam, EventHookMode_Post);

    HookEventEx("player_incapacitated", OnPlayerIncapacitated, EventHookMode_Post);

    HookEventEx("revive_success", OnPlayerRevive, EventHookMode_Post);

    RegConsoleCmd("rank", CommandViewRank, "View your rank");

    PrintToServer("[Left 4 Rank] Initialized");
}

/// REGION EVENTS
public void RoundStartVersus(Event event, const char[] name, bool dontBroadcast)
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

public void RoundStartSurvivalVersus(Event event, const char[] name, bool dontBroadcast)
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

    timeStampSurvived      = 0;
    timeStampSurvivedTimer = CreateTimer(1.0, OnTimestampPassed, 0, TIMER_REPEAT);
}

public Action OnTimestampPassed(Handle timer, any data)
{
    timeStampSurvived++;
    return Plugin_Handled;
}

public void MarkerReached(Event event, const char[] name, bool dontBroadcast)
{
    PrintToServer("[Left 4 Rank] Marker Reached");

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
            PrintToServer("[Left 4 Rank] [MarkerReached] %d Earned: %f for marker reach", client, playerScoreEarnOnMarker);
    }
}

public void RoundEndVersus(Event event, const char[] name, bool dontBroadcast)
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

    int survivorsMVP[MVP_COUNT];
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        int team = GetClientTeam(client);
        if (team == winner)
        {
            playersScores[client] += playerScoreEarnOnRoundWin;

            int kills = playerSpecialInfectedKilled[client];
            if (kills > playerSpecialInfectedKilled[survivorsMVP[0]])
            {
                survivorsMVP[2] = survivorsMVP[1];
                survivorsMVP[1] = survivorsMVP[0];
                survivorsMVP[0] = client;
            }
            else if (kills > playerSpecialInfectedKilled[survivorsMVP[1]]) {
                survivorsMVP[2] = survivorsMVP[1];
                survivorsMVP[1] = client;
            }
            else if (kills > playerSpecialInfectedKilled[survivorsMVP[2]]) {
                survivorsMVP[2] = client;
            }

            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [RoundEndVersus] %d Earned: %f for winning", client, playerScoreEarnOnRoundWin);
        }
        else {
            playersScores[client] -= playerScoreLoseOnRoundLose;
            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [RoundEndVersus] %d Losed: %f for losing", client, playerScoreLoseOnRoundLose);
        }
        PrintToServer("[Left 4 Rank] Player: %d, team: %d, score: %f", client, team, playersScores[client]);

        CheckMaxScore(client);

        UploadMMR(client, playersScores[client]);
    }

    PrintToChatAll("[Left 4 Rank] Survivors Special Infected MVP:");
    for (int i = 0; i < MVP_COUNT; i++)
    {
        int client = survivorsMVP[i];
        if (IsValidClient(client))
        {
            char clientUsername[128];
            GetClientName(client, clientUsername, sizeof(clientUsername));

            PrintToChatAll("[%d] %s: %d", i + 1, clientUsername, playerSpecialInfectedKilled[client]);
        }
    }

    ClearPlayerScores();
}

public void RoundEndSurvivalVersus(Event event, const char[] name, bool dontBroadcast)
{
    if (timeStampSurvivedTimer != INVALID_HANDLE)
        CloseHandle(timeStampSurvivedTimer);
    timeStampSurvivedTimer = INVALID_HANDLE;

    int reason             = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Scenario Restart
    if (reason == 0) return;

    // Chapter ended
    if (reason == 6) return;

    if (shouldDebug)
        PrintToServer("[Left 4 Rank] Round ended reason: %d", reason);

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    int survivorsMVP[3];
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        int team = GetClientTeam(client);

        if (team == 2)
        {
            playersScores[client] += GetRankEarnByTimeStampSurvival();

            int kills = playerSpecialInfectedKilled[client];
            if (kills > playerSpecialInfectedKilled[survivorsMVP[0]])
            {
                survivorsMVP[2] = survivorsMVP[1];
                survivorsMVP[1] = survivorsMVP[0];
                survivorsMVP[0] = client;
            }
            else if (kills > playerSpecialInfectedKilled[survivorsMVP[1]]) {
                survivorsMVP[2] = survivorsMVP[1];
                survivorsMVP[1] = client;
            }
            else if (kills > playerSpecialInfectedKilled[survivorsMVP[2]]) {
                survivorsMVP[2] = client;
            }

            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [RoundEndSurvivalVersus] %d SUpdated rank: %f", client, GetRankEarnByTimeStampSurvival());
        }
        else if (team == 3) {
            playersScores[client] += GetRankEarnByTimeStampInfected();

            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [RoundEndSurvivalVersus] %d IUpdated rank: %f", client, GetRankEarnByTimeStampInfected());
        }
        PrintToServer("[Left 4 Rank] Player: %d, team: %d, score: %d", client, team, playersScores[client]);

        CheckMaxScore(client);

        UploadMMR(client, playersScores[client]);
    }

    PrintToChatAll("[Left 4 Rank] Survivors Special Infected MVP:");
    for (int i = 0; i < sizeof(survivorsMVP); i++)
    {
        int client = survivorsMVP[i];
        if (IsValidClient(client))
        {
            char clientUsername[128];
            GetClientName(client, clientUsername, sizeof(clientUsername));

            PrintToChatAll("[%d] %s: %d", i + 1, clientUsername, playerSpecialInfectedKilled[client]);
        }
    }

    ClearPlayerScores();
}

public void RoundEndCoop(Event event, const char[] name, bool dontBroadcast)
{
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Chapter ended
    if (reason == 6) return;

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        playersScores[client] += playerScoreEarnOnRoundWin;

        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [RoundEndCoop] %d Earned: %f for winning", client, playerScoreEarnOnRoundWin);
        PrintToServer("[Left 4 Rank] Player: %d, score: %f", client, playersScores[client]);

        CheckMaxScore(client);

        UploadMMR(client, playersScores[client]);
    }

    ClearPlayerScores();
}

public void RoundEndLoseCoop(Event event, const char[] name, bool dontBroadcast)
{
    int reason = event.GetInt("reason");

    // Restart from hibernation
    if (reason == 8) return;

    // Chapter ended
    if (reason == 6) return;

    int onlinePlayers[MAXPLAYERS];
    GetOnlinePlayers(onlinePlayers, sizeof(onlinePlayers));

    for (int i = 0; i < MAXPLAYERS; i++)
    {
        int client = onlinePlayers[i];
        if (client == 0) break;

        if (!IsValidClient(client)) continue;

        playersScores[client] -= playerScoreLoseOnRoundLose;
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [RoundEndCoop] %d Losed: %f for losing", client, playerScoreLoseOnRoundLose);
        PrintToServer("[Left 4 Rank] Player: %d, score: %f", client, playersScores[client]);

        CheckMaxScore(client);

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

    if (shouldDebug)
        PrintToServer("[Left 4 Rank] %d changed their team: %d, previously: %d", client, team, oldTeam);

    if (oldTeam == 0)
    {
        ClearSinglePlayerScore(client);

        PrintToServer("[Left 4 Rank] Player started playing %d", client);

        RegisterPlayer(client);

        if (shouldDisplayMenu)
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
    if (IsValidClient(survivorIncapacitated) && GetClientTeam(survivorIncapacitated) == 2)
    {
        // Check if is valid client and the attacker is not a friendly fire
        if (!IsValidClient(infectedClient) || GetClientTeam(infectedClient) != 2)
        {
            playersScores[survivorIncapacitated] -= playerScoreLosePerIncapacitated;
            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [OnPlayerIncapacitated] %d was incapacitated and lose: %f MMR, total: %f", survivorIncapacitated, playerScoreLosePerIncapacitated, playersScores[survivorIncapacitated]);
        }
        else {
            if (shouldDebug)
                PrintToServer("[Left 4 Rank] [OnPlayerIncapacitated] Ignored mmr change: Invalid client or friendly fire");
        }
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
    char victimname[32];
    event.GetString("victimname", victimname, sizeof(victimname));
    if (StrEqual(victimname, "Infected"))
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] Special kill ignored normal infected");
        return;
    }

    int clientDied     = GetClientOfUserId(event.GetInt("userid"));
    int clientAttacker = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsValidClient(clientAttacker))
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] Special kill ignored: invalid client %d", clientAttacker);
        return;
    }
    if (GetClientTeam(clientAttacker) != 2)
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] Special kill ignored: invalid team %d", clientAttacker);
        return;
    }
    if (GetClientTeam(clientDied) != 3)
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] Special kill ignored: invalid enemy team %d", clientAttacker);
        return;
    }

    if (
        StrEqual(victimname, "Hunter") || StrEqual(victimname, "Boomer") || StrEqual(victimname, "Charger") || StrEqual(victimname, "Jockey") || StrEqual(victimname, "Smoker") || StrEqual(victimname, "Tank") || StrEqual(victimname, "Spitter"))
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] [OnSpecialKill] %d received %f for killing: %s", clientAttacker, playerScoreEarnPerSpecialKill, victimname);
        playersScores[clientAttacker] += playerScoreEarnPerSpecialKill;
        playerSpecialInfectedKilled[clientAttacker] += 1
    }
    else
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] %d wrong victim name: %s", clientAttacker, victimname);
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
stock float GetRankEarnByTimeStampSurvival()
{
    float result    = playerScoreStartSurvival;
    float increment = timeStampSurvived * playerScoreEarnSurvivalPerSecond;

    return result + increment;
}

stock float GetRankEarnByTimeStampInfected()
{
    float result    = playerScoreInfectedStartSurvival;
    float decrement = timeStampSurvived * playerScoreInfectedLoseSurvivalPerSecond;

    return result - decrement;
}

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
    // Cleanup player scores
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        playersScores[i] = 0.0;
    }

    // Cleanup special infected killed
    for (int i = 0; i < MAXPLAYERS; i++)
    {
        playerSpecialInfectedKilled[i] = 0;
    }

    PrintToServer("[Left 4 Rank] Scores cleared");
}

stock void ClearSinglePlayerScore(int client)
{
    playersScores[client]               = 0.0;
    playerSpecialInfectedKilled[client] = 0;

    PrintToServer("[Left 4 Rank] client %d Scores cleared", client);
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

    if (statement == null)
    {
        PrintToServer("[Left 4 Rank] SQL Prepare failed: %s", statementError);
        return;
    }

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
        PrintToChat(client, "[Left 4 Rank] %d MMR", mmr);
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

// Reset score to max score if needed
stock CheckMaxScore(int client)
{
    if (playersScores[client] > playerMaxScore)
    {
        if (shouldDebug)
            PrintToServer("[Left 4 Rank] %d is on max score");

        playersScores[client] = playerMaxScore;
    }
}