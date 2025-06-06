void PluginInit() {
    g_Module.ScriptInfo.SetAuthor("xWhitey");
    g_Module.ScriptInfo.SetContactInfo("@tyabus at Discord");
    
    g_rglpMaps.resize(0);
}

CClientCommand _lookpos("ar_lookpos", ".", @AR_CMD_LookPos, ConCommandFlag::AdminOnly);
CClientCommand _reload("ar_reload", ".", @AR_CMD_Reload, ConCommandFlag::AdminOnly);
CClientCommand _smartdivide("ar_smartdivide", ".", @AR_CMD_SmartDivide, ConCommandFlag::AdminOnly);
CClientCommand _getmodel("ar_getmodel", ".", @AR_CMD_GetModel, ConCommandFlag::AdminOnly);
//CClientCommand _test("ar_test", ".", @AR_CMD_Test, ConCommandFlag::AdminOnly);

string g_pszTemplateString = "______this_is_a_test_string_which_isn't_intended_to_be_read_by_anybody_anywhere_anytime_so_please_keep_your_eyes_out_of_this_very_precious_string._actually_the_history_why_this_string_exists_is_kinda_funny_lol._sniper_or_whoever_else_has_fucked_up_string_concatenation_entirely_in_angelscript_and_so_i_had_to_fix_this,_but_SetCharAt_method_in_string_class_doesn't_work_if_the_character_at_the_specified_position_is_empty_so_this_is_a_large_string_which_i_use_to_fill_resulting_strings_in_the_utility_which_concatenates_an_array_of_strings_into_a_big_string_to_bypass_the_SetCharAt_bug._Please_rate_five_stars_for_this_trick__________________________________________________________________________________________________________________________________________________________also_lmao_since_i_write_code_in_notepad_plus_plus_i_had_to_somehow_prevent_it_from_suggesting_words_from_this_very_string_and_this_is_the_reason_why_i_use_underscores_instead_of_spaces";

string AR_UTIL_BuildStringFromMultipleStrings(const array<string>& in _Strings) {
	size_t sTotalLength = 0;
	for (uint idx = 0; idx < _Strings.length(); idx++) {
		sTotalLength += _Strings[idx].Length();
	}
	
	if (sTotalLength > g_pszTemplateString.Length()) {
		return "Not enough data to copy from g_pszTemplateString!";
	}
	
	string szResult();
	szResult.Assign(g_pszTemplateString, 0, sTotalLength);
	
	uint nLocalIdx = 0;
	for (uint idx = 0; idx < _Strings.length(); idx++) {
		string szThis = _Strings[idx];
		for (uint j = 0; j < szThis.Length(); j++, nLocalIdx++) {
			szResult.SetCharAt(nLocalIdx, szThis[j]);
		}
	}
	
	return szResult;
}

void AR_CMD_Test(const CCommand@ _Args) {
    CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	string szResult();
	
	array<string> rgszStrings = array<string>(0);
	rgszStrings.insertLast("this");
	rgszStrings.insertLast(" is");
	rgszStrings.insertLast(" a");
	rgszStrings.insertLast(" test");
	
	szResult = AR_UTIL_BuildStringFromMultipleStrings(rgszStrings);
	
	g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "szResult: " + szResult + "\n");
}

Vector AR_UTIL_GetPosFromSight(CBasePlayer@ _Player) {
    g_EngineFuncs.MakeVectors(_Player.pev.v_angle);
    Vector vecStart = _Player.GetGunPosition();
    TraceResult tr;
    g_Utility.TraceLine(vecStart, vecStart + g_Engine.v_forward * 4096, dont_ignore_monsters, _Player.edict(), tr);
   
    return tr.vecEndPos;
}

CBaseEntity@ AR_UTIL_GetEyePosRayCastForEntity(CBasePlayer@ _Player) {
    g_EngineFuncs.MakeVectors(_Player.pev.v_angle);
    Vector vecStart = _Player.GetGunPosition();
    TraceResult tr;
    g_Utility.TraceLine(vecStart, vecStart + g_Engine.v_forward * 4096, dont_ignore_monsters, _Player.edict(), tr);
   
    return g_EntityFuncs.Instance(tr.pHit);
}

void AR_CMD_GetModel(const CCommand@ _Args) {
    CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
    CBaseEntity@ pEntity = AR_UTIL_GetEyePosRayCastForEntity(pPlayer);
    if (pEntity is null || pEntity.pev.classname == "worldspawn") {
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "[AntiRush] Ebulaxy?\n");
        return;
    }
    
    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "[AntiRush] Model: " + string(pEntity.pev.model) + "\n");
}

void AR_CMD_LookPos(const CCommand@ _Args) {
    CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
    Vector vecLookPos = AR_UTIL_GetPosFromSight(pPlayer);
    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[AntiRush] Your look position is " + string(int(vecLookPos.x)) + "," + string(int(vecLookPos.y)) + "," + string(int(vecLookPos.z)) + "\n");
}

void AR_CMD_SmartDivide(const CCommand@ _Args) {
    CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();
    float flNum1 = atof(_Args[1]);
    float flNum2 = atof(_Args[2]);
    float flNum3 = atof(_Args[3]);
    if (flNum3 == 0.f) {
        g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTCONSOLE, "[AntiRush] Ebulaxy?\n");
        return;
    }
    
    float flFinalNum = AR_UTIL_SmartDivide(Vector2D(flNum1, flNum2), flNum3);
    g_PlayerFuncs.ClientPrint(pPlayer, HUD_PRINTTALK, "[AntiRush] Number: " + string(flFinalNum) + "\n");
}

array<EHandle /* CBaseEntity@ */> g_rgpPathTracks;

void AR_CMD_Reload(const CCommand@ _Args) {
    for (int idx = 0; idx < g_Engine.maxEntities; idx++) {
        CBaseEntity@ pEntity = g_EntityFuncs.Instance(idx);
        if (pEntity !is null and pEntity.pev !is null) {
            string szClassname = pEntity.GetClassname();
            if (szClassname == "env_custom_beam") {
                CDynamicToggleableCustomEnvironmentBeam@ pBeam = cast<CDynamicToggleableCustomEnvironmentBeam@>(CastToScriptClass(pEntity));
                g_EntityFuncs.Remove(pBeam.m_pBeam);
                g_EntityFuncs.Remove(pEntity);
            } else if (szClassname == "func_dynamic_entity_spawner") {
                CDynamicEntitySpawner@ pSpawner = cast<CDynamicEntitySpawner@>(CastToScriptClass(pEntity));
                pSpawner.RemoveChildren(); //This will remove all children spawned by this spawner.
                g_EntityFuncs.Remove(pEntity);
            } else if (szClassname == "func_entry_exit_player_portal_parent") {
                CEntryExitPlayerPortals@ pPortals = cast<CEntryExitPlayerPortals@>(CastToScriptClass(pEntity));
                pPortals.RemoveChildren(); //This will remove "env_antirush_portal_sprite" too.
                g_EntityFuncs.Remove(pEntity);
            } else if (szClassname == "func_toggleable_custom_wall") {
                CToggleableCustomFuncWall@ pWall = cast<CToggleableCustomFuncWall@>(CastToScriptClass(pEntity));
                if (pWall.m_pChildWall !is null) {
                    g_EntityFuncs.Remove(pWall.m_pChildWall); //Meh. It would get deleted otherwise here, but let's save some computing power on comparing the classname.
                }
                g_EntityFuncs.Remove(pEntity);
            } else if (szClassname == "trigger_dynamic_player_counter" 
                    || szClassname == "env_dynamic_wall_number" || szClassname == "env_dynamic_wall_speaker" || szClassname == "env_dynamic_furniture"
                    || szClassname == "env_dynamic_kill_counter" || szClassname == "env_dynamic_skull" || szClassname == "env_dynamic_padlock" || szClassname == "func_custom_multi_manager"
                    || szClassname == "func_sqd_mstr_maker_hook" || szClassname == "func_checkpoint_spawner" || szClassname == "func_dynamic_lock_master"
                    || szClassname == "func_dynamic_keyvalue_dispatcher" || szClassname == "env_dynamic_arrow") {
                g_EntityFuncs.Remove(pEntity);
            } else if (szClassname == "env_dynamic_timer") {
                CEnvironmentDynamicWallTimer@ pTimer = cast<CEnvironmentDynamicWallTimer@>(CastToScriptClass(pEntity));
                for (uint j = 0; j < pTimer.m_rglpWallNumbers.length(); j++) {
                    CEnvironmentDynamicWallNumber@ pNumber = pTimer.m_rglpWallNumbers[j];
                    g_EntityFuncs.Remove(pNumber.GetSelf());
                }
                g_EntityFuncs.Remove(pEntity);
            } else if (szClassname == "env_flying_key") {
                CEnvironmentFlyingKey@ pKey = cast<CEnvironmentFlyingKey@>(CastToScriptClass(pEntity));
                g_EntityFuncs.Remove(pKey.m_pTheTrain);
                g_EntityFuncs.Remove(pEntity);
            }
        }
    }
    for (uint idx = 0; idx < g_rgpPathTracks.length(); idx++) {
        if (!g_rgpPathTracks[idx].IsValid()) continue;
        g_EntityFuncs.Remove(g_rgpPathTracks[idx].GetEntity());
    }
    g_rgpPathTracks.resize(0);

    AR_UTIL_ParseAntiRushMapEntriesList(true);
    string szMapName = g_Engine.mapname;
    CDynamicAntiRushMap@ pMap = AR_TryPlacingStuffIfMapExistsInList(szMapName);
    
    if (pMap is null) return;
    
    pMap.PlaceTimers();
    
    if (pMap.m_rglpSecondTargetNameStuff.length() == 0 && pMap.m_rglpSecondTargetNameMovedOutStuff.length() == 0) return;

    for (int idx = 0; idx < g_Engine.maxEntities; idx++) {
        CBaseEntity@ pEntity = g_EntityFuncs.Instance(idx);
        if (pEntity !is null and pEntity.pev !is null) {
            for (uint j = 0; j < pMap.m_rglpSecondTargetNameStuff.length(); j++) {
                CSecondEntityTargetNameHolder@ pHolder = @pMap.m_rglpSecondTargetNameStuff[j];
                if (pEntity.pev.model == pHolder.m_lpszModel) {
                    pHolder.m_hEntity = EHandle(pEntity);
                    break;
                }
            }
            for (uint j = 0; j < pMap.m_rglpSecondTargetNameMovedOutStuff.length(); j++) {
                CSecondEntityTargetNameMovedOutHolder@ pHolder = @pMap.m_rglpSecondTargetNameMovedOutStuff[j];
                if (pEntity.pev.model == pHolder.m_lpszModel) {
                    pHolder.m_hEntity = EHandle(pEntity);
                    g_EntityFuncs.SetOrigin(pEntity, Vector(171072, 171072, -171072));
                    pEntity.pev.absmin = g_vecZero;
                    pEntity.pev.absmax = g_vecZero;
                    break;
                }
            }
            for (uint j = 0; j < pMap.m_rglpSecondTargetNameMovedOutAndBackStuff.length(); j++) {
                CSecondEntityTargetNameMovedOutAndBackHolder@ pHolder = @pMap.m_rglpSecondTargetNameMovedOutAndBackStuff[j];
                if (pEntity.pev.model == pHolder.m_lpszModel) {
                    pHolder.m_hEntity = EHandle(pEntity);
                    pHolder.m_vecOriginalOrigin = pEntity.pev.origin;
                    pHolder.m_vecOriginalMins = pEntity.pev.absmin;
                    pHolder.m_vecOriginalMaxs = pEntity.pev.absmax;
                    g_EntityFuncs.SetOrigin(pEntity, Vector(171072, 171072, -171072));
                    pEntity.pev.absmin = g_vecZero;
                    pEntity.pev.absmax = g_vecZero;
                    break;
                }
            }
        }
    }
}

float g_flPI = 3.14159265358979323846f; 

float AR_UTIL_Degree2Radians(float _Degrees) {
      return (g_flPI * _Degrees / 180.0f);
}

void AR_UTIL_PrintToLog(string& in _Text) {
    string szEscaped = _Text.Replace("%", "{percent}");
    g_Log.PrintF(szEscaped);
}

bool AR_UTIL_DoesStringArrayHaveThisEntry(array<string>@ _Array, const string& in _TheEntry) {
    if (_Array is null) return false;

    for (uint idx = 0; idx < _Array.length(); idx++) {
        if (_Array[idx] == _TheEntry) return true;
    }
    
    return false;
}

class CCustomSpritePortalEntity : ScriptBaseAnimating {
    bool KeyValue(const string& in _KeyName, const string& in _KeyValue) {
		if (_KeyName == "m_bActive") {
			self.pev.iuser1 = (atoi(_KeyValue) != 0) ? 1 : 0;
		}
	
		return BaseClass.KeyValue(_KeyName, _KeyValue);
	}
	
	void Precache() {
        BaseClass.Precache();
        if (string(self.pev.model) != String::EMPTY_STRING)
            g_Game.PrecacheModel(string(self.pev.model));
    }
    
    void Animate(float frames) { 
        self.pev.frame += frames;
        if (self.pev.frame >= float(self.pev.iuser2))
            self.pev.frame = 0.f;
    }
    
    void Think() {
        if (!IsOn()) {
            self.pev.nextthink = g_Engine.time + 0.1f;
            return;
        }
    
        Animate(self.pev.framerate * (g_Engine.time - self.pev.fuser1));

        self.pev.nextthink = g_Engine.time + 0.1f;
        self.pev.fuser1 = g_Engine.time;
    }
    
    void Spawn() {
        BaseClass.Spawn();
        Precache();
        
        g_EntityFuncs.SetModel(self, self.pev.model);
        g_EntityFuncs.SetOrigin(self, self.pev.origin);
        g_EntityFuncs.SetSize(self.pev, g_vecZero, g_vecZero);
        self.pev.iuser2 = g_EngineFuncs.ModelFrames(g_EngineFuncs.ModelIndex(self.pev.model));
    
        self.pev.framerate = 10.f;
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        self.pev.scale = 1.f;
        self.pev.rendermode = kRenderTransAdd;
        self.pev.renderfx = kRenderFxNone;
        if (self.pev.iuser1 != 0) {
            self.pev.renderamt = 200;
        } else {
            self.pev.renderamt = 0;
        }
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void TurnOn() {
        self.pev.iuser1 = 1;
    }
    
    void TurnOff() {
        self.pev.iuser1 = 0;
    }
    
    bool IsOn() {
        return self.pev.iuser1 == 1;
    }
    
    bool ShouldToggle(USE_TYPE _UseType, bool _CurrentState) {
        if (_UseType != USE_TOGGLE && _UseType != USE_SET) {
            if ((_CurrentState && _UseType == USE_ON) || (!_CurrentState && _UseType == USE_OFF))
                return false;
        }
        return true;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unused) {
        if (ShouldToggle(_UseType, IsOn())) {
            if (IsOn()) {
                TurnOff();
            } else {
                TurnOn();
            }
        }
    }
}

class CEntryExitPlayerPortals : ScriptBaseEntity {
    EHandle m_hEntry;
    EHandle m_hExit;
    
    bool m_bArePortalsVisibleFromMapStart;
    bool m_bActive;
    
    Vector m_vecEntryPortal;
    Vector m_vecExitPortal;
    
    void RemoveChildren() {
        m_bActive = false;
        if (m_hEntry.IsValid()) {
            g_EntityFuncs.Remove(m_hEntry.GetEntity());
        }
        if (m_hExit.IsValid()) {
            g_EntityFuncs.Remove(m_hExit.GetEntity());
        }
    }

    void Precache() {
        BaseClass.Precache();
        
        g_Game.PrecacheModel("sprites/enter1.spr");
        g_Game.PrecacheModel("sprites/exit1.spr");
        g_SoundSystem.PrecacheSound("debris/beamstart7.wav");
        g_SoundSystem.PrecacheSound("debris/beamstart10.wav");
        g_SoundSystem.PrecacheSound("ambience/port_suckout1.wav");
    }
    
    void Spawn() {
        Precache();
        
        m_bActive = m_bArePortalsVisibleFromMapStart;
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        self.pev.mins = Vector(-36, -36, -36);
        self.pev.maxs = Vector(36, 36, 36);
        
        dictionary kvs;
        kvs["origin"] = string(m_vecEntryPortal.x) + " " + string(m_vecEntryPortal.y) + " " + string(m_vecEntryPortal.z);
        kvs["model"] = "sprites/enter1.spr";
        kvs["m_bActive"] = m_bArePortalsVisibleFromMapStart ? "1" : "0"; //Start on
        CBaseEntity@ pEntry = g_EntityFuncs.CreateEntity("env_antirush_portal_sprite", @kvs, false);
        if (pEntry is null) {
            AR_UTIL_PrintToLog("[AntiRush] CEntryExitPlayerPortals#Spawn: failed to create the entry portal sprite\n");
            return;
        }
        if (g_EntityFuncs.DispatchSpawn(pEntry.edict()) < 0) {
            AR_UTIL_PrintToLog("[AntiRush] CEntryExitPlayerPortals#Spawn: failed to dispatch spawn of the entry portal sprite\n");
            return;
        }
        m_hEntry = pEntry;
        kvs["origin"] = string(m_vecExitPortal.x) + " " + string(m_vecExitPortal.y) + " " + string(m_vecExitPortal.z);
        kvs["model"] = "sprites/exit1.spr";
        CBaseEntity@ pExit = g_EntityFuncs.CreateEntity("env_antirush_portal_sprite", @kvs, false);
        if (pExit is null) {
            AR_UTIL_PrintToLog("[AntiRush] CEntryExitPlayerPortals#Spawn: failed to create the exit portal sprite\n");
            return;
        }
        if (g_EntityFuncs.DispatchSpawn(pExit.edict()) < 0) {
            AR_UTIL_PrintToLog("[AntiRush] CEntryExitPlayerPortals#Spawn: failed to dispatch spawn of the exit portal sprite\n");
            return;
        }
        m_hExit = pExit;
        
        self.pev.nextthink = g_Engine.time + 1.0f;
    }
    
    void Think() {
        if (!m_bActive) {
            self.pev.nextthink = g_Engine.time + 0.5f;
            return;
        }
    
        CBaseEntity@ pEntry = m_hEntry.GetEntity();
        if (pEntry is null) {
            AR_UTIL_PrintToLog("[AntiRush] CEntryExitPlayerPortals#Think: entry portal sprite has died somehow\n");
            return;
        }
        CBaseEntity@ pExit = m_hExit.GetEntity();
        if (pExit is null) {
            AR_UTIL_PrintToLog("[AntiRush] CEntryExitPlayerPortals#Think: exit portal sprite has died somehow\n");
            return;
        }
        for (int idx = 1; idx <= g_Engine.maxClients; ++idx) {
            CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(idx);
        
            if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
                continue;
                
            bool bWantsToEnterEntry = true;
            
            bWantsToEnterEntry = bWantsToEnterEntry && pPlayer.pev.origin.x + pPlayer.pev.maxs.x >= pEntry.pev.origin.x + self.pev.mins.x;
            bWantsToEnterEntry = bWantsToEnterEntry && pPlayer.pev.origin.y + pPlayer.pev.maxs.y >= pEntry.pev.origin.y + self.pev.mins.y;
            bWantsToEnterEntry = bWantsToEnterEntry && pPlayer.pev.origin.z + pPlayer.pev.maxs.z >= pEntry.pev.origin.z + self.pev.mins.z;
            bWantsToEnterEntry = bWantsToEnterEntry && pPlayer.pev.origin.x + pPlayer.pev.mins.x <= pEntry.pev.origin.x + self.pev.maxs.x;
            bWantsToEnterEntry = bWantsToEnterEntry && pPlayer.pev.origin.y + pPlayer.pev.mins.y <= pEntry.pev.origin.y + self.pev.maxs.y;
            bWantsToEnterEntry = bWantsToEnterEntry && pPlayer.pev.origin.z + pPlayer.pev.mins.z <= pEntry.pev.origin.z + self.pev.maxs.z;
            
            if (!bWantsToEnterEntry) continue;
            
            g_SoundSystem.PlaySound(pEntry.edict(), CHAN_VOICE, "debris/beamstart10.wav", 1.f, ATTN_NORM, 0, PITCH_NORM, 1, true, pEntry.pev.origin);
            g_SoundSystem.PlaySound(pExit.edict(), CHAN_VOICE, "debris/beamstart7.wav", 1.f, ATTN_NORM, 0, PITCH_NORM, 1, true, pExit.pev.origin);
            
            g_EntityFuncs.SetOrigin(pPlayer, pExit.pev.origin + Vector(0, 0, 16));
        }
        
        self.pev.nextthink = g_Engine.time + 0.2f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unused) {
        CBaseEntity@ pEntry = m_hEntry.GetEntity();
        if (pEntry is null) {
            AR_UTIL_PrintToLog("[AntiRush] CEntryExitPlayerPortals#Use: entry portal sprite has died somehow\n");
        } else {
            if (!m_bActive) {
                pEntry.pev.renderamt = 200;
                g_SoundSystem.PlaySound(pEntry.edict(), CHAN_VOICE, "debris/beamstart7.wav", 1.f, ATTN_NORM, 0, PITCH_NORM, 1, true, pEntry.pev.origin);
            } else {
                pEntry.pev.renderamt = 0;
                g_SoundSystem.PlaySound(pEntry.edict(), CHAN_VOICE, "ambience/port_suckout1.wav", 1.f, ATTN_NORM, 0, PITCH_NORM, 1, true, pEntry.pev.origin);
            }
            pEntry.Use(_Activator, _Caller, _UseType, _Unused);
        }
        CBaseEntity@ pExit = m_hExit.GetEntity();
        if (pExit is null) {
            AR_UTIL_PrintToLog("[AntiRush] CEntryExitPlayerPortals#Use: exit portal sprite has died somehow\n");
        } else {
            if (!m_bActive) {
                pExit.pev.renderamt = 200;
                g_SoundSystem.PlaySound(pExit.edict(), CHAN_VOICE, "debris/beamstart7.wav", 1.f, ATTN_NORM, 0, PITCH_NORM, 1, true, pExit.pev.origin);
            } else {
                pExit.pev.renderamt = 0;
                g_SoundSystem.PlaySound(pExit.edict(), CHAN_VOICE, "ambience/port_suckout1.wav", 1.f, ATTN_NORM, 0, PITCH_NORM, 1, true, pExit.pev.origin);
            }
            pExit.Use(_Activator, _Caller, _UseType, _Unused);
        }
        m_bActive = !m_bActive;
    }
}

//Credits: CubeMath
class CToggleableCustomFuncWall : ScriptBaseEntity {
    Vector m_vecFirstPoint;   //should be pev.vuser1
    Vector m_vecSecondPoint;  //should be pev.vuser2
    Vector m_vecMinDiff;      //should be pev.vuser3
    Vector m_vecMaxDiff;      //should be pev.vuser4
    CBaseEntity@ m_pChildWall;
    string m_lpszTargetName; //needs to be cached here because pev.targetname cannot be set before spawn
    bool m_bAbleToHaveChildren;

    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        
        //
        //  Blocker wall which has the proper collision
        //
        if (m_bAbleToHaveChildren) {
            g_EntityFuncs.SetModel(self, "sprites/hlcancer/antirush/null.mdl"); //this is a "bad" wall
        }
        g_EntityFuncs.SetSize(self.pev, m_vecMinDiff, m_vecMaxDiff);
        g_EntityFuncs.SetOrigin(self, self.pev.origin);
        self.pev.solid = SOLID_BBOX;
        //
        //  Child wall which will block boolets (improper collision because no model is set)
        //  Notice the different order of calls/assignments
        //
        if (m_bAbleToHaveChildren) {
            @m_pChildWall = g_EntityFuncs.Create(self.pev.classname, self.pev.origin, g_vecZero, true, null);
            if (m_pChildWall !is null) {
                g_EntityFuncs.SetOrigin(m_pChildWall, self.pev.origin);
                m_pChildWall.pev.solid = SOLID_BBOX;
                m_pChildWall.pev.targetname = m_lpszTargetName;
                m_pChildWall.pev.effects |= EF_NODRAW;
                if (g_EntityFuncs.DispatchSpawn(m_pChildWall.edict()) >= 0) {
                    g_EntityFuncs.SetSize(m_pChildWall.pev, m_vecMinDiff, m_vecMaxDiff);
                } else {
                    string szText = "[AntiRush] CToggleableCustomFuncWall#Spawn: DispatchSpawn returned value less than zero on child wall\n";
                    AR_UTIL_PrintToLog(szText);
                    g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, szText);
                }
            } else {
                string szText = "[AntiRush] CToggleableCustomFuncWall#Spawn: Failure creating child wall\n";
                AR_UTIL_PrintToLog(szText);
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, szText);
            }
        }
        
        SetThink(ThinkFunction(KeepAlive));
        self.pev.nextthink = g_Engine.time + 1.0f;
    }
    
    void KeepAlive() {
        self.pev.nextthink = g_Engine.time + 1.0f;
    }
    
    void Touch(CBaseEntity@ _Other) {}
    
    void TurnOn() { //the child wall will also get toggled because it has the same classname we have
        self.pev.solid = SOLID_BBOX;
    }
    
    void TurnOff() {
        self.pev.solid = SOLID_NOT;
    }
    
    bool IsOn() {
        return self.pev.solid == SOLID_BBOX;
    }
    
    bool ShouldToggle(USE_TYPE _UseType, bool _CurrentState) {
        if (_UseType != USE_TOGGLE && _UseType != USE_SET) {
            if ((_CurrentState && _UseType == USE_ON) || (!_CurrentState && _UseType == USE_OFF))
                return false;
        }
        return true;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        if (ShouldToggle(_UseType, IsOn())) {
            if (IsOn()) {
                TurnOff();
            } else {
                TurnOn();
            }
        }
    }
}


