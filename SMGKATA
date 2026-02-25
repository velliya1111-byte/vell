-- =========================================================
-- ULTRA SMART AUTO KATA (FIXED VERSION)
-- =========================================================

-- ================================
-- LOAD RAYFIELD (paling atas)
-- ================================
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua"))()

-- ================================
-- SERVICES
-- ================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ================================
-- LOAD MODULE WORD LIST
-- ================================
local wordListFolder = ReplicatedStorage:FindFirstChild("WordList")
if not wordListFolder then
    warn("WordList tidak ditemukan")
    return
end

local kataModule = require(wordListFolder:WaitForChild("IndonesianWords"))

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

-- Huruf langka untuk menjebak lawan
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

local function addUsedWord(word)
    local w = string.lower(word)
    if not usedWords[w] then
        usedWords[w] = true
        table.insert(usedWordsList, word)
    end
end

-- Hitung kemungkinan lanjutan kata lawan
local function countNextOptions(lastLetter)
    lastLetter = lastLetter:lower()
    local count = 0

    for _, word in ipairs(kataModule) do
        local w = tostring(word):lower()
        if w:sub(1,1) == lastLetter and not isUsed(w) then
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

local function humanDelay()
    local min = math.min(config.minDelay, config.maxDelay)
    local max = math.max(config.minDelay, config.maxDelay)
    task.wait(math.random(min, max) / 1000)
end

-- =========================================================
-- SMART WORD SEARCH
-- =========================================================
local function getSmartWords(prefix)
    prefix = string.lower(prefix)
    local results = {}

    for _, word in ipairs(kataModule) do
        local w = tostring(word)
        local lw = string.lower(w)

        if lw:sub(1, #prefix) == prefix then
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

-- =========================================================
-- SMART AUTO ENGINE
-- =========================================================
local function startUltraAI()
    if autoRunning or not autoEnabled or not matchActive or not isMyTurn or serverLetter == "" then
        return
    end

    autoRunning = true

    task.spawn(function()
        humanDelay()

        local words = getSmartWords(serverLetter)
        if #words == 0 then
            autoRunning = false
            return
        end

        local selectedWord
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
        if not selectedWord then
            autoRunning = false
            return
        end

        local prediction = predictWinChance(selectedWord)

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

        print("AI pilih:", selectedWord, "| Chance:", prediction)

        SubmitWord:FireServer(selectedWord)
        addUsedWord(selectedWord)

        humanDelay()
        BillboardEnd:FireServer()

        autoRunning = false
    end)
end

-- =========================================================
-- UI
-- =========================================================
local Window = Rayfield:CreateWindow({
    Name = "Sambung Kata Ultra AI",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "Rayfield Edition",
    ConfigurationSaving = {Enabled = false}
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

-- =========================================================
-- REMOTE EVENTS
-- =========================================================
MatchUI.OnClientEvent:Connect(function(cmd, value)
    if cmd == "ShowMatchUI" then
        matchActive = true
        isMyTurn = false
        usedWords = {}
        usedWordsList = {}

    elseif cmd == "HideMatchUI" then
        matchActive = false
        isMyTurn = false
        serverLetter = ""

    elseif cmd == "StartTurn" then
        if opponentStreamWord ~= "" then
            addUsedWord(opponentStreamWord)
            opponentStreamWord = ""
        end

        isMyTurn = true
        startUltraAI()

    elseif cmd == "EndTurn" then
        isMyTurn = false

    elseif cmd == "UpdateServerLetter" then
        serverLetter = value or ""
    end
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
