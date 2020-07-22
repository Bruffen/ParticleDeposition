slice = function()
    local setupDone = { 0 }
    local step      = { 0 }
    getAttr("RENDERER", "CURRENT", "setupDone", 0, setupDone)
    getAttr("RENDERER", "CURRENT", "step", 0, step)

    print(step[1])
    if step[1] == 0 then
        setAttr("RENDERER", "CURRENT", "step", 0, { step[1] + 1 })
        return true
    end

    local sliceResult = {1, 1, 1, 1}
    getAttr("BUFFER_MATERIAL", "DIM", "particleLib::Slice", 0, sliceResult)
    print(":::::")
    print(sliceResult[1])
    print(sliceResult[2])
    print(sliceResult[3])
    print(sliceResult[4])
    print(":::::")

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