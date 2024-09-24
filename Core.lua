PBL = LibStub("AceAddon-3.0"):NewAddon("Personal Black List", "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0")
local GLDataBroker = LibStub("LibDataBroker-1.1"):NewDataObject("PBL", {
    type = "data source",
    text = "PBL",
    icon = "Interface\\AddOns\\PersonalBlacklist\\media\\___newIcon.blp",
    OnTooltipShow = function(tooltip)
          tooltip:SetText("Personal Blacklist")
          tooltip:AddLine("Ban List", 1, 1, 1)
          tooltip:Show()
     end,
    OnClick = function() PBL:showFrame() end,

})
local icon = LibStub("LibDBIcon-1.0")
local L = LibStub("AceLocale-3.0"):GetLocale("PBL")

local defaults = {
    global = {
        banlist = {},
        blackList = {}
    },
    profile= {
        classes={
            L["UNSPECIFIED"],
            L["DEATHKNIGHT"],
            L["DEMONHUNTER"],
            L["DRUID"],
            L["HUNTER"],
            L["MAGE"],
            L["MONK"],
            L["PALADIN"],
            L["PRIEST"],
            L["ROGUE"],
            L["SHAMAN"],
            L["WARLOCK"],
            L["WARRIOR"],
            L["EVOKER"],
        },
        categories={
            L["dropDownAll"],
            L["dropDownGuild"],
            L["dropDownRaid"],
            L["dropDownMythic"],
            L["dropDownPvP"],
            L["dropDownWorld"]
        },
        reasons={
            L["dropDownAll"],
            L["dropDownQuit"],
            L["dropDownToxic"],
            L["dropDownBadDPS"],
            L["dropDownBadHeal"],
            L["dropDownBadTank"],
            L["dropDownBadPlayer"],
            L["dropDownAFK"],
            L["dropDownNinja"],
            L["dropDownSpam"],
            L["dropDownScam"],
            L["dropDownRac"]
        },
        minimap = { hide = false, },
        chatfilter = { disabled = true, },
        ShowAlert = {
            ["LeaveAlert"] = false,
            ["count"] = 0,
            ["onparty"] = {},
        },

    }
}

-- --------------------------------------------------------------------------
-- Create Ban Item
-- --------------------------------------------------------------------------
-- Create item to add to blacklist.
-- TODO: Refactor to potentially use a class instead of a table.
--       Potentially move to Utils.lua
-- --------------------------------------------------------------------------

function createBanItem(name,realm,classFile,category,reason,pnote)
    local unitobjtoban = {
        name = strupper(name),
        realm = strupper(realm),
        classFile = strupper(classFile),
        catIdx = tonumber(category),
        reaIdx = tonumber(reason),
        note = ""
    }

    if pnote == "" then
      unitobjtoban.note = "N/A"
    else
      unitobjtoban.note = pnote
    end
    
    return unitobjtoban
end

-- --------------------------------------------------------------------------
-- General Addon Structure
-- --------------------------------------------------------------------------
-- OnInitialize, etc.
-- --------------------------------------------------------------------------

function PBL:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("PBLDB", defaults, true)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("PBL", "PBL")
    icon:Register("PBL", GLDataBroker, self.db.profile.minimap)
    StaticPopupDialogs.CONFIRM_LEAVE_IGNORE = {
        text = "%s",
        button1 = L["confirmYesBtn"],
        button2 = L["confirmNoBtn"],
        OnAccept = function() C_PartyInfo.LeaveParty() end,
        whileDead = 1, hideOnEscape = 1, showAlert = 1,
    }

    if #PBL.db.global.banlist > 0 then
        local index, value
        for index, value in ipairs(PBL.db.global.banlist) do
            local name,_,realm,_,classFile,_,category,_,reason = strsplit("$$",value)
            table.insert(PBL.db.global.blackList, createBanItem(name,realm,classFile,category,reason))

        end
        PBL.db.global.banlist = {}
    end
end

-- --------------------------------------------------------------------------
-- Chat Commands
-- --------------------------------------------------------------------------
-- Insert blacklist information into unit tooltips.
-- TODO: Refactor and potentially move to its own Options.lua module.
--       Rename ChatFilter to "ChatPrefix" or something more fitting.
-- --------------------------------------------------------------------------

