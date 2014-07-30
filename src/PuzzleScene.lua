require "Cocos2d"
require "Cocos2dConstants"
local _ = require "moses"
local Puzzle = require "Puzzle"
local Drop = require "Drop"

-- 定数
local UI_LAYER_TAG = 999
local PUZZLE_LAYER_TAG = 777
local DROP_LABEL_TAG = 666
local DROP_Z_ORDER = 1

-- パズルシーン
local PuzzleScene = class("PuzzleScene",function()
    return cc.Scene:create()
end)
-- ファクトリ
function PuzzleScene.create(numRows, numCols, numColors)
    local scene = PuzzleScene.new(numRows, numCols, numColors)
    assert(scene.puzzle,"パズルがある")
    local layer = scene:createPuzzleLayer()
    local menu = scene:createMenuLayer()
    layer:setTag(PUZZLE_LAYER_TAG)
    scene:addChild(layer)
    scene:addChild(menu, UI_LAYER_TAG)
    scene:reset()
    return scene
end
-- コンストラクタ
function PuzzleScene:ctor(numRows, numCols, numColors)
    self.puzzle = Puzzle.new(numRows, numCols, numColors)
    local vs = cc.Director:getInstance():getVisibleSize()
    self.dropRadius = vs.width/self.puzzle.numCols/2
    self.animating = false
end
-- レイヤーを作成
function PuzzleScene:createPuzzleLayer()
    local puzzleLayer = cc.Layer:create()
    -- パズル画面を構築する
    self.puzzle:eachDrop(function(drop,i,j)
        -- パズルのノードを追加
        local dropNode = cc.Sprite:create(drop:getSpriteName())
        dropNode:setAnchorPoint(0.5,0.5)
        local dr = self.dropRadius
        dropNode:setPosition((j-1)*dr*2 + dr, (i-1)*dr*2 + dr)
        dropNode:setTag(self:buildNodeTag(i,j))
        local label = cc.Label:createWithSystemFont("", "Arial", 18)
        label:setTag(DROP_LABEL_TAG)
        local s = dropNode:getContentSize()
        label:setPosition(s.width/2,s.height/2)
        dropNode:addChild(label)
        puzzleLayer:addChild(dropNode, DROP_Z_ORDER)
    end)
    -- 現在のドロップの行列座標
    local currentDrop = nil
    -- 移動中のドロップがいるエリアの中心
    local currentPivot = nil
    -- 現在移動させているノード
    local touchedNode = nil
    local function onTouchBegan(touch)
        if self.animating then return false end
        -- タッチの位置
        local loc = touch:getLocation()
        -- からマトリクス状の座標を取得
        local row = math.ceil(loc.y/self.dropRadius/2)
        local col = math.ceil(loc.x/self.dropRadius/2)
        -- print(string.format("touch at {%f, %f}",loc.x,loc.y))
        -- ノード上へのタッチでない場合は処理しない
        if row > self.puzzle.numRows or col > self.puzzle.numCols then return false end
        print(string.format("drop at {%i, %i}",row,col))
        local tag = self:buildNodeTag(row,col)
        local node = puzzleLayer:getChildByTag(tag)
        -- 他のノードの下に隠れないように
        node:setLocalZOrder(999)
        currentPivot = cc.p(node:getPosition())
        currentDrop = self.puzzle.drops[row][col]
        touchedNode = node
        return  true
    end
    local swapThresh = (self.dropRadius*3/2)^2
    local PI = math.pi
    local function onTouchMoved(touch)
        local loc = touch:getLocation()
        local dis = cc.pDistanceSQ(currentPivot,loc)
        touchedNode:setPosition(loc)
        if dis >= swapThresh then
            local v = cc.pNormalize(cc.pSub(loc,currentPivot))
            local atan = math.atan2(v.y,v.x)
            if atan < 0 then
                atan = atan + PI*2
            end
            local swap = {
                row = currentDrop.row,
                col = currentDrop.col
            }
            if (0 <= atan and atan < PI/4) or (PI*7/4 <= atan and atan < PI*2) then
                -- 右
                if not (currentDrop.col < self.puzzle.numCols) then return end
                swap.col = swap.col+1
                -- print("右")
            elseif PI/4 <= atan and atan < PI*3/4 then
                -- 上
                if not (currentDrop.row < self.puzzle.numRows) then return end
                swap.row = swap.row+1
                -- print("上")
            elseif PI*3/4 <= atan and atan < PI*5/4 then
                -- 左
                if not (1 < currentDrop.col) then return end
                swap.col = swap.col-1
                -- print("左")
            elseif PI*5/4 <= atan and atan < PI*7/4 then
                -- 下
                if not (1 < currentDrop.row) then return end
                swap.row = swap.row-1
                -- print("下")
            else
                print("不正な方向")
            end
            -- ノードの入替
            local swapTag = self:buildNodeTag(swap.row,swap.col)
            local swapNode = puzzleLayer:getChildByTag(swapTag)
            local swapPos = cc.p(swapNode:getPosition())
            -- アニメーションさせる
            swapNode:runAction(cc.MoveTo:create(0.1,currentPivot))
            -- ノードのタグも入れ替える
            swapNode:setTag(touchedNode:getTag())
            touchedNode:setTag(swapTag)
            -- パズルの入れ替え
            self.puzzle:swap(currentDrop.row, currentDrop.col, swap.row, swap.col)
            -- ピボットと
            currentPivot = swapPos
            currentDrop = self.puzzle.drops[swap.row][swap.col]
        else
        end
    end
    local function onTouchEnded(touch)
        touchedNode:setPosition(currentPivot)
        touchedNode:setLocalZOrder(DROP_Z_ORDER)
        currentDrop = nil
        touchedNode = nil
        currentPivot =
        self:render()
        self:crushMathes()
    end
    -- タッチイベントをバインド
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN)
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED)
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED)
    local ed = puzzleLayer:getEventDispatcher()
    ed:addEventListenerWithSceneGraphPriority(listener, puzzleLayer)
    return puzzleLayer
