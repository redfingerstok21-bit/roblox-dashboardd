local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local VERCEL_URL = "https://roblox-dashboardd.vercel.app/api/update"

-- Fungsi konversi angka ke format K, M, B
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

-- Deteksi Uang & Income Khusus Steal an Egg
local function getStealAnEggStats()
    local money = 0
    local income = 0

    -- 1. Cek folder Data / PlayerData
    local playerData = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("PlayerData") or LocalPlayer:FindFirstChild("leaderstats")
    
    if playerData then
        local moneyObj = playerData:FindFirstChild("Money") or playerData:FindFirstChild("Cash") or playerData:FindFirstChild("Coins")
        local incomeObj = playerData:FindFirstChild("Income") or playerData:FindFirstChild("Multiplier") or playerData:FindFirstChild("IncomePerSecond")

        if moneyObj then money = moneyObj.Value end
        if incomeObj then income = incomeObj.Value end
    end

    -- 2. Jika tidak ada di folder Data, cek modul/attributes
    if money == 0 then
        money = LocalPlayer:GetAttribute("Money") or LocalPlayer:GetAttribute("Cash") or 0
    end
    if income == 0 then
        income = LocalPlayer:GetAttribute("Income") or LocalPlayer:GetAttribute("Multiplier") or 0
    end

    return money, income
end

-- Deteksi Pet Khusus Steal an Egg
local function getEquippedPets()
    local pets = {}
    
    -- Cari folder Pet yang sedang equipped
    local petFolder = LocalPlayer:FindFirstChild("EquippedPets") or LocalPlayer:FindFirstChild("Pets") or LocalPlayer:FindFirstChild("PetsEquipped")
    
    if petFolder then
        for _, pet in ipairs(petFolder:GetChildren()) do
            local petName = pet.Name
            
            -- Ambil statistik multiplier / income pet
            local incomeObj = pet:FindFirstChild("Income") or pet:FindFirstChild("Multiplier") or pet:FindFirstChild("Boost")
            local incomeRaw = (incomeObj and incomeObj.Value) or pet:GetAttribute("Income") or 0

            table.insert(pets, {
                name = petName,
                incomeRaw = incomeRaw,
                income = formatNumber(incomeRaw)
            })
        end
    end

    return pets
end

local function sendData()
    local moneyVal, incomeVal = getStealAnEggStats()
    local equippedPets = getEquippedPets()

    -- WalkSpeed yang rapi (dibulatkan)
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
        pets = equippedPets
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

-- Kirim data setiap 3 detik
task.spawn(function()
    while true do
        sendData()
        task.wait(3)
    end
end)