PBL:RegisterChatCommand("pbl", "SlashPBLCommand")

-- Opens the main PBL frame.
function PBL:SlashPBLCommand(input)
    if not input or input:trim() == "" then
        --InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
        PBL:showFrame()
    elseif input:trim() =="config" then
        LibStub("AceConfigDialog-3.0"):Open("PBL")
    else
        LibStub("AceConfigCmd-3.0"):HandleCommand("pbl", "PBL", input)
    end
end

-- Toggles the minimap icon.
function PBL:CommandIcon()
    self.db.profile.minimap.hide = not self.db.profile.minimap.hide
    if self.db.profile.minimap.hide then
        icon:Hide("PBL")
    else
        icon:Show("PBL")
    end
end

-- Toggles the chat prefix.
function PBL:CommandChatFilter()
    self.db.profile.chatfilter.disabled = not self.db.profile.chatfilter.disabled
    if self.db.profile.chatfilter.disabled then
        PBL:Print(L["Chat filter disabled"])
    else
        PBL:Print(L["Chat filter enabled"])
    end
end

-- Toggles popup alerts.
function PBL:CommandAlerts()
    self.db.profile.ShowAlert["LeaveAlert"] = not self.db.profile.ShowAlert["LeaveAlert"]
    if self.db.profile.ShowAlert["LeaveAlert"] then
        PBL:Print(L["Alerts disabled"])
    else
        PBL:Print(L["Alerts enabled"])
    end
end

-- --------------------------------------------------------------------------
-- Utils - isbanned
-- --------------------------------------------------------------------------
-- Check if a given name exists in the blacklist.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - isBlacklisted()
-- --------------------------------------------------------------------------

function isbanned (tab, val)
    local index, value
    for index, value in ipairs(tab) do
        if value.name.."-"..value.realm == strupper(val) then
            return true, index
        end
    end
    return false, 0
end

-- --------------------------------------------------------------------------
-- Utils - has_value
-- --------------------------------------------------------------------------
-- Returns true if a value exists in a table.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - hasValue()
-- --------------------------------------------------------------------------

function has_value (tab, val)
    local index, value
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

-- --------------------------------------------------------------------------
-- Utils - getClassIdx
-- --------------------------------------------------------------------------
-- Returns the class index for storage and reference.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - hasValue()
--       Not necessary? Store global list instead or grab class from unitInfo
-- --------------------------------------------------------------------------

function getClassIdx(tab, val)
    local index, value
    for index, value in ipairs(tab) do
        if value == val then
          return index
        end
    end
    return 0
end

-- --------------------------------------------------------------------------
-- Utils - has_value
-- --------------------------------------------------------------------------
-- Custom string split.
-- TODO: Potentially move to Utils.lua
--       Not used anywhere in code. Remove?
-- --------------------------------------------------------------------------

function mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    local str
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

-- --------------------------------------------------------------------------
-- Utils - rmvfromlist
-- --------------------------------------------------------------------------
-- Removes a user from the blacklist.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - removeBlacklistEntry() or unblacklistPlayer()
-- --------------------------------------------------------------------------

function PBL:rmvfromlist(fullname, idx)
    table.remove(PBL.db.global.blackList, idx)
    PBL:Print("|cff008000"..fullname..L[" Removed from blacklist"])
end

-- --------------------------------------------------------------------------
-- Utils - addtolist
-- --------------------------------------------------------------------------
-- Adds a user to the blacklist.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - addBlacklistEntry() or blacklistPlayer()
-- --------------------------------------------------------------------------

function PBL:addtolist(name,realm,classFile,category,reason,note)
    local fullname = name.."-"..realm
    --local unitobjtoban = name.."$$"..realm.."$$"..classFile.."$$"..category.."$$"..reason..note
    local unitobjtoban = createBanItem(name,realm,classFile,category,reason,note)

    local banned, idx = isbanned(PBL.db.global.blackList, fullname)
    if banned then
      -- PBL:rmvfromlist(fullname, idx)
      -- table.insert(PBL.db.global.blackList, unitobjtoban)
      PBL.db.global.blackList[idx] = unitobjtoban
      PBL:Print("|cffff0000"..fullname..L["'s entry has been successfully edited!"])
    else
      table.insert(PBL.db.global.blackList, unitobjtoban)
      PBL:Print("|cffff0000"..fullname..L[" succesfully added to blacklist!"])
    end