float AR_UTIL_Hue2RGB(float p, float q, float t) {
    if (t < 0.0f) {
        t = t + 1.0f;
    }

    if (t > 1.0f) {
        t = t - 1.0f;
    }

    if (t < 1.0f / 6.0f) {
        return p + (q - p) * 6.0f * t;
    }

    if (t < 1.0f / 2.0f) {
        return q;
    }

    if (t < 2.0f / 3.0f) {
        return p + (q - p) * ((2.0f / 3.0f) - t) * 6.0f;
    }

    return p;
}

Vector AR_UTIL_HSL2RGB(Vector _HSL) {
    Vector vecRGB;

    if (_HSL.y == 0.0f) {
        vecRGB.x = _HSL.z;
        vecRGB.y = _HSL.z;
        vecRGB.z = _HSL.z;

        return vecRGB;
    }

    float q = _HSL.z < 0.5f ? _HSL.z * (1.0f + _HSL.y) : _HSL.z + _HSL.y - _HSL.z * _HSL.y;
    float p = 2.0f * _HSL.z - q;

    vecRGB.x = AR_UTIL_Hue2RGB(p, q, _HSL.x + (1.0f / 3.0f));
    vecRGB.y = AR_UTIL_Hue2RGB(p, q, _HSL.x);
    vecRGB.z = AR_UTIL_Hue2RGB(p, q, _HSL.x - (1.0f / 3.0f));

    return vecRGB;
}

class CDynamicToggleableCustomEnvironmentBeam : ScriptBaseEntity {
    Vector m_vecFirstPoint;
    Vector m_vecSecondPoint;
    Vector m_vecColour;
    Vector m_vecSecondColour;
    
    bool m_bFirstColourRainbow;
    bool m_bSecondColourRainbow;
    
    bool m_bState;
    
    float m_flHUE1;
    float m_flHUE2;
    
    float m_flDamage;
    
    CBeam@ m_pBeam; 
    
    bool m_bStateChanged;
    
    float m_flLastRainbowColourChangeTime;
    
    float m_flRenderAmount;
    
    string m_lpszBeamTargetName;

    void Precache() {
        BaseClass.Precache();
        
        g_Game.PrecacheModel("sprites/laserbeam.spr");
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
          
        if (m_vecColour.x == -1.f && m_vecColour.y == -1.f && m_vecColour.z == -1.f) {
            m_bFirstColourRainbow = true;
        }
        
        if (m_vecSecondColour.x == -1.f && m_vecSecondColour.y == -1.f && m_vecSecondColour.z == -1.f) {
            m_bSecondColourRainbow = true;
        }
        
        m_flHUE1 = m_flHUE2 = 0.f;
        
        @m_pBeam = g_EntityFuncs.CreateBeam("sprites/laserbeam.spr", 7);
        m_pBeam.SetFlags(BEAM_POINTS);
        m_pBeam.SetStartPos(m_vecFirstPoint);
        m_pBeam.SetEndPos(m_vecSecondPoint);
        m_pBeam.SetBrightness(int(m_flRenderAmount));
        m_pBeam.SetScrollRate(100);
        m_pBeam.pev.rendercolor = (m_bFirstColourRainbow ? g_vecZero : m_vecColour);
        @m_pBeam.pev.owner = self.edict();
        m_pBeam.pev.dmg = m_flDamage;
        m_pBeam.pev.targetname = m_lpszBeamTargetName;
        
        m_bStateChanged = true;
        
        m_flLastRainbowColourChangeTime = 0.f;
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        if (m_bState) {
            if (!m_bSecondColourRainbow) {
                m_pBeam.pev.rendercolor = m_vecSecondColour;
                if (m_pBeam.pev.rendercolor != m_vecSecondColour) {
                    m_bStateChanged = true;
                }
            } else {
                if (m_flLastRainbowColourChangeTime + 0.1f < g_Engine.time && g_Engine.time > 0.1f) {
                    Vector vecRGB = AR_UTIL_HSL2RGB(Vector(m_flHUE2, 0.8f, 0.5f));

                    m_flHUE2 = m_flHUE2 + 0.015f;

                    while (m_flHUE2 > 1.0f) {
                        m_flHUE2 = m_flHUE2 - 1.0f;
                    }
                    
                    m_pBeam.pev.rendercolor.x = 255.0f * vecRGB.x;
                    m_pBeam.pev.rendercolor.y = 255.0f * vecRGB.y;
                    m_pBeam.pev.rendercolor.z = 255.0f * vecRGB.z;
                    
                    m_bStateChanged = true;
                    
                    m_flLastRainbowColourChangeTime = g_Engine.time;
                }
            }
        } else {
            if (m_flDamage > 0.f) {
                TraceResult tr;
                
                g_Utility.TraceLine(m_vecFirstPoint, m_vecSecondPoint, dont_ignore_monsters, self.edict(), tr);
                m_pBeam.BeamDamage(tr);
            }
        
            if (!m_bFirstColourRainbow) {
                m_pBeam.pev.rendercolor = m_vecColour;
                if (m_pBeam.pev.rendercolor != m_vecColour) {
                    m_bStateChanged = true;
                }
            } else {
                if (m_flLastRainbowColourChangeTime + 0.1f < g_Engine.time && g_Engine.time > 0.1f) {
                    Vector vecRGB = AR_UTIL_HSL2RGB(Vector(m_flHUE1, 0.8f, 0.5f));

                    m_flHUE1 = m_flHUE1 + 0.015f;

                    while (m_flHUE1 > 1.0f) {
                        m_flHUE1 = m_flHUE1 - 1.0f;
                    }
                    
                    m_pBeam.pev.rendercolor.x = 255.0f * vecRGB.x;
                    m_pBeam.pev.rendercolor.y = 255.0f * vecRGB.y;
                    m_pBeam.pev.rendercolor.z = 255.0f * vecRGB.z;
                    
                    m_bStateChanged = true;
                    
                    m_flLastRainbowColourChangeTime = g_Engine.time;
                }
            }
        }
    
        if (m_bStateChanged)
            m_pBeam.RelinkBeam();
    
        self.pev.nextthink = g_Engine.time + 0.01f;
    }
    
    bool ShouldToggle(USE_TYPE _UseType, bool _CurrentState) {
        if (_UseType != USE_TOGGLE && _UseType != USE_SET) {
            if ((_CurrentState && _UseType == USE_ON) || (!_CurrentState && _UseType == USE_OFF))
                return false;
        }
        return true;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        if (ShouldToggle(_UseType, m_bState)) {
            m_bState = !m_bState;
            self.pev.nextthink = g_Engine.time + 0.01f; //think on the next frame
        }
    }
}

float AR_UTIL_RGB2HUE(const Vector& in _RGB) {
    float flR = _RGB.x;
    float flG = _RGB.y;
    float flB = _RGB.z;

    float flMax = Math.max(Math.max(flR, flG), flB);
    float flMin = Math.min(Math.min(flR, flG), flB);

    float flHUE;

    if (flMax == flMin) {
        flHUE = 0.0f;
    } else if (flMax == flR) {
        flHUE = (flG - flB) / (flMax - flMin);
        if (flG < flB)
            flHUE += 6.0f;
    } else if (flMax == flG) {
        flHUE = 2.0f + (flB - flR) / (flMax - flMin);
    } else {
        flHUE = 4.0f + (flR - flG) / (flMax - flMin);
    }

    flHUE /= 6.0f;

    if (flHUE < 0.0f)
        flHUE += 1.0f;

    return flHUE;
}

int AR_UTIL_PackColormap(uint8 _Top, uint8 _Bottom) {
    return _Top & 0xFF | ((_Bottom << 8) & 0xFF00);
}

void AR_UTIL_UnpackColormap(int _Colormap, uint8& out _Top, uint8& out _Bottom) {
    _Top = _Colormap & 0xFF;
    _Bottom = (_Colormap & 0xFF00) >> 8;
}

class CEnvironmentDynamicWallNumber : ScriptBaseEntity {
    Vector m_vecColour;
    Vector m_vecSecondColour;
    
    bool m_bFirstColourRainbow;
    bool m_bSecondColourRainbow;
    
    float m_flTopHue;
    float m_flBottomHue;
    
    bool m_bState;
    
    float m_flScale;
    
    CBaseEntity@ GetSelf() {
        return @self;
    }
    
    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        g_EntityFuncs.SetSize(self.pev, g_vecZero, g_vecZero);
        
        if (m_vecColour.x == -1.f && m_vecColour.y == -1.f && m_vecColour.z == -1.f) {
            m_bFirstColourRainbow = true;
        }
        
        if (m_vecSecondColour.x == -1.f && m_vecSecondColour.y == -1.f && m_vecSecondColour.z == -1.f) {
            m_bSecondColourRainbow = true;
        }
        
        self.pev.renderamt = 200;
        self.pev.rendermode = 5;
        self.pev.scale = m_flScale;
        m_flTopHue = AR_UTIL_RGB2HUE(m_bFirstColourRainbow ? g_vecZero : m_vecColour) * 255.f;
        m_flBottomHue = AR_UTIL_RGB2HUE(m_bSecondColourRainbow ? g_vecZero : m_vecSecondColour) * 255.f;
        self.pev.colormap = AR_UTIL_PackColormap(uint8(m_flTopHue), uint8(m_flTopHue));
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        self.pev.scale = m_flScale;
    
        if (m_bState) {
            if (m_bSecondColourRainbow) {
                Vector vecRGB = AR_UTIL_HSL2RGB(Vector(m_flBottomHue, 0.8f, 0.5f));

                m_flBottomHue = m_flBottomHue + 0.015f;

                while (m_flBottomHue > 1.0f) {
                    m_flBottomHue = m_flBottomHue - 1.0f;
                }
                
                float flHUE = AR_UTIL_RGB2HUE(vecRGB) * 255.f;
                
                self.pev.colormap = AR_UTIL_PackColormap(uint8(flHUE), uint8(flHUE));
            }
        } else {
            if (m_bFirstColourRainbow) {
                Vector vecRGB = AR_UTIL_HSL2RGB(Vector(m_flTopHue, 0.8f, 0.5f));

                m_flTopHue = m_flTopHue + 0.015f;

                while (m_flTopHue > 1.0f) {
                    m_flTopHue = m_flTopHue - 1.0f;
                }
                
                float flHUE = AR_UTIL_RGB2HUE(vecRGB) * 255.f;
                
                self.pev.colormap = AR_UTIL_PackColormap(uint8(flHUE), uint8(flHUE));
            }
        }
    
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        m_bState = !m_bState;
        self.pev.colormap = AR_UTIL_PackColormap(uint8(m_flBottomHue), uint8(m_flBottomHue));
    }
}

class CDynamicCheckpointSpawner : ScriptBaseEntity {
	CScheduledFunction@ m_pfnSpawnSnd, m_pfnCreateCheckoint;
    bool m_bActiveAtMapStart;
    string m_lpszKillTarget, m_lpszActivateTarget, m_lpszTargetName;
    Vector m_vecMinHullSize, m_vecMaxHullSize;
    CBaseEntity@ m_pCheckpoint;

	string m_lpszFunnelSprite /*= "sprites/glow01.spr"*/, m_lpszStartSound /*= "ambience/particle_suck2.wav"*/, m_lpszEndSound /*= "debris/beamstart7.wav"*/;

	void Precache() {
		BaseClass.Precache();
        
		/*g_Game.PrecacheOther("point_checkpoint");
		
		g_Game.PrecacheModel("models/common/lambda.mdl");
		g_Game.PrecacheGeneric("models/common/lambda.mdl");

		g_Game.PrecacheModel(m_lpszFunnelSprite);
		g_Game.PrecacheGeneric(m_lpszFunnelSprite);

		g_SoundSystem.PrecacheSound(m_lpszStartSound);
		g_SoundSystem.PrecacheSound(m_lpszEndSound);

		g_Game.PrecacheGeneric("sound/" + m_lpszStartSound);
		g_Game.PrecacheGeneric("sound/" + m_lpszEndSound);*/
	}

	void Spawn() {
        BaseClass.Spawn();
		Precache();
        
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.solid = SOLID_NOT;
        self.pev.targetname = m_lpszTargetName;
		g_EntityFuncs.SetOrigin(self, self.pev.origin);
        
        if (m_bActiveAtMapStart) {
            CreateCheckpoint();
            //g_EntityFuncs.Remove(self);
            return;
        }

		//BaseClass.Spawn();
	}

	void Use(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue) {
		@m_pfnSpawnSnd = g_Scheduler.SetTimeout(@this, "SpawnSnd", 1.6f);
		
		NetworkMessage largefunnel(MSG_PVS, NetworkMessages::SVC_TEMPENTITY, self.pev.origin, null);
			largefunnel.WriteByte(TE_LARGEFUNNEL);

			largefunnel.WriteCoord(self.pev.origin.x);
			largefunnel.WriteCoord(self.pev.origin.y);
			largefunnel.WriteCoord(self.pev.origin.z);

			largefunnel.WriteShort(g_EngineFuncs.ModelIndex(m_lpszFunnelSprite));
			largefunnel.WriteShort(0);
		largefunnel.End();

		@m_pfnCreateCheckoint = g_Scheduler.SetTimeout(@this, "CreateCheckpoint", 6.0f);
	}

	void SpawnSnd() {
		g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, m_lpszStartSound, 1.0f, ATTN_NORM);
	}

	void CreateCheckpoint() {
        dictionary kvs;
        if (m_vecMinHullSize != g_vecZero) {
            kvs["minhullsize"] = string(m_vecMinHullSize.x) + " " + string(m_vecMinHullSize.y) + " " + string(m_vecMinHullSize.z);
        }
        if (m_vecMaxHullSize != g_vecZero) {
            kvs["maxhullsize"] = string(m_vecMaxHullSize.x) + " " + string(m_vecMaxHullSize.y) + " " + string(m_vecMaxHullSize.z);
        }
        kvs["targetname"] = m_lpszTargetName;
        kvs["m_lpszActivateTarget"] = m_lpszActivateTarget;
        kvs["origin"] = string(self.pev.origin.x) + " " + string(self.pev.origin.y) + " " + string(self.pev.origin.z);
    
		CBaseEntity@ pCheckpoint = g_EntityFuncs.CreateEntity("point_checkpoint", @kvs, true); //self.pev.origin, g_vecZero, true, null
        //g_EntityFuncs.DispatchSpawn(pCheckpoint.edict());
        CBaseAnimating@ pAnimating = cast<CBaseAnimating@>(pCheckpoint);
        if (pAnimating !is null)
            pAnimating.m_iszKillTarget = m_lpszKillTarget;
		g_SoundSystem.EmitSound(self.edict(), CHAN_ITEM, m_lpszEndSound, 1.0f, ATTN_NORM);
        @m_pCheckpoint = pCheckpoint;
        
        //g_EntityFuncs.Remove(self);
	}

	void UpdateOnRemove() {
		if (m_pfnSpawnSnd !is null)
			g_Scheduler.RemoveTimer(m_pfnSpawnSnd);

		if (m_pfnCreateCheckoint !is null)
			g_Scheduler.RemoveTimer(m_pfnCreateCheckoint);
	}
}

class CDynamicLockMaster : ScriptBaseEntity {
    bool m_bActivated;
    
    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.solid = SOLID_NOT;
        self.pev.movetype = MOVETYPE_NONE;
        
        BaseClass.Spawn();
    }
    
    bool IsOn() {
        return m_bActivated;
    }
    
    bool ShouldToggle(USE_TYPE _UseType, bool _CurrentState) {
        if (_UseType != USE_TOGGLE && _UseType != USE_SET) {
            if ((_CurrentState && _UseType == USE_ON) || (!_CurrentState && _UseType == USE_OFF))
                return false;
        }
        return true;
    }
    
    void TurnOff() {
        m_bActivated = false;
    }
    
    void TurnOn() {
        m_bActivated = true;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        if (ShouldToggle(_UseType, IsOn())) {
            if (IsOn()) {
                TurnOff();
            } else {
                TurnOn();
            }
        }
    }
}

class CEnvironmentDynamicFurniture : ScriptBaseEntity {
    string m_lpszModel;
    Vector m_vecAbsMin;
    Vector m_vecAbsMax;
    EHandle m_hOriginalEntity;

    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.solid = SOLID_BSP;
        self.pev.movetype = MOVETYPE_PUSH;
        
        g_EntityFuncs.SetModel(self, m_lpszModel);
        
        g_EntityFuncs.SetOrigin(self, self.pev.origin);
        
        self.pev.absmin = m_vecAbsMin;
        self.pev.absmax = m_vecAbsMax;
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        self.pev.nextthink = g_Engine.time + 1.0f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        if (_Activator !is null && _Caller !is null) {
            if ((_Activator.pev.flags & FL_MONSTER) != 0 && _UseType != USE_TOGGLE) return;
            
            if (m_hOriginalEntity.IsValid()) {
                CBaseEntity@ pOriginalEntity = m_hOriginalEntity.GetEntity();
                g_EntityFuncs.SetOrigin(pOriginalEntity, self.pev.origin);
                pOriginalEntity.pev.absmin = m_vecAbsMin;
                pOriginalEntity.pev.absmax = m_vecAbsMax;
                g_EntityFuncs.Remove(self);
                pOriginalEntity.pev.velocity = g_vecZero;
            } else {
                AR_UTIL_PrintToLog("[AntiRush] Something REALLY weird happened to the original brush entity!\n");
            }
        }
    }
}

class CEnvironmentDynamicWallSpeaker : ScriptBaseEntity {
    string m_lpszSound;

    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        g_EntityFuncs.SetOrigin(self, self.pev.origin);
        
        g_Game.PrecacheGeneric("sound/" + m_lpszSound);
        g_SoundSystem.PrecacheSound(m_lpszSound);
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        self.pev.nextthink = g_Engine.time + 1.0f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        g_SoundSystem.EmitSoundDyn(self.edict(), CHAN_STATIC, m_lpszSound, 1.0f, ATTN_NORM, 1.0f, 100);
    }
}

