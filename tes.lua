local function ApplyFrameDirect(frame)
    SafeCall(function()
        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        if not hrp or not hum then return end
        
        -- ✅ [AUTO-HEIGHT] Ambil posisi asli + Offset Tinggi Badan
        local targetCFrame = GetFrameCFrame(frame)
        
        -- ✅ TERAPKAN OFFSET DI SINI
        -- ==============================
-- APPLY FRAME CLEAN (ANTI MELAYANG)
-- ==============================

local moveState = frame.MoveState
local targetCFrame = GetFrameCFrame(frame)
local targetPos = targetCFrame.Position
local currentPos = hrp.Position

-- 1️⃣ POSITION (JANGAN PAKSA Y SAAT GROUNDED)
if moveState == "Grounded" then
    hrp.CFrame =
        CFrame.new(
            targetPos.X,
            currentPos.Y,
            targetPos.Z
        ) * (targetCFrame - targetCFrame.Position)
else
    hrp.CFrame = targetCFrame
end

-- 2️⃣ VELOCITY (BIARKAN GRAVITY)
local frameVelocity = GetFrameVelocity(frame, moveState)

if moveState == "Grounded" then
    frameVelocity = Vector3.new(
        frameVelocity.X,
        math.min(frameVelocity.Y, 0),
        frameVelocity.Z
    )
end

hrp.AssemblyLinearVelocity = frameVelocity
hrp.AssemblyAngularVelocity = Vector3.zero

-- 3️⃣ SNAP KE TANAH (RAYCAST)
if moveState == "Grounded" and hum then
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {char}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist

    local ray = workspace:Raycast(
        hrp.Position,
        Vector3.new(0, -6, 0),
        rayParams
    )

    if ray then
        hrp.Position = Vector3.new(
            hrp.Position.X,
            ray.Position.Y + hum.HipHeight,
            hrp.Position.Z
        )
    end
end

        
        if hum then
            local frameWalkSpeed = GetFrameWalkSpeed(frame) * CurrentSpeed
            hum.WalkSpeed = frameWalkSpeed
            LastKnownWalkSpeed = frameWalkSpeed
            
            if ShiftLockEnabled then
                hum.AutoRotate = false
            else
                hum.AutoRotate = true
            end
            
            -- State Management (Versi Simple Script Kamu)
            local currentTime = tick()
            local JUMP_VELOCITY_THRESHOLD = 5
            local FALL_VELOCITY_THRESHOLD = -3
            
            local isJumpingByVelocity = frameVelocity.Y > JUMP_VELOCITY_THRESHOLD
            local isFallingByVelocity = frameVelocity.Y < -3
            
            if isJumpingByVelocity and moveState ~= "Jumping" then
                moveState = "Jumping"
            elseif isFallingByVelocity and moveState ~= "Falling" then
                moveState = "Falling"
            end
            
            if moveState == "Jumping" then
                if lastPlaybackState ~= "Jumping" then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    lastPlaybackState = "Jumping"
                    lastStateChangeTime = currentTime
                end
            elseif moveState == "Falling" then
                if lastPlaybackState ~= "Falling" then
                    hum:ChangeState(Enum.HumanoidStateType.Freefall)
                    lastPlaybackState = "Falling"
                    lastStateChangeTime = currentTime
                end
            else
                if moveState ~= lastPlaybackState and (currentTime - lastStateChangeTime) >= STATE_CHANGE_COOLDOWN then
                    if moveState == "Climbing" then
                        hum:ChangeState(Enum.HumanoidStateType.Climbing)
                        hum.PlatformStand = false
                    elseif moveState == "Swimming" then
                        hum:ChangeState(Enum.HumanoidStateType.Swimming)
                    else
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    lastPlaybackState = moveState
                    lastStateChangeTime = currentTime
                end
            end
        end
    end)
end

