slice = function()
    local setupDone = { 0 }
    local step      = { 0 }
    getAttr("RENDERER", "CURRENT", "setupDone", 0, setupDone)
    getAttr("RENDERER", "CURRENT", "step", 0, step)
    --print(setupDone[1], step[1])

    if setupDone[1] == 1 then
        return false
    end

    if step[1] == 0 then
        setAttr("RENDERER", "CURRENT", "step", 0, { step[1] + 1 })
        return true
    end
    
    local cameraPos = { 0, 0, 0 }
    getAttr("CAMERA", "HeightCamera", "POSITION", 0, cameraPos)
    local sceneHeight = cameraPos[2]
    
    --local sliceResult = {1, 1, 1, 1}
    --getBuffer("particleLib::Slice", 0, "VEC4", sliceResult)
    --print(":::::")
    --print(sliceResult[1], sliceResult[2], sliceResult[3], sliceResult[4])
    --print(":::::")
    
    local sliceResult = 0
    if     step[1] == 1 then
        sliceResult = 0.5
        setAttr("CAMERA", "HeightCamera1", "FAR", 0, { sceneHeight * sliceResult }) -- 0-0.5
        setAttr("CAMERA", "HeightCameraBot", "NEAR", 0, { sceneHeight * (1 - sliceResult) })
        
        setAttr("CAMERA", "HeightCamera3", "NEAR", 0, { sceneHeight * sliceResult }) -- 0.5-1
        setAttr("CAMERA", "HeightCameraBot3", "FAR", 0, { sceneHeight * sliceResult })
        --setAttr("RENDERER", "CURRENT", "height2", 0, { sceneHeight * sliceResult })
    elseif step[1] == 2 then
        sliceResult = 0.25
        setAttr("CAMERA", "HeightCamera1", "FAR", 0, { sceneHeight * sliceResult }) -- 0-0.25
        setAttr("CAMERA", "HeightCameraBot", "NEAR", 0, { sceneHeight * (1 - sliceResult) })
        
        setAttr("CAMERA", "HeightCamera2", "NEAR", 0, { sceneHeight * sliceResult }) -- 0.25-0.5
        setAttr("CAMERA", "HeightCamera2", "FAR", 0, { sceneHeight * 0.5 })
        setAttr("CAMERA", "HeightCameraBot2", "FAR", 0, { sceneHeight * (1 - sliceResult) })
        setAttr("CAMERA", "HeightCameraBot2", "NEAR", 0, { sceneHeight * 0.5 })
        --setAttr("RENDERER", "CURRENT", "height3", 0, { sceneHeight * sliceResult })
    elseif step[1] == 3 then
        sliceResult = 0.75
        setAttr("CAMERA", "HeightCamera3", "NEAR", 0, { sceneHeight * 0.5 }) -- 0.5-0.75
        setAttr("CAMERA", "HeightCamera3", "FAR", 0, { sceneHeight * sliceResult })
        setAttr("CAMERA", "HeightCameraBot3", "FAR", 0, { sceneHeight * (1 - sliceResult) })
        setAttr("CAMERA", "HeightCameraBot3", "NEAR", 0, { sceneHeight * 0.5 })
        
        setAttr("CAMERA", "HeightCamera4", "NEAR", 0, { sceneHeight * sliceResult }) -- 0.75-1
        setAttr("CAMERA", "HeightCameraBot4", "FAR", 0, { sceneHeight * (1 - sliceResult) })
        setAttr("RENDERER", "CURRENT", "setupDone", 0, { 1 })

        --setAttr("RENDERER", "CURRENT", "height1", 0, { sceneHeight * sliceResult })
        return false
    end

    setAttr("RENDERER", "CURRENT", "step", 0, { step[1] + 1 })
    return true
end
                --[[
                    if ~setupDone[1] then
                        print("Hello")
                        print(setupDone[1])
                        
                        setAttr("RENDERER", "CURRENT", "setupDone", 0, { 1 })
                        return false
                    else
                        return true
                    end
                    ]]