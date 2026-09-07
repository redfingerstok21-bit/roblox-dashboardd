local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- URL Vercel milik kamu
local VERCEL_URL = "https://roblox-dashboardd.vercel.app/api/update"

-- Fungsi konversi angka ke format K, M, B
local function formatNumber(n)
    if not n then return "0" end
    if n >= 1e9 then
        return string.format("%.1fB", n / 1e9)
    elseif n >= 1e6 then
        return string.format("%.1fM", n / 1e6)
    elseif n >= 1e3 then
        return string.format("%.1fK", n / 1e3)
    else
        return tostring(n)
    end
end

local function sendData()
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    
    -- Mengambil nilai Money & Income
    local moneyVal = leaderstats and leaderstats:FindFirstChild("Money") and leaderstats.Money.Value or 0
    local incomeVal = leaderstats and leaderstats:FindFirstChild("Income") and leaderstats.Income.Value or 0

    -- Mengambil WalkSpeed karakter
    local walkSpeed = 16
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        walkSpeed = LocalPlayer.Character.Humanoid.WalkSpeed
    end

    -- Data Pet yang sedang equipped
    local equippedPets = {
        { name = "Kitsune", incomeRaw = 3000000000, income = formatNumber(3000000000) },
        { name = "Dragon", incomeRaw = 800000000, income = formatNumber(800000000) },
        { name = "Dog", incomeRaw = 100000, income = formatNumber(100000) }
    }

    -- Payload data yang dikirim ke Vercel
    local payload = {
        username = LocalPlayer.Name,
        userId = LocalPlayer.UserId,
        money = formatNumber(moneyVal),
        income = formatNumber(incomeVal),
        incomeRaw = incomeVal, -- Angka mentah untuk sorting di dashboard
        walkSpeed = walkSpeed,
        pets = equippedPets
    }

    -- Menggunakan fungsi HTTP Request Delta Executor
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

-- Menjalankan pengiriman data otomatis setiap 3 detik
task.spawn(function()
    while true do
        sendData()
        task.wait(3)
    end
end)