void AR_UTIL_TargetEntity(const string& in _Name, CBaseEntity@ _Activator, CBaseEntity@ _Caller) {
    CBaseEntity@ pEntity = null;
    while ((@pEntity = g_EntityFuncs.FindEntityByTargetname(@pEntity, _Name)) !is null) {
        pEntity.Use(_Activator, _Caller, USE_TOGGLE, 0.f);
    }
    if (g_pCurrentMap !is null) {
        for (uint k = 0; k < g_pCurrentMap.m_rglpSecondTargetNameStuff.length(); k++) {
            CSecondEntityTargetNameHolder@ pHolder = g_pCurrentMap.m_rglpSecondTargetNameStuff[k];
            if (pHolder is null) continue;
            if (!pHolder.m_hEntity.IsValid()) continue;
            if (pHolder.m_lpszSecondTargetName != _Name) continue;
            CBaseEntity@ pHoldah = pHolder.m_hEntity.GetEntity();
            if (pHoldah.GetClassname().Find("trigger_") == 0) {
                for (int idx = 1; idx <= g_Engine.maxClients; ++idx) {
                    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(idx);
     
                    if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
                        continue;
                        
                    pHoldah.Use(pPlayer, pPlayer, USE_TOGGLE, 0.f);
                    pHoldah.Touch(pPlayer);
                    break;
                }
            } else {
                pHoldah.Use(_Activator, _Caller, USE_TOGGLE, 0.f);
            }
        }
        for (uint k = 0; k < g_pCurrentMap.m_rglpSecondTargetNameMovedOutStuff.length(); k++) {
            CSecondEntityTargetNameMovedOutHolder@ pHolder = g_pCurrentMap.m_rglpSecondTargetNameMovedOutStuff[k];
            if (pHolder is null) continue;
            if (!pHolder.m_hEntity.IsValid()) continue;
            if (pHolder.m_lpszSecondTargetName != _Name) continue;
            CBaseEntity@ pHoldah = pHolder.m_hEntity.GetEntity();
            if (pHoldah.GetClassname().Find("trigger_") == 0) {
                for (int idx = 1; idx <= g_Engine.maxClients; ++idx) {
                    CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(idx);
     
                    if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
                        continue;
                        
                    pHoldah.Use(pPlayer, pPlayer, USE_TOGGLE, 0.f);
                    pHoldah.Touch(pPlayer);
                    break;
                }
            } else {
                pHoldah.Use(_Activator, _Caller, USE_TOGGLE, 0.f);
            }
        }
        for (uint k = 0; k < g_pCurrentMap.m_rglpSecondTargetNameMovedOutAndBackStuff.length(); k++) {
            CSecondEntityTargetNameMovedOutAndBackHolder@ pHolder = g_pCurrentMap.m_rglpSecondTargetNameMovedOutAndBackStuff[k];
            if (pHolder is null) continue;
            if (!pHolder.m_hEntity.IsValid()) continue;
            if (pHolder.m_lpszSecondTargetName != _Name) continue;
            CBaseEntity@ pHoldah = pHolder.m_hEntity.GetEntity();
            g_EntityFuncs.SetOrigin(pHoldah, pHolder.m_vecOriginalOrigin);
            pHoldah.pev.absmin = pHolder.m_vecOriginalMins;
            pHoldah.pev.absmax = pHolder.m_vecOriginalMaxs;
            //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "Moved back this shit: " + pHoldah.GetClassname() + "\n");
        }
    }
}

class CEnvironmentDynamicWallTimer : ScriptBaseEntity {
    float m_flCurrentTimerValue;
    Vector m_vecColour;
    bool m_bActive;
    array<string> m_rgpszTargets;
    float m_flScale;

    array<CEnvironmentDynamicWallNumber@> m_rglpWallNumbers;
    
    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        g_EntityFuncs.SetOrigin(self, self.pev.origin);
        g_EntityFuncs.SetSize(self.pev, g_vecZero, g_vecZero);
        
        int iCurrentTimerValue = int(m_flCurrentTimerValue);
        string szCurrentTimerValue = string(iCurrentTimerValue);
        m_rglpWallNumbers.resize(szCurrentTimerValue.Length());
        Vector vecPosition = self.pev.origin;
            
        for (uint idx = 0; idx < m_rglpWallNumbers.length(); idx++) {
            float flYaw = self.pev.angles.y;
            float flRight = AR_UTIL_Degree2Radians(flYaw + 90.0f);
            CBaseEntity@ pEntity = g_EntityFuncs.Create("env_dynamic_wall_number", vecPosition, g_vecZero, true, null);
            CEnvironmentDynamicWallNumber@ pNumber = cast<CEnvironmentDynamicWallNumber@>(CastToScriptClass(pEntity));
            pNumber.m_vecColour = m_vecColour;
            pNumber.m_vecSecondColour = g_vecZero;
            pNumber.m_flScale = m_flScale;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.angles = self.pev.angles;
            @m_rglpWallNumbers[idx] = pNumber;
            
            vecPosition = Vector(vecPosition.x + cos(flRight) * (8.0f * pNumber.m_flScale), vecPosition.y + sin(flRight) * (8.0f * pNumber.m_flScale), vecPosition.z);
        }
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        if (m_flCurrentTimerValue <= 0.f) {
            for (uint j = 0; j < m_rgpszTargets.length(); j++) {
                string szName = m_rgpszTargets[j];
                float flTimeout = -1.f;
                for (uint i = 0; i < szName.Length(); i++) {
                    if (szName[i] == '#' /* timeout */) {
                        string szTimeout = szName.SubString(i + 1, szName.Length() - 1);
                        flTimeout = atof(szTimeout);
                        szName = szName.SubString(0, i);
                    }
                }
                        
                if (flTimeout <= -1.f) {
                    AR_UTIL_TargetEntity(szName, @self, @self);
                } else {
                    g_Scheduler.SetTimeout("AR_UTIL_TargetEntity", flTimeout, szName, @self, @self);
                }
            }
        
            for (uint idx = 0; idx < m_rglpWallNumbers.length(); idx++) {
                g_EntityFuncs.Remove(m_rglpWallNumbers[idx].GetSelf());
            }
            
            g_EntityFuncs.Remove(self);
        
            return;
        }
        
        int iCurrentTimerValue = int(m_flCurrentTimerValue);
        string szCurrentTimerValue = string(iCurrentTimerValue);
        while (szCurrentTimerValue.Length() != m_rglpWallNumbers.length()) {
            for (uint idx = 0; idx <= m_rglpWallNumbers.length() - 2; idx++) {
                CEnvironmentDynamicWallNumber@ pNum = m_rglpWallNumbers[m_rglpWallNumbers.length() - 2];
                float flYaw = pNum.pev.angles.y;
                float flRight = AR_UTIL_Degree2Radians(flYaw + 90.0f);
                pNum.pev.origin = Vector(pNum.pev.origin.x + cos(flRight) * (4.0f * m_flScale), pNum.pev.origin.y + sin(flRight) * (4.0f * m_flScale), pNum.pev.origin.z);
            }
            CEnvironmentDynamicWallNumber@ pLast = m_rglpWallNumbers[m_rglpWallNumbers.length() - 1];
            g_EntityFuncs.Remove(pLast.GetSelf());
        
            m_rglpWallNumbers.removeLast();
        }
        
        for (uint idx = 0; idx < szCurrentTimerValue.Length(); idx++) {
            CEnvironmentDynamicWallNumber@ pNumber = m_rglpWallNumbers[idx];
            string szModel = "sprites/hlcancer/antirush/d" + string(szCurrentTimerValue[idx]) + ".mdl";
            g_EntityFuncs.SetModel(pNumber.GetSelf(), szModel);
        }
        
        if (m_bActive) {
            m_flCurrentTimerValue = m_flCurrentTimerValue - 0.1f;
        }
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        m_bActive = !m_bActive;
    }
}

class CEnvironmentFlyingKey : ScriptBaseAnimating {
    CBaseEntity@ m_pTheTrain;
    float m_flSpeed;
    string m_lpszFirstNode;
    bool m_bActive;
    Vector m_vecColour;
    bool m_bActivated;
	string m_lpszTramTargetName;
    
    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        m_bActivated = false;
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        float flHUE = AR_UTIL_RGB2HUE(m_vecColour) * 255.f;
        self.pev.colormap = AR_UTIL_PackColormap(uint8(flHUE), uint8(flHUE));
        
        dictionary kvs;
        kvs["origin"] = string(self.pev.origin.x) + " " + string(self.pev.origin.y) + " " + string(self.pev.origin.z);
        kvs["speed"] = "256";
        kvs["rendermode"] = "1"; //Color
        kvs["renderamt"] = "0";
        kvs["spawnflags"] = "10"; //No User Control | Passable
        kvs["wheels"] = "32";
        kvs["target"] = m_lpszFirstNode;
        kvs["targetname"] = m_lpszTramTargetName.IsEmpty() ? (string(self.pev.targetname) + "_tram") : m_lpszTramTargetName;
        
        @m_pTheTrain = g_EntityFuncs.CreateEntity("func_tracktrain", @kvs, false);
        m_pTheTrain.pev.effects |= (EF_NOINTERP | EF_NODECALS | EF_NOANIMTEXTURES | EF_NODRAW);
        g_EntityFuncs.DispatchSpawn(m_pTheTrain.edict());
        m_pTheTrain.pev.mins = m_pTheTrain.pev.maxs = m_pTheTrain.pev.absmin = m_pTheTrain.pev.absmax = g_vecZero;
        m_pTheTrain.pev.effects |= (EF_NOINTERP | EF_NODECALS | EF_NOANIMTEXTURES | EF_NODRAW); //TBH I dunno if effects can be set pre-Spawn but I'm sure they can be set after Spawn, so yeah.
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        if (m_pTheTrain is null || !m_bActive) {
            self.pev.nextthink = g_Engine.time + 0.1f;
        
            return;
        }
        
        self.pev.angles = m_pTheTrain.pev.angles;
        self.pev.angles.y = self.pev.angles.y - 180.f;
        g_EntityFuncs.SetOrigin(self, m_pTheTrain.pev.origin);
        
        self.pev.nextthink = g_Engine.time + 0.01f;
    }
    
    void TurnOn() {
        m_bActivated = false;
        self.pev.renderamt = 255;
        self.pev.rendermode = kRenderNormal;
        self.pev.effects &= ~EF_NODRAW;
    }
    
    void TurnOff() {
        m_bActivated = true;
        self.pev.renderamt = 0;
        self.pev.rendermode = kRenderTransColor;
        self.pev.effects |= EF_NODRAW;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        if (m_pTheTrain is null) return;
        
        if (m_bActivated) {
            g_EntityFuncs.Remove(self);
            
            return;
        }
        
        if (m_bActive) {
            TurnOff();
        } else {
            TurnOn();
        }
        
        m_bActive = !m_bActive;
    
        m_pTheTrain.Use(_Activator, _Caller, _UseType, _Unknown);
    }
}

class CDynamicPlayerCounterTrigger : ScriptBaseEntity {
    private bool m_bActivated = false;
    array<string> m_rgpszTargets;
    float m_flPercentage = 0.66f; //Percentage of living people to be inside trigger to trigger
    Vector m_vecFirstPoint;
    Vector m_vecSecondPoint;
    array<string> m_rgpszMasters;
    array<EHandle> m_rghMasters;
    bool m_bHasFoundAllTheSkulls;
    
    bool KeyValue(const string& in _KeyName, const string& in _KeyValue) {
        if (_KeyName == "m_vecFirstPoint") {
            // the delimiter could've been a dot but "create" command would take that as an another kv so no
            g_Utility.StringToVector(m_vecFirstPoint, _KeyValue, ' ');
        
            return true;
        } else if (_KeyName == "m_vecSecondPoint") {
            g_Utility.StringToVector(m_vecSecondPoint, _KeyValue, ' ');
        
            return true;
        } else if (_KeyName == "m_rgpszTargets") {
            // same here as in the first kv
            const array<string>@ rgpszTargets = _KeyValue.Split(" ");
        
            m_rgpszTargets = rgpszTargets;
            
            return true;
        } else if (_KeyName == "m_flPercentage") {
            m_flPercentage = atof(_KeyValue);
        
            return true;
        } else if (_KeyName == "m_rgpszMasters") {
            // same here as in the first kv
            const array<string>@ rgpszMasters = _KeyValue.Split(" ");
        
            m_rgpszMasters = rgpszMasters;
        
            return true;
        }
    
        return BaseClass.KeyValue(_KeyName, _KeyValue);
    }
    
    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        self.pev.framerate = 1.0f;
        
        g_EntityFuncs.SetOrigin(self, self.pev.origin);
        g_EntityFuncs.SetSize(self.pev, m_vecFirstPoint, m_vecSecondPoint);
        
        self.pev.nextthink = g_Engine.time + 1.0f;
    }
    
    void Think() {
        if (m_rgpszMasters.length() != 0 && !m_bHasFoundAllTheSkulls) {
            m_rghMasters.resize(m_rgpszMasters.length());
            
            for (int j = 0; j < g_Engine.maxEntities; j++) {
                CBaseEntity@ pEntity = g_EntityFuncs.Instance(j);
                if (pEntity !is null and pEntity.pev !is null) {
                    for (uint idx = 0; idx < m_rgpszMasters.length(); idx++) {
                        if (pEntity.pev.targetname == m_rgpszMasters[idx]) {
                            m_rghMasters[idx] = EHandle(pEntity);
                            break;
                        }
                    }
                }
            }
            
            uint nValidSkulls = 0; 
            
            for (uint idx = 0; idx < m_rghMasters.length(); idx++) {
                if (m_rghMasters[idx].IsValid())
                    nValidSkulls++;
            }
            
            if (nValidSkulls == m_rghMasters.length()) {
                m_bHasFoundAllTheSkulls = true;
            } else {
                self.pev.nextthink = g_Engine.time + 1.0f;
            
                return;
            }
        }
    
        if (!m_bActivated) {
            float flTotalPlayers = 0.0f;
            float flTouchingPlayers = 0.0f;
                
            for (int idx = 1; idx <= g_Engine.maxClients; ++idx) {
                CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex(idx);
 
                if (pPlayer is null || !pPlayer.IsConnected() || !pPlayer.IsAlive())
                    continue;
                    
                bool bCondition = true;
                bCondition = bCondition && pPlayer.pev.origin.x + pPlayer.pev.maxs.x >= self.pev.origin.x + self.pev.mins.x;
                bCondition = bCondition && pPlayer.pev.origin.y + pPlayer.pev.maxs.y >= self.pev.origin.y + self.pev.mins.y;
                bCondition = bCondition && pPlayer.pev.origin.z + pPlayer.pev.maxs.z >= self.pev.origin.z + self.pev.mins.z;
                bCondition = bCondition && pPlayer.pev.origin.x + pPlayer.pev.mins.x <= self.pev.origin.x + self.pev.maxs.x;
                bCondition = bCondition && pPlayer.pev.origin.y + pPlayer.pev.mins.y <= self.pev.origin.y + self.pev.maxs.y;
                bCondition = bCondition && pPlayer.pev.origin.z + pPlayer.pev.mins.z <= self.pev.origin.z + self.pev.maxs.z;
                    
                if (bCondition) {
                    flTouchingPlayers = flTouchingPlayers + 1.0f;
                }
                
                flTotalPlayers = flTotalPlayers + 1.0f;
            }
                
            if (flTotalPlayers > 0.0f) {
                float flCurrentPercentage = flTouchingPlayers / flTotalPlayers + 0.00001f;

                bool bContinue = true;

                if (m_rghMasters.length() != 0 && m_bHasFoundAllTheSkulls) {
                    uint nFinishedMasters = 0;
                
                    for (uint idx = 0; idx < m_rghMasters.length(); idx++) {
                        EHandle hMaster = m_rghMasters[idx];
                        if (!hMaster.IsValid()) {
                            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] CDynamicPlayerCounterTrigger#Think: master is null\n");
                        
                            continue;
                        }
                        CBaseEntity@ pEntity = hMaster.GetEntity();
                        string szClassname = pEntity.GetClassname();
                        if (szClassname != "env_dynamic_skull" && szClassname != "env_flying_key" && szClassname != "func_checkpoint_spawner" && szClassname != "func_dynamic_lock_master") {
                            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] CDynamicPlayerCounterTrigger#Think: not a key, nor a skull and nor a checkpoint nor a lockmaster passed as a master\n");
                            
                            continue;
                        }
                        CEnvironmentDynamicSkull@ pSkull = cast<CEnvironmentDynamicSkull@>(CastToScriptClass(pEntity));
                        CEnvironmentFlyingKey@ pKey = cast<CEnvironmentFlyingKey@>(CastToScriptClass(pEntity));
                        CDynamicCheckpointSpawner@ pSpawner = cast<CDynamicCheckpointSpawner@>(CastToScriptClass(pEntity));
                        CDynamicLockMaster@ pMaster = cast<CDynamicLockMaster@>(CastToScriptClass(pEntity));
                        if (pSkull is null && pKey is null && pSpawner is null && pMaster is null) {
                            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] CDynamicPlayerCounterTrigger#Think: failed to cast pEntity!\n");
                            
                            continue;
                        }
                        if (pKey !is null) {
                            if (pKey.m_bActivated)
                                nFinishedMasters++;
                        }
                        if (pSkull !is null) {
                            if (pSkull.m_bActivated)
                                nFinishedMasters++;
                        }
                        if (pSpawner !is null) {
                            if (pSpawner.m_pCheckpoint !is null) {
                                if (pSpawner.m_pCheckpoint.pev.iuser4 == 1)
                                    nFinishedMasters++;
                            }
                        }
                        if (pMaster !is null) {
                            if (pMaster.m_bActivated)
                                nFinishedMasters++;
                        }
                    }
                    
                    if (nFinishedMasters != m_rghMasters.length()) {
                        bContinue = false;
                        //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[DEBUG] Skull wasn't collected!\n");
                    } else {
                        //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[DEBUG] Skull collected!\n");
                    }
                }

                if (flCurrentPercentage >= m_flPercentage && bContinue) {
                    m_bActivated = true;
                
                    for (uint j = 0; j < m_rgpszTargets.length(); j++) {
                        string szName = m_rgpszTargets[j];
                        float flTimeout = -1.f;
                        for (uint i = 0; i < szName.Length(); i++) {
                            if (szName[i] == '#' /* timeout */) {
                                string szTimeout = szName.SubString(i + 1, szName.Length() - 1);
                                flTimeout = atof(szTimeout);
                                szName = szName.SubString(0, i);
                            }
                        }
                        
                        if (flTimeout <= -1.f) {
                            AR_UTIL_TargetEntity(szName, @self, @self);
                        } else {
                            g_Scheduler.SetTimeout("AR_UTIL_TargetEntity", flTimeout, szName, @self, @self);
                        }
                    }
                }
            }
            
            self.pev.nextthink = g_Engine.time + 0.1f;
        }
    }
}

class CDynamicKeyValueDispatcher : ScriptBaseEntity {
    EHandle m_hTarget;
    bool m_bDoMagicAtMapStart;
    string m_lpszKeyvalueName;
    string m_lpszKeyvalueValue;
    
    string m_lpszTargetClassname;
    Vector m_vecOrigin;
    float m_flMaxError;
    
    string m_lpszModel;
    
    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        if (m_bDoMagicAtMapStart) {
            if (!m_hTarget.IsValid()) {
                SetThink(ThinkFunction(DispatchNoEntityThink));
                self.pev.nextthink = g_Engine.time + 0.1f;
                return;
            }
            CBaseEntity@ pEntity = m_hTarget.GetEntity();
            if (!g_EntityFuncs.DispatchKeyValue(pEntity.edict(), m_lpszKeyvalueName, m_lpszKeyvalueValue)) {
                AR_UTIL_PrintToLog("[AntiRush] CDynamicKeyValueDispatcher#Spawn: DispatchKeyValue failed\n");
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] CDynamicKeyValueDispatcher#Spawn: DispatchKeyValue failed\n");
            }
        }
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void DispatchNoEntityThink() {
        CBaseEntity@ pEntity = null;
        if (m_lpszTargetClassname != String::EMPTY_STRING && m_lpszModel == String::EMPTY_STRING) {
            for (int idx = 1; idx <= g_Engine.maxEntities; ++idx) {
                @pEntity = g_EntityFuncs.Instance(idx);
                if (pEntity is null) continue;
                if (pEntity.GetClassname().ToLowercase() != m_lpszTargetClassname.ToLowercase()) continue;
                if (fabsf(pEntity.pev.origin.x - m_vecOrigin.x) < m_flMaxError && fabsf(pEntity.pev.origin.y - m_vecOrigin.y) < m_flMaxError && fabsf(pEntity.pev.origin.z - m_vecOrigin.z) < m_flMaxError) {
                    m_hTarget = EHandle(pEntity);
                    break;
                }
            }
        } else if (m_lpszTargetClassname == String::EMPTY_STRING && m_lpszModel != String::EMPTY_STRING) {
            for (int idx = 1; idx <= g_Engine.maxEntities; ++idx) {
                @pEntity = g_EntityFuncs.Instance(idx);
                if (pEntity is null) continue;
                if (pEntity.pev.model != m_lpszModel.ToLowercase()) continue;
                m_hTarget = EHandle(pEntity);
                break;
            }
        }
        if (!m_hTarget.IsValid()) {
            //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "Invalid! " + m_lpszTargetClassname + "\n");
            self.pev.nextthink = g_Engine.time + 0.1f;
            return;
        }
        @pEntity = m_hTarget.GetEntity();
        if (!g_EntityFuncs.DispatchKeyValue(pEntity.edict(), m_lpszKeyvalueName, m_lpszKeyvalueValue)) {
            AR_UTIL_PrintToLog("[AntiRush] CDynamicKeyValueDispatcher#DispatchNoEntityThink: DispatchKeyValue failed\n");
            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] CDynamicKeyValueDispatcher#DispatchNoEntityThink: DispatchKeyValue failed\n");
        } else {
            SetThink(null);
            return;
        }
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        self.pev.nextthink = g_Engine.time + 5.0f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        if (!m_hTarget.IsValid()) {
            SetThink(ThinkFunction(DispatchNoEntityThink));
            self.pev.nextthink = g_Engine.time + 0.1f;
            return;
        }
        CBaseEntity@ pEntity = m_hTarget.GetEntity();
        if (!g_EntityFuncs.DispatchKeyValue(pEntity.edict(), m_lpszKeyvalueName, m_lpszKeyvalueValue)) {
            AR_UTIL_PrintToLog("[AntiRush] CDynamicKeyValueDispatcher#Use: DispatchKeyValue failed\n");
            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] CDynamicKeyValueDispatcher#Use: DispatchKeyValue failed\n");
        }
    }
}

array<int> g_rgiImmuneToDeleteByDeleteCommandEnts;

bool AR_UTIL_IsThisVeryEntityImmuneToDelete(const int& in _Index) {
    for (uint idx = 0; idx < g_rgiImmuneToDeleteByDeleteCommandEnts.length(); idx++) {
        if (g_rgiImmuneToDeleteByDeleteCommandEnts[idx] == _Index) {
            return true;
        }
    }

    return false;
}

class CDynamicEntitySpawner : ScriptBaseEntity {
    string m_lpszClassname;
    array<string> m_rgszKeyvalues;
    bool m_bDoMagicAtMapStart;
    array<EHandle> m_rghChildren;
    
    void RemoveChildren() {
        for (uint idx = 0; idx < m_rghChildren.length(); idx++) {
            if (!m_rghChildren[idx].IsValid()) continue;
            g_EntityFuncs.Remove(m_rghChildren[idx].GetEntity());
        }
    }
    
    void Precache() {
        BaseClass.Precache();
        if (g_CustomEntityFuncs.IsCustomEntity(m_lpszClassname)) return;
        g_Game.PrecacheOther(m_lpszClassname);
    }
    
