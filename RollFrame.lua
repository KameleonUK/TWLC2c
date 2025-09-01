local addonVer = "1.0.3.2"
local me = UnitName('player')

function rfprint(a)
    DEFAULT_CHAT_FRAME:AddMessage("|cff69ccf0[TWLC2c] |cffffffff" .. a)
end

function rfdebug(a)
    if (me == 'Xerrbear' or me == 'Kzktst' or me == 'Heallios') then
        rfprint('|cff0070de[Rollframe :' .. time() .. '] |cffffffff[' .. a .. ']')
    end
end

local RollFrame = CreateFrame("Frame")

RollFrame.watchRolls = false
RollFrame.rolls = {}

RollFrame:RegisterEvent("ADDON_LOADED")
RollFrame:RegisterEvent("CHAT_MSG_SYSTEM")
--RollFrame:RegisterEvent("START_LOOT_ROLL")

RollFrame:SetScript("OnEvent", function()
    if (event) then
        if (event == "ADDON_LOADED" and arg1 == 'TWLC2c') then
            RollFrame:HideAnchor()
            if TWLC_ROLL_ENABLE_SOUND == nil then
                TWLC_ROLL_ENABLE_SOUND = true
            end
            if not TWLC_ROLL_VOLUME then
                TWLC_ROLL_VOLUME = 'high'
            end
            rfprint('TWLC2c RollFrame (v' .. addonVer .. ') Loaded. Type |cfffff569/tw|cff69ccf0roll |cffffffffto show the Anchor window.')

            if TWLC_ROLL_ENABLE_SOUND then
                rfprint('Roll Sound is Enabled(' .. TWLC_ROLL_VOLUME .. '). Type |cfffff569/tw|cff69ccf0roll|cfffff569sound |cffffffffto toggle win sound on or off.')
            else
                rfprint('Roll Sound is Disabled. Type |cfffff569/tw|cff69ccf0roll|cfffff569sound |cffffffffto toggle win sound on or off.')
            end

            if TWLC_TROMBONE == nil then
                TWLC_TROMBONE = true
            end

            if TWLC_TROMBONE then
                wfprint('Sad Trombone Sound is Enabled. Type |cfffff569/tw|cff69ccf0trombone |cffffffffto toggle sad trombone sound on or off.')
            else
                wfprint('Sad Trombone Sound is Disabled. Type |cfffff569/tw|cff69ccf0trombone |cffffffffto toggle sad trombone sound on or off.')
            end

            RollFrame.ResetVars()
        end
        if (event == "CHAT_MSG_SYSTEM" and RollFrame.watchRolls) then
            if ((string.find(arg1, "rolls", 1, true) or string.find(arg1, "würfelt. Ergebnis", 1, true)) and string.find(arg1, "(1-100)", 1, true)) then
                --vote tie rolls
                --en--Er rolls 47 (1-100)
                --de--Er würfelt. Ergebnis: 47 (1-100)
                local r = string.split(arg1, " ")

                if not r[2] or not r[3] then
                    return false
                end

                local name = r[1]
                local roll = tonumber(r[3])

                if string.find(arg1, "würfelt. Ergebnis", 1, true) then
                    if not r[4] then
                        return false
                    end
                    roll = tonumber(r[4])
                end

                RollFrame.rolls[name] = roll
                --                rfprint('recorded roll '..name..' ' .. roll)
            end

        end
  --      if (event == "START_LOOT_ROLL") then
            --arg1, arg2
  --          rfprint("Roll event fired - letting hijacked function take over")
            --RollFrame.GroupLootFrameAddItem(arg1, arg2)
    --    end
    end
end)

local RollFrameComms = CreateFrame("Frame")
RollFrameComms:RegisterEvent("CHAT_MSG_ADDON")

local RollFrameCountdown = CreateFrame("Frame")

RollFrameCountdown:Hide()
RollFrameCountdown.timeToRoll = 30 --default, will be gotten via addonMessage

