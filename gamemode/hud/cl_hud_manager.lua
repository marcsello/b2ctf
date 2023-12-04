local hudManager = {
    elements = {},
    initialized = false
}

function hudManager:RegisterElement(name, element)
    if self.initialized then error("HUD Manager already initialized") end
    self.elements[name] = element
end

function hudManager:Init()
    for _, element in pairs(self.elements) do
        if element["Init"] then
            -- call init when defined
            element:Init()
        end
    end

    self.initialized = true -- otherwise the following hacked OnPhaseChanged would do nothing...

    -- Hack: it is possible that a client might miss the initial phase transition because of how files loaded in order
    local currentPhaseInfo = Phaser:CurrentPhaseInfo()
    if currentPhaseInfo then
        self:OnPhaseChanged(Phaser:CurrentPhaseID(), currentPhaseInfo, nil, nil, Phaser:CurrentPhaseStart(), Phaser:CurrentPhaseEnd())
    end
end

function hudManager:Draw()
    if not self.initialized then return end
    for name, element in pairs(self.elements) do
        if hook.Run("HUDShouldDraw", GAMEMODE, name) then
            element:Draw()
        end
    end
end

function hudManager:OnPhaseChanged(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
    if not self.initialized then return end
    for _, element in pairs(self.elements) do
        if element["OnPhaseChanged"] then
            -- call OnPhaseChanged when defined
            element:OnPhaseChanged(newPhaseID, newPhaseInfo, oldPhaseID, oldPhaseInfo, startTime, endTime)
        end
    end
end

return hudManager
