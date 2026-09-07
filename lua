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

-- Fungsi otomatis mencari statistik player
local function getStatValue(statNames)
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats") or LocalPlayer:FindFirstChild("stats")
    if leaderstats then
        for _, name in ipairs(statNames) do
            local found = leaderstats:FindFirstChild(name)
            if found then
                return found.Value
            end
        end
    end
    return 0
end

local function sendData()
    -- Otomatis mencari statistik berdasarkan nama yang sering dipakai di game
    local moneyVal = getStatValue({"Money", "Coins", "Cash", "Yen", "Gems", "Gold", "Tokens"})
    local incomeVal = getStatValue({"Income", "Income/s", "MPS", "GPS", "Multiplier"})

    -- Ambil WalkSpeed & bulatkan nilainya
    local walkSpeed = 16
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        walkSpeed = math.floor(LocalPlayer.Character.Humanoid.WalkSpeed + 0.5)
    end

    -- Contoh data Pet (Sesuaikan jika kamu punya sistem scanning Pet otomatis di game)
    local equippedPets = {
        { name = "Kitsune", incomeRaw = 3000000000, income = formatNumber(3000000000) },
        { name = "Dragon", incomeRaw = 800000000, income = formatNumber(800000000) },
        { name = "Dog", incomeRaw = 100000, income = formatNumber(100000) }
    }

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

task.spawn(function()
    while true do
        sendData()
        task.wait(3)
    end
end)
