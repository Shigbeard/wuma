
WUMA = WUMA or {}
WUMA.GUI = {}
WUMA.GUI.Tabs = {}

local WGUI = WUMA.GUI

if not WUMA.HasCreatedFonts then
	surface.CreateFont("WUMATextSmall", {
		font = "Arial",
		size = 10,
		weight = 700,
		blursize = 0,
		scanlines = 0,
		antialias = true
	})
end
WUMA.HasCreatedFonts = true

WUMA.Subscriptions = {}
WUMA.Subscriptions.user = {}
WUMA.Subscriptions.timers = {}

WUMA.HasUserAccessNetworkBool = "WUMAHasAccess"

function WUMA.GUI.Initialize()

	//Requests
	if LocalPlayer():GetNWBool(WUMA.HasUserAccessNetworkBool) then
		WUMA.RequestFromServer(WUMA.NET.SETTINGS:GetID())
		
		if GetConVar("wuma_request_on_join"):GetBool() then
			WUMA.RequestFromServer(WUMA.NET.RESTRICTION:GetID())
			WUMA.RequestFromServer(WUMA.NET.LIMIT:GetID())
			WUMA.RequestFromServer(WUMA.NET.LOADOUT:GetID())
			WUMA.RequestFromServer(WUMA.NET.USERS:GetID())
			WUMA.RequestFromServer(WUMA.NET.GROUPS:GetID())
			WUMA.RequestFromServer(WUMA.NET.MAPS:GetID())
			WUMA.RequestFromServer(WUMA.NET.LOOKUP:GetID(),200)
			 
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Restriction:GetID())
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Limit:GetID())
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Loadout:GetID())
			
			WUMA.Subscriptions.info = true
			WUMA.Subscriptions.restrictions = true
			WUMA.Subscriptions.limits = true
			WUMA.Subscriptions.loadouts = true
			WUMA.Subscriptions.users = true
		end
	end

	--Create EditablePanel 
	WGUI.Base = vgui.Create("EditablePanel")
	WGUI.Base:SetSize(ScrW()*0.40,ScrH()*0.44)
	WGUI.Base:SetPos(ScrW()/2-WGUI.Base:GetWide()/2,ScrH()/2-WGUI.Base:GetTall()/2)
	WGUI.Base:SetVisible(false)
	
	--Create propertysheet
	WGUI.PropertySheet = vgui.Create("WPropertySheet",WGUI.Base)
	WGUI.PropertySheet:SetSize(WGUI.Base:GetSize())
	WGUI.PropertySheet:SetPos(0,0)
	WGUI.PropertySheet:SetShowExitButton(true)

	--Request panels
	WGUI.Tabs.Settings = vgui.Create("WUMA_Settings", WGUI.PropertySheet) --Settings
	WGUI.Tabs.Restrictions = vgui.Create("WUMA_Restrictions", WGUI.PropertySheet) --Restriction	
	WGUI.Tabs.Limits = vgui.Create("WUMA_Limits", WGUI.PropertySheet) --Limit	
	WGUI.Tabs.Loadouts = vgui.Create("WUMA_Loadouts", WGUI.PropertySheet) --Loadouts
	WGUI.Tabs.Users = vgui.Create("WUMA_Users", WGUI.PropertySheet) --Users
	
	WGUI.PropertySheet.OnTabChange = WUMA.OnTabChange

	--Adding panels to PropertySheet
	WGUI.PropertySheet:AddSheet(WGUI.Tabs.Settings.TabName, WGUI.Tabs.Settings, WGUI.Tabs.Settings.TabIcon) --Settings
	WGUI.PropertySheet:AddSheet(WGUI.Tabs.Restrictions.TabName, WGUI.Tabs.Restrictions, WGUI.Tabs.Restrictions.TabIcon) --Restriction
	WGUI.PropertySheet:AddSheet(WGUI.Tabs.Limits.TabName, WGUI.Tabs.Limits, WGUI.Tabs.Limits.TabIcon) --Limit
	WGUI.PropertySheet:AddSheet(WGUI.Tabs.Loadouts.TabName, WGUI.Tabs.Loadouts, WGUI.Tabs.Loadouts.TabIcon) --Loadout
	WGUI.PropertySheet:AddSheet(WGUI.Tabs.Users.TabName, WGUI.Tabs.Users, WGUI.Tabs.Users.TabIcon) --Player
	
	WGUI.Tabs.Users.OnExtraChange = WUMA.OnUserTabChange
	
	hook.Call("OnWUMAInitialized", _, WGUI.PropertySheet)
	
