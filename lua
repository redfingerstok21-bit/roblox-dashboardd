local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local VERCEL_URL = "https://roblox-dashboardd.vercel.app/api/update"

-- Helper Format Angka
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

-- Helper Parsing Teks (K, M, B -> Angka Raw)
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

-- DETEKSI OTOMATIS DATA GAME "STEAL AN EGG"
local function getRealGameStats()
    local moneyRaw = 0
    local incomeRaw = 0
    local equippedPets = {}

    -- 1. Deteksi Data Utama dari Player / DataFolder
    local playerData = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("Stats") or LocalPlayer:FindFirstChild("leaderstats")
    if playerData then
        for _, child in ipairs(playerData:GetChildren()) do
            local name = child.Name:lower()
            if name:find("money") or name:find("cash") or name:find("egg") or name:find("coin") then
                moneyRaw = tonumber(child.Value) or moneyRaw
            elseif name:find("income") or name:find("sec") or name:find("mult") then
                incomeRaw = tonumber(child.Value) or incomeRaw
            end
        end
    end

    -- 2. Jika tidak ada di Player, Deteksi via Attributes (Metode Game Baru)
    if moneyRaw == 0 then
        moneyRaw = LocalPlayer:GetAttribute("Money") or LocalPlayer:GetAttribute("Coins") or 0
    end
    if incomeRaw == 0 then
        incomeRaw = LocalPlayer:GetAttribute("Income") or LocalPlayer:GetAttribute("IncomePerSec") or 0
    end

    -- 3. Deteksi dari Plot / Base Milik Pemain di Map
    local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases")
    if plots then
        for _, plot in ipairs(plots:GetChildren()) do
            local owner = plot:FindFirstChild("Owner") or plot:FindFirstChild("Player")
            if owner and (owner.Value == LocalPlayer or owner.Value == LocalPlayer.Name) then
                -- Cari Pet yang aktif di Plot
                local petFolder = plot:FindFirstChild("Pets") or plot:FindFirstChild("EquippedPets")
                if petFolder then
                    for _, pet in ipairs(petFolder:GetChildren()) do
                        local pInc = 0
                        local incObj = pet:FindFirstChild("Income") or pet:FindFirstChild("Multiplier")
                        if incObj then pInc = tonumber(incObj.Value) or 0 end

                        table.insert(equippedPets, {
                            name = pet.Name,
                            incomeRaw = pInc,
                            income = formatNumber(pInc)
                        })
                    end
                end
            end
        end
    end

    -- 4. Deteksi Cadangan (UI Scanning Otomatis jika lokasi internal terkunci)
    if moneyRaw == 0 or incomeRaw == 0 then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("TextLabel") and gui.Visible and gui.Text ~= "" then
                    local txt = gui.Text
                    -- Deteksi format teks layar Uang & Income
                    if (txt:find("%$") or gui.Name:lower():find("money")) and moneyRaw == 0 then
                        moneyRaw = parseValue(txt)
                    elseif (txt:find("/s") or gui.Name:lower():find("income")) and incomeRaw == 0 then
                        incomeRaw = parseValue(txt)
                    end
                end
            end
        end
    end

    return moneyRaw, incomeRaw, equippedPets
end

-- FUNGSI UTAMA PENGIRIM DATA
local function sendData()
    local moneyVal, incomeVal, petsList = getRealGameStats()

    -- Ambil WalkSpeed karakter secara presisi
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

-- Kirim data langsung saat pertama kali di-execute
sendData()

-- Lalu perbarui terus secara realtime setiap 3 detik
task.spawn(function()
    while true do
        task.wait(3)
        sendData()
    end
end)
