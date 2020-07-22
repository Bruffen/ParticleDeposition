-- Put here the scene with the biggest bounding box
scene = "camoes"

adapt = function()
    local bb_center = {0, 0, 0}
    local bb_max    = {0, 0, 0}
    local bb_min    = {0, 0, 0}
    local scale     = {0, 0, 0}

    getAttr("SCENE", scene, "BB_CENTER", 0, bb_center)
    getAttr("SCENE", scene, "BB_MAX", 0, bb_max)
    getAttr("SCENE", scene, "BB_MIN", 0, bb_min)
    getAttr("SCENE", scene, "SCALE", 0, scale)

    local a = (bb_max[1] - bb_min[1]) * scale[1];
    local b = (bb_max[2] - bb_min[2]) * scale[2];
    local c = (bb_max[3] - bb_min[3]) * scale[3];
    local volume = a * b * c;

    
    setAttr("CAMERA", "HeightCamera", "LEFT"    , 0, {-a / 2 })
    setAttr("CAMERA", "HeightCamera", "RIGHT"   , 0, { a / 2 })
    setAttr("CAMERA", "HeightCamera", "BOTTOM"  , 0, {-c / 2 })
    setAttr("CAMERA", "HeightCamera", "TOP"     , 0, { c / 2 })
    setAttr("CAMERA", "HeightCamera", "FAR"     , 0, { b })
    setAttr("CAMERA", "HeightCamera", "POSITION", 0, { bb_center[1] * scale[1], bb_max[2] * scale[2], bb_center[3] * scale[3]})

    setAttr("RENDERER", "CURRENT", "radius", 0, { b })

    print(a)
    print(b)
    print(c)
    print(volume)
    --print("BB_MAX: ", unpack(bb_max))
end