    void Spawn() {
        Precache();
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        m_rghChildren.resize(0);
        
        if (m_bDoMagicAtMapStart) {
            CreateEntity();
        }
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void CreateEntity() {
        if (m_rgszKeyvalues.length() % 2 != 0) {
            AR_UTIL_PrintToLog("[AntiRush] CDynamicEntitySpawner#CreateEntity: there's probably a mismatch between key and its value, because length of the array isn't divisible by two!\n");
            string szTotal();
            for (uint idx = 0; idx < m_rgszKeyvalues.length(); idx++) {
                szTotal += m_rgszKeyvalues[idx];
                if (idx == m_rgszKeyvalues.length() - 1) {
                    szTotal += "\n";
                } else {
                    szTotal += ",";
                }
            }
            AR_UTIL_PrintToLog("[AntiRush] This spawner's keyvalues: " + szTotal);
            return;
        }
    
        dictionary kvs;
        for (uint idx = 0; idx < m_rgszKeyvalues.length(); ) {
            kvs[m_rgszKeyvalues[idx]] = m_rgszKeyvalues[idx + 1];
            idx += 2;
        }
        CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity(m_lpszClassname, @kvs, false);
        if (pEntity is null) {
            AR_UTIL_PrintToLog("[AntiRush] CDynamicEntitySpawner#CreateEntity: CreateEntity failed!\n");
            return;
        }
        if (g_EntityFuncs.DispatchSpawn(pEntity.edict()) < 0) {
            AR_UTIL_PrintToLog("[AntiRush] CDynamicEntitySpawner#CreateEntity: DispatchSpawn failed!\n");
            return;
        }
        g_rgiImmuneToDeleteByDeleteCommandEnts.insertLast(pEntity.entindex());
        m_rghChildren.insertLast(EHandle(pEntity));
    }
    
    void Think() {
        self.pev.nextthink = g_Engine.time + 5.0f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        CreateEntity();
    }
}

//useless shit that I don't really want to spend time on thinking about
class CEnvironmentDynamicKillCounter : ScriptBaseEntity {
    EHandle m_hTarget;

    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
}

class CEnvironmentDynamicSkull : ScriptBaseEntity {
    Vector m_vecColour;
    Vector m_vecSecondColour;
    array<string> m_rgpszTargets;
    array<string> m_rgpszKillCounters;
    array<EHandle> m_rghKillCounters;
    bool m_bActivated;

    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.scale = 2.f;
        
        m_bActivated = false;
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        float flHUE = AR_UTIL_RGB2HUE(m_vecColour) * 255.f;
        self.pev.colormap = AR_UTIL_PackColormap(uint8(flHUE), uint8(flHUE));
        
        m_rghKillCounters.resize(m_rgpszKillCounters.length());
        
        for (int j = 0; j < g_Engine.maxEntities; j++) {
            CBaseEntity@ pEntity = g_EntityFuncs.Instance(j);
            if (pEntity !is null and pEntity.pev !is null) {
                for (uint idx = 0; idx < m_rgpszKillCounters.length(); idx++) {
                    if (pEntity.pev.targetname == m_rgpszKillCounters[idx]) {
                        m_rghKillCounters[idx] = EHandle(pEntity);
                        break;
                    }
                }
            }
        }
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        uint nDeadTargets = 0;
        for (uint idx = 0; idx < m_rghKillCounters.length(); idx++) {
            EHandle hCounter = m_rghKillCounters[idx];
            if (!hCounter.IsValid()) {
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] CEnvironmentDynamicSkull#Think: one of counters has died somehow! Possible name: " + m_rgpszKillCounters[idx] + "\n");
                
                continue;
            }
            CBaseEntity@ pEntity = hCounter.GetEntity();
            CEnvironmentDynamicKillCounter@ pCounter = cast<CEnvironmentDynamicKillCounter@>(CastToScriptClass(pEntity));
            CSquadMonsterMakerHook@ pHook = cast<CSquadMonsterMakerHook@>(CastToScriptClass(pEntity));
            if (pCounter is null && pHook is null) {
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] CEnvironmentDynamicSkull#Think: failed to cast pEntity!\n");
                
                continue;
            }
            if (pHook !is null) {
                if (pHook.m_bHasKilledEveryone)
                    nDeadTargets++;
            }
            if (pCounter !is null) {
                if (!pCounter.m_hTarget.IsValid()) {
                    nDeadTargets++;
                    
                    continue;
                }
                CBaseEntity@ pTarget = pCounter.m_hTarget.GetEntity();
                if (!pTarget.IsAlive()) {
                    nDeadTargets++;
                    
                    continue;
                }
                if (pTarget.pev.health <= 0.f) {
                    nDeadTargets++;
                    
                    continue;
                }
            }
        }
        if (nDeadTargets == m_rghKillCounters.length()) {
            for (uint j = 0; j < m_rgpszTargets.length(); j++) {
                string szName = m_rgpszTargets[j];
                float flTimeout = -1.f;
                for (uint i = 0; i < szName.Length(); i++) {
                    if (szName[i] == '#' /* timeout */) {
                        string szTimeout = szName.SubString(i + 1, szName.Length() - 1);
                        flTimeout = atof(szTimeout);
                        szName = szName.SubString(0, i);
                    }
                }
                        
                if (flTimeout <= -1.f) {
                    AR_UTIL_TargetEntity(szName, @self, @self);
                } else {
                    g_Scheduler.SetTimeout("AR_UTIL_TargetEntity", flTimeout, szName, @self, @self);
                }
            }
                
            float flHUE = AR_UTIL_RGB2HUE(m_vecSecondColour) * 255.f;
            self.pev.colormap = AR_UTIL_PackColormap(uint8(flHUE), uint8(flHUE));
            
            //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "Yee\n");
            
            m_bActivated = true;
            
            return;
        }
        
        self.pev.nextthink = g_Engine.time + 0.5f;
    }
}

class CEnvironmentDynamicPadlock : ScriptBaseEntity {
    Vector m_vecColour;

    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        float flHUE = AR_UTIL_RGB2HUE(m_vecColour) * 255.f;
        self.pev.colormap = AR_UTIL_PackColormap(uint8(flHUE), uint8(flHUE));
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        self.pev.nextthink = g_Engine.time + 5.f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        g_EntityFuncs.Remove(self);
    }
}

class CEnvironmentDynamicArrow : ScriptBaseEntity {
    Vector m_vecColour;
    bool m_bActiveAtMapStart;
    bool m_bActive;

    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        self.pev.effects |= EF_NODRAW;
        
        m_bActive = m_bActiveAtMapStart;
        
        if (m_bActive) {
            TurnOn();
        }
        /*
         else {
            TurnOff();
        }
        */
        
        float flHUE = AR_UTIL_RGB2HUE(m_vecColour) * 255.f;
        self.pev.colormap = AR_UTIL_PackColormap(uint8(flHUE), uint8(flHUE));
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        self.pev.nextthink = g_Engine.time + 5.f;
    }
    
    void TurnOn() {
        self.pev.rendermode = kRenderNormal;
        self.pev.renderamt = 255;
        self.pev.effects &= ~EF_NODRAW;
    }
    
    void TurnOff() {
        self.pev.rendermode = kRenderTransColor;
        self.pev.renderamt = 0;
        self.pev.effects |= EF_NODRAW;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        if (m_bActive) {
            TurnOff();
        } else {
            TurnOn();
        }
        
        m_bActive = !m_bActive;
    }
}

class CCustomMultiManager : ScriptBaseEntity {
    array<string> m_rgpszTargets;

    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        self.pev.nextthink = g_Engine.time + 5.f;
    }
    
    void Use(CBaseEntity@ _Activator, CBaseEntity@ _Caller, USE_TYPE _UseType, float _Unknown) {
        //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "Yee!\n");
    
        for (uint j = 0; j < m_rgpszTargets.length(); j++) {
            string szName = m_rgpszTargets[j];
            float flTimeout = -1.f;
            for (uint i = 0; i < szName.Length(); i++) {
                if (szName[i] == '#' /* timeout */) {
                    string szTimeout = szName.SubString(i + 1, szName.Length() - 1);
                    flTimeout = atof(szTimeout);
                    szName = szName.SubString(0, i);
                }
            }
                        
            if (flTimeout <= -1.f) {
                AR_UTIL_TargetEntity(szName, @self, @self);
            } else {
                g_Scheduler.SetTimeout("AR_UTIL_TargetEntity", flTimeout, szName, @self, @self);
            }
        }
    }
}

class CSquadMonsterMakerHook : ScriptBaseEntity {
    EHandle m_hSquadMaker;
    float m_flMaxError;
    bool m_bHasSetUp;
    string m_lpszSquadMemberTargetName;
    bool m_bHasKilledEveryone;
    array<EHandle> m_hTargets;
    
    float m_flLastMessagePrintTime;
    
    string m_lpszTargetClassname;
    
    void Precache() {
        BaseClass.Precache();
    }
    
    void Spawn() {
        Precache();
        
        self.pev.movetype = MOVETYPE_NONE;
        self.pev.solid = SOLID_NOT;
        
        m_hTargets.resize(0);
        
        m_flLastMessagePrintTime = 0.f;
        
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
    
    void Think() {
        if (!m_hSquadMaker.IsValid()) {
            CBaseEntity@ pEntity = null;
            while ((@pEntity = g_EntityFuncs.FindEntityByClassname(pEntity, m_lpszTargetClassname)) !is null) {
                if (fabsf(pEntity.pev.origin.x - self.pev.origin.x) < m_flMaxError && fabsf(pEntity.pev.origin.y - self.pev.origin.y) < m_flMaxError && fabsf(pEntity.pev.origin.z - self.pev.origin.z) < m_flMaxError) {
                    m_hSquadMaker = EHandle(pEntity);
                    break;
                }
            }
            if (!m_hSquadMaker.IsValid() && m_flLastMessagePrintTime + 2.5f < g_Engine.time) {
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] Failed to find a squadmaker/monstermaker at these coors: " + self.pev.origin.ToString() + "\n");
            
                m_flLastMessagePrintTime = g_Engine.time;
            }
        }
        if (m_hSquadMaker.IsValid() && !m_bHasSetUp) {
            CBaseEntity@ pSquadMaker = m_hSquadMaker.GetEntity();
            string szNetName = string(pSquadMaker.pev.netname);
            if (szNetName.IsEmpty()) {
                m_lpszSquadMemberTargetName = string(self.pev.targetname);
                m_lpszSquadMemberTargetName = m_lpszSquadMemberTargetName + "_sqd_mbr";
                pSquadMaker.pev.netname = m_lpszSquadMemberTargetName;
            } else {
                m_lpszSquadMemberTargetName = pSquadMaker.pev.netname;
            }
        
            m_bHasSetUp = true;
        }
        if (m_bHasSetUp && !m_bHasKilledEveryone) {
            int nAliveCount = 0;
            
            array<EHandle> hTargets;
        
            CBaseEntity@ pEntity = null;
            while ((@pEntity = g_EntityFuncs.FindEntityByTargetname(pEntity, m_lpszSquadMemberTargetName)) !is null) {
                if (pEntity.IsAlive() || pEntity.pev.health > 0.f)
                    nAliveCount++;
                
                hTargets.insertLast(EHandle(pEntity));
            }
            
            if (hTargets.length() != 0 && hTargets.length() != m_hTargets.length()) {
                m_hTargets = hTargets;
            }
            
            uint nDeadCount = 0;
            
            for (uint idx = 0; idx < m_hTargets.length(); idx++) {
                EHandle hTarget = m_hTargets[idx];
                if (!hTarget.IsValid()) {
                    nDeadCount++;
                    continue;
                }
                CBaseEntity@ pTarget = hTarget.GetEntity();
                if (!pTarget.IsAlive() || pTarget.pev.health <= 0.f) {
                    nDeadCount++;
                }
            }
            
            if (m_hTargets.length() != 0 && nDeadCount == m_hTargets.length()) {
                m_bHasKilledEveryone = true;
                //g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "Yes!\n");
            }/* else {
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "nAliveCount: " + string(nAliveCount) + ", nFoundCount: " + string(m_hTargets.length()) + "\n");
            }*/
        }
    
        self.pev.nextthink = g_Engine.time + 0.1f;
    }
}

class CDynamicFuncWallToggle {
    Vector m_vecFirstPoint;
    Vector m_vecSecondPoint;
    string m_lpszName;
    
    CDynamicFuncWallToggle(const Vector& in _P1, const Vector& in _P2, const string& in _Name) {
        m_vecFirstPoint = _P1;
        m_vecSecondPoint = _P2;
        m_lpszName = _Name;
    }
}

class CDynamicEnvBeam {
    Vector m_vecFirstPoint;
    Vector m_vecSecondPoint;
    Vector m_vecColour;
    Vector m_vecSecondColour;
    string m_lpszName;
    float m_flDamage;
    float m_flRenderAmount;
    
    CDynamicEnvBeam(const Vector& in _P1, const Vector& in _P2, const Vector& in _Colour, const Vector& in _SecondColour, const string& in _Name, const float& in _RenderAmount, const float& in _Damage) {
        m_vecFirstPoint = _P1;
        m_vecSecondPoint = _P2;
        m_vecColour = _Colour;
        m_vecSecondColour = _SecondColour;
        m_lpszName = _Name;
        m_flDamage = _Damage;
        m_flRenderAmount = _RenderAmount;
    }
}

class CDynamicPlayerCounter {
    Vector m_vecFirstPoint;
    Vector m_vecSecondPoint;
    array<string> m_rgpszTargets;
    float m_flPercentage;
    array<string> m_rgpszMasters;
    
    CDynamicPlayerCounter(const Vector& in _P1, const Vector& in _P2, float _Percentage, array<string> _Targets, array<string> _Masters) {
        m_vecFirstPoint = _P1;
        m_vecSecondPoint = _P2;
        m_rgpszTargets = _Targets;
        m_flPercentage = _Percentage;
        m_rgpszMasters = _Masters;
    }
}

class CDynamicWallTimer {
    Vector m_vecPosition;
    Vector m_vecAngles;
    Vector m_vecColour; //RGB
    float m_flTime;
    bool m_bActivatedOnMapStart;
    float m_flScale;
    string m_lpszTargetName;
    array<string> m_rgpszTargets;
    
    CDynamicWallTimer(const Vector& in _Position, const Vector& in _Angles, const Vector& in _Colour, float _Time, bool _ActivatedOnMapStart, float _Scale, const string& in _TargetName, array<string> _Targets) {
        m_vecPosition = _Position;
        m_vecAngles = _Angles;
        m_vecColour = _Colour;
        m_flTime = _Time;
        m_bActivatedOnMapStart = _ActivatedOnMapStart;
        m_flScale = _Scale;
        m_lpszTargetName = _TargetName;
        m_rgpszTargets = _Targets;
    }
}

class CDynamicWallNumber {
    Vector m_vecPosition;
    string m_lpszNumber;
    string m_lpszTargetName;
    Vector m_vecAngles;
    Vector m_vecColour;
    Vector m_vecSecondColour;
    float m_flScale;
    
    CDynamicWallNumber(const Vector& in _Position, const string& in _Number, const string& in _TargetName, const Vector& in _Angles, const Vector& in _Colour, const Vector& in _SecondColour, float _Scale) {
        m_vecPosition = _Position;
        m_lpszNumber = _Number;
        m_lpszTargetName = _TargetName;
        m_vecAngles = _Angles;
        m_vecColour = _Colour;
        m_vecSecondColour = _SecondColour;
        m_flScale = _Scale;
    }
}

class CDynamicWallSpeaker {
    string m_lpszSound;
    Vector m_vecPosition;
    string m_lpszTargetName;
    
    CDynamicWallSpeaker(const Vector& in _Position, const string& in _Sound, const string& in _TargetName) {
        m_vecPosition = _Position;
        m_lpszSound = _Sound;
        m_lpszTargetName = _TargetName;
    }
}

class CSecondEntityTargetNameHolder {
    EHandle m_hEntity;
    string m_lpszModel;
    string m_lpszSecondTargetName;
    
    CSecondEntityTargetNameHolder(const string& in _Model, const string& in _TargetName) {
        m_lpszModel = _Model;
        m_lpszSecondTargetName = _TargetName;
        m_hEntity = null;
    }
}

class CDynamicFurnitureHolder {
    string m_lpszModel;
    string m_lpszTargetName;
    
    CDynamicFurnitureHolder(const string& in _Model, const string& in _TargetName) {
        m_lpszModel = _Model;
        m_lpszTargetName = _TargetName;
    }
}

class CSecondEntityTargetNameMovedOutHolder {
    EHandle m_hEntity;
    string m_lpszModel;
    string m_lpszSecondTargetName;
    
    CSecondEntityTargetNameMovedOutHolder(const string& in _Model, const string& in _TargetName) {
        m_lpszModel = _Model;
        m_lpszSecondTargetName = _TargetName;
        m_hEntity = null;
    }
}

class CSecondEntityTargetNameMovedOutAndBackHolder {
    EHandle m_hEntity;
    string m_lpszModel;
    string m_lpszSecondTargetName;
    Vector m_vecOriginalOrigin;
    Vector m_vecOriginalMins;
    Vector m_vecOriginalMaxs;
    
    CSecondEntityTargetNameMovedOutAndBackHolder(const string& in _Model, const string& in _TargetName) {
        m_lpszModel = _Model;
        m_lpszSecondTargetName = _TargetName;
        m_hEntity = null;
        m_vecOriginalOrigin = m_vecOriginalMins = m_vecOriginalMaxs = g_vecZero;
    }
}

class CMoveOutEntityOnSpawnHolder {
    Vector m_vecOrigin;
    Vector m_vecDest;
    float m_flMaxError;
    string m_lpszClassname;
    bool m_bDelete;
    
    CMoveOutEntityOnSpawnHolder(const Vector& in _Origin, const Vector& in _Dest, float _MaxError, const string& in _Classname, bool _Delete) {
        m_vecOrigin = _Origin;
        m_vecDest = _Dest;
        m_flMaxError = _MaxError;
        m_lpszClassname = _Classname;
        m_bDelete = _Delete;
    }
}

class CKillCounterHolder {
    Vector m_vecOrigin;
    float m_flMaxError;
    string m_lpszClassname;
    string m_lpszTargetName;
    
    CKillCounterHolder(const Vector& in _Origin, float _MaxError, const string& in _Classname, const string& in _TargetName) {
        m_vecOrigin = _Origin;
        m_flMaxError = _MaxError;
        m_lpszClassname = _Classname;
        m_lpszTargetName = _TargetName;
    }
}

class CKeyValueDispatcherHolder {
    Vector m_vecOrigin;
    float m_flMaxError;
    string m_lpszClassname;
    string m_lpszKeyvalueName;
    string m_lpszKeyvalueValue;
    string m_lpszTargetName;
    bool m_bDoMagicAtMapStart;
    
    CKeyValueDispatcherHolder(const Vector& in _Origin, float _MaxError, const string& in _Classname, const string& in _TargetName, const string& in _KeyvalueName, const string& in _KeyvalueValue, const bool& in _DoMagicAtMapStart) {
        m_vecOrigin = _Origin;
        m_flMaxError = _MaxError;
        m_lpszClassname = _Classname;
        m_lpszTargetName = _TargetName;
        m_lpszKeyvalueName = _KeyvalueName;
        m_lpszKeyvalueValue = _KeyvalueValue;
        m_bDoMagicAtMapStart = _DoMagicAtMapStart;
    }
}

class CKeyValueDispatcherByModelHolder {
    string m_lpszModel;
    string m_lpszKeyvalueName;
    string m_lpszKeyvalueValue;
    string m_lpszTargetName;
    bool m_bDoMagicAtMapStart;
    
    CKeyValueDispatcherByModelHolder(const string& in _Model, const string& in _TargetName, const string& in _KeyvalueName, const string& in _KeyvalueValue, const bool& in _DoMagicAtMapStart) {
        m_lpszModel = _Model;
        m_lpszTargetName = _TargetName;
        m_lpszKeyvalueName = _KeyvalueName;
        m_lpszKeyvalueValue = _KeyvalueValue;
        m_bDoMagicAtMapStart = _DoMagicAtMapStart;
    }
}

class CTrainPathNode {
    Vector m_vecPosition;
    float m_flSpeed;
    string m_lpszTargetName;
    string m_lpszNextNode;
    string m_lpszFireOnPass;

    CTrainPathNode(const Vector& in _Position, float _Speed, const string& in _TargetName, const string& in _NextNode, const string& in _FireOnPass) {
        m_vecPosition = _Position;
        m_flSpeed = _Speed;
        m_lpszTargetName = _TargetName;
        m_lpszNextNode = _NextNode;
        m_lpszFireOnPass = _FireOnPass;
    }
}

class CDynamicFlyingKey {
    Vector m_vecPosition;
    Vector m_vecAngles;
    Vector m_vecColour;
    string m_lpszTargetName;
    string m_lpszFirstNode;

    CDynamicFlyingKey(const Vector& in _Position, const Vector& in _Angles, const Vector& in _Colour, const string& in _TargetName, const string& in _FirstNode) {
        m_vecPosition = _Position;
        m_vecAngles = _Angles;
        m_vecColour = _Colour;
        m_lpszTargetName = _TargetName;
        m_lpszFirstNode = _FirstNode;
    }
}

class CDynamicPadlock {
    Vector m_vecPosition;
    Vector m_vecAngles;
    Vector m_vecColour;
    string m_lpszTargetName;

    CDynamicPadlock(const Vector& in _Position, const Vector& in _Angles, const Vector& in _Colour, const string& in _TargetName) {
        m_vecPosition = _Position;
        m_vecAngles = _Angles;
        m_vecColour = _Colour;
        m_lpszTargetName = _TargetName;
    }
}

class CDynamicSkullHolder {
    Vector m_vecPosition;
    Vector m_vecAngles;
    Vector m_vecColour;
    Vector m_vecSecondColour;
    string m_lpszTargetName;
    array<string> m_rgpszTargets;
    array<string> m_rgpszKillCounters;

    CDynamicSkullHolder(const Vector& in _Position, const Vector& in _Angles, const Vector& in _Colour, const Vector& in _SecondColour, const string& in _TargetName, array<string> _Targets, array<string> _KillCounters) {
        m_vecPosition = _Position;
        m_vecAngles = _Angles;
        m_vecColour = _Colour;
        m_vecSecondColour = _SecondColour;
        m_lpszTargetName = _TargetName;
        m_rgpszTargets = _Targets;
        m_rgpszKillCounters = _KillCounters;
    }
}

