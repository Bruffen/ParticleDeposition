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

    if a > c then c = a else a = c end

    local cameras = { "HeightCamera", "HeightCamera1", "HeightCamera2", "HeightCamera3", "HeightCamera4",
    "HeightCameraBot1", "HeightCameraBot2", "HeightCameraBot3", "HeightCameraBot4"}
    
    local left  = -a / 2
    local right =  a / 2
    local bottom= -c / 2
    local top   =  c / 2
    local far = b
    local position = { bb_center[1] * scale[1], bb_max[2] * scale[2], bb_center[3] * scale[3] }

    setAttr("CAMERA", "HeightCamera", "LEFT"    , 0, { left })
    setAttr("CAMERA", "HeightCamera", "RIGHT"   , 0, { right })
    setAttr("CAMERA", "HeightCamera", "BOTTOM"  , 0, { bottom })
    setAttr("CAMERA", "HeightCamera", "TOP"     , 0, { top })
    setAttr("CAMERA", "HeightCamera", "FAR"     , 0, { far })
    setAttr("CAMERA", "HeightCamera", "POSITION", 0, position)

    setAttr("RENDERER", "CURRENT", "radius", 0, { a })
    
    local marching_step = { 0 }
    local marching_maxd = { 0 }
    
    marching_maxd[1] = math.sqrt( a*a + c*c ) 
    marching_step[1] = marching_maxd[1] / 1000
    setAttr("RENDERER", "CURRENT", "marchingStep", 0, { marching_step[1] })
    setAttr("RENDERER", "CURRENT", "marchingMax" , 0, { marching_maxd[1] })
    
    print(a, b, c, volume)
    print(marching_step[1], marching_maxd[1])
    --print("BB_MAX: ", unpack(bb_max))
end