end
hook.Add("InitPostEntity", "WUMAGuiInitialize", WUMA.GUI.Initialize)

function WUMA.GUI.Show()
	if LocalPlayer():GetNWBool(WUMA.HasUserAccessNetworkBool) then
		WUMA.GUI.Base:SetVisible(true)
		WUMA.GUI.Base:MakePopup()
	else
		LocalPlayer():PrintMessage(HUD_PRINTCONSOLE,"You do not have access to this command\n")
	end
end

function WUMA.GUI.Hide()
	WUMA.GUI.Base:SetVisible(false)
end

function WUMA.GUI.Toggle()
	if WUMA.GUI.Base:IsVisible() then
		WUMA.GUI.Hide()
	else
		WUMA.GUI.Show()
	end
end

function WUMA.OnTabChange(_,tabname)
	
	if not WUMA.Subscriptions.info then
		WUMA.RequestFromServer(WUMA.NET.USERS:GetID())
		WUMA.RequestFromServer(WUMA.NET.GROUPS:GetID())
		WUMA.RequestFromServer(WUMA.NET.MAPS:GetID())
		
		WUMA.Subscriptions.info = true
	end
	
	if (tabname == WUMA.GUI.Tabs.Restrictions.TabName and not WUMA.Subscriptions.restrictions) then
		WUMA.FetchData(Restriction:GetID())
	elseif (tabname == WUMA.GUI.Tabs.Limits.TabName and not WUMA.Subscriptions.limits) then
		WUMA.FetchData(Limit:GetID())
	elseif (tabname == WUMA.GUI.Tabs.Loadouts.TabName and not WUMA.Subscriptions.loadouts) then
		WUMA.FetchData(Loadout:GetID())
	elseif (tabname == WUMA.GUI.Tabs.Users.TabName and not WUMA.Subscriptions.users) then
		WUMA.RequestFromServer(WUMA.NET.LOOKUP:GetID(),200)
		
		WUMA.Subscriptions.users = true
	end
	
end

function WUMA.OnUserTabChange(_,typ,steamid)
	if not (typ == "default") then
		if not WUMA.Subscriptions.user[steamid] then
			WUMA.Subscriptions.user[steamid] = {}
		end
	end

	if (typ == Restriction:GetID()) then
		if not WUMA.Subscriptions.user[steamid][typ] then
			WUMA.RequestFromServer(WUMA.NET.RESTRICTION:GetID(),steamid)	
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),{steamid,false,typ})
		else
			if timer.Exists(typ..":::"..steamid) then
				timer.Remove(typ..":::"..steamid)
			end
		end
		
		WUMA.Subscriptions.user[steamid][typ] = true
	elseif (typ == Limit:GetID()) then
		if not WUMA.Subscriptions.user[steamid][typ] then
			WUMA.RequestFromServer(WUMA.NET.LIMIT:GetID(),steamid)	
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),{steamid,false,typ})
		else
			if timer.Exists(typ..":::"..steamid) then
				timer.Remove(typ..":::"..steamid)
			end
		end
		
		WUMA.Subscriptions.user[steamid][typ] = true
	elseif (typ == Loadout:GetID()) then
		if not WUMA.Subscriptions.user[steamid][typ] then
			WUMA.RequestFromServer(WUMA.NET.LOADOUT:GetID(),steamid)	
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),{steamid,false,typ})
		else
			if timer.Exists(typ..":::"..steamid) then
				timer.Remove(typ..":::"..steamid)
			end
		end
		
		WUMA.Subscriptions.user[steamid][typ] = true
	elseif (typ == "default") then
		local timeout = GetConVar("wuma_autounsubscribe_user"):GetInt()
	
		if timeout and (timeout >= 0) and WUMA.Subscriptions.user[steamid] then
			for k, _ in pairs(WUMA.Subscriptions.user[steamid]) do
				timer.Create(k..":::"..steamid,timeout,1,function() WUMA.FlushUserData(steamid,k) end)
			end
		end
	end
