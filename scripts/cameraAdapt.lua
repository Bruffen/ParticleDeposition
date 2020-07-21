adapt = function()
    local bb_center = {0, 0, 0}
    local bb_max    = {0, 0, 0}
    local bb_min    = {0, 0, 0}

    getAttr("SCENE", "camoes", "BB_CENTER", 0, bb_center)
    getAttr("SCENE", "camoes", "BB_MAX", 0, bb_max)
    getAttr("SCENE", "camoes", "BB_MIN", 0, bb_min)
    print(bb_center[0])
    print(bb_max[0])
    print(bb_min[0])
    --print("BB_MAX: ", unpack(bb_max))
end