RollFrameCountdown.T = 1
RollFrameCountdown.C = RollFrameCountdown.timeToRoll

local RollFrames = CreateFrame("Frame")
RollFrames.itemFrames = {}
RollFrames.execs = 0
RollFrames.itemQuality = {}

local fadeInAnimationFrameRF = CreateFrame("Frame")
fadeInAnimationFrameRF:Hide()
fadeInAnimationFrameRF.ids = {}
fadeInAnimationFrameRF.frameIndex = {}

local fadeOutAnimationFrameRF = CreateFrame("Frame")
fadeOutAnimationFrameRF:Hide()
fadeOutAnimationFrameRF.ids = {}

local delayAddItem = CreateFrame("Frame")
delayAddItem:Hide()
delayAddItem.data = {}

delayAddItem:SetScript("OnShow", function()
    this.startTime = GetTime();
end)
delayAddItem:SetScript("OnUpdate", function()
    local plus = 1
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then

        local atLeastOne = false
        for id, data in next, delayAddItem.data do
            if delayAddItem.data[id] then
                atLeastOne = true
                RollFrames.addRolledItem(data)
                delayAddItem.data[id] = nil
            end
        end

        if not atLeastOne then
            delayAddItem:Hide()
        end
    end
end)

RollFrameCountdown:SetScript("OnShow", function()
    this.startTime = GetTime();
end)

RollFrameCountdown:SetScript("OnUpdate", function()
    local plus = 0.03
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000

    if gt >= st then
        if (RollFrameCountdown.T ~= RollFrameCountdown.timeToRoll + plus) then

            for index in next, RollFrames.itemFrames do
                if (math.floor(RollFrameCountdown.C - RollFrameCountdown.T + plus) < 0) then
                    getglobal('RollFrame' .. index .. 'TimeLeftBarText'):SetText("CLOSED")
                else
                    getglobal('RollFrame' .. index .. 'TimeLeftBarText'):SetText(math.ceil(RollFrameCountdown.C - RollFrameCountdown.T + plus) .. "s")
                end

                getglobal('RollFrame' .. index .. 'TimeLeftBar'):SetWidth((RollFrameCountdown.C - RollFrameCountdown.T + plus) * 190 / RollFrameCountdown.timeToRoll)
            end
        end
        RollFrameCountdown:Hide()
        if (RollFrameCountdown.T < RollFrameCountdown.C + plus) then
            --still tick
            RollFrameCountdown.T = RollFrameCountdown.T + plus
            RollFrameCountdown:Show()
        elseif (RollFrameCountdown.T > RollFrameCountdown.timeToRoll + plus) then

            -- hide frames and send auto pass
            for index in next, RollFrames.itemFrames do
                if (RollFrames.itemFrames[index]:IsVisible()) then
                    PlayerRollItemButton_OnClick(this:GetID(), 'roll');
                end
            end
            -- end hide frames

            RollFrameCountdown:Hide()
            RollFrameCountdown.T = 1

        else
            --
        end
    else
        --
    end
end)

RollFrames.freeSpots = {}

