require "Cocos2d"
local _ = require "moses"
local Drop = require "Drop"

-- パズルのクラス
local Puzzle = class("Puzzle", {})
function Puzzle:ctor(numRows, numCols, numColors)
    self.numRows = numRows
    self.numCols = numCols
    self.numColors = numColors
    local drops = {}
    for i=1, numRows do
        local row = {}
        for j=1, numCols do
            local drop = Drop.createRandom(numColors, i, j)
            row[j] = drop
        end
        drops[i] = row
    end
    assert(drops,"ドロップがある")
    self.drops = drops
end
function Puzzle:eachDrop(callback)
    _.each(self.drops, function(i,r)
        _.each(r, function(j,c)
            callback(c,i,j)
        end)
    end)
end
function Puzzle:getRow(r)
    return _.map(_.range(1,self.numCols), function(i)
        return self.drops[r][i]
    end)
end
function Puzzle:getRows()
    return _.map(_.range(1,self.numRows), function(i)
        return self:getRow(i)
    end)
end
function Puzzle:getColumn(c)
    return _.map(_.range(1,self.numRows), function(i)
        return self.drops[i][c]
    end)
end
function Puzzle:getColumns()
    return _.map(_.range(1,self.numCols), function(i)
        return self:getColumn(i)
    end)
end
-- パズルの中の3マッチを取得する
function Puzzle:get3Matches()
    --[[
        Phase1: まず隣接を無視してパズル中にあるすべての3マッチを抽出する
    ]]
    local ret = {}
    local rowAndCols = _.append(self:getRows(), self:getColumns())
    local allMatches = {}
    for i, v in ipairs(rowAndCols) do
        -- 各行or列を先頭から順に観ていき、同じ色が３つ以上続くかをカウントする
        local prev = v[1]
        local loc, len = -1, 1
        for i=2, #v do
            local cur = v[i]
            if _.isEqual(cur.color, prev.color) then
                if loc < 0 then
                    loc = i-1
                end
                len = len+1
            else
                -- この時点で３つ以上連続が続いていたら結果にpushする
                if len >= 3 then
                    local match = _.slice(v, loc, loc+len-1)
                    _.push(allMatches, match)
                end
                loc, len = -1, 1
            end
            prev = cur
        end
        if len >= 3 then
            local match = _.slice(v, loc, loc+len-1)
            _.push(allMatches, match)
        end
    end
    if #allMatches == 0 then return end
    --[[
        Phase2: 抽出した3マッチから隣接しているマッチをまとめる
    ]]
    -- マッチが他のマッチと隣接しているかを判定する関数
    local function contacts(m1, m2)
        --[[
            隣接の条件:
                1: 互いの色が同じ
                2: 1つ以上のドロップが隣接している
                    ⇔ 行と列が同じ or 行が同じで列が1つ違い or 列が同じで行が1つ違い
        ]]
        -- 1の判定
        if not (m1[1].color == m2[1].color) then return false end
        -- 2の判定
        for i, v in ipairs(m1) do
            for j, w in ipairs(m2) do
                local s = math.abs(v.row-w.row) + math.abs(v.col-w.col)
                if s == 0 or  s == 1 then
                    return true
                end
            end
        end
        return false
    end
    --[[
        隣接をまとめるアルゴリズム
        1: まずすべての3マッチを先頭から順番に同じ色でソートする
            Ex:) {r,g,b,r,r,b,g}
                -> {r,r,r,g,g,b,b}
        2: 次に連続した3マッチをまとめる
            Ex:) {r,r,r,g,g,b,b}
                -> {{r,r,r},{g,g},{b,b}}
        3: 各色の和集合をとる
        4: 重複のないドロップの集合ができる
    ]]
    local loc = 1
    local seqs = {}
    -- 1
    repeat
        local m = allMatches[loc]
        local contacted = {}
        for i=loc+1, #allMatches do
            local n = allMatches[i]
            if contacts(m,n) then
                _.push(contacted, i)
            end
        end
        -- 隣接したマッチを上に寄せる
        for i,v in ipairs(contacted) do
            local tmp = allMatches[v]
            table.remove(allMatches,v)
            table.insert(allMatches,loc+i,tmp)
        end
        _.push(seqs, {s = loc, e = loc+#contacted})
        loc = loc + 1 + #contacted
    until loc > #allMatches
    -- 2 ~ 4
    for i, v in ipairs(seqs) do
        local u = _.chain(allMatches)
                    :slice(v.s, v.e)
                    :flatten(true)
                    :map(function(i,v)
                        return {row = v.row, col = v.col}
                    end)
                    :uniq()
                    :each(function(d)
                        d.isHidden = true
                    end)
                    :value()
        _.push(ret, u)
    end
    return ret
end
-- ドロップを入れ替える
function Puzzle:swap(row1, col1, row2, col2)
    local a, b = self.drops[row1][col1], self.drops[row2][col2]
    a.color, b.color = b.color, a.color
end
function Puzzle:debug()
    _.each(_.reverse(self:getRows()), function(i, row)
        local s = _.reduce(row, function(memo, v)
            if _.isEqual(v.color, Drop.COLORS.red) then
                memo = memo .. "r"
            elseif _.isEqual(v.color, Drop.COLORS.green) then
                memo = memo .. "g"
            elseif  _.isEqual(v.color, Drop.COLORS.blue) then
                memo = memo .. "b"
            elseif  _.isEqual(v.color, Drop.COLORS.yellow) then
                memo = memo .. "y"
            elseif  _.isEqual(v.color, Drop.COLORS.purple) then
                memo = memo .. "p"
            end
            return memo
        end, "")
        print(s)
    end)
    print("-----")
end

return Puzzle