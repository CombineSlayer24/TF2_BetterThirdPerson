#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1

bool inThirdPerson[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Better Thirdperson",
	author = "Pyri",
	description = "Thirdperson camera, but acomedates the sniper",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_tp", Command_ThirdPerson,"Enable First/Third person?");
	RegConsoleCmd("sm_thirdperson", Command_ThirdPerson,"Enable First/Third person?");
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
			SetVariantInt(0);
			AcceptEntityInput(client, "SetForcedTauntCam");
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
			SetVariantInt(1);
			AcceptEntityInput(client, "SetForcedTauntCam");
		}
	}
}

public Action Command_ThirdPerson(int client, int args)
{
	if (!IsClientInGame(client))
		return Plugin_Handled;

	if (!inThirdPerson[client])
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		inThirdPerson[client] = true;
		PrintToChat(client, "[SM] Thirdperson is {green}enabled{default}. Tpye the command again to disable thirdperson.");
	}
	else
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		inThirdPerson[client] = false;
		PrintToChat(client, "[SM] Thirdperson is {red}disabled{default}. Tpye the command again to enable thirdperson.");
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