function RollFrames.addRolledItem(data)

    --rfprint('add: ' .. data)

    local item = string.split(data, "=")

    RollFrameCountdown.timeToRoll = tonumber(item[6])
    RollFrameCountdown.C = RollFrameCountdown.timeToRoll

    RollFrames.execs = RollFrames.execs + 1

    local index = tonumber(item[2])
    local texture = item[3]
    local name = item[4]
    local link = item[5]
    local game = item[8] == 'game'

    local _, _, itemLink = string.find(link, "(item:%d+:%d+:%d+:%d+)");

    if not game then
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
    end

    local quality, count, bindOnPickUp

    if game then
        texture, name, count, quality, bindOnPickUp = GetLootRollItemInfo(index);
        link = name
    else
        name, _, quality, _, _, _, _, _, texture = GetItemInfo(itemLink)
    end

    -- dev
    if not name then
        name = 'test'
        quality = 2
        texture = 'test'
    end

    local r, g, b, hex = GetItemQualityColor(quality)

    link = hex .. name

    if (not name or not quality) then
        delayAddItem.data[index] = data
        delayAddItem:Show()
        return false
    end

    RollFrames.itemQuality[index] = quality
    RollFrames.execs = 0

    if RollFrames.itemFrames[index] then
        if RollFrames.itemFrames[index]:IsVisible() then
            RollFrames.itemFrames[index]:Hide()
            RollFrames.addRolledItem(data)
            return false
        end
    else
        RollFrames.itemFrames[index] = CreateFrame("Frame", "RollFrame" .. index, getglobal("RollFrame"), "RollFrameItemTemplate")
    end

    RollFrames.itemFrames[index].game = game
    RollFrames.itemFrames[index].rollID = index

    RollFrames.itemFrames[index]:Show()
    RollFrames.itemFrames[index]:SetAlpha(0)

    RollFrames.itemFrames[index]:ClearAllPoints()

    local freeGroupLootFrame = RollFrame.GroupLootFrameFreeFrame()

    RollFrame.gropLootFrames[freeGroupLootFrame].busy = true
    RollFrame.gropLootFrames[freeGroupLootFrame].rollID = index

    if index == 0 then
        --test button
        RollFrames.itemFrames[index]:SetPoint("TOP", getglobal("RollFrame"), "TOP", 0, 40 + (90 * 1))
    else
        if game then
            RollFrames.itemFrames[index]:SetPoint("TOP", getglobal("RollFrame"), "TOP", 0, 40 + (90 * freeGroupLootFrame))
        else
            RollFrames.itemFrames[index]:SetPoint("TOP", getglobal("RollFrame"), "TOP", 0, 40 + (90 * firstFree(index)))
        end

    end
    RollFrames.itemFrames[index].link = link -- index 

    getglobal('RollFrame' .. index .. 'ItemIcon'):SetNormalTexture(texture);
    getglobal('RollFrame' .. index .. 'ItemIcon'):SetPushedTexture(texture);
    getglobal('RollFrame' .. index .. 'ItemIconItemName'):SetText(link);

    getglobal('RollFrame' .. index .. 'Roll'):SetID(index);

    getglobal('RollFrame' .. index .. 'Greed'):Hide();
    if game then
        getglobal('RollFrame' .. index .. 'Greed'):SetID(index);
        getglobal('RollFrame' .. index .. 'Greed'):Show();
    end
    getglobal('RollFrame' .. index .. 'Pass'):SetID(index);


    getglobal('RollFrame' .. index .. 'TimeLeftBar'):SetBackdropColor(r, g, b, .76)

    addOnEnterTooltipRollFrame(getglobal('RollFrame' .. index .. 'ItemIcon'), link, game, index)

    FadeInFrameRF(index)
end

function PlayerRollItemButton_OnClick(id, roll)

    --rfprint('PlayerRollItemButton_OnClick id = ' .. id) -- COMMENT THIS OUT WHEN FIRST NEED ROLL BUG IS RESOLVED - HEALLIOS

    for i = 1, table.getn(RollFrames.freeSpots) do
        if RollFrames.freeSpots[i] == id then
            RollFrames.freeSpots[i] = 0
            break
        end
    end

   -- if (id == 0) then -- COMMENTED OUT AS THIS STOPS THE FIRST ITEM ROLL IN A NEW CLIENT SESSION FROM APPEARING
    --    fadeOutFrameRF(id)
   --     return
   -- end

    if RollFrames.itemFrames[id].game then
        if roll == 'roll' then
            RollOnLoot(RollFrames.itemFrames[id].rollID, 1);
        end
        if roll == 'greed' then
            RollOnLoot(RollFrames.itemFrames[id].rollID, 2);
        end
        if roll == 'pass' then
            RollOnLoot(RollFrames.itemFrames[id].rollID, 0);
        end
    else
        if (roll == 'pass') then
            SendAddonMessage("TWLCNF", "rollChoice=" .. id .. "=-1", "RAID")
        end

        if (roll == 'roll') then
            --        SendAddonMessage("TWLCNF", "rollChoice=" .. id, "RAID")
            RandomRoll(1, 100)
        end
    end

    fadeOutFrameRF(id)
