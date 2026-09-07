local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")

local VERCEL_URL = "https://roblox-dashboardd.vercel.app/api/update"

-- Helper Format Angka (K, M, B)
local function formatNumber(n)
    if not n or type(n) ~= "number" then return "0" end
    if n >= 1e9 then
        return string.format("%.1fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    else
        return tostring(math.floor(n))
    end
end

-- Helper Parsing Teks
local function parseValue(str)
    if not str then return 0 end
    local num = str:gsub("[%$,/s]", ""):match("^%s*(.-)%s*$")
    local mult = 1
    if num:lower():find("b") then mult = 1e9 num = num:lower():gsub("b","")
    elseif num:lower():find("m") then mult = 1e6 num = num:lower():gsub("m","")
    elseif num:lower():find("k") then mult = 1e3 num = num:lower():gsub("k","")
    end
    return (tonumber(num) or 0) * mult
end

-- 1. DETEKSI BASE / PLOT PEMAIN
local function getMyPlot()
    local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases") or Workspace:FindFirstChild("PlotsFolder")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player")
            if owner and (owner.Value == LocalPlayer or owner.Value == LocalPlayer.Name) then
                return plot
            end
        end
    end
    return nil
end

-- 2. READ STATS & PETS DARI PLOT / PLAYER
local function getPlayerData()
    local moneyRaw = 0
    local incomeRaw = 0
    local petsList = {}

    -- A. Cek dari Leaderstats standar jika ada
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        if leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Coins") then
            moneyRaw = (leaderstats:FindFirstChild("Money") or leaderstats:FindFirstChild("Coins")).Value
        end
        if leaderstats:FindFirstChild("Income") or leaderstats:FindFirstChild("Income/s") then
            incomeRaw = (leaderstats:FindFirstChild("Income") or leaderstats:FindFirstChild("Income/s")).Value
        end
    end

    -- B. Cek langsung dari Plot / Base di Map
    local myPlot = getMyPlot()
    if myPlot then
        -- Cari pet di dalam plot
        local petsFolder = myPlot:FindFirstChild("Pets") or myPlot:FindFirstChild("Animals") or myPlot:FindFirstChild("HatchedPets")
        if petsFolder then
            for _, pet in ipairs(petsFolder:GetChildren()) do
                local pName = pet.Name
                local pInc = 0
                local incVal = pet:FindFirstChild("Income") or pet:FindFirstChild("Mult")
                if incVal then pInc = tonumber(incVal.Value) or 0 end
                
                table.insert(petsList, {
                    name = pName,
                    incomeRaw = pInc,
                    income = formatNumber(pInc)
                })
            end
        end
    end

    -- C. Fallback: Baca dari UI Player Gui jika belum ketemu
    if moneyRaw == 0 or incomeRaw == 0 then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("TextLabel") and gui.Visible then
                    local txt = gui.Text
                    if txt:find("%$") and moneyRaw == 0 then
                        moneyRaw = parseValue(txt)
                    elseif txt:find("/s") and incomeRaw == 0 then
                        incomeRaw = parseValue(txt)
                    end
                end
            end
        end
    end

    return moneyRaw, incomeRaw, petsList
end

-- 3. KIRIM DATA KE VERCEL
local function sendData()
    local moneyVal, incomeVal, pets = getPlayerData()

    local walkSpeed = 16
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        walkSpeed = math.floor(LocalPlayer.Character.Humanoid.WalkSpeed + 0.5)
    end

    local payload = {
        username = LocalPlayer.Name,
        userId = LocalPlayer.UserId,
        money = formatNumber(moneyVal),
        income = formatNumber(incomeVal),
        incomeRaw = incomeVal,
        walkSpeed = walkSpeed,
        pets = #pets > 0 and pets or {}
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

-- Loop setiap 3 detik
task.spawn(function()
    while true do
        sendData()
        task.wait(3)
    end
end)
