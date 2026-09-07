local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local VERCEL_URL = "https://roblox-dashboardd.vercel.app/api/update"

-- Fungsi membersihkan angka dari teks layar (contoh: "$100K" -> 100000)
local function parseTextToNumber(text)
    if not text then return 0 end
    local cleanText = text:gsub("[%$,/s]", ""):match("^%s*(.-)%s*$")
    
    local mult = 1
    if cleanText:lower():find("b") then
        mult = 1e9
        cleanText = cleanText:lower():gsub("b", "")
    elseif cleanText:lower():find("m") then
        mult = 1e6
        cleanText = cleanText:lower():gsub("m", "")
    elseif cleanText:lower():find("k") then
        mult = 1e3
        cleanText = cleanText:lower():gsub("k", "")
    end
    
    local num = tonumber(cleanText)
    if num then
        return num * mult
    end
    return 0
end

-- Format angka kembali ke K, M, B untuk dashboard
local function formatNumber(n)
    if not n or n == 0 then return "0" end
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

-- Membaca teks otomatis dari UI Layar Roblox
local function getUIStats()
    local moneyRaw = 0
    local incomeRaw = 0

    for _, gui in ipairs(PlayerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible then
            local txt = gui.Text
            -- Jika teks di layar mengandung simbol $ atau Uang
            if txt:find("%$") or gui.Name:lower():find("money") or gui.Name:lower():find("coin") then
                local val = parseTextToNumber(txt)
                if val > moneyRaw then moneyRaw = val end
            end
            -- Jika teks di layar mengandung /s atau Income
            if txt:find("/s") or txt:find("sec") or gui.Name:lower():find("income") then
                local val = parseTextToNumber(txt)
                if val > incomeRaw then incomeRaw = val end
            end
        end
    end

    return moneyRaw, incomeRaw
end

local function sendData()
    local moneyVal, incomeVal = getUIStats()

    -- Ambil WalkSpeed (dibulatkan)
    local walkSpeed = 16
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        walkSpeed = math.floor(LocalPlayer.Character.Humanoid.WalkSpeed + 0.5)
    end

    -- Format Data Pet (Sistem sementara jika pet belum memiliki folder khusus)
    local equippedPets = {
        { name = "Top Egg Pet", incomeRaw = incomeVal, income = formatNumber(incomeVal) }
    }

    local payload = {
        username = LocalPlayer.Name,
        userId = LocalPlayer.UserId,
        money = formatNumber(moneyVal),
        income = formatNumber(incomeVal),
        incomeRaw = incomeVal,
        walkSpeed = walkSpeed,
        pets = (incomeVal > 0) and equippedPets or {}
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

-- Kirim otomatis setiap 3 detik
task.spawn(function()
    while true do
        sendData()
        task.wait(3)
    end
end)
