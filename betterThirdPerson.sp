#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <multicolors>

#pragma semicolon 1

bool inThirdPerson[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Better Thirdperson",
	author = "Pyri",
	description = "Thirdperson camera, but acomedates the sniper",
	version = "1.0.3",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_tp", Command_ThirdPerson,"Enable First/Third person?");
	RegConsoleCmd("sm_thirdperson", Command_ThirdPerson,"Enable First/Third person?");
	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("player_class", OnPlayerSpawned);
}

public void OnPlayerSpawned(Handle event, const char[] name, bool dontBroadcast)
{
	int userid = GetEventInt(event, "userid");
	if (inThirdPerson[GetClientOfUserId(userid)])
		CreateTimer(0.2, SetViewOnSpawn, userid);
}

public Action SetViewOnSpawn(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client != 0)
	{
		SetThirdPersonStatus(client, 1);
	}

	return Plugin_Stop;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!IsValidEntity(entity))
		return;

	if (StrEqual(classname, "env_sniperdot"))
		SDKHook(entity, SDKHook_SpawnPost, SniperdotSpawnPost);
}

public Action SniperdotSpawnPost(int entity)
{
	RequestFrame(SniperdotSpawnPostPost, entity);
	
	return Plugin_Continue;
}

//Used to disable Thirdperson if Sniper scopes in
public void SniperdotSpawnPostPost(int ent)
{
	if (IsValidEntity(ent))
	{
		int client = GetOwnerEntity(ent);

		//We are scoped in, go in firstperson for accurate shots
		if (inThirdPerson[client])
		{
			SetThirdPersonStatus(client, 0);
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
	if (TF2_GetPlayerClass(client) == TFClass_Sniper && condition == TFCond_Zoomed)
	{
		//Not scoped in anymore, go back to thirdperson
		if (inThirdPerson[client])
		{
			SetThirdPersonStatus(client, 1);
		}
	}
}

public Action Command_ThirdPerson(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;

	if (!inThirdPerson[client])
	{
		SetThirdPersonStatus(client, 1);
		inThirdPerson[client] = true;
		CPrintToChat(client, "[SM] Thirdperson is {green}enabled{default}. Type the command again to disable thirdperson.");
	}
	else
	{
		SetThirdPersonStatus(client, 0);
		inThirdPerson[client] = false;
		CPrintToChat(client, "[SM] Thirdperson is {red}disabled{default}. Type the command again to enable thirdperson.");
	}

	return Plugin_Handled;
}

stock int GetOwnerEntity(int entity)
{
	return GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
}

public OnClientDisconnect(client)
{
	inThirdPerson[client] = false;
}

stock void SetThirdPersonStatus(int client, int status)
{
	SetVariantInt(status);
	AcceptEntityInput(client, "SetForcedTauntCam");
}