end

function FadeInFrameRF(id)
    if TWLC_ROLL_ENABLE_SOUND then
        PlaySoundFile("Interface\\AddOns\\TWLC2c\\sound\\please_roll_" .. TWLC_ROLL_VOLUME .. ".ogg");
    end
    fadeInAnimationFrameRF.ids[id] = true
    fadeInAnimationFrameRF.frameIndex[id] = 0
    fadeInAnimationFrameRF:Show()
end

function fadeOutFrameRF(id)
    fadeOutAnimationFrameRF.ids[id] = true
    fadeOutAnimationFrameRF:Show()

    for i = 1, 10 do
        if RollFrame.gropLootFrames[i].busy and RollFrame.gropLootFrames[i].rollID == id then
            RollFrame.gropLootFrames[i].busy = false
            RollFrame.gropLootFrames[i].rollID = 0
            break
        end
    end

end

fadeInAnimationFrameRF:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

fadeOutAnimationFrameRF:SetScript("OnShow", function()
    this.startTime = GetTime()
end)

fadeInAnimationFrameRF:SetScript("OnUpdate", function()
    if ((GetTime()) >= (this.startTime) + 0.03) then

        this.startTime = GetTime()

        local atLeastOne = false
        for id in next, fadeInAnimationFrameRF.ids do
            if fadeInAnimationFrameRF.ids[id] then
                atLeastOne = true
                local frame = getglobal("RollFrame" .. id)

                local frameNr = fadeInAnimationFrameRF.frameIndex[id]
                if (fadeInAnimationFrameRF.frameIndex[id] < 10) then
                    frameNr = '0' .. fadeInAnimationFrameRF.frameIndex[id]
                end

                if fadeInAnimationFrameRF.frameIndex[id] > 30 then
                    frameNr = 30
                end

                local q = RollFrames.itemQuality[id] < 3 and 3 or RollFrames.itemQuality[id]

                frame:SetBackdrop({
                    bgFile = "Interface\\addons\\TWLC2c\\images\\roll\\roll_frame_" .. q .. "_" .. frameNr,
                    tile = false,
                })

                --fadein
                if fadeInAnimationFrameRF.frameIndex[id] >= 0 and fadeInAnimationFrameRF.frameIndex[id] <= 5 then
                    frame:SetAlpha(fadeInAnimationFrameRF.frameIndex[id] * 0.2)
                end

                --fadeout
                if fadeInAnimationFrameRF.frameIndex[id] >= (RollFrameCountdown.timeToRoll - 1) * 30 and fadeInAnimationFrameRF.frameIndex[id] <= RollFrameCountdown.timeToRoll * 30 then
                    frame:SetAlpha(frame:GetAlpha() - 0.2)
                end

                if (fadeInAnimationFrameRF.frameIndex[id] < RollFrameCountdown.timeToRoll * 30) then
                    getglobal('RollFrame' .. id .. 'TimeLeftBarText'):SetText(math.ceil(RollFrameCountdown.timeToRoll - fadeInAnimationFrameRF.frameIndex[id] / 30) - 1 .. "s")
                    getglobal('RollFrame' .. id .. 'TimeLeftBar'):SetWidth(math.ceil(RollFrameCountdown.timeToRoll - fadeInAnimationFrameRF.frameIndex[id] / 30 - 1) * 190 / RollFrameCountdown.timeToRoll)
                    fadeInAnimationFrameRF.frameIndex[id] = fadeInAnimationFrameRF.frameIndex[id] + 1
                else
                    if frame:IsVisible() then
                        rfdebug('auto roll because it ended')
                        PlayerRollItemButton_OnClick(id, 'roll');
                    else
                        rfdebug('timer ended and frame is invisible, should not roll')
                    end
                    fadeInAnimationFrameRF.ids[id] = false
                    fadeInAnimationFrameRF.ids[id] = nil

                    if RollFrame.watchRolls == true then
                        --and enabled global var

                        local maxRoll = 0
                        for name, roll in next, RollFrame.rolls do
                            if maxRoll < roll then
                                maxRoll = roll
                            end
                        end

                        rfdebug(' maxroll = ' .. maxRoll)

                        if RollFrame.rolls[me] ~= maxRoll and TWLC_TROMBONE then
                            PlaySoundFile("Interface\\AddOns\\TWLC2c\\sound\\sadtrombone.ogg")
                            RollFrame.watchRolls = false
                        end

                    end

                end
                --                return
            end
        end
        if (not atLeastOne) then
            fadeInAnimationFrameRF:Hide()
        end
    end
end)

