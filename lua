local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")

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
    if not str or str == "" then return 0 end
    local clean = str:gsub("[%$,/s]", ""):gsub("^%s*(.-)%s*$", "%1")
    local mult = 1
    local lower = clean:lower()
    if lower:find("b") then 
        mult = 1e9 
        clean = clean:lower():gsub("b","")
    elseif lower:find("m") then 
        mult = 1e6 
        clean = clean:lower():gsub("m","")
    elseif lower:find("k") then 
        mult = 1e3 
        clean = clean:lower():gsub("k","")
    end
    local num = tonumber(clean)
    return num and (num * mult) or 0
end

-- DETEKSI OTOMATIS DATA GAME
local function getRealGameStats()
    local moneyRaw = 0
    local incomeRaw = 0
    local equippedPets = {}
    local petCount = 0

    -- 1. Deteksi dari leaderstats (paling umum)
    local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
    if leaderstats then
        for _, child in ipairs(leaderstats:GetChildren()) do
            local name = child.Name:lower()
            if name:find("money") or name:find("cash") or name:find("coin") or name:find("egg") then
                moneyRaw = tonumber(child.Value) or moneyRaw
            elseif name:find("income") or name:find("sec") or name:find("mult") then
                incomeRaw = tonumber(child.Value) or incomeRaw
            end
        end
    end

    -- 2. Deteksi dari Data Folder
    if moneyRaw == 0 or incomeRaw == 0 then
        local dataFolder = LocalPlayer:FindFirstChild("Data") or LocalPlayer:FindFirstChild("Stats")
        if dataFolder then
            for _, child in ipairs(dataFolder:GetChildren()) do
                local name = child.Name:lower()
                if name:find("money") or name:find("cash") or name:find("coin") or name:find("egg") then
                    moneyRaw = tonumber(child.Value) or moneyRaw
                elseif name:find("income") or name:find("sec") or name:find("mult") then
                    incomeRaw = tonumber(child.Value) or incomeRaw
                end
            end
        end
    end

    -- 3. Deteksi dari Attributes
    if moneyRaw == 0 then
        local attrs = {
            "Money", "Coins", "Cash", "Currency", 
            "Eggs", "Gold", "Points"
        }
        for _, attr in ipairs(attrs) do
            local val = LocalPlayer:GetAttribute(attr)
            if val and tonumber(val) then
                moneyRaw = tonumber(val)
                break
            end
        end
    end
    
    if incomeRaw == 0 then
        local attrs = {
            "Income", "IncomePerSec", "PerSecond", 
            "Multiplier", "Gain"
        }
        for _, attr in ipairs(attrs) do
            local val = LocalPlayer:GetAttribute(attr)
            if val and tonumber(val) then
                incomeRaw = tonumber(val)
                break
            end
        end
    end

    -- 4. Deteksi dari UI
    if moneyRaw == 0 or incomeRaw == 0 then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            for _, gui in ipairs(playerGui:GetDescendants()) do
                if gui:IsA("TextLabel") and gui.Visible and gui.Text ~= "" then
                    local txt = gui.Text
                    local txtLower = txt:lower()
                    
                    -- Deteksi Money
                    if moneyRaw == 0 and (txt:find("%$") or txtLower:find("money") or txtLower:find("cash") or txtLower:find("coin")) then
                        local val = parseValue(txt)
                        if val > 0 then moneyRaw = val end
                    end
                    
                    -- Deteksi Income
                    if incomeRaw == 0 and (txtLower:find("/s") or txtLower:find("per sec") or txtLower:find("income") or txtLower:find("sec")) then
                        local val = parseValue(txt)
                        if val > 0 then incomeRaw = val end
                    end
                end
            end
        end
    end

    -- 5. Deteksi Pet dari Workspace (dengan error handling)
    pcall(function()
        local plots = Workspace:FindFirstChild("Plots") or Workspace:FindFirstChild("Bases") or Workspace:FindFirstChild("Pets")
        if plots then
            for _, obj in ipairs(plots:GetChildren()) do
                -- Cek kepemilikan
                local owner = obj:FindFirstChild("Owner") or obj:FindFirstChild("Player") or obj:FindFirstChild("PlayerName")
                local isOwner = false
                if owner then
                    local ownerVal = owner.Value
                    if ownerVal == LocalPlayer or ownerVal == LocalPlayer.Name or ownerVal == tostring(LocalPlayer.UserId) then
                        isOwner = true
                    end
                end
                
                -- Cek apakah objek adalah pet
                local isPet = obj.Name:lower():find("pet") or obj:FindFirstChild("Pet") or obj:FindFirstChild("PetName")
                
                if isOwner or isPet then
                    -- Cari income/multiplier
                    local inc = 0
                    local incObj = obj:FindFirstChild("Income") or obj:FindFirstChild("Multiplier") or obj:FindFirstChild("PerSecond")
                    if incObj then 
                        inc = tonumber(incObj.Value) or 0 
                    end
                    
                    -- Cari nama pet
                    local petName = obj.Name
                    local nameObj = obj:FindFirstChild("PetName") or obj:FindFirstChild("Name")
                    if nameObj and nameObj.Value and nameObj.Value ~= "" then
                        petName = tostring(nameObj.Value)
                    end
                    
                    if inc > 0 then
                        table.insert(equippedPets, {
                            name = petName,
                            incomeRaw = inc,
                            income = formatNumber(inc)
                        })
                        petCount = petCount + 1
                    end
                end
            end
        end
    end)

    -- 6. Deteksi Pet dari PlayerData
    pcall(function()
        local petData = LocalPlayer:FindFirstChild("Pets") or LocalPlayer:FindFirstChild("PetData")
        if petData then
            for _, pet in ipairs(petData:GetChildren()) do
                local inc = 0
                local incObj = pet:FindFirstChild("Income") or pet:FindFirstChild("Multiplier")
                if incObj then inc = tonumber(incObj.Value) or 0 end
                
                if inc > 0 then
                    table.insert(equippedPets, {
                        name = pet.Name,
                        incomeRaw = inc,
                        income = formatNumber(inc)
                    })
                    petCount = petCount + 1
                end
            end
        end
    end)

    -- 7. Deteksi dari Remote Events (jika ada)
    pcall(function()
        for _, child in ipairs(ReplicatedStorage:GetChildren()) do
            if child.Name:lower():find("money") or child.Name:lower():find("income") then
                -- Coba trigger atau baca nilai
            end
        end
    end)

    return moneyRaw, incomeRaw, equippedPets