end
-- Getter for Layer
function PuzzleScene:getPuzzleLayer()
    return self:getChildByTag(PUZZLE_LAYER_TAG)
end
-- メニューを作る
function PuzzleScene:createMenuLayer()
    local renderButton = cc.MenuItemFont:create("Render")
    renderButton:registerScriptTapHandler(function()
        self:render()
    end)
    local crushButton = cc.MenuItemFont:create("Crush")
    crushButton:registerScriptTapHandler(function()
        self:crushMathes()
    end)
    local resetButton = cc.MenuItemFont:create("Shuffle")
    resetButton:registerScriptTapHandler(function()
        self:reset()
    end)
    local menu = cc.Menu:create(resetButton, renderButton, crushButton)
    menu:alignItemsHorizontallyWithPadding(15)
    local vs = cc.Director:getInstance():getVisibleSize()
    menu:setPosition(vs.width*0.5, vs.height*0.9)
    return menu
end
function PuzzleScene:reset()
   self.puzzle = Puzzle.new(self.puzzle.numRows, self.puzzle.numCols, self.puzzle.numColors)
   self:render()
end
-- パズルを描画
function PuzzleScene:render()
    local layer = self:getChildByTag(PUZZLE_LAYER_TAG)
    local rad = 10
    local db = layer:getChildByTag(222)
    if not db then
        db = cc.DrawNode:create()
        local vs = cc.Director:getInstance():getVisibleSize()
        db:setPosition(30, vs.height*0.7)
        layer:addChild(db)
    end
    self.puzzle:eachDrop(function(drop, i, j)
        local c = nil
        if drop.color == "red" then c = cc.c4f(1,0,0,1)
        elseif drop.color == "blue" then c = cc.c4f(0,0,1,1)
        elseif drop.color == "green" then c = cc.c4f(0,1,0,1)
        elseif drop.color == "purple" then c = cc.c4f(1,0,1,1)
        elseif drop.color == "yellow" then c = cc.c4f(1,1,0,1)
        end
        db:drawDot(cc.p((j-1)*rad*2, (i-1)*rad*2), rad, c)
        local node = layer:getChildByTag(self:buildNodeTag(i,j))
        local drop = self.puzzle.drops[i][j]
        node:getChildByTag(DROP_LABEL_TAG):setString(tostring(node:getTag()))
        node:setOpacity(255)
        local t = cc.TextureCache:getInstance():getTextureForKey(drop:getSpriteName())
        node:setTexture(t)
    end)
    -- self.puzzle:debug()
    return self
end
-- ３マッチを消す
function PuzzleScene:crushMathes()
    local matches = self.puzzle:get3Matches()
    if #matches == 0 then return end
    for i, match in ipairs(matches) do
        local s = _.reduce(match, function(memo, v)
            memo = memo .. string.format("{(%i,%i) = %i} ", v.row, v.col, self:buildNodeTag(v.row,v.col))
            return memo
        end, "[") .. "]"
        print(s)
    end
    print("----")
    self.animating = true
    _.each(matches, function (i, match)
        _.chain(match)
            :map(function(j,d)
                return self:buildNodeTag(d.row,d.col)
            end)
            :each(function(j,tag)
                local dropNode = self:getPuzzleLayer():getChildByTag(tag)
                local act = cc.Sequence:create(cc.DelayTime:create((i-1)), cc.FadeOut:create(0.5))
                dropNode:runAction(act)
                if i == #matches then self.animating = false end
            end)
    end)
end
-- タグを生成する
function PuzzleScene:buildNodeTag(row, col)
    return self.puzzle.numCols*row + col
end
return PuzzleScene