fadeOutAnimationFrameRF:SetScript("OnUpdate", function()
    if ((GetTime()) >= (this.startTime) + 0.03) then

        this.startTime = GetTime()

        local atLeastOne = false
        for id in next, fadeOutAnimationFrameRF.ids do
            if fadeOutAnimationFrameRF.ids[id] then
                atLeastOne = true
                local frame = getglobal("RollFrame" .. id)
                if (frame:GetAlpha() > 0) then
                    frame:SetAlpha(frame:GetAlpha() - 0.15)
                else
                    fadeOutAnimationFrameRF.ids[id] = false
                    fadeOutAnimationFrameRF.ids[id] = nil
                    frame:Hide()
                end
            end
        end
        if (not atLeastOne) then
            fadeOutAnimationFrameRF:Hide()
        end
    end
end)

function RollFrame.ResetVars()

    for index, frame in next, RollFrames.itemFrames do
        RollFrames.itemFrames[index]:Hide()
    end

    RollFrames.freeSpots = {}

    getglobal('RollFrame'):Hide()

    RollFrameCountdown:Hide()
    RollFrameCountdown.T = 1

    fadeInAnimationFrameRF:Hide()

    fadeInAnimationFrameRF.ids = {}
    RollFrames.itemQuality = {}

    RollFrame.watchRolls = false
    RollFrame.rolls = {}
end

RollFrameComms:SetScript("OnEvent", function()
    --TWLCNF
    if (event) then
        if (event == 'CHAT_MSG_ADDON' and arg1 == 'TWLCNF') then

            if (RollFrame:twlc2isRL(arg4)) then

                if (string.find(arg2, 'rollFor=', 1, true)) then

                    -- 'rollFor=' .. itemindex.. '=' .. tex .. '=' .. iname .. '=' .. link .. '=' .. TIME_TO_ROLL .. '=' .. me?'
                    local rfEx = string.split(arg2, '=')
                    if rfEx[7] then
                        if rfEx[7] == me then
                            RollFrames.addRolledItem(arg2)
                            if (not getglobal('RollFrame'):IsVisible()) then
                                getglobal('RollFrame'):Show()
                            end
                            RollFrame.watchRolls = true
                        end
                    end
                end

                if (string.find(arg2, 'rollframe=', 1, true)) then
                    local command = string.split(arg2, '=')
                    if (command[2] == "reset") then
                        RollFrame.ResetVars()
                    end
                end
            end
        end
    end
end)

function RFIT_DragStart()
    getglobal('RollFrame'):StartMoving();
    getglobal('RollFrame').isMoving = true;
end

function RFIT_DragEnd()
    getglobal('RollFrame'):StopMovingOrSizing();
    getglobal('RollFrame').isMoving = false;
end

function RollFrame:ShowAnchor()
    getglobal('RollFrame'):SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        tile = true,
    })
    getglobal('RollFrame'):Show()
    getglobal('RollFrame'):EnableMouse(true)
    getglobal('RollFrameTitle'):Show()
    getglobal('RollFrameTestPlacement'):Show()
    getglobal('RollFrameClosePlacement'):Show()
