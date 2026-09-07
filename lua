local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local VERCEL_URL = "https://roblox-dashboardd.vercel.app/api/update"

local function scanData()
    local incStr = "0/s"
    local petsFound = {}

    -- 1. Scan Income dari Layar UI
    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible and gui.Text:find("/s") then
            incStr = gui.Text
            break
        end
    end

    -- 2. Scan Pet dari Karakter Player / Backpack
    local char = LocalPlayer.Character
    if char then
        for _, obj in ipairs(char:GetChildren()) do
            if obj:IsA("Model") and not obj:FindFirstChildOfClass("Humanoid") then
                table.insert(petsFound, {
                    name = obj.Name,
                    income = incStr
                })
            end
        end
    end

    -- Fallback jika pet tidak berbentuk 3D Model di Karakter
    if #petsFound == 0 then
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if gui:IsA("ImageLabel") or gui:IsA("TextLabel") then
                if gui.Name:lower():find("pet") or (gui.Parent and gui.Parent.Name:lower():find("pet")) then
                    if gui:IsA("TextLabel") and gui.Text ~= "" and not gui.Text:find("/s") then
                        table.insert(petsFound, { name = gui.Text, income = incStr })
                        break
                    end
                end
            end
        end
    end

    local ws = 16
    if char and char:FindFirstChild("Humanoid") then
        ws = math.floor(char.Humanoid.WalkSpeed + 0.5)
    end

    return incStr, ws, petsFound
end

local function sendData()
    local inc, ws, pets = scanData()
    
    local payload = {
        username = LocalPlayer.Name,
        userId = tostring(LocalPlayer.UserId),
        income = inc,
        walkSpeed = ws,
        pets = pets
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

sendData()
task.spawn(function()
    while true do
        task.wait(3)
        sendData()
    end
end)
