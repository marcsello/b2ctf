-- Draw boundaries in the 3D world
local function DrawHomeBoundaries()

    if (not IsValid(LocalPlayer())) or (not LocalPlayer():TeamValid()) then return end

    local t = B2CTF_MAP.teams[LocalPlayer():Team()]
    if t == nil then return end

    local cubeMin = t.boundaries[1]
    local cubeMax = t.boundaries[2]

    -- TODO: pre-calculate and store lines in an array and render the array
    render.DrawLine(Vector(cubeMin.x, cubeMin.y, cubeMin.z), Vector(cubeMax.x, cubeMin.y, cubeMin.z), t.color, true) -- Draw the bottom face
    render.DrawLine(Vector(cubeMin.x, cubeMin.y, cubeMin.z), Vector(cubeMin.x, cubeMax.y, cubeMin.z), t.color, true)
    render.DrawLine(Vector(cubeMax.x, cubeMin.y, cubeMin.z), Vector(cubeMax.x, cubeMax.y, cubeMin.z), t.color, true)
    render.DrawLine(Vector(cubeMin.x, cubeMax.y, cubeMin.z), Vector(cubeMax.x, cubeMax.y, cubeMin.z), t.color, true)

    render.DrawLine(Vector(cubeMin.x, cubeMin.y, cubeMax.z), Vector(cubeMax.x, cubeMin.y, cubeMax.z), t.color, true) -- Draw the top face
    render.DrawLine(Vector(cubeMin.x, cubeMin.y, cubeMax.z), Vector(cubeMin.x, cubeMax.y, cubeMax.z), t.color, true)
    render.DrawLine(Vector(cubeMax.x, cubeMin.y, cubeMax.z), Vector(cubeMax.x, cubeMax.y, cubeMax.z), t.color, true)
    render.DrawLine(Vector(cubeMin.x, cubeMax.y, cubeMax.z), Vector(cubeMax.x, cubeMax.y, cubeMax.z), t.color, true)

    render.DrawLine(Vector(cubeMin.x, cubeMin.y, cubeMin.z), Vector(cubeMin.x, cubeMin.y, cubeMax.z), t.color, true) -- Connect the corners
    render.DrawLine(Vector(cubeMax.x, cubeMin.y, cubeMin.z), Vector(cubeMax.x, cubeMin.y, cubeMax.z), t.color, true)
    render.DrawLine(Vector(cubeMin.x, cubeMax.y, cubeMin.z), Vector(cubeMin.x, cubeMax.y, cubeMax.z), t.color, true)
    render.DrawLine(Vector(cubeMax.x, cubeMax.y, cubeMin.z), Vector(cubeMax.x, cubeMax.y, cubeMax.z), t.color, true)
end

hook.Add("PostDrawOpaqueRenderables", "B2CTF_DrawHomeBoundaries", DrawHomeBoundaries)