end

function WUMA.FetchData(typ)
	if typ then
		if (typ == Restriction:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.RESTRICTION:GetID())
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Restriction:GetID())
			
			WUMA.Subscriptions.restrictions = true
		elseif (typ == Limit:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.LIMIT:GetID())
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Limit:GetID())
			
			WUMA.Subscriptions.limits = true
		elseif (typ == Loadout:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.LOADOUT:GetID())
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Loadout:GetID())
			
			WUMA.Subscriptions.loadouts = true
		end
		
	else
		WUMA.FetchData(Restriction:GetID())
		WUMA.FetchData(Limit:GetID())
		WUMA.FetchData(Loadout:GetID())
	end
end

function WUMA.FlushData(typ)
	if typ then
		if (typ == Restriction:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Restriction:GetID(),true)
			WUMA.Restrictions = {}
			
			if WUMA.GUI.Tabs.Restrictions then
				WUMA.GUI.Tabs.Restrictions:GetDataView():SetDataTable({})
			end
			
			WUMA.Subscriptions.restrictions = false
		elseif (typ == Limit:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Limit:GetID(),true)
			WUMA.Limits = {}
			
			if WUMA.GUI.Tabs.Limits then
				WUMA.GUI.Tabs.Limits:GetDataView():SetDataTable({})
			end
			 
			WUMA.Subscriptions.loadouts = false
		elseif (typ == Loadout:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),Loadout:GetID(),true)
			WUMA.Loadouts = {}
			
			if WUMA.GUI.Tabs.Loadouts then
				WUMA.GUI.Tabs.Loadouts:GetDataView():SetDataTable({})
			end
			
			WUMA.Subscriptions.limits = false
		end
		
	else
		WUMA.FlushData(Restriction:GetID())
		WUMA.FlushData(Limit:GetID())
		WUMA.FlushData(Loadout:GetID())
	end
end

function WUMA.FlushUserData(steamid,typ)
	if typ and steamid then
		if (typ == Restriction:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),{steamid,true,Restriction:GetID()})
			if WUMA.UserData[steamid] then WUMA.UserData[steamid].Restrictions = nil end
			
			WUMA.GUI.Tabs.Users.restrictions:GetDataView():SetDataTable({})
			if WUMA.GUI.Tabs.Users.restrictions:IsVisible() then WUMA.GUI.Tabs.Users.OnBackClick(WUMA.GUI.Tabs.Users.restrictions) end
			
			if WUMA.Subscriptions.user[steamid] then WUMA.Subscriptions.user[steamid][typ] = nil end
		elseif (typ == Limit:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),{steamid,true,Limit:GetID()})
			if WUMA.UserData[steamid] then WUMA.UserData[steamid].Limits = nil end
			
			WUMA.GUI.Tabs.Users.limits:GetDataView():SetDataTable({})
			if WUMA.GUI.Tabs.Users.limits:IsVisible() then WUMA.GUI.Tabs.Users.OnBackClick(WUMA.GUI.Tabs.Users.limits) end
			
			if WUMA.Subscriptions.user[steamid] then WUMA.Subscriptions.user[steamid][typ] = nil end
		elseif (typ == Loadout:GetID()) then
			WUMA.RequestFromServer(WUMA.NET.SUBSCRIPTION:GetID(),{steamid,true,Loadout:GetID()})
			if WUMA.UserData[steamid] then WUMA.UserData[steamid].Loadouts = nil end
			
			WUMA.GUI.Tabs.Users.loadouts:GetDataView():SetDataTable({})
			if WUMA.GUI.Tabs.Users.loadouts:IsVisible() then WUMA.GUI.Tabs.Users.OnBackClick(WUMA.GUI.Tabs.Users.loadouts) end
			
			if WUMA.Subscriptions.user[steamid] then WUMA.Subscriptions.user[steamid][typ] = nil end
		end
		
		if (WUMA.Subscriptions.user[steamid] and table.Count(WUMA.Subscriptions.user[steamid]) < 1) then WUMA.Subscriptions.user[steamid] = nil end
		if (WUMA.UserData[steamid] and table.Count(WUMA.UserData[steamid]) < 1) then WUMA.UserData[steamid] = nil end
	elseif (steamid) then
		WUMA.FlushUserData(steamid,Restriction:GetID())
		WUMA.FlushUserData(steamid,Limit:GetID())
		WUMA.FlushUserData(steamid,Loadout:GetID())
	else
		for id, _ in pairs(WUMA.Subscriptions.user) do
			WUMA.FlushUserData(id)
		end
	end