class CDynamicArrowHolder {
    string m_lpszTargetName;
    Vector m_vecPosition;
    Vector m_vecAngles;
    Vector m_vecColour;
    bool m_bActiveAtMapStart;

    CDynamicArrowHolder(const string& in _TargetName, const Vector& in _Position, const Vector& in _Angles, const Vector& in _Colour, const bool& in _ActiveAtMapStart) {
        m_lpszTargetName = _TargetName;
        m_vecPosition = _Position;
        m_vecAngles = _Angles;
        m_vecColour = _Colour;
        m_bActiveAtMapStart = _ActiveAtMapStart;
    }
}

class CMultiManagerHolder {
    string m_lpszTargetName;
    array<string> m_rgpszTargets;
    
    CMultiManagerHolder(const string& in _TargetName, array<string> _Targets) {
        m_lpszTargetName = _TargetName;
        m_rgpszTargets = _Targets;
    }
}

class CSquadMakerHookHolder {
    Vector m_vecPosition;
    float m_flMaxError;
    string m_lpszTargetName;
    
    CSquadMakerHookHolder(const Vector& in _Position, float _MaxError, const string& in _TargetName) {
        m_vecPosition = _Position;
        m_flMaxError = _MaxError;
        m_lpszTargetName = _TargetName;
    }
}

class CCheckpointSpawnerHolder {
    Vector m_vecPosition;
    string m_lpszFunnelSprite, m_lpszStartSound, m_lpszEndSound, m_lpszTargetName, m_lpszKillTarget, m_lpszActivateTarget;
    bool m_bActiveAtMapStart;
    Vector m_vecMinHullSize;
    Vector m_vecMaxHullSize;

    CCheckpointSpawnerHolder(const Vector& in _Position, const string& in _FunnelSprite, const string& in _StartSound, const string& in _EndSound, const string& in _TargetName, const string& in _KillTarget, const string& in _ActivateTarget, bool _ActiveAtMapStart, const Vector& in _MinHullSize, const Vector& in _MaxHullSize) {
        m_vecPosition = _Position;
        m_lpszFunnelSprite = _FunnelSprite;
        m_lpszStartSound = _StartSound;
        m_lpszEndSound = _EndSound;
        m_lpszTargetName = _TargetName;
        m_lpszKillTarget = _KillTarget;
        m_lpszActivateTarget = _ActivateTarget;
        m_bActiveAtMapStart = _ActiveAtMapStart;
        m_vecMinHullSize = _MinHullSize;
        m_vecMaxHullSize = _MaxHullSize;
    }
}

class CMasterHolder {
    string m_lpszTargetName;
    
    CMasterHolder(const string& in _TargetName) {
        m_lpszTargetName = _TargetName;
    }
}

class CEntitySpawnerHolder {
    string m_lpszClassname;
    string m_lpszTargetName;
    array<string> m_rgszKeyvalues;
    bool m_bDoMagicAtMapStart;
    
    CEntitySpawnerHolder(const string& in _Classname, const string& in _TargetName, array<string> _Keyvalues, const bool& in _DoMagicAtMapStart) {
        m_lpszClassname = _Classname;
        m_lpszTargetName = _TargetName;
        m_rgszKeyvalues = _Keyvalues;
        m_bDoMagicAtMapStart = _DoMagicAtMapStart;
    }
}
    
class CEntryExitPlayerPortalsHolder {
    Vector m_vecEntryPortal, m_vecExitPortal;
    string m_lpszTargetName;
    bool m_bActivatedOnMapStart;
    
    CEntryExitPlayerPortalsHolder(const Vector& in _EntryPortal, const Vector& in _ExitPortal, const string& in _TargetName, const bool& in _ActivatedOnMapStart) {
        m_vecEntryPortal = _EntryPortal;
        m_vecExitPortal = _ExitPortal;
        m_lpszTargetName = _TargetName;
        m_bActivatedOnMapStart = _ActivatedOnMapStart;
    }
}

class CDynamicAntiRushMap {
    string m_lpszName;
    array<CDynamicFuncWallToggle@> m_rglpWalls;
    array<CDynamicEnvBeam@> m_rglpBeams;
    array<CDynamicPlayerCounter@> m_rglpCounters;
    array<CDynamicWallNumber@> m_rglpNumbers;
    array<CDynamicWallSpeaker@> m_rglpSpeakers;
    array<CDynamicFurnitureHolder@> m_rglpFurniture;
    array<CSecondEntityTargetNameHolder@> m_rglpSecondTargetNameStuff;
    array<CSecondEntityTargetNameMovedOutHolder@> m_rglpSecondTargetNameMovedOutStuff;
    array<CSecondEntityTargetNameMovedOutAndBackHolder@> m_rglpSecondTargetNameMovedOutAndBackStuff;
    array<CMoveOutEntityOnSpawnHolder@> m_rglpMoveOnSpawnStuff;
    array<string> m_rglpszDeleteOnSpawnByModel;
    array<CDynamicWallTimer@> m_rglpTimers;
    array<CTrainPathNode@> m_rglpNodes;
    array<CDynamicFlyingKey@> m_rglpKeys;
    array<CKillCounterHolder@> m_rglpKillCounters;
    array<CDynamicSkullHolder@> m_rglpSkulls;
    array<CDynamicPadlock@> m_rglpPadlocks;
    array<CMultiManagerHolder@> m_rglpMultiManagers;
    array<CSquadMakerHookHolder@> m_rglpSquads;
    array<CSquadMakerHookHolder@> m_rglpMonsterMakers;
    array<CCheckpointSpawnerHolder@> m_rglpCheckpoints;
    array<CMasterHolder@> m_rglpMasters;
    array<CKeyValueDispatcherHolder@> m_rglpKeyValueDispatchers;
    array<CKeyValueDispatcherByModelHolder@> m_rglpKeyValueDispatchersByModel;
    array<CEntitySpawnerHolder@> m_rglpSpawners;
    array<CEntryExitPlayerPortalsHolder@> m_rglpPortals;
    array<CDynamicArrowHolder@> m_rglpArrows;
    
    CDynamicAntiRushMap(const string& in _Name) {
        m_lpszName = _Name;
        m_rglpWalls.resize(0);
        m_rglpBeams.resize(0);
        m_rglpCounters.resize(0);
        m_rglpNumbers.resize(0);
        m_rglpSpeakers.resize(0);
        m_rglpFurniture.resize(0);
        m_rglpSecondTargetNameStuff.resize(0);
        m_rglpSecondTargetNameMovedOutStuff.resize(0);
        m_rglpSecondTargetNameMovedOutAndBackStuff.resize(0);
        m_rglpMoveOnSpawnStuff.resize(0);
        m_rglpszDeleteOnSpawnByModel.resize(0);
        m_rglpTimers.resize(0);
        m_rglpNodes.resize(0);
        m_rglpKeys.resize(0);
        m_rglpKillCounters.resize(0);
        m_rglpSkulls.resize(0);
        m_rglpPadlocks.resize(0);
        m_rglpMultiManagers.resize(0);
        m_rglpKeyValueDispatchers.resize(0);
        m_rglpKeyValueDispatchersByModel.resize(0);
        m_rglpSpawners.resize(0);
        m_rglpPortals.resize(0);
        m_rglpArrows.resize(0);
    }
    
    void PlaceWalls() {
        for (uint idx = 0; idx < m_rglpWalls.length(); idx++) {
            CDynamicFuncWallToggle@ pWall = @m_rglpWalls[idx];
            Vector vecCenter = AR_UTIL_FindCenterOfTwoVecs(pWall.m_vecFirstPoint, pWall.m_vecSecondPoint);
            CBaseEntity@ pEntity = g_EntityFuncs.Create("func_toggleable_custom_wall", vecCenter, g_vecZero, true, null);
            CToggleableCustomFuncWall@ pToggleableWall = cast<CToggleableCustomFuncWall@>(CastToScriptClass(pEntity));
            if (pEntity is null || pToggleableWall is null) {
                AR_UTIL_PrintToLog("[AntiRush] Failure placing a wall with these coors: " + pWall.m_vecFirstPoint.ToString() + " and " + pWall.m_vecSecondPoint.ToString() + "\n");
                continue;
            }
            pToggleableWall.m_vecFirstPoint = pWall.m_vecFirstPoint;
            pToggleableWall.m_vecSecondPoint = pWall.m_vecSecondPoint;
            pToggleableWall.m_vecMinDiff = AR_UTIL_FindDifferenceBetweenCenterAndACorner(vecCenter, pWall.m_vecFirstPoint);
            pToggleableWall.m_vecMaxDiff = AR_UTIL_FindDifferenceBetweenCenterAndACorner(vecCenter, pWall.m_vecSecondPoint);
            pToggleableWall.m_lpszTargetName = pWall.m_lpszName;
            pToggleableWall.m_bAbleToHaveChildren = true;
            pEntity.pev.targetname = pWall.m_lpszName;
            //pEntity.pev.effects |= EF_NODRAW;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
        }
    }
    
    void PlaceBeams() {
        for (uint idx = 0; idx < m_rglpBeams.length(); idx++) {
            CDynamicEnvBeam@ pDynBeam = @m_rglpBeams[idx];
            CBaseEntity@ pEntity = g_EntityFuncs.Create("env_custom_beam", g_vecZero, g_vecZero, true, null);
            CDynamicToggleableCustomEnvironmentBeam@ pBeam = cast<CDynamicToggleableCustomEnvironmentBeam@>(CastToScriptClass(pEntity));
            pBeam.m_vecFirstPoint = pDynBeam.m_vecFirstPoint;
            pBeam.m_vecSecondPoint = pDynBeam.m_vecSecondPoint;
            pBeam.m_vecColour = pDynBeam.m_vecColour;
            pBeam.m_vecSecondColour = pDynBeam.m_vecSecondColour;
            pBeam.m_flDamage = pDynBeam.m_flDamage;
            pBeam.m_flRenderAmount = pDynBeam.m_flRenderAmount;
            pBeam.m_lpszBeamTargetName = pDynBeam.m_lpszName + "_beam";
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pDynBeam.m_lpszName;
            g_EntityFuncs.SetOrigin(pEntity, pBeam.m_vecFirstPoint);
        }
    }
    
    void PlaceCounters() {
        for (uint idx = 0; idx < m_rglpCounters.length(); idx++) {
            CDynamicPlayerCounter@ pDynCnter = @m_rglpCounters[idx];
            CBaseEntity@ pEntity = g_EntityFuncs.Create("trigger_dynamic_player_counter", g_vecZero, g_vecZero, true, null);
            CDynamicPlayerCounterTrigger@ pTrigger = cast<CDynamicPlayerCounterTrigger@>(CastToScriptClass(pEntity));
            pTrigger.m_vecFirstPoint = pDynCnter.m_vecFirstPoint;
            pTrigger.m_vecSecondPoint = pDynCnter.m_vecSecondPoint;
            pTrigger.m_rgpszTargets = pDynCnter.m_rgpszTargets;
            pTrigger.m_flPercentage = pDynCnter.m_flPercentage;
            pTrigger.m_rgpszMasters = pDynCnter.m_rgpszMasters;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
        }
    }
    
    void PlaceNumbers() {
        for (uint idx = 0; idx < m_rglpNumbers.length(); idx++) {
            CDynamicWallNumber@ pDynNumber = @m_rglpNumbers[idx];
            Vector vecPosition = pDynNumber.m_vecPosition;
            for (uint j = 0; j < pDynNumber.m_lpszNumber.Length(); j++) {
                if (!isdigit(pDynNumber.m_lpszNumber[j]) && pDynNumber.m_lpszNumber[j] != '%') continue;
            
                string szModel;
                float flYaw = pDynNumber.m_vecAngles.y;
                float flRight = AR_UTIL_Degree2Radians(flYaw + 90.0f);
                if (pDynNumber.m_lpszNumber[j] == '%') {
                    vecPosition = Vector(vecPosition.x + cos(flRight) * 2.0f, vecPosition.y + sin(flRight) * 2.f, vecPosition.z);
                    szModel = "sprites/hlcancer/antirush/percent.mdl";
                } else {
                    szModel = "sprites/hlcancer/antirush/d" + string(pDynNumber.m_lpszNumber[j]) + ".mdl";
                }
                CBaseEntity@ pEntity = g_EntityFuncs.Create("env_dynamic_wall_number", vecPosition, g_vecZero, true, null);
                CEnvironmentDynamicWallNumber@ pNumber = cast<CEnvironmentDynamicWallNumber@>(CastToScriptClass(pEntity));
                pNumber.m_vecColour = pDynNumber.m_vecColour;
                pNumber.m_vecSecondColour = pDynNumber.m_vecSecondColour;
                pNumber.m_flScale = pDynNumber.m_flScale;
                g_EntityFuncs.SetModel(pEntity, szModel);
                g_EntityFuncs.DispatchSpawn(pEntity.edict());
                pEntity.pev.angles = pDynNumber.m_vecAngles;
                pEntity.pev.targetname = pDynNumber.m_lpszTargetName;
            
                vecPosition = Vector(vecPosition.x + cos(flRight) * (8.0f * pDynNumber.m_flScale), vecPosition.y + sin(flRight) * (8.0f * pDynNumber.m_flScale), vecPosition.z);
            }
        }
    }
    
    void PlaceSpeakers() {
        for (uint idx = 0; idx < m_rglpSpeakers.length(); idx++) {
            CDynamicWallSpeaker@ pDynSpeaker = @m_rglpSpeakers[idx];
            CBaseEntity@ pEntity = g_EntityFuncs.Create("env_dynamic_wall_speaker", pDynSpeaker.m_vecPosition, g_vecZero, true, null);
            CEnvironmentDynamicWallSpeaker@ pSpeaker = cast<CEnvironmentDynamicWallSpeaker@>(CastToScriptClass(pEntity));
            pSpeaker.m_lpszSound = pDynSpeaker.m_lpszSound;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pSpeaker.pev.targetname = pDynSpeaker.m_lpszTargetName;
        }
    }
    
    void PlaceFurniture() {
        for (uint idx = 0; idx < m_rglpFurniture.length(); idx++) {
            CDynamicFurnitureHolder@ pDynFurniture = @m_rglpFurniture[idx];
            
            EHandle hTheEntity;
            
            for (int j = 0; j < g_Engine.maxEntities; j++) {
                CBaseEntity@ pEntity = g_EntityFuncs.Instance(j);
                if (pEntity !is null and pEntity.pev !is null) {
                    if (pEntity.pev.model == pDynFurniture.m_lpszModel) {
                        hTheEntity = EHandle(pEntity);
                        break;
                    }
                }
            }
            
            if (!hTheEntity.IsValid()) {
                AR_UTIL_PrintToLog("[AntiRush] Failed to find the specified model: " + pDynFurniture.m_lpszModel + "\n");
            
                continue;
            }
            
            CBaseEntity@ pEntity = hTheEntity.GetEntity();
            CBaseEntity@ pFurnitureEntity = g_EntityFuncs.Create("env_dynamic_furniture", pEntity.pev.origin, pEntity.pev.angles, true, pEntity.pev.owner);
            CEnvironmentDynamicFurniture@ pFurniture = cast<CEnvironmentDynamicFurniture@>(CastToScriptClass(pFurnitureEntity));
            pFurniture.m_lpszModel = pDynFurniture.m_lpszModel;
            pFurniture.m_vecAbsMin = pEntity.pev.absmin;
            pFurniture.m_vecAbsMax = pEntity.pev.absmax;
            pFurniture.m_hOriginalEntity = EHandle(pEntity);
            g_EntityFuncs.DispatchSpawn(pFurnitureEntity.edict());
            pFurniture.pev.targetname = pDynFurniture.m_lpszTargetName;
            g_EntityFuncs.SetOrigin(pEntity, Vector(131072, 131072, -131072));
            pEntity.pev.absmin = pEntity.pev.absmax = g_vecZero;
        }
    }

    void MoveEnts() {
        for (uint idx = 0; idx < m_rglpMoveOnSpawnStuff.length(); idx++) {
            CMoveOutEntityOnSpawnHolder@ pHoldah = @m_rglpMoveOnSpawnStuff[idx];
            
            EHandle hTheEntity;
            
            CBaseEntity@ pEntity = null;
            for (int j = 1; j <= g_Engine.maxEntities; ++j) {
                @pEntity = g_EntityFuncs.Instance(j);
                if (pEntity is null) continue;
                if (pEntity.GetClassname().ToLowercase() != pHoldah.m_lpszClassname.ToLowercase()) continue;
                if (fabsf(pEntity.pev.origin.x - pHoldah.m_vecOrigin.x) < pHoldah.m_flMaxError && fabsf(pEntity.pev.origin.y - pHoldah.m_vecOrigin.y) < pHoldah.m_flMaxError && fabsf(pEntity.pev.origin.z - pHoldah.m_vecOrigin.z) < pHoldah.m_flMaxError) {
                    if (pHoldah.m_bDelete && AR_UTIL_IsThisVeryEntityImmuneToDelete(pEntity.entindex()))
                        continue; //find another one
                
                    hTheEntity = EHandle(pEntity);
                    break;
                }
            }
            
            if (!hTheEntity.IsValid()) {
                AR_UTIL_PrintToLog("[AntiRush] Failed to find entity by this classname: " + pHoldah.m_lpszClassname + " (required origin: (X: " + string(pHoldah.m_vecOrigin.x) + ", Y: " + string(pHoldah.m_vecOrigin.y) + ", Z: " + string(pHoldah.m_vecOrigin.z) + "), maxerror: " + string(pHoldah.m_flMaxError) + ")\n");
            
                continue;
            }
            
            CBaseEntity@ pTheEntity = hTheEntity.GetEntity();
            if (pHoldah.m_vecDest == g_vecZero && pHoldah.m_bDelete) {
                g_EntityFuncs.Remove(pTheEntity);
            } else {
                g_EntityFuncs.SetOrigin(pTheEntity, pHoldah.m_vecDest);
            }
        }
    }
    
    void DeleteEntitiesByModel() {
        for (int j = 0; j < g_Engine.maxEntities; j++) {
            CBaseEntity@ pEntity = g_EntityFuncs.Instance(j);
            if (pEntity !is null and pEntity.pev !is null) {
                if (AR_UTIL_IsThisVeryEntityImmuneToDelete(pEntity.entindex())) continue;
                for (uint idx = 0; idx < m_rglpszDeleteOnSpawnByModel.length(); idx++) {
                    string szModel = m_rglpszDeleteOnSpawnByModel[idx];
                    if (szModel == pEntity.pev.model) {
                        g_EntityFuncs.Remove(pEntity);
                        break;
                    }
                }
            }
        }
    }
    
