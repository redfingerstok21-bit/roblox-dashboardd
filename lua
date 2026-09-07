local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Workspace = game:GetService("Workspace")

local VERCEL_URL = "https://roblox-dashboardd.vercel.app/api/update"

-- Format Angka (K, M, B, T)
local function formatNumber(n)
    if not n or type(n) ~= "number" then return "0" end
    if n >= 1e12 then return string.format("%.1fT", n / 1e12)
    elseif n >= 1e9 then return string.format("%.1fB", n / 1e9)
    elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
    else return tostring(math.floor(n)) end
end

-- Convert Teks Layar ke Angka Raw
local function parseIncome(str)
    if not str then return 0 end
    local num = str:gsub("[%$,/s]", ""):match("^%s*(.-)%s*$")
    local mult = 1
    if num:lower():find("t") then mult = 1e12 num = num:lower():gsub("t","")
    elseif num:lower():find("b") then mult = 1e9 num = num:lower():gsub("b","")
    elseif num:lower():find("m") then mult = 1e6 num = num:lower():gsub("m","")
    elseif num:lower():find("k") then mult = 1e3 num = num:lower():gsub("k","")
    end
    return (tonumber(num) or 0) * mult
end

-- Scan Otomatis Income dan Pet
local function scanStatsAndPets()
    local incomeRaw = 0
    local equippedPets = {}

    -- 1. Cek Folder Data
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("Data")
    if leaderstats then
        for _, v in ipairs(leaderstats:GetChildren()) do
            local name = v.Name:lower()
            if name:find("income") or name:find("sec") or name:find("multiplier") then
                incomeRaw = tonumber(v.Value) or incomeRaw
            end
        end
    end

    if incomeRaw == 0 then
        incomeRaw = LocalPlayer:GetAttribute("Income") or LocalPlayer:GetAttribute("IncomePerSec") or 0
    end

    -- 2. Cek Plot Pemain di Map
    local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player")
            if owner and (owner.Value == LocalPlayer or owner.Value == LocalPlayer.Name) then
                local petFolder = plot:FindFirstChild("Pets") or plot:FindFirstChild("EquippedPets")
                if petFolder then
                    for _, pet in ipairs(petFolder:GetChildren()) do
                        local pInc = 0
                        local incVal = pet:FindFirstChild("Income") or pet:FindFirstChild("Multiplier")
                        if incVal then pInc = tonumber(incVal.Value) or 0 end

                        table.insert(equippedPets, {
                            name = pet.Name,
                            incomeRaw = pInc,
                            income = formatNumber(pInc) .. "/s"
                        })
                    end
                end
            end
        end
    end

    -- 3. Cek UI Layar (Fallback)
    if incomeRaw == 0 then
        for _, gui in ipairs(PlayerGui:GetDescendants()) do
            if gui:IsA("TextLabel") and gui.Visible then
                local txt = gui.Text
                if txt:find("/s") or gui.Name:lower():find("income") then
                    local val = parseIncome(txt)
                    if val > incomeRaw then incomeRaw = val end
                end
            end
        end
    end

    return incomeRaw, equippedPets
end

-- Kirim Data Tanpa Parameter Money
local function sendData()
    local incomeVal, petsList = scanStatsAndPets()

    local walkSpeed = 16
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        walkSpeed = math.floor(LocalPlayer.Character.Humanoid.WalkSpeed + 0.5)
    end

    local incomeFormatted = (incomeVal > 0) and (formatNumber(incomeVal) .. "/s") or "0/s"

    local payload = {
        username = LocalPlayer.Name,
        userId = LocalPlayer.UserId,
        income = incomeFormatted,
        incomeRaw = incomeVal,
        walkSpeed = walkSpeed,
        pets = petsList
    }

    local requestFunc = (syn and syn.request) or (http and http.request) or request or http_request

    if requestFunc then
        requestFunc({
            Url = VERCEL_URL,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode(payload)
        })
    end
end

-- Eksekusi langsung & loop tiap 3 detik
sendData()
task.spawn(function()
    while true do
        task.wait(3)
        sendData()
    end
end)