end

WUMA.GUI.HookIDs = 1
function WUMA.GUI.AddHook(h,name,func)
	hook.Add(h,name..WUMA.GUI.HookIDs,func)
	WUMA.GUI.HookIDs = WUMA.GUI.HookIDs + 1
end

concommand.Add( "wuma", function() 
	WUMA.GUI.Toggle()
end)

concommand.Add( "loadout", function() 
	WUMA.Selfout = vgui.Create("DFrame")
	WUMA.Selfout:SetSize(ScrW()*0.40,ScrH()*0.44)
	WUMA.Selfout:SetPos(ScrW()/2-WUMA.Selfout:GetWide()/2,ScrH()/2-WUMA.Selfout:GetTall()/2)
	WUMA.Selfout:SetTitle("Select your loadout")
	WUMA.Selfout.Paint = function()
		draw.RoundedBox(5, 0, 0, WUMA.Selfout:GetWide(), WUMA.Selfout:GetTall(), Color(59, 59, 59, 255))
		draw.RoundedBox(5, 1, 1, WUMA.Selfout:GetWide() - 2, WUMA.Selfout:GetTall() - 2, Color(226, 226, 226, 255))
		
		draw.RoundedBox(5, 1, 1, WUMA.Selfout:GetWide()-2, 25-1, Color(163, 165, 169, 255))
		surface.SetDrawColor(Color(163, 165, 169, 255))
		surface.DrawRect(1, 10, WUMA.Selfout:GetWide()- 2, 15)
	end
		
	local loadout = vgui.Create("WUMA_PersonalLoadout",WUMA.Selfout)
	loadout:Dock(TOP)
	loadout:SetWide(WUMA.Selfout:GetWide())
	loadout:SetTall(WUMA.Selfout:GetTall()-35)
	loadout.OnClose = function() 
		WUMA.RequestFromServer(WUMA.NET.PERSONAL:GetID(),"unsubscribe")
		hook.Remove(WUMA.USERDATAUPDATE, "WUMAPersonalLoadoutUpdate")
	end
	
	hook.Add(WUMA.USERDATAUPDATE, "WUMAPersonalLoadoutUpdate", function(user, enum, update)
		if not loadout then return end
		
		if (enum == Loadout:GetID()) then
			if update.primary then
				for k, v in pairs(update.weapons) do
					if (k == update.primary) then update.weapons[k].isprimary = true end
				end
			end
			
			loadout:GetDataView():SetDataTable(update.weapons)
		elseif (enum == Restriction:GetID()) then
			PrintTable(update)
			for key, restriction in pairs(update) do
				if istable(restriction) and (restriction.type == "swep") then
					table.RemoveByValue(loadout.weapons, restriction.string)
				else 
					table.insert(loadout.weapons,string.sub(key, 6))
				end
			end
			
			loadout:ReloadSuggestions()
		end
		
	end)
	
	WUMA.RequestFromServer(WUMA.NET.PERSONAL:GetID(),"subscribe")
	WUMA.RequestFromServer(WUMA.NET.PERSONAL:GetID(),"loadout")
	WUMA.RequestFromServer(WUMA.NET.PERSONAL:GetID(),"restrictions")

	WUMA.Selfout:MakePopup()
	WUMA.Selfout:SetVisible(true)
	
end)
