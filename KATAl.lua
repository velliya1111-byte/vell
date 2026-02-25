--// LOAD UI LIBRARY
local Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source.lua'))()
--// WINDOW
local Window = Library:CreateWindow({
    Name = "SBKATA AUTO",
    LoadingTitle = "SBKATA Loading...",
    LoadingSubtitle = "by velliya",
    ConfigurationSaving = {
        Enabled = false
    }
})

--// TAB
local MainTab = Window:CreateTab("Main", 4483362458)

--// CONFIG
local config = {
    minDelay = 300,
    maxDelay = 900
}

--// DATA KATA (contoh, ganti dengan module milikmu)
local kataModule = {
    "apel","elang","gajah","harimau","ular","rusa","ayam","mangga","anggur","rumah","hujan"
}

local usedWords = {}
local AutoPlay = false

--// CEK SUDAH DIGUNAKAN
local function isUsed(word)
    return usedWords[word] == true
end

--// HITUNG OPSI LANJUTAN LAWAN
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

--// PREDIKSI MENANG
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

--// DELAY HUMAN
local function humanDelay()
    local min = config.minDelay
    local max = config.maxDelay
    if min > max then min = max end
    task.wait(math.random(min, max) / 1000)
end

--// PILIH KATA TERBAIK
local function getBestWord(lastLetter)
    local bestWord = nil
    local bestScore = -1

    for _, word in ipairs(kataModule) do
        local w = word:lower()
        if w:sub(1,1) == lastLetter and not isUsed(w) then
            local score = countNextOptions(w:sub(-1))
            if score > bestScore then
                bestScore = score
                bestWord = w
            end
        end
    end

    return bestWord
end

--// TOGGLE UI
MainTab:CreateToggle({
    Name = "Auto Sambung Kata",
    CurrentValue = false,
    Callback = function(Value)
        AutoPlay = Value
    end,
})

--// INFO BUTTON
MainTab:CreateButton({
    Name = "Test UI",
    Callback = function()
        print("UI Berhasil Muncul!")
    end,
})

--// LOOP AUTO PLAY
task.spawn(function()
    while true do
        if AutoPlay then
            -- contoh simulasi (ganti dengan remote game asli)
            local lastLetter = "a" -- ambil huruf terakhir dari lawan (sesuaikan game)
            local bestWord = getBestWord(lastLetter)

            if bestWord then
                usedWords[bestWord] = true
                local chance = predictWinChance(bestWord)
                print("Kata Dipilih:", bestWord, "| Prediksi:", chance)
            else
                print("Tidak ada kata tersedia!")
            end

            humanDelay()
        end
        task.wait(0.1)
    end

end)