end

-- --------------------------------------------------------------------------
-- Utils - clearlist
-- --------------------------------------------------------------------------
-- Completely wipes the blacklist.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - wipeBlacklist()
-- --------------------------------------------------------------------------

function PBL:clearlist()
    PBL.db.global.blackList = {}
end

-- --------------------------------------------------------------------------
-- Utils - blackListButton
-- --------------------------------------------------------------------------
-- Adds/removes a user from context menus.
-- TODO: Potentially move to Utils.lua
--       Rename to be more fitting - blacklistFromContext()
--       Refactor for optimization.
--           Potential for taint here - consider another way?
-- --------------------------------------------------------------------------

local TestDropdownMenuList = {"PLAYER","RAID_PLAYER","PARTY","FRIEND"}

for _, menuName in pairs(TestDropdownMenuList) do
    Menu.ModifyMenu("MENU_UNIT_"..menuName, function(ownerRegion, rootDescription, contextData)
        local name, server = contextData.name, contextData.server or GetRealmName()
        local selfname = UnitName("player")
        local selfrealm = GetRealmName()
        local guid = contextData.unit and UnitGUID(contextData.unit) or ""
        if contextData.which == "FRIEND" and name.."-"..server == selfname.."-"..selfrealm then
            return
        end
        local fullname = name.."-"..server
        local exist, i = isbanned(PBL.db.global.blackList, fullname)
        local text = exist and "|cff008000Remove from PBL" or "|cffff0000Add to PBL"
        rootDescription:CreateButton(text, function()
            local classFile = UnitClassBase(contextData.unit or fullname) or "UNSPECIFIED"
            local note = "Added from unitframe."
            if exist then
                PBL:rmvfromlist(fullname, i)
            else
                PBL:addtolist(name, server, L[classFile], 1, 1, guid..","..note)
            end
            PBL:refreshWidgetCore()
        end)
    end)
end

-- --------------------------------------------------------------------------
-- DEPRECATED: Unit Tooltips
-- --------------------------------------------------------------------------
-- Insert blacklist information into unit tooltips.
-- --------------------------------------------------------------------------
-- GameTooltip:HookScript("OnTooltipSetUnit", function(self)
--     local name, unit = self:GetUnit()
--     if UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and not UnitIsUnit(unit, "party") then
--         local name, realm = UnitName(unit)
--         if realm == nil then
--             realm=GetRealmName()
--             realm=realm:gsub(" ","");
--         end
--         fullname = name .. "-" .. realm;

--         local banned, idx = isbanned(PBL.db.global.blackList,fullname)
--         local p = PBL.db.global.blackList[idx]
--         if banned then
--             local banStr = PBL.db.profile.categories[tonumber(p.catIdx)] .. " (" .. PBL.db.profile.reasons[tonumber(p.reaIdx)] .. ")" .. " - " .. p.note
--             self:AddLine("Blacklisted (PBL): |cffFFFFFF" .. banStr .. "|r", 1, 0, 0, true)
--             self:AddLine(" ")
--             -- self:AddLine(PBL.db.global.blackList[idx].note, 1, 0, 0, true)
--         end
--     end
-- end)