    void PlaceTimers() {
        for (uint idx = 0; idx < m_rglpTimers.length(); idx++) {
            CDynamicWallTimer@ pHoldah = @m_rglpTimers[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("env_dynamic_timer", pHoldah.m_vecPosition, pHoldah.m_vecAngles, true, null);
            CEnvironmentDynamicWallTimer@ pTimer = cast<CEnvironmentDynamicWallTimer@>(CastToScriptClass(pEntity));
            pTimer.m_vecColour = pHoldah.m_vecColour;
            pTimer.m_flCurrentTimerValue = pHoldah.m_flTime;
            pTimer.m_bActive = pHoldah.m_bActivatedOnMapStart;
            pTimer.m_rgpszTargets = pHoldah.m_rgpszTargets;
            pTimer.m_flScale = pHoldah.m_flScale;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        
        }
    }

    void PlacePathNodes() {
        for (uint idx = 0; idx < m_rglpNodes.length(); idx++) {
            CTrainPathNode@ pNode = @m_rglpNodes[idx];
            
            dictionary kvs;
            kvs["origin"] = string(pNode.m_vecPosition.x) + " " + string(pNode.m_vecPosition.y) + " " + string(pNode.m_vecPosition.z);
            kvs["targetname"] = pNode.m_lpszTargetName;
            if (!pNode.m_lpszNextNode.IsEmpty()) {
                kvs["target"] = pNode.m_lpszNextNode;
            }
            kvs["speed"] = string(int(pNode.m_flSpeed));
            if (!pNode.m_lpszFireOnPass.IsEmpty()) {
                kvs["message"] = pNode.m_lpszFireOnPass;
            }
            
            CBaseEntity@ pEntity = g_EntityFuncs.CreateEntity("path_track", @kvs, false);
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            
            g_rgpPathTracks.insertLast(EHandle(pEntity));
        }
    }
    
    void PlaceKeys() {
        for (uint idx = 0; idx < m_rglpKeys.length(); idx++) {
            CDynamicFlyingKey@ pDynKey = @m_rglpKeys[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("env_flying_key", pDynKey.m_vecPosition, pDynKey.m_vecAngles, true, null);
            CEnvironmentFlyingKey@ pFlyingKey = cast<CEnvironmentFlyingKey@>(CastToScriptClass(pEntity));
            pFlyingKey.m_vecColour = pDynKey.m_vecColour;
            pFlyingKey.m_lpszFirstNode = pDynKey.m_lpszFirstNode;
			pFlyingKey.m_lpszTramTargetName = pDynKey.m_lpszTargetName + "_tram";
            g_EntityFuncs.SetModel(pEntity, "sprites/hlcancer/antirush/key.mdl");
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pDynKey.m_lpszTargetName;
        }
    }
    
    void PlaceKillCounters() {
        for (uint idx = 0; idx < m_rglpKillCounters.length(); idx++) {
            CKillCounterHolder@ pHoldah = @m_rglpKillCounters[idx];
            
            EHandle hTheEntity;
            
            CBaseEntity@ pEntity = null;
            for (int j = 1; j <= g_Engine.maxEntities; ++j) {
                @pEntity = g_EntityFuncs.Instance(j);
                if (pEntity is null) continue;
                if (pEntity.GetClassname().ToLowercase() != pHoldah.m_lpszClassname.ToLowercase()) continue;
                if (fabsf(pEntity.pev.origin.x - pHoldah.m_vecOrigin.x) < pHoldah.m_flMaxError && fabsf(pEntity.pev.origin.y - pHoldah.m_vecOrigin.y) < pHoldah.m_flMaxError && fabsf(pEntity.pev.origin.z - pHoldah.m_vecOrigin.z) < pHoldah.m_flMaxError) {
                    hTheEntity = EHandle(pEntity);
                    break;
                }
            }
            
            if (!hTheEntity.IsValid() || pEntity.GetClassname().ToLowercase() != pHoldah.m_lpszClassname.ToLowercase()) {
                AR_UTIL_PrintToLog("[AntiRush] Failed to find entity by this classname: " + pHoldah.m_lpszClassname + " (required origin: (X: " + string(pHoldah.m_vecOrigin.x) + ", Y: " + string(pHoldah.m_vecOrigin.y) + ", Z: " + string(pHoldah.m_vecOrigin.z) + "), maxerror: " + string(pHoldah.m_flMaxError) + ")\n");
            
                continue;
            }
            
            CBaseEntity@ pKillCounter = g_EntityFuncs.Create("env_dynamic_kill_counter", g_vecZero, g_vecZero, true, null);
            CEnvironmentDynamicKillCounter@ pCounter = cast<CEnvironmentDynamicKillCounter@>(CastToScriptClass(pKillCounter));
            pCounter.m_hTarget = hTheEntity;
            g_EntityFuncs.DispatchSpawn(pKillCounter.edict());
            pKillCounter.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceSkulls() {
        for (uint idx = 0; idx < m_rglpSkulls.length(); idx++) {
            CDynamicSkullHolder@ pHoldah = @m_rglpSkulls[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("env_dynamic_skull", pHoldah.m_vecPosition, pHoldah.m_vecAngles, true, null);
            CEnvironmentDynamicSkull@ pSkull = cast<CEnvironmentDynamicSkull@>(CastToScriptClass(pEntity));
            pSkull.m_vecColour = pHoldah.m_vecColour;
            pSkull.m_vecSecondColour = pHoldah.m_vecSecondColour;
            pSkull.m_rgpszTargets = pHoldah.m_rgpszTargets;
            pSkull.m_rgpszKillCounters = pHoldah.m_rgpszKillCounters;
            g_EntityFuncs.SetModel(pEntity, "sprites/hlcancer/antirush/skull.mdl");
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlacePadlocks() {
        for (uint idx = 0; idx < m_rglpPadlocks.length(); idx++) {
            CDynamicPadlock@ pHoldah = @m_rglpPadlocks[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("env_dynamic_padlock", pHoldah.m_vecPosition, pHoldah.m_vecAngles, true, null);
            CEnvironmentDynamicPadlock@ pSkull = cast<CEnvironmentDynamicPadlock@>(CastToScriptClass(pEntity));
            pSkull.m_vecColour = pHoldah.m_vecColour;
            g_EntityFuncs.SetModel(pEntity, "sprites/hlcancer/antirush/padlock.mdl");
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceMultiManagers() {
        for (uint idx = 0; idx < m_rglpMultiManagers.length(); idx++) {
            CMultiManagerHolder@ pHoldah = @m_rglpMultiManagers[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("func_custom_multi_manager", g_vecZero, g_vecZero, true, null);
            CCustomMultiManager@ pManager = cast<CCustomMultiManager@>(CastToScriptClass(pEntity));
            pManager.m_rgpszTargets = pHoldah.m_rgpszTargets;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceSquadMakerHooks() {
        for (uint idx = 0; idx < m_rglpSquads.length(); idx++) {
            CSquadMakerHookHolder@ pHoldah = @m_rglpSquads[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("func_sqd_mstr_maker_hook", pHoldah.m_vecPosition, g_vecZero, true, null);
            CSquadMonsterMakerHook@ pHook = cast<CSquadMonsterMakerHook@>(CastToScriptClass(pEntity));
            pHook.m_flMaxError = pHoldah.m_flMaxError;
            pHook.m_lpszTargetClassname = "squadmaker";
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceMonsterMakerHooks() {
        for (uint idx = 0; idx < m_rglpMonsterMakers.length(); idx++) {
            CSquadMakerHookHolder@ pHoldah = @m_rglpMonsterMakers[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("func_sqd_mstr_maker_hook", pHoldah.m_vecPosition, g_vecZero, true, null);
            CSquadMonsterMakerHook@ pHook = cast<CSquadMonsterMakerHook@>(CastToScriptClass(pEntity));
            pHook.m_flMaxError = pHoldah.m_flMaxError;
            pHook.m_lpszTargetClassname = "monstermaker";
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceCheckpoints() {
        for (uint idx = 0; idx < m_rglpCheckpoints.length(); idx++) {
            CCheckpointSpawnerHolder@ pHoldah = @m_rglpCheckpoints[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("func_checkpoint_spawner", pHoldah.m_vecPosition, g_vecZero, true, null);
            CDynamicCheckpointSpawner@ pSpawner = cast<CDynamicCheckpointSpawner@>(CastToScriptClass(pEntity));
            pSpawner.m_lpszFunnelSprite = pHoldah.m_lpszFunnelSprite;
            pSpawner.m_lpszStartSound = pHoldah.m_lpszStartSound;
            pSpawner.m_lpszEndSound = pHoldah.m_lpszEndSound;
            pSpawner.m_bActiveAtMapStart = pHoldah.m_bActiveAtMapStart;
            pSpawner.m_lpszKillTarget = pHoldah.m_lpszKillTarget;
            pSpawner.m_lpszActivateTarget = pHoldah.m_lpszActivateTarget;
            pSpawner.m_vecMinHullSize = pHoldah.m_vecMinHullSize;
            pSpawner.m_vecMaxHullSize = pHoldah.m_vecMaxHullSize;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pSpawner.m_lpszTargetName = pHoldah.m_lpszTargetName;
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceMasters() {
        for (uint idx = 0; idx < m_rglpMasters.length(); idx++) {
            CMasterHolder@ pHoldah = @m_rglpMasters[idx];
        
            CBaseEntity@ pEntity = g_EntityFuncs.Create("func_dynamic_lock_master", g_vecZero, g_vecZero, true, null);
            CDynamicLockMaster@ pMaster = cast<CDynamicLockMaster@>(CastToScriptClass(pEntity));
            pMaster.m_bActivated = false;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceKeyValueDispatchers() {
        for (uint idx = 0; idx < m_rglpKeyValueDispatchers.length(); idx++) {
            CKeyValueDispatcherHolder@ pHoldah = @m_rglpKeyValueDispatchers[idx];
            
            EHandle hTheEntity;
            
            CBaseEntity@ pEntity = null;
            for (int j = 1; j <= g_Engine.maxEntities; ++j) {
                @pEntity = g_EntityFuncs.Instance(j);
                if (pEntity is null) continue;
                if (pEntity.GetClassname().ToLowercase() != pHoldah.m_lpszClassname.ToLowercase()) continue;
                if (fabsf(pEntity.pev.origin.x - pHoldah.m_vecOrigin.x) < pHoldah.m_flMaxError && fabsf(pEntity.pev.origin.y - pHoldah.m_vecOrigin.y) < pHoldah.m_flMaxError && fabsf(pEntity.pev.origin.z - pHoldah.m_vecOrigin.z) < pHoldah.m_flMaxError) {
                    hTheEntity = EHandle(pEntity);
                    break;
                }
            }
            
            /*if (!hTheEntity.IsValid()) {
                AR_UTIL_PrintToLog("[AntiRush] Failed to find entity by this classname: " + pHoldah.m_lpszClassname + " (required origin: (X: " + string(pHoldah.m_vecOrigin.x) + ", Y: " + string(pHoldah.m_vecOrigin.y) + ", Z: " + string(pHoldah.m_vecOrigin.z) + "), maxerror: " + string(pHoldah.m_flMaxError) + ")\n");
            
                continue;
            }*/
            
            CBaseEntity@ pFunc = g_EntityFuncs.Create("func_dynamic_keyvalue_dispatcher", g_vecZero, g_vecZero, true, null);
            CDynamicKeyValueDispatcher@ pDispatcher = cast<CDynamicKeyValueDispatcher@>(CastToScriptClass(pFunc));
            pDispatcher.m_hTarget = hTheEntity;
            pDispatcher.m_bDoMagicAtMapStart = pHoldah.m_bDoMagicAtMapStart;
            pDispatcher.m_lpszKeyvalueName = pHoldah.m_lpszKeyvalueName;
            pDispatcher.m_lpszKeyvalueValue = pHoldah.m_lpszKeyvalueValue;
            pDispatcher.m_flMaxError = pHoldah.m_flMaxError;
            pDispatcher.m_lpszTargetClassname = pHoldah.m_lpszClassname;
            pDispatcher.m_vecOrigin = pHoldah.m_vecOrigin;
            g_EntityFuncs.DispatchSpawn(pFunc.edict());
            pFunc.pev.targetname = pHoldah.m_lpszTargetName;
        }
        for (uint j = 0; j < m_rglpKeyValueDispatchersByModel.length(); j++) {
            CKeyValueDispatcherByModelHolder@ pHoldah = @m_rglpKeyValueDispatchersByModel[j];
            
            EHandle hTheEntity;
            
            CBaseEntity@ pEntity = null;
            while ((@pEntity = g_EntityFuncs.FindEntityByString(pEntity, "model", pHoldah.m_lpszModel)) !is null) {
                hTheEntity = EHandle(pEntity);
            }
            
            /*if (!hTheEntity.IsValid()) {
                AR_UTIL_PrintToLog("[AntiRush] Failed to find entity by this model: " + pHoldah.m_lpszModel + "\n");
            
                continue;
            }*/
            
            CBaseEntity@ pFunc = g_EntityFuncs.Create("func_dynamic_keyvalue_dispatcher", g_vecZero, g_vecZero, true, null);
            CDynamicKeyValueDispatcher@ pDispatcher = cast<CDynamicKeyValueDispatcher@>(CastToScriptClass(pFunc));
            pDispatcher.m_hTarget = hTheEntity;
            pDispatcher.m_bDoMagicAtMapStart = pHoldah.m_bDoMagicAtMapStart;
            pDispatcher.m_lpszKeyvalueName = pHoldah.m_lpszKeyvalueName;
            pDispatcher.m_lpszKeyvalueValue = pHoldah.m_lpszKeyvalueValue;
            pDispatcher.m_lpszModel = pHoldah.m_lpszModel;
            g_EntityFuncs.DispatchSpawn(pFunc.edict());
            pFunc.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceSpawners() {
        for (uint idx = 0; idx < m_rglpSpawners.length(); idx++) {
            CEntitySpawnerHolder@ pHoldah = @m_rglpSpawners[idx];
        
            CBaseEntity@ pEntity = g_EntityFuncs.Create("func_dynamic_entity_spawner", g_vecZero, g_vecZero, true, null);
            CDynamicEntitySpawner@ pSpawner = cast<CDynamicEntitySpawner@>(CastToScriptClass(pEntity));
            pSpawner.m_bDoMagicAtMapStart = pHoldah.m_bDoMagicAtMapStart;
            pSpawner.m_lpszClassname = pHoldah.m_lpszClassname;
            pSpawner.m_rgszKeyvalues = pHoldah.m_rgszKeyvalues;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlacePortals() {
        for (uint idx = 0; idx < m_rglpPortals.length(); idx++) {
            CEntryExitPlayerPortalsHolder@ pHoldah = @m_rglpPortals[idx];
        
            CBaseEntity@ pEntity = g_EntityFuncs.Create("func_entry_exit_player_portal_parent", g_vecZero, g_vecZero, true, null);
            CEntryExitPlayerPortals@ pPortals = cast<CEntryExitPlayerPortals@>(CastToScriptClass(pEntity));
            pPortals.m_bArePortalsVisibleFromMapStart = pHoldah.m_bActivatedOnMapStart;
            pPortals.m_vecEntryPortal = pHoldah.m_vecEntryPortal;
            pPortals.m_vecExitPortal = pHoldah.m_vecExitPortal;
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
    
    void PlaceArrows() {
        for (uint idx = 0; idx < m_rglpArrows.length(); idx++) {
            CDynamicArrowHolder@ pHoldah = @m_rglpArrows[idx];
            
            CBaseEntity@ pEntity = g_EntityFuncs.Create("env_dynamic_arrow", pHoldah.m_vecPosition, pHoldah.m_vecAngles, true, null);
            CEnvironmentDynamicArrow@ pArrow = cast<CEnvironmentDynamicArrow@>(CastToScriptClass(pEntity));
            pArrow.m_vecColour = pHoldah.m_vecColour;
            pArrow.m_bActiveAtMapStart = pHoldah.m_bActiveAtMapStart;
            g_EntityFuncs.SetModel(pEntity, "sprites/hlcancer/antirush/arrow2d.mdl");
            g_EntityFuncs.DispatchSpawn(pEntity.edict());
            pEntity.pev.targetname = pHoldah.m_lpszTargetName;
        }
    }
}

array<CDynamicAntiRushMap@> g_rglpMaps;

CDynamicAntiRushMap@ g_pCurrentMap;

CDynamicAntiRushMap@ AR_TryPlacingStuffIfMapExistsInList(string& in _MapName) {
    for (uint idx = 0; idx < g_rglpMaps.length(); idx++) {
        CDynamicAntiRushMap@ pMap = g_rglpMaps[idx];
        if (pMap.m_lpszName.ToLowercase().CompareN(_MapName.ToLowercase(), _MapName.Length()) == 0) {
            pMap.PlaceWalls();
            pMap.PlaceBeams();
            pMap.PlaceCounters();
            pMap.PlaceNumbers();
            pMap.PlaceSpeakers();
            pMap.PlacePathNodes();
            pMap.PlaceKeys();
            pMap.PlacePadlocks();
            pMap.PlaceMultiManagers();
            pMap.PlaceSquadMakerHooks();
            pMap.PlaceMonsterMakerHooks();
            pMap.PlaceMasters();
            pMap.PlaceSpawners();
            pMap.PlacePortals();
            pMap.PlaceArrows();
            //pMap.PlaceCheckpoints();
            //break;
            @g_pCurrentMap = pMap;
            return pMap;
        }
    }
    
    return null;
}

void AR_PlaceStuffMapActivate() {
    /*for (uint idx = 0; idx < g_rglpMaps.length(); idx++) {
        CDynamicAntiRushMap@ pMap = g_rglpMaps[idx];
        if (pMap.m_lpszName == _MapName) {
            pMap.PlaceFurniture();
            break;
        }
    }*/
    if (g_pCurrentMap is null) return;
    g_pCurrentMap.MoveEnts();
    g_pCurrentMap.DeleteEntitiesByModel();
    g_pCurrentMap.PlaceKillCounters();
    g_pCurrentMap.PlaceSkulls();
    g_pCurrentMap.PlaceCheckpoints();
    g_pCurrentMap.PlaceKeyValueDispatchers();
}

void AR_PlaceStuffMapStart() {
    if (g_pCurrentMap is null) return;
        
    g_pCurrentMap.PlaceFurniture();
    g_pCurrentMap.PlaceTimers();
            
    if (g_pCurrentMap.m_rglpSecondTargetNameStuff.length() == 0 && g_pCurrentMap.m_rglpSecondTargetNameMovedOutStuff.length() == 0 && g_pCurrentMap.m_rglpSecondTargetNameMovedOutAndBackStuff.length() == 0) return;

    for (int idx = 0; idx < g_Engine.maxEntities; idx++) {
        CBaseEntity@ pEntity = g_EntityFuncs.Instance(idx);
        if (pEntity !is null and pEntity.pev !is null) {
            for (uint j = 0; j < g_pCurrentMap.m_rglpSecondTargetNameStuff.length(); j++) {
                CSecondEntityTargetNameHolder@ pHolder = g_pCurrentMap.m_rglpSecondTargetNameStuff[j];
                if (pEntity.pev.model == pHolder.m_lpszModel) {
                    pHolder.m_hEntity = EHandle(pEntity);
                    break;
                }
            }
            for (uint j = 0; j < g_pCurrentMap.m_rglpSecondTargetNameMovedOutStuff.length(); j++) {
                CSecondEntityTargetNameMovedOutHolder@ pHolder = g_pCurrentMap.m_rglpSecondTargetNameMovedOutStuff[j];
                if (pEntity.pev.model == pHolder.m_lpszModel) {
                    pHolder.m_hEntity = EHandle(pEntity);
                    g_EntityFuncs.SetOrigin(pEntity, Vector(171072, 171072, -171072));
                    pEntity.pev.absmin = g_vecZero;
                    pEntity.pev.absmax = g_vecZero;
                    //if (pEntity.GetClassname() == "trigger_changelevel") pEntity.pev.spawnflags = 2; // USE only
                    break;
                }
            }
            for (uint j = 0; j < g_pCurrentMap.m_rglpSecondTargetNameMovedOutAndBackStuff.length(); j++) {
                CSecondEntityTargetNameMovedOutAndBackHolder@ pHolder = g_pCurrentMap.m_rglpSecondTargetNameMovedOutAndBackStuff[j];
                if (pEntity.pev.model == pHolder.m_lpszModel) {
                    pHolder.m_hEntity = EHandle(pEntity);
                    pHolder.m_vecOriginalOrigin = pEntity.pev.origin;
                    pHolder.m_vecOriginalMins = pEntity.pev.absmin;
                    pHolder.m_vecOriginalMaxs = pEntity.pev.absmax;
                    g_EntityFuncs.SetOrigin(pEntity, Vector(171072, 171072, -171072));
                    pEntity.pev.absmin = g_vecZero;
                    pEntity.pev.absmax = g_vecZero;
                    //if (pEntity.GetClassname() == "trigger_changelevel") pEntity.pev.spawnflags = 2; // USE only
                    break;
                }
            }
        }
    }
}

Vector AR_UTIL_FindCenterOfTwoVecs(const Vector& in _P1, const Vector& in _P2) {
    Vector vecCenter;
    vecCenter.x = (_P1.x + _P2.x) / 2.0;
    vecCenter.y = (_P1.y + _P2.y) / 2.0;
    vecCenter.z = (_P1.z + _P2.z) / 2.0;
    return vecCenter;
}

float fabsf(float _Value) {
    return _Value < 0.f ? _Value * -1.f : _Value;
}

float AR_UTIL_SmartDivide(const Vector2D& in _Nums, float _Divisor) {
    float flA = _Nums.x;
    float flB = _Nums.y;
    /*if (flA > flB) {
        float flD = flA;
        flA = flB;
        flB = flD;
    }*/
    //(a-b) / _Divisor + b
    float flC = (flA - flB) / _Divisor + flB;
    
    return flC;
}

Vector AR_UTIL_FindDifferenceBetweenCenterAndACorner(const Vector& in _Center, const Vector& in _Corner) {
    Vector vecDiff;
    vecDiff.x = _Corner.x - _Center.x;
    vecDiff.y = _Corner.y - _Center.y;
    vecDiff.z = _Corner.z - _Center.z;
    return vecDiff;
}

array<int> AR_UTIL_SplitNumberIntoParts(int _Number) {
    array<int> aiOutput;
    array<int> aiTemp;
    aiOutput.resize(0);
    aiTemp.resize(0);
    
    while (_Number > 0) {
        int iDigit = _Number % 10;
        aiOutput.insertLast(iDigit);
        _Number /= 10;
    }
    
    //for (uint idx = aiTemp.length() - 1; idx > 0; idx--) {
    //    aiOutput.insertLast(aiTemp[idx]);
    //}
    
    return aiOutput;
}

void AR_UTIL_ParseAntiRushMapEntriesList(bool _bDuringGameplay) {
    File@ lpFile = g_FileSystem.OpenFile("scripts/plugins/store/hlcancer/antirush/maps.txt", OpenFile::READ);

    if (lpFile is null || !lpFile.IsOpen()) {
        AR_UTIL_PrintToLog("[AntiRush] Couldn't open \"maps.txt\"!\n");
        if (_bDuringGameplay) {
            g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
        }
        return;
    }
    
    g_rglpMaps.resize(0);
    
    string szLine;
    
    array<string> rgszMapList;
    rgszMapList.resize(0);
    
    while (!lpFile.EOFReached()) {
        lpFile.ReadLine(szLine);
        
        if (szLine.Length() < 1) continue;
        
        rgszMapList.insertLast(szLine);
    }
    
    for (uint idx = 0; idx < rgszMapList.length(); idx++) {
		string szFileName();
		
		array<string> rgszStrings;
        rgszStrings.resize(3);
		rgszStrings[0] = "scripts/plugins/store/hlcancer/antirush/";
		rgszStrings[1] = rgszMapList[idx];

		szFileName = AR_UTIL_BuildStringFromMultipleStrings(rgszStrings);
		
        //string szFileName = "scripts/plugins/store/hlcancer/antirush/" + rgszMapList[idx] + ".txt";
        File@ lpMap = g_FileSystem.OpenFile(szFileName, OpenFile::READ);
        if (lpMap is null || !lpMap.IsOpen()) {
			rgszStrings.resize(3);
			rgszStrings[0] = "[AntiRush] Couldn't open \"scripts/plugins/store/hlcancer/antirush/";
			rgszStrings[1] = rgszMapList[idx];
			rgszStrings[2] = ".txt\"!\n";
		
			string szFormat = AR_UTIL_BuildStringFromMultipleStrings(rgszStrings);
            AR_UTIL_PrintToLog(szFormat);
            if (_bDuringGameplay) {
                g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
            }
            continue;
        }
        CDynamicAntiRushMap@ lpAntiRushMap = CDynamicAntiRushMap(rgszMapList[idx]);
        int nLineIdx = 0;
        while (!lpMap.EOFReached()) {
            lpMap.ReadLine(szLine);
            nLineIdx++;
            
            if (szLine.Length() < 1) continue;
            
            szLine = szLine.ToLowercase();
            
            if (szLine.StartsWith("wall")) { //wall|459,-1,100
                szLine = szLine.SubString(5, szLine.Length() - 1); //cut "wall|"
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                    } else if (szLine[i] == "$" /* wall name */) {
                        if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                float flX2 = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flY2 = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flZ2 = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                //mins - flX, flY, flZ, maxs - flX2, flY2, flZ2
                if (flX > flX2 || flY > flY2 || flZ > flZ2) {
                    AR_UTIL_PrintToLog("[AntiRush] Illegal wall mins/maxs at " + string(nLineIdx) + " line. (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                
                string szTargetName = szLine.SubString(iSplitter6Pos + 1);
                Vector vecFirstWallPoint(flX, flY, flZ);
                Vector vecSecondWallPoint(flX2, flY2, flZ2);
                CDynamicFuncWallToggle@ pWall = CDynamicFuncWallToggle(vecFirstWallPoint, vecSecondWallPoint, szTargetName);
                lpAntiRushMap.m_rglpWalls.insertLast(@pWall);
            } else if (szLine.StartsWith("beam")) {
                szLine = szLine.SubString(5, szLine.Length() - 1); //cut "beam|"
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                int iSplitter10Pos = -1;
                int iSplitter11Pos = -1;
                int iSplitter12Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                        else if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                        else if (iSplitter10Pos == -1)
                            iSplitter10Pos = i;
                        else if (iSplitter11Pos == -1)
                            iSplitter11Pos = i;
                        else if (iSplitter11Pos == -1)
                            iSplitter11Pos = i;
                    } else if (szLine[i] == "$" /* beam name */) {
                        if (iSplitter12Pos == -1)
                            iSplitter12Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1 || iSplitter10Pos == -1 || iSplitter11Pos == -1 || iSplitter12Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flX2 = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flY2 = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flZ2 = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                float flR = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flG = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flB = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                
                if (flR > 255.f) {
                    flR = 255.f;
                }
                if (flG > 255.f) {
                    flG = 255.f;
                }
                if (flB > 255.f) {
                    flB = 255.f;
                }
                
                float flR2 = atof(szLine.SubString(iSplitter9Pos + 1, iSplitter10Pos - iSplitter9Pos - 1));
                float flG2 = atof(szLine.SubString(iSplitter10Pos + 1, iSplitter11Pos - iSplitter10Pos - 1));
                float flB2 = atof(szLine.SubString(iSplitter11Pos + 1, iSplitter12Pos - iSplitter11Pos - 1));
                
                if (flR2 > 255.f) {
                    flR2 = 255.f;
                }
                if (flG2 > 255.f) {
                    flG2 = 255.f;
                }
                if (flB2 > 255.f) {
                    flB2 = 255.f;
                }

                string szTargetName = szLine.SubString(iSplitter12Pos + 1);
                
                Vector vecFirstPoint(flX, flY, flZ);
                Vector vecSecondPoint(flX2, flY2, flZ2);
                Vector vecColour(flR, flG, flB);
                Vector vecSecondColour(flR2, flG2, flB2);
                
                CDynamicEnvBeam@ pBeam = CDynamicEnvBeam(vecFirstPoint, vecSecondPoint, vecColour, vecSecondColour, szTargetName, 128.f, 0.f);
                lpAntiRushMap.m_rglpBeams.insertLast(@pBeam);
            } else if (szLine.StartsWith("counter")) {
                //counter|x,y,z,x2,y2,z2,percentage$va(targets)@va(skulls)
                szLine = szLine.SubString(8, szLine.Length() - 1); //cut "counter|"
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                    } else if (szLine[i] == "$" /* activate targets */) {
                        if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                    } else if (szLine[i] == "@" /* skulls */) {
                        if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                float flX2 = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flY2 = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flZ2 = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                //mins - flX, flY, flZ, maxs - flX2, flY2, flZ2
                if (flX > flX2 || flY > flY2 || flZ > flZ2) {
                    AR_UTIL_PrintToLog("[AntiRush] Illegal wall mins/maxs at " + string(nLineIdx) + " line. (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                
                float flPercentage = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                
                string szTargets = "";
                string szSkulls = "";
                if (iSplitter8Pos == -1) {
                    szTargets = szLine.SubString(iSplitter7Pos + 1);
                } else {
                    szSkulls = szLine.SubString(iSplitter8Pos + 1);
                    szTargets = szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1);
                }
                
                const array<string>@ rgszTargets = szTargets.Split(",");
                const array<string>@ prgszSkulls = null;
                if (!szSkulls.IsEmpty()) {
                    @prgszSkulls = szSkulls.Split(",");
                }
                array<string>@ prgszSkullsCopy = array<string>(0);
                //rgszSkulls.resize(0);
                if (prgszSkulls !is null) {
                    prgszSkullsCopy.resize(prgszSkulls.length());
                    for (uint l = 0; l < prgszSkulls.length(); l++) {
                        prgszSkullsCopy[l] = prgszSkulls[l];
                    }
                    //rgszSkulls = prgszSkulls;
                }
                
                Vector vecFirstWallPoint(flX, flY, flZ);
                Vector vecSecondWallPoint(flX2, flY2, flZ2);
                
                CDynamicPlayerCounter@ pCounter = CDynamicPlayerCounter(vecFirstWallPoint, vecSecondWallPoint, flPercentage, rgszTargets, prgszSkullsCopy);
                lpAntiRushMap.m_rglpCounters.insertLast(@pCounter);
            } else if (szLine.StartsWith("number")) {
                szLine = szLine.SubString(7, szLine.Length() - 1); //cut "number|"
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                int iSplitter10Pos = -1;
                int iSplitter11Pos = -1;
                int iSplitter12Pos = -1;
                int iSplitter13Pos = -1;
                int iSplitter14Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                        else if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                        else if (iSplitter10Pos == -1)
                            iSplitter10Pos = i;
                        else if (iSplitter11Pos == -1)
                            iSplitter11Pos = i;
                        else if (iSplitter12Pos == -1)
                            iSplitter12Pos = i;
                        else if (iSplitter13Pos == -1)
                            iSplitter13Pos = i;
                    } else if (szLine[i] == "$" /* activate targets */) {
                        if (iSplitter14Pos == -1)
                            iSplitter14Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1 || iSplitter10Pos == -1 || iSplitter11Pos == -1 || iSplitter12Pos == -1 || iSplitter13Pos == -1 || iSplitter14Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flPitch = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flYaw = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flRoll = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                float flR = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flG = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flB = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                if (flR > 255.f) {
                    flR = 255.f;
                }
                if (flG > 255.f) {
                    flG = 255.f;
                }
                if (flB > 255.f) {
                    flB = 255.f;
                }
                flR = flR / 255.f;
                flG = flG / 255.f;
                flB = flB / 255.f;
                
                float flR2 = atof(szLine.SubString(iSplitter9Pos + 1, iSplitter10Pos - iSplitter9Pos - 1));
                float flG2 = atof(szLine.SubString(iSplitter10Pos + 1, iSplitter11Pos - iSplitter10Pos - 1));
                float flB2 = atof(szLine.SubString(iSplitter11Pos + 1, iSplitter12Pos - iSplitter11Pos - 1));
                if (flR2 > 255.f) {
                    flR2 = 255.f;
                }
                if (flG2 > 255.f) {
                    flG2 = 255.f;
                }
                if (flB2 > 255.f) {
                    flB2 = 255.f;
                }
                flR2 = flR2 / 255.f;
                flG2 = flG2 / 255.f;
                flB2 = flB2 / 255.f;
                
                float flScale = atof(szLine.SubString(iSplitter12Pos + 1, iSplitter13Pos - iSplitter12Pos - 1));
                
                string szNumber = szLine.SubString(iSplitter13Pos + 1, iSplitter14Pos - iSplitter13Pos - 1);
                
                string szTargetName = szLine.SubString(iSplitter14Pos + 1);
                
                Vector vecPosition(flX, flY, flZ);
                
                Vector vecAngles(flPitch, flYaw, flRoll);
                
                Vector vecColour(flR, flG, flB);
                Vector vecSecondColour(flR2, flG2, flB2);
                
                CDynamicWallNumber@ pNumber = CDynamicWallNumber(vecPosition, szNumber, szTargetName, vecAngles, vecColour, vecSecondColour, flScale);
                lpAntiRushMap.m_rglpNumbers.insertLast(@pNumber);
            } else if (szLine.StartsWith("speaker")) {
                szLine = szLine.SubString(8, szLine.Length() - 1); //cut "speaker|"
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                    } else if (szLine[i] == "$" /* sound */) {
                        if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                string szSound = szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1);
                
                string szTargetName = szLine.SubString(iSplitter4Pos + 1);
                
                Vector vecPosition(flX, flY, flZ);
                
                CDynamicWallSpeaker@ pSpeaker = CDynamicWallSpeaker(vecPosition, szSound, szTargetName);
                lpAntiRushMap.m_rglpSpeakers.insertLast(@pSpeaker);
            } else if (szLine.StartsWith("rename")) {
                szLine = szLine.SubString(7, szLine.Length() - 1); //cut "rename|"
                //rename|*33$_antirush_lvl_chng_trigger
                int iSplitter1Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                    }
                }
                if (iSplitter1Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                
                string szModel = szLine.SubString(0, iSplitter1Pos);
                
                string szTargetName = szLine.SubString(iSplitter1Pos + 1);
                
                CSecondEntityTargetNameHolder@ pHolder = CSecondEntityTargetNameHolder(szModel, szTargetName);
                
                lpAntiRushMap.m_rglpSecondTargetNameStuff.insertLast(pHolder);
            } else if (szLine.StartsWith("fakemdl")) {
                szLine = szLine.SubString(8, szLine.Length() - 1); //cut "fakemdl|"
                //fakemdl|*33$_antirush_some_fake_btn
                int iSplitter1Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                    }
                }
                if (iSplitter1Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                
                string szModel = szLine.SubString(0, iSplitter1Pos);
                
                string szTargetName = szLine.SubString(iSplitter1Pos + 1);
                
                CDynamicFurnitureHolder@ pHolder = CDynamicFurnitureHolder(szModel, szTargetName);
                
                lpAntiRushMap.m_rglpFurniture.insertLast(pHolder);
            } else if (szLine.StartsWith("movout") && !szLine.StartsWith("movoutback")) {
                szLine = szLine.SubString(7, szLine.Length() - 1); //cut "movout|"
                //movout|*33$_antirush_lvl_chng_trigger
                int iSplitter1Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                    }
                }
                if (iSplitter1Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                
                string szModel = szLine.SubString(0, iSplitter1Pos);
                
                string szTargetName = szLine.SubString(iSplitter1Pos + 1);
                
                CSecondEntityTargetNameMovedOutHolder@ pHolder = CSecondEntityTargetNameMovedOutHolder(szModel, szTargetName);
                
                lpAntiRushMap.m_rglpSecondTargetNameMovedOutStuff.insertLast(pHolder);
            } else if (szLine.StartsWith("movoutback")) {
                szLine = szLine.SubString(11, szLine.Length() - 1); //cut "movoutback|"
                //movoutback|*33$_antirush_lvl_chng_trigger
                int iSplitter1Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                    }
                }
                if (iSplitter1Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                
                string szModel = szLine.SubString(0, iSplitter1Pos);
                
                string szTargetName = szLine.SubString(iSplitter1Pos + 1);
                
                CSecondEntityTargetNameMovedOutAndBackHolder@ pHolder = CSecondEntityTargetNameMovedOutAndBackHolder(szModel, szTargetName);
                
                lpAntiRushMap.m_rglpSecondTargetNameMovedOutAndBackStuff.insertLast(pHolder);
            } else if (szLine.StartsWith("mov")) {
                szLine = szLine.SubString(4, szLine.Length() - 1); //cut "mov|"
                //mov|x,y,z,maxerror,classname,x2,y2,z2
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* delimiter end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                float flMaxError = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                
                string szClassname = szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1);
                
                float flX2 = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                float flY2 = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flZ2 = atof(szLine.SubString(iSplitter7Pos + 1));

                Vector vecOrigin(flX, flY, flZ);
                Vector vecDest(flX2, flY2, flZ2);
                
                CMoveOutEntityOnSpawnHolder@ pHolder = CMoveOutEntityOnSpawnHolder(vecOrigin, vecDest, flMaxError, szClassname, false);
                
                lpAntiRushMap.m_rglpMoveOnSpawnStuff.insertLast(pHolder);
            } else if (szLine.StartsWith("delete")) {
                szLine = szLine.SubString(7, szLine.Length() - 1); //cut "delete|"
                //delete|x,y,z,maxerror,classname
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* delimiter end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                float flMaxError = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                
                string szClassname = szLine.SubString(iSplitter4Pos + 1);

                Vector vecOrigin(flX, flY, flZ);
                
                CMoveOutEntityOnSpawnHolder@ pHolder = CMoveOutEntityOnSpawnHolder(vecOrigin, g_vecZero, flMaxError, szClassname, true);
                
                lpAntiRushMap.m_rglpMoveOnSpawnStuff.insertLast(pHolder);
            } else if (szLine.StartsWith("delmdl")) {
                szLine = szLine.SubString(7, szLine.Length() - 1); //cut "delmdl|"
                //delmdl|*33
                
                lpAntiRushMap.m_rglpszDeleteOnSpawnByModel.insertLast(szLine);
            } else if (szLine.StartsWith("timer")) {
                szLine = szLine.SubString(6, szLine.Length() - 1); //cut "timer|"
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                int iSplitter10Pos = -1;
                int iSplitter11Pos = -1;
                int iSplitter12Pos = -1;
                int iSplitter13Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                        else if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                        else if (iSplitter10Pos == -1)
                            iSplitter10Pos = i;
                        else if (iSplitter11Pos == -1)
                            iSplitter11Pos = i;
                    } else if (szLine[i] == "$" /* targetname & activate targets */) {
                        if (iSplitter12Pos == -1)
                            iSplitter12Pos = i;
                        else if (iSplitter13Pos == -1)
                            iSplitter13Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1 || iSplitter10Pos == -1 || iSplitter11Pos == -1 || iSplitter12Pos == -1 || iSplitter13Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                //timer|x,y,z,yaw,pitch,roll,r,g,b,time,activatedonmapstart,scale$targetname$target1,target2,target3,...
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flYaw = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flPitch = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flRoll = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                float flR = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flG = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flB = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                if (flR > 255.f) {
                    flR = 255.f;
                }
                if (flG > 255.f) {
                    flG = 255.f;
                }
                if (flB > 255.f) {
                    flB = 255.f;
                }
                flR = flR / 255.f;
                flG = flG / 255.f;
                flB = flB / 255.f;
                
                float flTime = atof(szLine.SubString(iSplitter9Pos + 1, iSplitter10Pos - iSplitter9Pos - 1));
                
                bool bActivatedOnMapStart = atoi(szLine.SubString(iSplitter10Pos + 1, iSplitter11Pos - iSplitter10Pos - 1)) > 0;
                
                float flScale = atof(szLine.SubString(iSplitter11Pos + 1, iSplitter12Pos - iSplitter11Pos - 1));
                
                string szTargetname = szLine.SubString(iSplitter12Pos + 1, iSplitter13Pos - iSplitter12Pos - 1);
                
                string szTargets = szLine.SubString(iSplitter13Pos + 1);
                
                const array<string>@ rgszTargets = szTargets.Split(",");
                
                Vector vecPosition(flX, flY, flZ);
                
                Vector vecAngles(flYaw, flPitch, flRoll);
                
                Vector vecColour(flR, flG, flB);
                
                CDynamicWallTimer@ pCounter = CDynamicWallTimer(vecPosition, vecAngles, vecColour, flTime, bActivatedOnMapStart, flScale, szTargetname, rgszTargets);
                lpAntiRushMap.m_rglpTimers.insertLast(@pCounter);
            } else if (szLine.StartsWith("tramnode")) {
                szLine = szLine.SubString(9, szLine.Length() - 1); //cut "tramnode|"
                //tramnode|x,y,z,speed$targetname$nextnode@fireonpass
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                    } else if (szLine[i] == "$" /* targetname & activate targets */) {
                        if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                    } else if (szLine[i] == "@" /* fire on pass ye */) {
                        if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flSpeed = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                
                string szTargetname = "";
                string szNextNode = "";
                string szFireOnPass = "";
                if (iSplitter5Pos != -1) {
                    if (iSplitter6Pos != -1) {
                        szNextNode = szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1);
                    } else {
                        szNextNode = szLine.SubString(iSplitter5Pos + 1);
                    }
                
                    szTargetname = szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1);
                } else if (iSplitter5Pos == -1 && iSplitter6Pos != -1) {
                    szTargetname = szLine.SubString(iSplitter4Pos + 1, iSplitter6Pos - iSplitter4Pos - 1);
                } else if (iSplitter5Pos == -1 && iSplitter6Pos == -1) {
                    szTargetname = szLine.SubString(iSplitter4Pos + 1);
                }
                if (iSplitter6Pos != -1) {
                    szFireOnPass = szLine.SubString(iSplitter6Pos + 1);
                }
                
                //AR_UTIL_PrintToLog("[DEBUG] szFireOnPass: " + szFireOnPass + ", szNextNode: " + szNextNode + "\n");
                
                Vector vecPosition(flX, flY, flZ);
                
                CTrainPathNode@ pNode = CTrainPathNode(vecPosition, flSpeed, szTargetname, szNextNode, szFireOnPass);
                lpAntiRushMap.m_rglpNodes.insertLast(@pNode);
            } else if (szLine.StartsWith("key")) {
                szLine = szLine.SubString(4, szLine.Length() - 1); //cut "key|"
                //key|x,y,z,yaw,pitch,roll,r,g,b$targetname$firstnode
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                int iSplitter10Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                    } else if (szLine[i] == "$" /* targetname & activate targets */) {
                        if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                        else if (iSplitter10Pos == -1)
                            iSplitter10Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1 || iSplitter10Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flYaw = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flPitch = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flRoll = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                float flR = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flG = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flB = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                
                if (flR > 255.f) {
                    flR = 255.f;
                }
                if (flG > 255.f) {
                    flG = 255.f;
                }
                if (flB > 255.f) {
                    flB = 255.f;
                }
                flR = flR / 255.f;
                flG = flG / 255.f;
                flB = flB / 255.f;
                
                string szTargetname = szLine.SubString(iSplitter9Pos + 1, iSplitter10Pos - iSplitter9Pos - 1);
                
                string szFirstNode = szLine.SubString(iSplitter10Pos + 1);
                
                Vector vecPosition(flX, flY, flZ);
                
                Vector vecAngles(flYaw, flPitch, flRoll);
                
                Vector vecColour(flR, flG, flB);
                
                CDynamicFlyingKey@ pKey = CDynamicFlyingKey(vecPosition, vecAngles, vecColour, szTargetname, szFirstNode);
                lpAntiRushMap.m_rglpKeys.insertLast(@pKey);
            } else if (szLine.StartsWith("killcounter")) {
                szLine = szLine.SubString(12, szLine.Length() - 1); //cut "killcounter|"
                //killcounter|x,y,z,maxerror,classname$targetname
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                    } else if (szLine[i] == "$" /* targetname & activate targets */) {
                        if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flMaxError = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                
                string szClassname = szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1);
                
                string szTargetname = szLine.SubString(iSplitter5Pos + 1);
                
                Vector vecPosition(flX, flY, flZ);
                
                CKillCounterHolder@ pKillCounter = CKillCounterHolder(vecPosition, flMaxError, szClassname, szTargetname);
                lpAntiRushMap.m_rglpKillCounters.insertLast(@pKillCounter);
            } else if (szLine.StartsWith("skull")) {
                szLine = szLine.SubString(6, szLine.Length() - 1); //cut "skull|"
                //skull|x,y,z,yaw,pitch,roll,r,g,b,r2,g2,b2$targetname$target1,target2,...@killcounter1,killcounter2,...
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                int iSplitter10Pos = -1;
                int iSplitter11Pos = -1;
                int iSplitter12Pos = -1;
                int iSplitter13Pos = -1;
                int iSplitter14Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                        else if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                        else if (iSplitter10Pos == -1)
                            iSplitter10Pos = i;
                        else if (iSplitter11Pos == -1)
                            iSplitter11Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter12Pos == -1)
                            iSplitter12Pos = i;
                        else if (iSplitter13Pos == -1)
                            iSplitter13Pos = i;
                    } else if (szLine[i] == "@" /* killcounters */) {
                        if (iSplitter14Pos == -1)
                            iSplitter14Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1 || iSplitter10Pos == -1 || iSplitter11Pos == -1 || iSplitter12Pos == -1 || iSplitter13Pos == -1 || iSplitter14Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flYaw = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flPitch = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flRoll = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                float flR = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flG = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flB = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                
                if (flR > 255.f) {
                    flR = 255.f;
                }
                if (flG > 255.f) {
                    flG = 255.f;
                }
                if (flB > 255.f) {
                    flB = 255.f;
                }
                flR = flR / 255.f;
                flG = flG / 255.f;
                flB = flB / 255.f;
                
                float flR2 = atof(szLine.SubString(iSplitter9Pos + 1, iSplitter10Pos - iSplitter9Pos - 1));
                float flG2 = atof(szLine.SubString(iSplitter10Pos + 1, iSplitter11Pos - iSplitter10Pos - 1));
                float flB2 = atof(szLine.SubString(iSplitter11Pos + 1, iSplitter12Pos - iSplitter11Pos - 1));
                
                if (flR2 > 255.f) {
                    flR2 = 255.f;
                }
                if (flG2 > 255.f) {
                    flG2 = 255.f;
                }
                if (flB2 > 255.f) {
                    flB2 = 255.f;
                }
                flR2 = flR2 / 255.f;
                flG2 = flG2 / 255.f;
                flB2 = flB2 / 255.f;
                
                string szTargetname = szLine.SubString(iSplitter12Pos + 1, iSplitter13Pos - iSplitter12Pos - 1);
                
                string szTargets = szLine.SubString(iSplitter13Pos + 1, iSplitter14Pos - iSplitter13Pos - 1);
                
                const array<string>@ rgszTargets = szTargets.Split(",");
                
                string szKillCounters = szLine.SubString(iSplitter14Pos + 1);
                
                const array<string>@ rgszKillCounters = szKillCounters.Split(",");
                
                Vector vecPosition(flX, flY, flZ);
                
                Vector vecAngles(flYaw, flPitch, flRoll);
                
                Vector vecColour(flR, flG, flB);
                Vector vecSecondColour(flR2, flG2, flB2);
                
                CDynamicSkullHolder@ pSkull = CDynamicSkullHolder(vecPosition, vecAngles, vecColour, vecSecondColour, szTargetname, rgszTargets, rgszKillCounters);
                lpAntiRushMap.m_rglpSkulls.insertLast(@pSkull);
            } else if (szLine.StartsWith("padlock")) {
                szLine = szLine.SubString(8, szLine.Length() - 1); //cut "padlock|"
                //padlock|x,y,z,yaw,pitch,roll,r,g,b$targetname
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flYaw = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flPitch = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flRoll = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                float flR = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flG = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flB = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                
                if (flR > 255.f) {
                    flR = 255.f;
                }
                if (flG > 255.f) {
                    flG = 255.f;
                }
                if (flB > 255.f) {
                    flB = 255.f;
                }
                flR = flR / 255.f;
                flG = flG / 255.f;
                flB = flB / 255.f;
                
                string szTargetname = szLine.SubString(iSplitter9Pos + 1);
                
                Vector vecPosition(flX, flY, flZ);
                
                Vector vecAngles(flYaw, flPitch, flRoll);
                
                Vector vecColour(flR, flG, flB);
                
                CDynamicPadlock@ pPadlock = CDynamicPadlock(vecPosition, vecAngles, vecColour, szTargetname);
                lpAntiRushMap.m_rglpPadlocks.insertLast(@pPadlock);
            } else if (szLine.StartsWith("multi")) {
                szLine = szLine.SubString(6, szLine.Length() - 1); //cut "multi|"
                //multi|targetname$va(targets)
                int iSplitter1Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == "$" /* targets */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                    }
                }
                if (iSplitter1Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                string szTargetname = szLine.SubString(0, iSplitter1Pos);
                string szTargets = szLine.SubString(iSplitter1Pos + 1);
                
                const array<string>@ rgszTargets = szTargets.Split(",");
                
                CMultiManagerHolder@ pManager = CMultiManagerHolder(szTargetname, rgszTargets);
                lpAntiRushMap.m_rglpMultiManagers.insertLast(@pManager);
            } else if (szLine.StartsWith("squad")) {
                szLine = szLine.SubString(6, szLine.Length() - 1); //cut "squad|"
                //squad|x,y,z,maxerror$targetname
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flMaxError = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                
                string szTargetName = szLine.SubString(iSplitter4Pos + 1);
                
                Vector vecPosition(flX, flY, flZ);
                
                CSquadMakerHookHolder@ pSquad = CSquadMakerHookHolder(vecPosition, flMaxError, szTargetName);
                lpAntiRushMap.m_rglpSquads.insertLast(@pSquad);
            } else if (szLine.StartsWith("monstermaker")) {
                szLine = szLine.SubString(13, szLine.Length() - 1); //cut "monstermaker|"
                //monstermaker|x,y,z,maxerror$targetname
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flMaxError = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                
                string szTargetName = szLine.SubString(iSplitter4Pos + 1);
                
                Vector vecPosition(flX, flY, flZ);
                
                CSquadMakerHookHolder@ pMonster = CSquadMakerHookHolder(vecPosition, flMaxError, szTargetName);
                lpAntiRushMap.m_rglpMonsterMakers.insertLast(@pMonster);
            } else if (szLine.StartsWith("checkpoint")) {
                szLine = szLine.SubString(11, szLine.Length() - 1); //cut "checkpoint|"
                //checkpoint|x,y,z,funnel,startsound,endsound,vecMinHullSize,vecMaxHullSize$targetname$target@bActiveAtMapStart
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                int iSplitter10Pos = -1;
                int iSplitter11Pos = -1;
                int iSplitter12Pos = -1;
                int iSplitter13Pos = -1;
                int iSplitter14Pos = -1;
                int iSplitter15Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                        else if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                        else if (iSplitter10Pos == -1)
                            iSplitter10Pos = i;
                        else if (iSplitter11Pos == -1)
                            iSplitter11Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter12Pos == -1)
                            iSplitter12Pos = i;
                        else if (iSplitter13Pos == -1)
                            iSplitter13Pos = i;
                        else if (iSplitter14Pos == -1)
                            iSplitter14Pos = i;
                    } else if (szLine[i] == "@" /* bActiveAtMapStart */) {
                        if (iSplitter15Pos == -1)
                            iSplitter15Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1 || iSplitter10Pos == -1 || iSplitter11Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                string szFunnelSprite = szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1);
                string szStartSound = szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1);
                string szEndSound = szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1);
                
                float flMinHSX = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flMinHSY = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flMinHSZ = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                
                float flMaxHSX = atof(szLine.SubString(iSplitter9Pos + 1, iSplitter10Pos - iSplitter9Pos - 1));
                float flMaxHSY = atof(szLine.SubString(iSplitter10Pos + 1, iSplitter11Pos - iSplitter10Pos - 1));
                float flMaxHSZ = 0.f;
                if (iSplitter12Pos != -1) {
                    flMaxHSZ = atof(szLine.SubString(iSplitter11Pos + 1, iSplitter12Pos - iSplitter11Pos - 1));
                } else {
                    flMaxHSZ = atof(szLine.SubString(iSplitter11Pos + 1));
                }
                
                string szTargetName = "";
                string szKillTarget = "";
                string szActivateTarget = "";
                if (iSplitter13Pos == -1) {
                    szTargetName = szLine.SubString(iSplitter12Pos + 1);
                } else {
                    szTargetName = szLine.SubString(iSplitter12Pos + 1, iSplitter13Pos - iSplitter12Pos - 1);
                    if (iSplitter14Pos == -1) {
                        szKillTarget = szLine.SubString(iSplitter13Pos + 1);
                    } else {
                        szKillTarget = szLine.SubString(iSplitter13Pos + 1, iSplitter14Pos - iSplitter13Pos - 1);
                    }
                }
                if (iSplitter15Pos == -1) {
                    szActivateTarget = szLine.SubString(iSplitter14Pos + 1);
                } else {
                    szActivateTarget = szLine.SubString(iSplitter14Pos + 1, iSplitter15Pos - iSplitter14Pos - 1);
                }
                bool bActiveAtMapStart = false;
                if (iSplitter15Pos != -1) {
                    string szActiveAtMapStart = szLine.SubString(iSplitter15Pos + 1);
                    bActiveAtMapStart = atoi(szActiveAtMapStart) != 0;
                }
                Vector vecMinHullSize(flMinHSX, flMinHSY, flMinHSZ), vecMaxHullSize(flMaxHSX, flMaxHSY, flMaxHSZ);
                
                Vector vecPosition(flX, flY, flZ);
                
                CCheckpointSpawnerHolder@ pHolder = CCheckpointSpawnerHolder(vecPosition, szFunnelSprite, szStartSound, szEndSound, szTargetName, szKillTarget, szActivateTarget, bActiveAtMapStart, vecMinHullSize, vecMaxHullSize);
                lpAntiRushMap.m_rglpCheckpoints.insertLast(@pHolder);
            } else if (szLine.StartsWith("master")) {
                szLine = szLine.SubString(7, szLine.Length() - 1); //cut "master|"
                //master|targetname
                if (szLine.Length() < 1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                string szTargetname = szLine.SubString(0);
                
                CMasterHolder@ pMaster = CMasterHolder(szTargetname);
                lpAntiRushMap.m_rglpMasters.insertLast(@pMaster);
            } else if (szLine.StartsWith("dispatchkv") && !szLine.StartsWith("dispatchkvbymdl")) {
                szLine = szLine.SubString(11, szLine.Length() - 1); //cut "dispatchkv|"
                //dispatchkv|x,y,z,maxerror,classname,szKeyValueName,szKeyValueValue$targetname@bDoMagicAtMapStart
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                    } else if (szLine[i] == "@") {
                        if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flMaxError = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                
                string szClassname = szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1);
                
                string szKeyValueName = szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1);
                string szKeyValueValue = szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1);
                
                string szTargetname = "";
                bool bDoMagicAtMapStart = false;
                if (iSplitter8Pos == -1) {
                    szTargetname = szLine.SubString(iSplitter7Pos + 1);
                } else {
                    szTargetname = szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1);
                    bDoMagicAtMapStart = atoi(szLine.SubString(iSplitter8Pos + 1)) != 0;
                }
                
                Vector vecPosition(flX, flY, flZ);
                
                CKeyValueDispatcherHolder@ pDispatcher = CKeyValueDispatcherHolder(vecPosition, flMaxError, szClassname, szTargetname, szKeyValueName, szKeyValueValue, bDoMagicAtMapStart);
                lpAntiRushMap.m_rglpKeyValueDispatchers.insertLast(@pDispatcher);
            } else if (szLine.StartsWith("dispatchkvbymdl")) {
                szLine = szLine.SubString(16, szLine.Length() - 1); //cut "dispatchkvbymdl|"
                //dispatchkvbymdl|szModel,szKeyValueName,szKeyValueValue$targetname@bDoMagicAtMapStart
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                    } else if (szLine[i] == "@") {
                        if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                string szModel = szLine.SubString(0, iSplitter1Pos);
                
                string szKeyValueName = szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1);
                string szKeyValueValue = szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1);
                
                string szTargetname = "";
                bool bDoMagicAtMapStart = false;
                if (iSplitter4Pos == -1) {
                    szTargetname = szLine.SubString(iSplitter3Pos + 1);
                } else {
                    szTargetname = szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1);
                    bDoMagicAtMapStart = atoi(szLine.SubString(iSplitter4Pos + 1)) != 0;
                }
                
                CKeyValueDispatcherByModelHolder@ pDispatcher = CKeyValueDispatcherByModelHolder(szModel, szTargetname, szKeyValueName, szKeyValueValue, bDoMagicAtMapStart);
                lpAntiRushMap.m_rglpKeyValueDispatchersByModel.insertLast(@pDispatcher);
            } else if (szLine.StartsWith("create")) {
                szLine = szLine.SubString(7, szLine.Length() - 1); //cut "create|"
                //create|classname$targetname$va(keyvalues)@bDoMagicAtMapStart
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                    } else if (szLine[i] == "@") {
                        if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                string szClassname = szLine.SubString(0, iSplitter1Pos);
                string szTargetname = szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1);
                
                string szKeyvalues = String::EMPTY_STRING;
                bool bDoMagicAtMapStart = false;
                if (iSplitter3Pos == -1) {
                    szKeyvalues = szLine.SubString(iSplitter2Pos + 1);
                } else {
                    szKeyvalues = szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1);
                    bDoMagicAtMapStart = atoi(szLine.SubString(iSplitter3Pos + 1)) != 0;
                }
                const array<string>@ rgszKeyvalues = szKeyvalues.Split(",");
                
                CEntitySpawnerHolder@ pSpawner = CEntitySpawnerHolder(szClassname, szTargetname, rgszKeyvalues, bDoMagicAtMapStart);
                lpAntiRushMap.m_rglpSpawners.insertLast(@pSpawner);
            } else if (szLine.StartsWith("portals")) {
                szLine = szLine.SubString(8, szLine.Length() - 1); //cut "portals|"
                //portals|coors,coors2$targetname@bActivatedOnMapStart
                //portals|x,y,z,x2,y2,z2$targetname@bActivatedOnMapStart
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == "," /* coors */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                    } else if (szLine[i] == "@") {
                        if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                float flX2 = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flY2 = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flZ2 = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                string szTargetname = "";
                bool bActivatedOnMapStart = false;
                if (iSplitter7Pos == -1) {
                    szTargetname = szLine.SubString(iSplitter6Pos + 1);
                } else {
                    szTargetname = szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1);
                    bActivatedOnMapStart = atoi(szLine.SubString(iSplitter7Pos + 1)) != 0;
                }
                
                Vector vecEntryPortal(flX, flY, flZ);
                Vector vecExitPortal(flX2, flY2, flZ2);
                
                CEntryExitPlayerPortalsHolder@ pPortals = CEntryExitPlayerPortalsHolder(vecEntryPortal, vecExitPortal, szTargetname, bActivatedOnMapStart);
                lpAntiRushMap.m_rglpPortals.insertLast(@pPortals);
            } else if (szLine.StartsWith("arrow")) {
                szLine = szLine.SubString(6, szLine.Length() - 1); //cut "arrow|"
                //arrow|x,y,z,yaw,pitch,roll,r,g,b$targetname@bActiveAtMapStart
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                int iSplitter10Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                    } else if (szLine[i] == "$" /* targetname */) {
                        if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                    } else if (szLine[i] == "@" /* bActiveAtMapStart */) {
                        if (iSplitter10Pos == -1)
                            iSplitter10Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flYaw = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flPitch = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flRoll = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                float flR = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flG = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flB = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                
                if (flR > 255.f) {
                    flR = 255.f;
                }
                if (flG > 255.f) {
                    flG = 255.f;
                }
                if (flB > 255.f) {
                    flB = 255.f;
                }
                flR = flR / 255.f;
                flG = flG / 255.f;
                flB = flB / 255.f;
                
                string szTargetname();
                
                bool bActiveAtMapStart = false;
                if (iSplitter10Pos != -1) {
                    szTargetname = szLine.SubString(iSplitter9Pos + 1, iSplitter10Pos - iSplitter9Pos - 1);
                
                    string szActiveAtMapStart = szLine.SubString(iSplitter10Pos + 1);
                    bActiveAtMapStart = atoi(szActiveAtMapStart) != 0;
                } else {
                    szTargetname = szLine.SubString(iSplitter9Pos + 1);
                }
                
                Vector vecPosition(flX, flY, flZ);
                
                Vector vecAngles(flYaw, flPitch, flRoll);
                
                Vector vecColour(flR, flG, flB);
                
                CDynamicArrowHolder@ pArrow = CDynamicArrowHolder(szTargetname, vecPosition, vecAngles, vecColour, bActiveAtMapStart);
                lpAntiRushMap.m_rglpArrows.insertLast(@pArrow);
            } else if (szLine.StartsWith("laser")) {
                szLine = szLine.SubString(6, szLine.Length() - 1); //cut "laser|"
                int iSplitter1Pos = -1;
                int iSplitter2Pos = -1;
                int iSplitter3Pos = -1;
                int iSplitter4Pos = -1;
                int iSplitter5Pos = -1;
                int iSplitter6Pos = -1;
                int iSplitter7Pos = -1;
                int iSplitter8Pos = -1;
                int iSplitter9Pos = -1;
                int iSplitter10Pos = -1;
                int iSplitter11Pos = -1;
                int iSplitter12Pos = -1;
                int iSplitter13Pos = -1;
                int iSplitter14Pos = -1;
                for (uint i = 0; i < szLine.Length(); i++) {
                    if (szLine[i] == ',' /* coord end */) {
                        if (iSplitter1Pos == -1)
                            iSplitter1Pos = i;
                        else if (iSplitter2Pos == -1)
                            iSplitter2Pos = i;
                        else if (iSplitter3Pos == -1)
                            iSplitter3Pos = i;
                        else if (iSplitter4Pos == -1)
                            iSplitter4Pos = i;
                        else if (iSplitter5Pos == -1)
                            iSplitter5Pos = i;
                        else if (iSplitter6Pos == -1)
                            iSplitter6Pos = i;
                        else if (iSplitter7Pos == -1)
                            iSplitter7Pos = i;
                        else if (iSplitter8Pos == -1)
                            iSplitter8Pos = i;
                        else if (iSplitter9Pos == -1)
                            iSplitter9Pos = i;
                        else if (iSplitter10Pos == -1)
                            iSplitter10Pos = i;
                        else if (iSplitter11Pos == -1)
                            iSplitter11Pos = i;
                        else if (iSplitter11Pos == -1)
                            iSplitter11Pos = i;
                        else if (iSplitter12Pos == -1)
                            iSplitter12Pos = i;
                        else if (iSplitter13Pos == -1)
                            iSplitter13Pos = i;
                    } else if (szLine[i] == "$" /* beam name */) {
                        if (iSplitter14Pos == -1)
                            iSplitter14Pos = i;
                    }
                }
                if (iSplitter1Pos == -1 || iSplitter2Pos == -1 || iSplitter3Pos == -1 || iSplitter4Pos == -1 || iSplitter5Pos == -1 || iSplitter6Pos == -1 || iSplitter7Pos == -1 || iSplitter8Pos == -1 || iSplitter9Pos == -1 || iSplitter10Pos == -1 || iSplitter11Pos == -1 || iSplitter12Pos == -1 || iSplitter13Pos == -1 || iSplitter14Pos == -1) {
                    AR_UTIL_PrintToLog("[AntiRush] Failure parsing " + string(nLineIdx) + " line. Check if everything is correct! (Map: " + rgszMapList[idx] + ")\n");
                    if (_bDuringGameplay) {
                        g_PlayerFuncs.ClientPrintAll(HUD_PRINTTALK, "[AntiRush] There was a problem when we were parsing antirush file. Check the logs for more info!\n");
                    }
                    continue;
                }
                float flX = atof(szLine.SubString(0, iSplitter1Pos));
                float flY = atof(szLine.SubString(iSplitter1Pos + 1, iSplitter2Pos - iSplitter1Pos - 1));
                float flZ = atof(szLine.SubString(iSplitter2Pos + 1, iSplitter3Pos - iSplitter2Pos - 1));
                
                float flX2 = atof(szLine.SubString(iSplitter3Pos + 1, iSplitter4Pos - iSplitter3Pos - 1));
                float flY2 = atof(szLine.SubString(iSplitter4Pos + 1, iSplitter5Pos - iSplitter4Pos - 1));
                float flZ2 = atof(szLine.SubString(iSplitter5Pos + 1, iSplitter6Pos - iSplitter5Pos - 1));
                
                float flR = atof(szLine.SubString(iSplitter6Pos + 1, iSplitter7Pos - iSplitter6Pos - 1));
                float flG = atof(szLine.SubString(iSplitter7Pos + 1, iSplitter8Pos - iSplitter7Pos - 1));
                float flB = atof(szLine.SubString(iSplitter8Pos + 1, iSplitter9Pos - iSplitter8Pos - 1));
                
                if (flR > 255.f) {
                    flR = 255.f;
                }
                if (flG > 255.f) {
                    flG = 255.f;
                }
                if (flB > 255.f) {
                    flB = 255.f;
                }
                
                float flR2 = atof(szLine.SubString(iSplitter9Pos + 1, iSplitter10Pos - iSplitter9Pos - 1));
                float flG2 = atof(szLine.SubString(iSplitter10Pos + 1, iSplitter11Pos - iSplitter10Pos - 1));
                float flB2 = atof(szLine.SubString(iSplitter11Pos + 1, iSplitter12Pos - iSplitter11Pos - 1));
                
                if (flR2 > 255.f) {
                    flR2 = 255.f;
                }
                if (flG2 > 255.f) {
                    flG2 = 255.f;
                }
                if (flB2 > 255.f) {
                    flB2 = 255.f;
                }
                
                float flRenderAmount = atof(szLine.SubString(iSplitter12Pos + 1, iSplitter13Pos - iSplitter12Pos - 1));
                
                float flDamage = atof(szLine.SubString(iSplitter13Pos + 1, iSplitter14Pos - iSplitter13Pos - 1));

                string szTargetName = szLine.SubString(iSplitter14Pos + 1);
                
                Vector vecFirstPoint(flX, flY, flZ);
                Vector vecSecondPoint(flX2, flY2, flZ2);
                Vector vecColour(flR, flG, flB);
                Vector vecSecondColour(flR2, flG2, flB2);
                
                CDynamicEnvBeam@ pBeam = CDynamicEnvBeam(vecFirstPoint, vecSecondPoint, vecColour, vecSecondColour, szTargetName, flRenderAmount, flDamage);
                lpAntiRushMap.m_rglpBeams.insertLast(@pBeam);
            } 
        }
        g_rglpMaps.insertLast(@lpAntiRushMap);
    }
}

void MapInit() {
    //Number characters precache
    for (int idx = 0; idx < 10; idx++) {
        g_Game.PrecacheModel("sprites/hlcancer/antirush/d" + string(idx) + ".mdl");
    }
    g_Game.PrecacheModel("sprites/hlcancer/antirush/null.mdl");
    g_Game.PrecacheModel("sprites/hlcancer/antirush/percent.mdl");
    g_Game.PrecacheModel("sprites/hlcancer/antirush/key.mdl");
    g_Game.PrecacheModel("sprites/hlcancer/antirush/padlock.mdl");
    g_Game.PrecacheModel("sprites/hlcancer/antirush/skull.mdl");
    g_Game.PrecacheModel("sprites/hlcancer/antirush/arrow2d.mdl");
    g_CustomEntityFuncs.RegisterCustomEntity("CToggleableCustomFuncWall", "func_toggleable_custom_wall");
    g_CustomEntityFuncs.RegisterCustomEntity("CDynamicToggleableCustomEnvironmentBeam", "env_custom_beam");
    g_CustomEntityFuncs.RegisterCustomEntity("CDynamicPlayerCounterTrigger", "trigger_dynamic_player_counter");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentDynamicWallNumber", "env_dynamic_wall_number");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentDynamicWallSpeaker", "env_dynamic_wall_speaker");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentDynamicFurniture", "env_dynamic_furniture");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentDynamicWallTimer", "env_dynamic_timer");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentFlyingKey", "env_flying_key");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentDynamicKillCounter", "env_dynamic_kill_counter");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentDynamicSkull", "env_dynamic_skull");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentDynamicPadlock", "env_dynamic_padlock");
    g_CustomEntityFuncs.RegisterCustomEntity("CCustomMultiManager", "func_custom_multi_manager");
    g_CustomEntityFuncs.RegisterCustomEntity("CSquadMonsterMakerHook", "func_sqd_mstr_maker_hook");
    g_CustomEntityFuncs.RegisterCustomEntity("CDynamicCheckpointSpawner", "func_checkpoint_spawner");
    g_CustomEntityFuncs.RegisterCustomEntity("CDynamicLockMaster", "func_dynamic_lock_master");
    g_CustomEntityFuncs.RegisterCustomEntity("CDynamicKeyValueDispatcher", "func_dynamic_keyvalue_dispatcher");
    g_CustomEntityFuncs.RegisterCustomEntity("CDynamicEntitySpawner", "func_dynamic_entity_spawner");
    g_CustomEntityFuncs.RegisterCustomEntity("CEntryExitPlayerPortals", "func_entry_exit_player_portal_parent");
    g_CustomEntityFuncs.RegisterCustomEntity("CCustomSpritePortalEntity", "env_antirush_portal_sprite");
    g_CustomEntityFuncs.RegisterCustomEntity("CEnvironmentDynamicArrow", "env_dynamic_arrow");
    g_Game.PrecacheOther("env_custom_beam");
    
    @g_pCurrentMap = null;
    g_rgpPathTracks.resize(0);
    g_rgiImmuneToDeleteByDeleteCommandEnts.resize(0);
    
    AR_UTIL_ParseAntiRushMapEntriesList(false);
    
    string szMapName = g_Engine.mapname;
    CDynamicAntiRushMap@ pMap = AR_TryPlacingStuffIfMapExistsInList(szMapName);
    g_Game.PrecacheOther("point_checkpoint");
            
    g_Game.PrecacheModel("models/common/lambda.mdl");
    g_Game.PrecacheGeneric("models/common/lambda.mdl");
            
    if (pMap !is null) {
        for (uint idx = 0; idx < pMap.m_rglpCheckpoints.length(); idx++) {
            CCheckpointSpawnerHolder@ pHoldah = @pMap.m_rglpCheckpoints[idx];

            g_Game.PrecacheModel(pHoldah.m_lpszFunnelSprite);
            g_Game.PrecacheGeneric(pHoldah.m_lpszFunnelSprite);

            g_SoundSystem.PrecacheSound(pHoldah.m_lpszStartSound);
            g_SoundSystem.PrecacheSound(pHoldah.m_lpszEndSound);

            g_Game.PrecacheGeneric("sound/" + pHoldah.m_lpszStartSound);
            g_Game.PrecacheGeneric("sound/" + pHoldah.m_lpszEndSound);
        }
    }
}

void MapActivate() {
    AR_PlaceStuffMapActivate();
}

void MapStart() {
    AR_PlaceStuffMapStart();
}