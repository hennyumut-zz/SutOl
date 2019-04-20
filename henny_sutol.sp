/*
 * CS:GO Sut Ol
 * by: Henny!
 * 
 * Copyright (C) 2016-2019 Umut 'Henny!' Uzatmaz
 *
 * This file is part of the Henny! SourceMod Plugin Package.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <renkler>
#include <store>

#define plugintag "Sunucu"

bool KomutKullanildi[MAXPLAYERS + 1];
Handle CvarKredi;

public Plugin myinfo =
{
	name 	= "[CSGO] Süt Ol",
	author 	= "Henny!",
	version = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_sutol", sutol);
	HookEvent("round_start", turBaslangici);
	
	CvarKredi = CreateConVar("henny_sutol_kredi", "300", "Sut Ol sistemini kullanan oyuncuya kac kredi versin?");
	AutoExecConfig(true, "henny_sutol", "HennyConfig");
}

public OnMapStart()
{
	decl String:mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));
	if (!((StrEqual(mapName, "jb_", false)) || (StrEqual(mapName, "jail", false)) || (StrEqual(mapName, "ba_jail", false))))
	{
		SetFailState("[Henny] Bu eklenti sadece Jailbreak oyun modunda calismaktadir.");
	}
}

public OnClientPutInServer(int client)
{
	KomutKullanildi[client] = false;
	SDKUnhook(client, SDKHook_WeaponEquip, WeaponEquip);
}

public Action sutol(int client, int args)
{
	if (!(IsClientInGame(client)))
	{
		CPrintToChat(client, "{darkred}[%s] {default}Bu komutu kullanabilmeniz için {lime}oyunda {default}olmanız {red}lazım.", plugintag);
		return Plugin_Handled;
	}
	if (!(IsPlayerAlive(client)))
	{
		CPrintToChat(client, "{darkred}[%s] {default}Bu komutu kullanabilmeniz için {lime}yaşıyor {default}olmanız {red}lazım.", plugintag);
		return Plugin_Handled;
	}
	if (GetClientTeam(client) != 2)
	{
		CPrintToChat(client, "{darkred}[%s] {default}Bu komutu kullanabilmeniz için {gold}T Takımında {default}olmanız {red}lazım.", plugintag);
		return Plugin_Handled;
	}
	if (KomutKullanildi[client])
	{
		CPrintToChat(client, "{darkred}[%s] {default}Bu komut {gold}her round {default}sadece {lime}1 kere {red}kullanılabilir.", plugintag);
		return Plugin_Handled;
	}
	
	SilahlariTemizle(client);
	KomutKullanildi[client] = true;
	SDKHook(client, SDKHook_WeaponEquip, WeaponEquip);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + GetConVarInt(CvarKredi));
	CPrintToChatAll("{darkred}[%s] {gold}%N {default}bu el {orchid}süt olmayı {lime}tercih etti {default}ve {darkblue}%i kredi {green}kazandı.", plugintag, client, GetConVarInt(CvarKredi));
}

public Action turBaslangici(Event event, const String:name[], bool dontBroadcast)
{
	OyunculariSifirlari();
}

public Action WeaponEquip(int client, int weapon)
{
	if (KomutKullanildi[client])
	{
		CPrintToChat(client, "{darkred}[%s] {orchid}Süt Ol {default}yazdığınız için elinize {lime}silah {red}alamazsınız!", plugintag);
		AcceptEntityInput(weapon, "kill");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

OyunculariSifirlari()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		KomutKullanildi[i] = false;
		SDKUnhook(i, SDKHook_WeaponEquip, WeaponEquip);
	}
}

SilahlariTemizle(int client)
{
	for (new i = 0; i < 5; i++)
	{
		new weapon = -1;
		while ((weapon = GetPlayerWeaponSlot(client, i)) != -1)
		{
			if (IsValidEntity(weapon))
			{
				RemovePlayerItem(client, weapon);
				AcceptEntityInput(weapon, "Kill");
			}
		}
	}
}