-- --------------------------------------------------------------------------
-- Unit Tooltips
-- --------------------------------------------------------------------------
-- Insert blacklist information into unit tooltips.
-- TODO: Refactor significantly. This is a temporary implementation to match API changes from 10.0.2.
--       Will ned to use TooltipUtil.GetUnit and sub out titles and realm names from the unit name in the table.
-- --------------------------------------------------------------------------
local function OnTooltipSetUnit(tooltip, data)

    -- Temporary bandaid fix pending rewrite to be fully compatible with 10.0.2 tooltip changes.
    -- API changes mean that tooltip handlers now run on EVERY tooltip instead of native GameTooltips.
    if tooltip ~= GameTooltip then return end

    local name, unit = tooltip:GetUnit()
    if UnitIsPlayer(unit) and not UnitIsUnit(unit, "player") and not UnitIsUnit(unit, "party") then
        local name, realm = UnitName(unit)
        if realm == nil then
            realm=GetRealmName()
            realm=realm:gsub(" ","");
        end
        local fullname = name .. "-" .. realm;

        local banned, idx = isbanned(PBL.db.global.blackList,fullname)
        local p = PBL.db.global.blackList[idx]
        if banned then
            local banStr = PBL.db.profile.categories[tonumber(p.catIdx)] .. " (" .. PBL.db.profile.reasons[tonumber(p.reaIdx)] .. ")" .. " - " .. p.note
            tooltip:AddLine("Blacklisted (PBL): |cffFFFFFF" .. banStr .. "|r", 1, 0, 0, true)
            tooltip:AddLine(" ")
            -- self:AddLine(PBL.db.global.blackList[idx].note, 1, 0, 0, true)
        end
    end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnTooltipSetUnit)

-- --------------------------------------------------------------------------
-- LFG Tooltips
-- --------------------------------------------------------------------------
-- Returns true if a value exists in a table.
-- TODO: Completely broken due to 10.0.0/2 changes.
--       Find another workaround or fall back to chat notifications instead.
-- --------------------------------------------------------------------------

-- local hooked = { }

-- local function OnLeaveHook(self)
-- 		GameTooltip:Hide();
-- end

-- -- ADD BAN TO LFG
-- hooksecurefunc("LFGListApplicationViewer_UpdateResults", function(self)
--     local buttons = self.ScrollFrame.buttons
--     local i, j
-- 	for i = 1, #buttons do
-- 		local button = buttons[i]
-- 		if not hooked[button] then
-- 			if button.applicantID and button.Members then
-- 				for j = 1, #button.Members do
-- 					local b = button.Members[j]
-- 					if not hooked[b] then
-- 						hooked[b] = 1
-- 						b:HookScript("OnEnter", function()
-- 							local appID = button.applicantID;
-- 							local name = C_LFGList.GetApplicantMemberInfo(appID, 1);
-- 							if not string.match(name, "-") then
-- 								local realm = GetRealmName();
-- 								realm=realm:gsub(" ","");
-- 								fullname = name.."-"..realm;
-- 							end

--                             local banned, idx = isbanned(PBL.db.global.blackList, fullname)
--                             local p = PBL.db.global.blackList[idx]
-- 							if banned then
--                                 local banStr = PBL.db.profile.categories[tonumber(p.catIdx)] .. " (" .. PBL.db.profile.reasons[tonumber(p.reaIdx)] .. ")" .. " - " .. p.note
--                                 GameTooltip:AddLine("\nBlacklisted (PBL): |cffFFFFFF" .. banStr .. "|r", 1, 0, 0, true)
--                                 GameTooltip:AddLine(" ")
-- 								GameTooltip:Show();
-- 							end
-- 						end)
-- 						b:HookScript("OnLeave", OnLeaveHook)
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- end)

-- Pseudocode for Temp. Fix:
-- Hook into LFG_LIST_APPLICANT_LIST_UPDATED
-- If LFG_LIST_APPLICANT_LIST_UPDATED == true, true:
--     LFG_LIST_APPLICANT_UPDATED returns new applicantID
--     C_LFGList.GetApplicantInfo(applicantID) returns table {applicantID, pendingApplicationStatus, numMembers, isNew, ...}
--        isNew returns true if applicant has not applied to the group before.
--     C_LFGList.GetApplicants() returns a table of applicantID. Can get memberIndex from this.
--        Grab table. Get index where table[applicantID] = applicantID (from LFG_LIST_APPLICANT_UPDATED or GetApplicantInfo())
--     C_LFGList.GetApplicantMemberInfo(applicantID, memberIndex) returns table {name, class, ...}

-- --------------------------------------------------------------------------
-- Event Handler - Group Join/Leave
-- --------------------------------------------------------------------------
-- Handles checking for blacklist entries when users join a group.
-- TODO: Refactor for optimization.
--       Rename to be more fitting - OnGroupChange() or eh_GroupChange()
-- --------------------------------------------------------------------------