end

function RollFrame:HideAnchor()
    getglobal('RollFrame'):SetBackdrop({
        bgFile = "",
        tile = true,
    })
    getglobal('RollFrame'):Hide()
    getglobal('RollFrame'):EnableMouse(false)
    getglobal('RollFrameTitle'):Hide()
    getglobal('RollFrameTestPlacement'):Hide()
    getglobal('RollFrameClosePlacement'):Hide()
end

function roll_frame_close()
    rfprint('Anchor window closed. Type |cfffff569/tw|cff69ccf0roll |cffffffffto show the Anchor window.')
    RollFrame:HideAnchor()
end

function roll_frame_test()

    --    local linkString = '|cffff8000|Hitem:19364:0:0:0:::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r'
    local linkString = '|cffa335ee|Hitem:19364:0:0:0:0:0:0:0:0|h[Ashkandi, Greatsword of the Brotherhood]|h|r'
    local _, _, itemLink = string.find(linkString, "(item:%d+:%d+:%d+:%d+)");
    local name, il, quality, _, _, _, _, _, tex = GetItemInfo(itemLink)

    if (name and tex) then
        RollFrames.addRolledItem('rollFor=0=' .. tex .. '=' .. name .. '=' .. linkString .. '=30=' .. me)
        if (not getglobal('RollFrame'):IsVisible()) then
            getglobal('RollFrame'):Show()
        end
    else
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
    end
end

function roll_frame_test2()

    --    local linkString = '|cffff8000|Hitem:19364:0:0:0:::::|h[Thunderfury, Blessed Blade of the Windseeker]|h|r'
    local linkString = '|cffa335ee|Hitem:1717:0:0:0:0:0:0:0:0|h[Ashkandi, Greatsword of the Brotherhood]|h|r'
    local _, _, itemLink = string.find(linkString, "(item:%d+:%d+:%d+:%d+)");
    local name, il, quality, _, _, _, _, _, tex = GetItemInfo(itemLink)

    if (name and tex) then
        RollFrames.addRolledItem('rollFor=0=' .. tex .. '=' .. name .. '=' .. linkString .. '=30=' .. me)
        if (not getglobal('RollFrame'):IsVisible()) then
            getglobal('RollFrame'):Show()
        end
    else
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
    end
end

SLASH_TWTROMBONE1 = "/twtrombone"
SlashCmdList["TWTROMBONE"] = function(cmd)
    if cmd then
        TWLC_TROMBONE = not TWLC_TROMBONE
        if TWLC_TROMBONE then
            wfprint('Sad Trombone Sound is Enabled. Type |cfffff569/tw|cff69ccf0trombone |cffffffffto toggle sad trombone sound on or off.')
        else
            wfprint('Sad Trombone Sound is Disabled. Type |cfffff569/tw|cff69ccf0trombone |cffffffffto toggle sad trombone sound on or off.')
        end
    end
end

SLASH_TWROLL1 = "/twroll"
SlashCmdList["TWROLL"] = function(cmd)
    if cmd then
        RollFrame:ShowAnchor()
    end
end

SLASH_TWROLLSOUND1 = "/twrollsound"
SlashCmdList["TWROLLSOUND"] = function(cmd)
    if cmd then
        if cmd == 'high' or cmd == 'low' then
            TWLC_ROLL_VOLUME = cmd
            wfprint('Roll Sound Volume set to |cfffff569' .. TWLC_ROLL_VOLUME)
            return true
        end
        TWLC_ROLL_ENABLE_SOUND = not TWLC_ROLL_ENABLE_SOUND
        if TWLC_ROLL_ENABLE_SOUND then
            rfprint('Roll Sound Enabled')
        else
            rfprint('Roll Sound Disabled')
        end
    end
end

-- utils

function RollFrame:twlc2isRL(name)
    for i = 0, GetNumRaidMembers() do
        if (GetRaidRosterInfo(i)) then
            local n, r = GetRaidRosterInfo(i);
            if (n == name and r == 2) then
                return true
            end
        end
    end
    return false
