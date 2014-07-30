require "Cocos2d"

-- ドロップのクラス
local Drop = class("Drop",{})
Drop.COLORS = {
    "red",
    "blue",
    "green",
    "purple",
    "yellow"
}
function Drop.create(color, row, col)
    return Drop.new(color, row, col)
end
function Drop.createRandom(numColors, row, col)
    -- ドロップの色
    local r = 1 + math.floor(math.random()*numColors)
    return Drop.create(Drop.COLORS[r], row, col)
end
function Drop:ctor(color, row, col)
    assert(color, "colorがない")
    assert(row, "rowがない")
    assert(col, "colがない")
    self.color = color
    self.row = row
    self.col = col
    self.isHidden = false
end
function Drop:getSpriteName()
    return "drop_"..self.color..".png"
end

return Drop