function PBL:gru_eventhandler()
    local aux = false
    local latestGroupMembers = GetNumGroupMembers()
    if self.db.profile.ShowAlert["count"] < latestGroupMembers then
        return
    elseif self.db.profile.ShowAlert["count"] > latestGroupMembers then
        self.db.profile.ShowAlert["count"] = latestGroupMembers
        local name, realm = "", "";
        self.db.profile.ShowAlert["onparty"] = {}
        for l=1, latestGroupMembers do
            if latestGroupMembers < 6 then
                name,realm = UnitName("party".. l)
            else
                name,realm = UnitName("raid".. l)
            end
            if name then
                if (not realm) or (realm == " ") or (realm == "") then realm = GetRealmName(); realm=realm:gsub(" ",""); end
                local fullname = name.."-"..realm
                if fullname ~= nil or fullname ~= "" then
                    local exist, i = isbanned(PBL.db.global.blackList, fullname)
                    if exist == true then
                        table.insert(self.db.profile.ShowAlert["onparty"], fullname)
                    end
                end
            end
        end


        return
    elseif self.db.profile.ShowAlert["count"] == latestGroupMembers then
        return
    end

    local pjs = {};
    local name, realm= "", "";
    local i
    for i=1, latestGroupMembers do
        if latestGroupMembers < 6 then
            name,realm = UnitName("party".. i)
        else
            name,realm = UnitName("raid".. i)
        end
        if name then
            if (not realm) or (realm == " ") or (realm == "") then realm = GetRealmName(); realm=realm:gsub(" ",""); end
            local fullname = name.."-"..realm
            if fullname ~= nil or fullname ~= "" then
                local exist, i = isbanned(PBL.db.global.blackList, fullname)
                local exist2, j = has_value(PBL.db.profile.ShowAlert["onparty"], fullname)
                if exist == true then
                    if exist2 == false then
                        PBL:Print("|cffff0000"..L["Here is"],fullname,L["who is in your BlackList"])
                        table.insert(self.db.profile.ShowAlert["onparty"], fullname)
                        aux = true
                    end
                    pjs[#pjs + 1] = fullname
                    self.db.profile.ShowAlert["count"] = latestGroupMembers
                end
            end
        end
    end

    if self.db.profile.ShowAlert["LeaveAlert"] == false and aux == true then
        if #pjs ~= 0 then
            local text = "";
            for j=1, #pjs do
                text = text..pjs[j].."\n"
            end
            if #pjs > 1 then
                text = text..L["confirmMultipleTxt"]
            else
                text = text..L["confirmSingleTxt"]
            end
            StaticPopup_Show("CONFIRM_LEAVE_IGNORE", text);
        end
    end
end

PBL:RegisterEvent("GROUP_ROSTER_UPDATE", "gru_eventhandler")

-- --------------------------------------------------------------------------
-- Chat Filter
-- --------------------------------------------------------------------------
-- Adds a prefix to messages from blacklisted users.
-- TODO: Potentially move to Modules.lua
--       Rename to be more fitting - chatPrefix()
-- --------------------------------------------------------------------------

local function myChatFilter(self, event, msg, author, ...)
    if PBL.db.profile.chatfilter.disabled then
        return false
    end
    local category = ""
    local exist, i = isbanned(PBL.db.global.blackList, author)
    if exist then
        local banObj = PBL.db.global.blackList[i]
        local categorystr = PBL.db.profile.categories[tonumber(banObj.catIdx)]
        local reasonstr = PBL.db.profile.reasons[tonumber(banObj.reaIdx)]
        if exist then
            --DEFAULT_CHAT_FRAME:AddMessage(tostring(categorystr))
            if banObj.catIdx ~= 1 then
                category=" w "..tostring(categorystr)
            end
            return false, "|cffff3030[PBL:"..tostring(reasonstr)..category.."]|cffff7f7f "..msg, author, ...
        end
    end
    return false
 end

 ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_SAY", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_RAID", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_PARTY", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_GUILD", myChatFilter)
 ChatFrame_AddMessageEventFilter("CHAT_MSG_INSTANCE", myChatFilter)