end

function tablen(t)
    local count = 0
    for i in next, RollFrames.itemFrames do
        count = count + 1
    end
    return count
end

function firstFree(index)
    for i = 1, table.getn(RollFrames.freeSpots) do
        if RollFrames.freeSpots[i] == 0 then
            return i
        end
    end

    RollFrames.freeSpots[table.getn(RollFrames.freeSpots) + 1] = index
    return table.getn(RollFrames.freeSpots)
end

function addOnEnterTooltipRollFrame(frame, itemLink, game, index)
    local ex = string.split(itemLink, "|")

    if game then
        frame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
            GameTooltip:SetLootRollItem(index);
            CursorUpdate();
        end)
        frame:SetScript("OnClick", function(self)
            if ( IsControlKeyDown() ) then
                DressUpItemLink(GetLootRollItemLink(index));
            elseif ( IsShiftKeyDown() ) then
                if ( ChatFrameEditBox:IsVisible() ) then
                    ChatFrameEditBox:Insert(GetLootRollItemLink(index));
                end
            end
        end)
        frame:SetScript("OnLeave", function(self)
            GameTooltip:Hide();
            ResetCursor();
        end)

        return
    end

    if (not ex[3]) then
        return
    end

    frame:SetScript("OnEnter", function(self)
        RollFrameTooltip:SetOwner(this, "ANCHOR_RIGHT", 0, 0);
        RollFrameTooltip:SetHyperlink(string.sub(ex[3], 2, string.len(ex[3])));
        RollFrameTooltip:Show();
    end)
    frame:SetScript("OnLeave", function(self)
        RollFrameTooltip:Hide();
    end)
end

RollFrame.i = 1

function rftest()
    RollFrame.GroupLootFrameAddItem(RollFrame.i, 30)
    RollFrame.i = RollFrame.i + 1
end

RollFrame.gropLootFrames = {}
for i = 1, 10 do
    RollFrame.gropLootFrames[i] = {
        busy = false,
        rollID = 0
    }
end

function RollFrame.GroupLootFrameFreeFrame()
    for i= 1, 10 do
        if not RollFrame.gropLootFrames[i].busy then
            return i
        end
    end
    return 10
end
function GroupLootFrame_OpenNewFrame(id, rollTime)
    rollTime = tonumber(rollTime) / 1000
    local texture, name, count, quality, bindOnPickUp = GetLootRollItemInfo(id);
    -- dev
    if not name then
        name = 'test'
        texture = 'test'
        quality = 1
    end
    local linkString = '';

    if name and texture then
        RollFrames.addRolledItem('rollFor=' .. id.. '=' .. texture .. '=' .. name .. '=' .. linkString .. '=' .. rollTime .. '=' .. UnitName('player') .. '=game')
        if (not getglobal('RollFrame'):IsVisible()) then
            getglobal('RollFrame'):Show()
        end
    else
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
    end
end


function RollFrame.GroupLootFrameAddItem(index, rollTime)
    -- NO LONGER USED, OG FUNCTION HIJACKED ABOVE.
    rfprint("TWLC Roll Frame Function")
    
    rollTime = tonumber(rollTime) / 1000

    local texture, name, count, quality, bindOnPickUp = GetLootRollItemInfo(index);

    -- dev
    if not name then
        name = 'test'
        texture = 'test'
        quality = 1
    end

    --rfprint(index)
    --rfprint(name)
    --rfprint('q: ' .. quality)

    local linkString = '';

    if name and texture then
        RollFrames.addRolledItem('rollFor=' .. index .. '=' .. texture .. '=' .. name .. '=' .. linkString .. '=' .. rollTime .. '=' .. UnitName('player') .. '=game')
        if (not getglobal('RollFrame'):IsVisible()) then
            getglobal('RollFrame'):Show()
        end
    else
        GameTooltip:SetHyperlink(itemLink)
        GameTooltip:Hide()
    end

end