local function PlayFromSpecificFrame(recording, startFrame, recordingName)
    if IsPlaying or IsAutoLoopPlaying then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        PlaySound("Error")
        return
    end  

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        WalkSpeedBeforePlayback = hum.WalkSpeed 
    end

    -- ✨ [AUTO-HEIGHT CALCULATION] ✨
    local recordedHipHeight = RecordingHipHeights[recordingName] or 2 
    local currentHipHeight = 2
    if hum then currentHipHeight = hum.HipHeight end
    
    local heightDifference = currentHipHeight - recordedHipHeight
    PlaybackHeightOffset = Vector3.zero
    -- ✨ [END CALCULATION] ✨

    IsPlaying = true
    IsPaused = false
    CurrentPlayingRecording = recording
    PausedAtFrame = 0
    playbackAccumulator = 0
    previousFrameData = nil
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local currentPos = hrp.Position
    local targetFrame = recording[startFrame]
    
    -- Hitung target posisi dengan offset
    local targetPos = GetFramePosition(targetFrame) + PlaybackHeightOffset
    
    local distance = (currentPos - targetPos).Magnitude
    
    if distance > 3 then
        hrp.CFrame = GetFrameCFrame(targetFrame) + PlaybackHeightOffset
        hrp.AssemblyLinearVelocity = Vector3.zero
        hrp.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.03)
    end
    
    currentPlaybackFrame = startFrame
    playbackStartTime = tick() - (GetFrameTimestamp(recording[startFrame]) / CurrentSpeed)
    totalPausedDuration = 0
    pauseStartTime = 0
    lastPlaybackState = nil
    lastStateChangeTime = 0

    SaveHumanoidState()
    PlaySound("Toggle")
    
    if PlayBtnControl then
        -- Gunakan fungsi update button yang baru
        UpdatePlayButtonStatus()
    end

    playbackConnection = RunService.Heartbeat:Connect(function(deltaTime)
        SafeCall(function()
            if not IsPlaying then
                playbackConnection:Disconnect()
                RestoreFullUserControl()
                
                CheckIfPathUsed(recordingName)
                lastPlaybackState = nil
                lastStateChangeTime = 0
                previousFrameData = nil
                UpdatePlayButtonStatus()
                return
            end
            
            local char = player.Character
            if not char or not char:FindFirstChild("HumanoidRootPart") then
                IsPlaying = false
                RestoreFullUserControl()
                CheckIfPathUsed(recordingName)
                lastPlaybackState = nil
                lastStateChangeTime = 0
                previousFrameData = nil
                UpdatePlayButtonStatus()
                return
            end
            
            local hum = char:FindFirstChildOfClass("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hum or not hrp then
                IsPlaying = false
                RestoreFullUserControl()
                CheckIfPathUsed(recordingName)
                lastPlaybackState = nil
                lastStateChangeTime = 0
                previousFrameData = nil
                UpdatePlayButtonStatus()
                return
            end

            playbackAccumulator = playbackAccumulator + deltaTime
            
            while playbackAccumulator >= PLAYBACK_FIXED_TIMESTEP do
                playbackAccumulator = playbackAccumulator - PLAYBACK_FIXED_TIMESTEP
                 
                local currentTime = tick()
                local effectiveTime = (currentTime - playbackStartTime - totalPausedDuration) * CurrentSpeed
                
                local nextFrame = currentPlaybackFrame
                while nextFrame < #recording and GetFrameTimestamp(recording[nextFrame + 1]) <= effectiveTime do
                    nextFrame = nextFrame + 1
                end

                if nextFrame >= #recording then
                    IsPlaying = false
                    RestoreFullUserControl()
                    CheckIfPathUsed(recordingName)
                    PlaySound("Success")
                    lastPlaybackState = nil
                    lastStateChangeTime = 0
                    previousFrameData = nil
                    UpdatePlayButtonStatus()
                    return
                end

                local frame = recording[nextFrame]
                if not frame then
                    IsPlaying = false
                    RestoreFullUserControl()
                    CheckIfPathUsed(recordingName)
                    lastPlaybackState = nil
                    lastStateChangeTime = 0
                    previousFrameData = nil
                    UpdatePlayButtonStatus()
                    return
                end

                -- ⭐ Apply frame (Offset sudah dihandle di dalam fungsi ini)
                ApplyFrameDirect(frame)
                
                currentPlaybackFrame = nextFrame
            end
        end)
    end)
    
    AddConnection(playbackConnection)
    UpdatePlayButtonStatus()
end

local function SmartPlayRecording(maxDistance)
    if IsPlaying or IsAutoLoopPlaying then return end
    
    local char = player.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then
        PlaySound("Error")
        return
    end

    local currentPos = char.HumanoidRootPart.Position
    local bestRecording = nil
    local bestFrame = 1
    local bestDistance = math.huge
    local bestRecordingName = nil
    
    for _, recordingName in ipairs(RecordingOrder) do
        local recording = RecordedMovements[recordingName]
        if recording and #recording > 0 then
            local nearestFrame, frameDistance = FindNearestFrame(recording, currentPos)
            
            if frameDistance < bestDistance and frameDistance <= (maxDistance or 50) then
                bestDistance = frameDistance
                bestRecording = recording
                bestFrame = nearestFrame
                bestRecordingName = recordingName
            end
        end
    end
    
    if bestRecording then
        PlayFromSpecificFrame(bestRecording, bestFrame, bestRecordingName)
    else
        local firstRecording = RecordingOrder[1] and RecordedMovements[RecordingOrder[1]]
        if firstRecording then
            PlayFromSpecificFrame(firstRecording, 1, RecordingOrder[1])
        else
            PlaySound("Error")
        end
    end
end

local function PlayRecording(name)
    if not name then
        SmartPlayRecording(50)
        return
    end
    
    local recording = RecordedMovements[name]
    if recording then
        PlayFromSpecificFrame(recording, 1, name)
    else
        PlaySound("Error")
    end
end

local function StopAutoLoopAll()
    AutoLoop = false
    IsAutoLoopPlaying = false
    IsPlaying = false
    IsLoopTransitioning = false
    lastPlaybackState = nil
    lastStateChangeTime = 0
    
    if loopConnection then
        SafeCall(function() task.cancel(loopConnection) end)
        loopConnection = nil
    end
    
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end
    
    RestoreFullUserControl()
    
    SafeCall(function()
        local char = player.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then
                local currentState = hum:GetState()
                local isClimbing = (currentState == Enum.HumanoidStateType.Climbing)
                local isSwimming = (currentState == Enum.HumanoidStateType.Swimming)
                
                if not isClimbing and not isSwimming then
                    CompleteCharacterReset(char)
                end
            end
        end
    end)
    
    PlaySound("Toggle")
    if PlayBtnControl then
        PlayBtnControl.Text = "PLAY"
        PlayBtnControl.BackgroundColor3 = Color3.fromRGB(59, 15, 116)
    end
    if LoopBtnControl then
        LoopBtnControl.Text = "Loop OFF"
        LoopBtnControl.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    end
    UpdatePlayButtonStatus()
end

local function StopPlayback()
    lastStateChangeTime = 0
    lastPlaybackState = nil

    if AutoLoop then
        StopAutoLoopAll()
        if LoopBtnControl then
            LoopBtnControl.Text = "Loop OFF"
            LoopBtnControl.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
    end
    
    if not IsPlaying and not IsAutoLoopPlaying then return end
    
    IsPlaying = false
    IsAutoLoopPlaying = false
    IsLoopTransitioning = false
    LastPausePosition = nil
    LastPauseRecording = nil
    
    if playbackConnection then
        playbackConnection:Disconnect()
        playbackConnection = nil
    end
    
    if loopConnection then
        SafeCall(function() task.cancel(loopConnection) end)
        loopConnection = nil
    end
    
    local char = player.Character
    local isClimbing = false
    local isSwimming = false
    
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then
            local currentState = hum:GetState()
            isClimbing = (currentState == Enum.HumanoidStateType.Climbing)
            isSwimming = (currentState == Enum.HumanoidStateType.Swimming)
        end
    end
    
    RestoreFullUserControl()
    
    if char and not isClimbing and not isSwimming then
        CompleteCharacterReset(char)
    end
    
     LastKnownWalkSpeed = 0
     WalkSpeedBeforePlayback = 0
    
    PlaySound("Toggle")
    if PlayBtnControl then
        PlayBtnControl.Text = "PLAY"
        PlayBtnControl.BackgroundColor3 = Color3.fromRGB(59, 15, 116)
    end
    UpdatePlayButtonStatus()
end

local function StartAutoLoopAll()
    if not AutoLoop then return end
    
    if #RecordingOrder == 0 then
        AutoLoop = false
        if LoopBtnControl then
            LoopBtnControl.Text = "Loop OFF"
            LoopBtnControl.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
        PlaySound("Error")
        return
    end
    
    if IsPlaying then
        IsPlaying = false
        if playbackConnection then
            playbackConnection:Disconnect()
            playbackConnection = nil
        end
    end
    
    -- ✅ ShiftLock TIDAK dimatikan saat auto loop!
    
    PlaySound("Toggle")
    
    if CurrentLoopIndex == 0 or CurrentLoopIndex > #RecordingOrder then
        local nearestRecording, distance, nearestName = FindNearestRecording(50)
        if nearestRecording then
            CurrentLoopIndex = table.find(RecordingOrder, nearestName) or 1
        else
            CurrentLoopIndex = 1
        end
    end
    
    IsAutoLoopPlaying = true
    LoopRetryAttempts = 0
    lastPlaybackState = nil
    lastStateChangeTime = 0
    
    if PlayBtnControl then
        PlayBtnControl.Text = "STOP"
        PlayBtnControl.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
    end
    if LoopBtnControl then
        LoopBtnControl.Text = "Loop ON"
        LoopBtnControl.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
    end

    loopConnection = task.spawn(function()
        while AutoLoop and IsAutoLoopPlaying do
            if not AutoLoop or not IsAutoLoopPlaying then break end
            
            local recordingToPlay = nil
            local recordingNameToPlay = nil
            local searchAttempts = 0
            
            while searchAttempts < #RecordingOrder do
                recordingNameToPlay = RecordingOrder[CurrentLoopIndex]
                recordingToPlay = RecordedMovements[recordingNameToPlay]
                
                if recordingToPlay and #recordingToPlay > 0 then
                    break
                else
                    CurrentLoopIndex = CurrentLoopIndex + 1
                    if CurrentLoopIndex > #RecordingOrder then
                        CurrentLoopIndex = 1
                    end
                    searchAttempts = searchAttempts + 1
                end
            end
            
            if not recordingToPlay or #recordingToPlay == 0 then
                CurrentLoopIndex = 1
                task.wait(1)
                continue
            end
            
            if not IsCharacterReady() then
                if AutoRespawn then
                    ResetCharacter()
                    local success = WaitForRespawn()
                    if not success then
                        task.wait(AUTO_LOOP_RETRY_DELAY)
                        continue
                    end
                    task.wait(0.5)
                else
                    local waitTime = 0
                    local maxWaitTime = 30
                    
                    while not IsCharacterReady() and AutoLoop and IsAutoLoopPlaying do
                        waitTime = waitTime + 0.5
                        if waitTime >= maxWaitTime then
                            break
                        end
                        task.wait(0.5)
                    end
                    
                    if not AutoLoop or not IsAutoLoopPlaying then break end
                    if not IsCharacterReady() then
                        task.wait(AUTO_LOOP_RETRY_DELAY)
                        continue
                    end
                    task.wait(0.5)
                end
            end
            
            if not AutoLoop or not IsAutoLoopPlaying then break end
            
            SafeCall(function()
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    
                    if hum then
                        hum.PlatformStand = false
                        if ShiftLockEnabled then
                            hum.AutoRotate = false
                        else
                            hum.AutoRotate = false
                        end
                        hum:ChangeState(Enum.HumanoidStateType.Running)
                    end
                    
                    local targetCFrame = GetFrameCFrame(recordingToPlay[1])
                    hrp.CFrame = targetCFrame
                    hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                    hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                    
                    task.wait(0.5)
                end
            end)
            
            local playbackCompleted = false
            local currentFrame = 1
            local playbackStartTime = tick()
            local loopAccumulator = 0
            
            lastPlaybackState = nil
            lastStateChangeTime = 0
            
            SaveHumanoidState()
            
            IsLoopTransitioning = false
            
            while AutoLoop and IsAutoLoopPlaying and currentFrame <= #recordingToPlay do
                
                if not IsCharacterReady() then
                    
                    if AutoRespawn then
                        ResetCharacter()
                        local success = WaitForRespawn()
                        
                        if success then
                            RestoreFullUserControl()
                            task.wait(0.5)
                            
                            currentFrame = 1
                            playbackStartTime = tick()
                            lastPlaybackState = nil
                            lastStateChangeTime = 0
                            loopAccumulator = 0
                            
                            SaveHumanoidState()
                            
                            SafeCall(function()
                                local char = player.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    local hum = char:FindFirstChildOfClass("Humanoid")
                                    if hum then
                                        if ShiftLockEnabled then
                                            hum.AutoRotate = false
                                        else
                                            hum.AutoRotate = false
                                        end
                                    end
                                    char.HumanoidRootPart.CFrame = GetFrameCFrame(recordingToPlay[1])
                                    task.wait(0.1)
                                end
                            end)
                            
                            continue
                        else
                            task.wait(AUTO_LOOP_RETRY_DELAY)
                            continue
                        end
                    else
                        local manualRespawnWait = 0
                        local maxManualWait = 30
                        
                        while not IsCharacterReady() and AutoLoop and IsAutoLoopPlaying do
                            manualRespawnWait = manualRespawnWait + 0.5
                            if manualRespawnWait >= maxManualWait then
                                break
                            end
                            task.wait(0.5)
                        end
                        
                        if not AutoLoop or not IsAutoLoopPlaying then break end
                        if not IsCharacterReady() then
                            break
                        end
                        
                        RestoreFullUserControl()
                        task.wait(0.5)
                        
                        currentFrame = 1
                        playbackStartTime = tick()
                        lastPlaybackState = nil
                        lastStateChangeTime = 0
                        loopAccumulator = 0
                        
                        SaveHumanoidState()
                        continue
                    end
                end
                
                SafeCall(function()
                    local char = player.Character
                    if not char or not char:FindFirstChild("HumanoidRootPart") then
                        task.wait(0.5)
                        return
                    end
                    
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if not hum or not hrp then
                        task.wait(0.5)
                        return
                    end
                    
                    local deltaTime = task.wait()
                    loopAccumulator = loopAccumulator + deltaTime
                    
                    if loopAccumulator >= PLAYBACK_FIXED_TIMESTEP then
                        loopAccumulator = loopAccumulator - PLAYBACK_FIXED_TIMESTEP
                        
                        local currentTime = tick()
                        local effectiveTime = (currentTime - playbackStartTime) * CurrentSpeed
                        
                        local targetFrame = currentFrame
                        for i = currentFrame, #recordingToPlay do
                            if GetFrameTimestamp(recordingToPlay[i]) <= effectiveTime then
                                targetFrame = i
                            else
                                break
                            end
                        end
                        
                        currentFrame = targetFrame
                        
                        if currentFrame >= #recordingToPlay then
                            playbackCompleted = true
                        end
                        
                        if not playbackCompleted then
                            local frame = recordingToPlay[currentFrame]
                            if frame then
                                -- ⭐ HYBRID: Apply frame directly
                                ApplyFrameDirect(frame)
                            end
                        end
                    end
                end)
                
                if playbackCompleted then
                    break
                end
            end
            
            RestoreFullUserControl()
            lastPlaybackState = nil
            lastStateChangeTime = nil
            
            if playbackCompleted then
                PlaySound("Success")
                CheckIfPathUsed(recordingNameToPlay)
                
                local isLastRecording = (CurrentLoopIndex >= #RecordingOrder)
                
                if AutoReset and isLastRecording then
                    ResetCharacter()
                    local success = WaitForRespawn()
                    if success then
                        task.wait(0.5)
                    end
                end
                
                CurrentLoopIndex = CurrentLoopIndex + 1
                if CurrentLoopIndex > #RecordingOrder then
                    CurrentLoopIndex = 1
                    
                    if AutoLoop and IsAutoLoopPlaying then
                        IsLoopTransitioning = true
                        task.wait(LOOP_TRANSITION_DELAY)
                        IsLoopTransitioning = false
                    end
                end
                
                if not AutoLoop or not IsAutoLoopPlaying then break end
            else
                if not AutoLoop or not IsAutoLoopPlaying then
                    break
                else
                    CurrentLoopIndex = CurrentLoopIndex + 1
                    if CurrentLoopIndex > #RecordingOrder then
                        CurrentLoopIndex = 1
                    end
                    task.wait(AUTO_LOOP_RETRY_DELAY)
                end
            end
        end
        
        IsAutoLoopPlaying = false
        IsLoopTransitioning = false
        RestoreFullUserControl()
        lastPlaybackState = nil
        lastStateChangeTime = 0
        if PlayBtnControl then
            PlayBtnControl.Text = "PLAY"
            PlayBtnControl.BackgroundColor3 = Color3.fromRGB(59, 15, 116)
        end
        if LoopBtnControl then
            LoopBtnControl.Text = "Loop OFF"
            LoopBtnControl.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        end
        UpdatePlayButtonStatus()
    end)
end
