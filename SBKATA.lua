-- =========================================================
-- ULTRA SMART AUTO KATA (RAYFIELD EDITION - MOBILE SAFE)
-- =========================================================

-- ================================
-- LOAD RAYFIELD
-- ================(
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

if not Rayfield then
    warn("Rayfield gagal dimuat")
    return
end

-- ================================
-- SERVICES
-- ================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ================================
-- LOAD MODULE
-- ================================
local wordList = ReplicatedStorage:FindFirstChild("WordList")
if not wordList then
    Rayfield:Notify({
        Title = "Error",
        Content = "WordList tidak ditemukan!",
        Duration = 5
    })
    return
end

local kataModule = require(wordList:WaitForChild("IndonesianWords"))

-- ================================
-- REMOTES
-- ================================
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local MatchUI = remotes:WaitForChild("MatchUI")
local SubmitWord = remotes:WaitForChild("SubmitWord")
local BillboardUpdate = remotes:WaitForChild("BillboardUpdate")
local BillboardEnd = remotes:WaitForChild("BillboardEnd")
local TypeSound = remotes:WaitForChild("TypeSound")
local UsedWordWarn = remotes:WaitForChild("UsedWordWarn")

-- =========================================================
-- STATE
-- =========================================================
local matchActive = false
local isMyTurn = false
local serverLetter = ""

local usedWords = {}
local usedWordsList = {}
local opponentStreamWord = ""

local autoEnabled = false
local autoRunning = false

local config = {
    minDelay = 35,
    maxDelay = 150,
    aggression = 50,
    minLength = 3,
    maxLength = 20
}
local rareLetters = {
    z = true, 
    q = true, 
    x = true,
    v = true
}

-- =========================================================
-- HELPERS
-- =========================================================
local function isUsed(word)
    return usedWords[string.lower(word)] == true
end

local usedWordsDropdown

local function addUsedWord(word)
    local w = string.lower(word)
    if not usedWords[w] then
        usedWords[w] = true
        table.insert(usedWordsList, word)

        if usedWordsDropdown then
            usedWordsDropdown:Set(usedWordsList)
        end
    end
end

local function getSmartWords(prefix)
    prefix = string.lower(prefix)
    local results = {}

    for _, word in ipairs(kataModule) do
        local w = tostring(word)
        if string.sub(string.lower(w), 1, #prefix) == prefix then
            if not isUsed(w) then
                local len = #w
                if len >= config.minLength and len <= config.maxLength then
                    table.insert(results, w)
                end
            end
        end
    end

    table.sort(results, function(a, b)
    local aLast = a:sub(-1):lower()
    local bLast = b:sub(-1):lower()

    if rareLetters[aLast] and not rareLetters[bLast] then
        return true
    elseif not rareLetters[aLast] and rareLetters[bLast] then
        return false
    end

    return #a > #b
end)

    return results
end

local function humanDelay()
    local min = config.minDelay
    local max = config.maxDelay
    if min > max then min = max end
    task.wait(math.random(min, max) / 1000)
end
-- Hitung kemungkinan lanjutan kata lawan
local function countNextOptions(lastLetter)
    lastLetter = lastLetter:lower()
    local count = 0

    for _, word in ipairs(kataModule) do
        local w = tostring(word):lower()
        if w:sub(1, 1) == lastLetter and not isUsed(w) then
            count += 1
        end
    end

    return count
end

-- Prediksi peluang menang
local function predictWinChance(word)
    local lastLetter = word:sub(-1)
    local options = countNextOptions(lastLetter)

    if options == 0 then
        return "WIN GUARANTEED"
    elseif options <= 3 then
        return "HIGH WIN CHANCE"
    elseif options <= 10 then
        return "MEDIUM"
    else
        return "RISKY"
    end
end

-- =========================================================
-- SMART AUTO ENGINE
-- =========================================================
local function startUltraAI()
    if autoRunning then return end
    if not autoEnabled then return end
    if not matchActive or not isMyTurn then return end
    if serverLetter == "" then return end

    autoRunning = true

    task.spawn(function()
        humanDelay()

        local words = getSmartWords(serverLetter)
        if #words == 0 then
            autoRunning = false
            return
        end

        local selectedWord

        if config.aggression >= 100 then
            selectedWord = words[1]
        elseif config.aggression <= 0 then
            selectedWord = words[math.random(1, #words)]
        else
            local pickIndex
if config.aggression >= 100 then
    pickIndex = 1
elseif config.aggression <= 0 then
    pickIndex = math.random(1, #words)
else
    local range = math.floor(#words * (config.aggression / 100))
    range = math.max(1, range)
    pickIndex = math.random(1, range)
end

selectedWord = words[pickIndex]
            topN = math.min(topN, #words)
            selectedWord = words[math.random(1, topN)]
        end

        if not selectedWord then
            autoRunning = false
            return
        end

        local currentWord = serverLetter
        local remain = selectedWord:sub(#serverLetter + 1)

        for i = 1, #remain do
            if not matchActive or not isMyTurn then
                autoRunning = false
                return
            end

            currentWord = currentWord .. remain:sub(i, i)

            TypeSound:FireServer()
            BillboardUpdate:FireServer(currentWord)

            humanDelay()
        end

        humanDelay()

        local prediction = predictWinChance(selectedWord)

statusParagraph:Set({
    Title = "AI Decision",
    Content = "Word: "..selectedWord.."\nChance: "..prediction
})

local prediction = predictWinChance(selectedWord)

statusParagraph:Set({
    Title = "AI Decision",
    Content = "Word: "..selectedWord.."\nChance: "..prediction
})

SubmitWord:FireServer(selectedWord)
addUsedWord(selectedWord)

        humanDelay()
        BillboardEnd:FireServer()

        autoRunning = false
    end)
end

-- =========================================================
-- UI RAYFIELD
-- =========================================================
local Window = Rayfield:CreateWindow({
    Name = "Sambung-kata by Sazaraaax",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Rayfield Edition",
    ConfigurationSaving = {
        Enabled = false
    }
})

local MainTab = Window:CreateTab("Main", 4483345998)

MainTab:CreateToggle({
    Name = "Aktifkan Auto",
    CurrentValue = false,
    Callback = function(Value)
        autoEnabled = Value
        if Value then
            startUltraAI()
        end
    end
})

MainTab:CreateSlider({
    Name = "Min Delay (ms)",
    Range = {10, 500},
    Increment = 5,
    CurrentValue = config.minDelay,
    Callback = function(Value)
        config.minDelay = Value
    end
})

MainTab:CreateSlider({
    Name = "Max Delay (ms)",
    Range = {20, 1000},
    Increment = 5,
    CurrentValue = config.maxDelay,
    Callback = function(Value)
        config.maxDelay = Value
    end
})

MainTab:CreateSlider({
    Name = "Aggression",
    Range = {0, 100},
    Increment = 5,
    CurrentValue = config.aggression,
    Callback = function(Value)
        config.aggression = Value
    end
})

MainTab:CreateSlider({
    Name = "Min Word Length",
    Range = {1, 10},
    Increment = 1,
    CurrentValue = config.minLength,
    Callback = function(Value)
        config.minLength = Value
    end
})

MainTab:CreateSlider({
    Name = "Max Word Length",
    Range = {5, 30},
    Increment = 1,
    CurrentValue = config.maxLength,
    Callback = function(Value)
        config.maxLength = Value
    end
})

usedWordsDropdown = MainTab:CreateDropdown({
    Name = "Used Words",
    Options = usedWordsList,
    CurrentOption = "",
    Callback = function() end
})

local statusParagraph = MainTab:CreateParagraph({
    Title = "Status",
    Content = "Idle"
})

-- =========================================================
-- REMOTE EVENTS
-- =========================================================
MatchUI.OnClientEvent:Connect(function(cmd, value)

    if cmd == "ShowMatchUI" then
        matchActive = true
        isMyTurn = false
        usedWords = {}
        usedWordsList = {}
        usedWordsDropdown:Set({})

    elseif cmd == "HideMatchUI" then
        matchActive = false
        isMyTurn = false
        serverLetter = ""
        usedWords = {}
        usedWordsList = {}
        usedWordsDropdown:Set({})

    elseif cmd == "StartTurn" then
        if opponentStreamWord ~= "" then
            addUsedWord(opponentStreamWord)
            opponentStreamWord = ""
        end

        isMyTurn = true
        if autoEnabled then
            startUltraAI()
        end

    elseif cmd == "EndTurn" then
        isMyTurn = false

    elseif cmd == "UpdateServerLetter" then
        serverLetter = value or ""
    end

    statusParagraph:Set({
        Title = "Status",
        Content = "Match: "..tostring(matchActive)..
        " | Turn: "..(isMyTurn and "You" or "Opponent")..
        " | Start: "..serverLetter
    })
end)

BillboardUpdate.OnClientEvent:Connect(function(word)
    if matchActive and not isMyTurn then
        opponentStreamWord = word or ""
    end
end)

UsedWordWarn.OnClientEvent:Connect(function(word)
    if word then
        addUsedWord(word)

        if autoEnabled and matchActive and isMyTurn then
            humanDelay()
            startUltraAI()
        end
    end

end)

