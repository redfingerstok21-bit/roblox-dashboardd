local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local VERCEL_URL = "https://roblox-dashboardd.vercel.app/api/update"

local function getStats()
    local incStr = "0/s"
    
    -- Fast scan text UI
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Text:find("/s") then
            incStr = gui.Text
            break
        end
    end

    local ws = 16
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        ws = math.floor(LocalPlayer.Character.Humanoid.WalkSpeed)
    end

    return incStr, ws
end

local function send()
    local inc, ws = getStats()
    
    local payload = {
        username = LocalPlayer.Name,
        userId = tostring(LocalPlayer.UserId),
        income = inc,
        walkSpeed = ws,
        pets = {}
    }

    local req = (syn and syn.request) or (http and http.request) or request or http_request
    if req then
        req({
            Url = VERCEL_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = game:GetService("HttpService"):JSONEncode(payload)
        })
    end
end

send()
task.spawn(function()
    while true do
        task.wait(3)
        send()
    end
end)
