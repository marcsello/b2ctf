-- Client-side overrides for the sandbox gamemode

local function preventWhenNotBuilding(...)
    if not (LocalPlayer() and IsValid(LocalPlayer())) then return end

    if not LocalPlayer():CurrentlyBuilding() then
        return false
    end
end

hook.Add("SpawnMenuOpen", "B2CTF_SpawnMenuCheck", preventWhenNotBuilding)
hook.Add("CanDrive", "B2CTF_DriveCheck", preventWhenNotBuilding)
hook.Add("CanTool", "B2CTF_ToolCheck", preventWhenNotBuilding)
hook.Add("CanProperty", "B2CTF_PropertyCheck", preventWhenNotBuilding)
hook.Add("CanArmDupe", "B2CTF_DupeCheck", preventWhenNotBuilding)

hook.Add( "PlayerBindPress", "B2CTF_CanUndo", function( ply, bind )
    if not (LocalPlayer() and IsValid(LocalPlayer())) then return end

    if ply == LocalPlayer() and bind == "gmod_undo" then
        if not ply:CurrentlyBuilding() then
            return true -- true to prevent
        end
    end
end )

hook.Add("B2CTF_PhaseChanged", "CloseSandboxMenus", function(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    if not newPhaseInfo.buildAllowed then
        -- hide menu spawn and context menu if building is not allowed in the new phase (context menu can be re-opened later but with limited functionality)
        g_ContextMenu:EndKeyFocus()
        g_ContextMenu:Close()

        g_SpawnMenu:EndKeyFocus()
        g_SpawnMenu:Close()

        -- The context menu can show the last tool used even without a toolgun, let's prevent it
        -- TODO: Use ContextMenuShowTool hook, when it becomes GA https://wiki.facepunch.com/gmod/SANDBOX:ContextMenuShowTool
        spawnmenu.SetActiveControlPanel(nil) -- this is internal, but seems working (sometimes crashes the game lol)

        -- if we could not remove the control panel for some reason, we could still try to hide it
        local panel = spawnmenu.ActiveControlPanel()
        if panel and IsValid(panel) then
            panel:SetVisible(false)
        end
        -- Sadly, this does not add back the tool menu to the context menu, when it is allowed to be used again... but whatever I don't care for now
    end
end)

include("sh_sandbox.lua")