end

-- FUNGSI UTAMA PENGIRIM DATA
local function sendData()
    local success, moneyVal, incomeVal, petsList = pcall(getRealGameStats)
    
    if not success then
        moneyVal, incomeVal, petsList = 0, 0, {}
    end

    -- Ambil WalkSpeed karakter
    local walkSpeed = 16
    pcall(function()
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            walkSpeed = math.floor(LocalPlayer.Character.Humanoid.WalkSpeed + 0.5)
        end
    end)

    -- Ambil jumlah pet yang dipakai
    local petsEquipped = #petsList

    -- Siapkan payload
    local payload = {
        username = LocalPlayer.Name,
        userId = LocalPlayer.UserId,
        money = formatNumber(moneyVal),
        moneyRaw = moneyVal,
        income = formatNumber(incomeVal),
        incomeRaw = incomeVal,
        walkSpeed = walkSpeed,
        petsEquipped = petsEquipped,
        pets = petsList,
        topPet = petsList[1] and petsList[1].name or "None",
        timestamp = os.time()
    }

    -- Kirim data
    local requestFunc = syn and syn.request or http and http.request or request or http_request
    
    if requestFunc then
        local jsonBody = HttpService:JSONEncode(payload)
        
        pcall(function()
            requestFunc({
                Url = VERCEL_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json"
                },
                Body = jsonBody
            })
        end)
    end
end

-- Kirim data pertama kali
sendData()

-- Update setiap 3 detik
task.spawn(function()
    while task.wait(3) do
        sendData()
    end
end)

print("✅ Dashboard Tracker Aktif - Mengirim data setiap 3 detik")
print("👤 Akun: " .. LocalPlayer.Name)
print("🆔 UserID: " .. LocalPlayer.UserId)
