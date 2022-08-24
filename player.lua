Player = Object:extend()

function Player:new(n)
    self.n =  n
end

-- updates tetromino to fall or lock
function Player:update(dt)
    -- if self.obstructed then print(self.n) end
    if Player.obstructed then
        -- if the player is obstructed, keep trying to spawn
        self:TryNewPiece()
        -- print("trynewpiece from obstructed")
        return
    end
    -- self.piece.time_next_fall keeps track of how long until a piece should try to fall again
    -- self.piece.time_still keeps track of how long the piece hasn't fallen for
    -- self.piece locks if it is still for more than Locktime seconds
    if self.piece.time_still > Locktime then
        local rot = self.piece.rotation
        local row = self.piece.row
        local col = self.piece.col

        self.piece:erase() -- always gotta erase before checking collisions
        -- don't lock if the piece can still fall downwards
        if not self.piece:collides_at(row + 1, col, rot) then
            self.piece:mark()
            return
        end

        -- from henceforth, the piece is locked

        -- check if piece landed by spinning
        -- spin doesn't count if it only happened becuase player got sandwiched by other player
        if self.n == 1 and P2.piece then P2.piece:erase() end
        if self.n == 2 and P1.piece then P1.piece:erase() end
        if      self.piece:collides_at(row - 1, col, rot) -- couldn't arrive by falling
            and self.piece:collides_at(row, col + 1, rot) -- couldn't arrive by moving left
            and self.piece:collides_at(row, col - 1, rot) -- couldn't arrive by moving right
            and self.piece.justspun  -- and the last action the piece did was spin
            then
            if Event[2].yes == true then
                Event[2].time = 0
            end
            Event[1].yes = true
            Event[1].mult = SPINPOINTMULT
            print("spin")
        end
        if self.n == 1 and P2.piece then P2.piece:mark() end
        if self.n == 2 and P1.piece then P1.piece:mark() end
        self.piece:mark()

        -- if piece locks, then player is able to use hold pieces again
        self.usedhold = false

        -- if it locks on to a player, then add the map to that player
        if self:onplayer() then
            self:givemap()
            -- eg if p1 lands on p2, then all tiles belonging to p1 now belong to p2
            -- so, don't need to p1:playererase() because is no longer any 1 on playerfield
        else
            -- if it isn't locked on to a player, then it must be on the ground
            -- so, try clearing rows
            self.piece:playererase()-- erase from the Playerfield because the piece is no longer under control
            TryRowClear()
        end
        
        self.piece = nil   -- player has no piece
        self.ghost = nil   -- gotta remove the ghost, too
        self:TryNewPiece() -- try to give player a new piece
    elseif self.piece then
        self.piece.time_still = self.piece.time_still + dt
        if not self.piece.landed then
            self.piece.time_still = 0
        end
        if self.piece.time_next_fall > 0 then
            self.piece.time_next_fall = self.piece.time_next_fall - self.piece.speed * dt
        -- if it is time to fall, then try falling. If it falls, then timers need to reset to account for movement
        elseif self.piece:fall() then
            self.piece.time_next_fall = Falltime

            -- also gotta update the ghosts
            P1:make_ghost()
            P2:make_ghost()
        end
    end
end


-- checks if a player is on top of another player
function Player:onplayer()
    local me = self.n
    if me == 1 and not P2.piece then return end
    if me == 2 and not P1.piece then return end
    return ForMapOccupiesDo(self.piece.map[self.piece.rotation], self.piece.col, self.piece.row, function(x, y)
        if y >= FIELDHEIGHT then return end
        local underme = Playerfield[y + 1][x]
        if underme ~= " "          -- if there is a player under me
            and underme ~= me then -- and the player is not me
            return true            -- then i am on another player
        end
    end)
end

-- gives its map to the other player
function Player:givemap()
    local otherp
    if self.n == 1 then otherp = 2
    elseif self.n == 2 then otherp = 1 end

    -- set all of its blocks to belong to the other player
    ForMapOccupiesDo(self.piece.map[self.piece.rotation], self.piece.col, self.piece.row, function(x, y)
        Playerfield[y][x] = otherp
    end)

    -- makes other player remap to incorperate the new blocks
    -- also resets other player's fall time and lock time so they have time to react to this
    if self.n == 1 then
        P2:remap()
        P2.piece.time_next_fall = Falltime
        P2.piece.still_time = 0
    end
    if self.n == 2 then
        P1:remap()
        P1.piece.time_next_fall = Falltime
        P1.piece.still_time = 0
    end
end

-- rechecks the playerfield for tiles belonging to the player, then updates map for tiles
function Player:remap()
    Debug:printfields("beginning remap")
    -- find outer bounds for the new shape
    local xmost = 0
    local xleast = FIELDWIDTH
    local ymost = 1
    local yleast = FIELDHEIGHT
    ForMapOccupiesDo(Playerfield, 1, 1, function(x, y, block)
        if block == self.n then
            if x > xmost then xmost = x end
            if x < xleast then xleast = x end
            if y > ymost then ymost = y end
            if y < yleast then yleast = y end
        end
    end)

    -- if no bounds are found, then there must be no tiles for the player
    -- so, player needs to try getting a new piece
    if xmost == 0 then
        Player:TryNewPiece()
    end

    local width = xmost - xleast + 1
    local height = ymost - yleast + 1

    -- make a map for player stuff within the bounds
    local map = {}
    local index = 0
    for y=yleast, ymost do
        index = index + 1
        table.insert(map, {})
        for x=xleast, xmost do
            if Playerfield[y][x] == " " then
                table.insert(map[index], " ")
            else
                table.insert(map[index], Field[y][x])
            end
        end
    end

    -- rotates table 'a' clockwise
    local function rotate(a)
        local b = {}
        local ilen = #a[1]
        local jlen = #a
        for i = 1, ilen do
            table.insert(b, {})
            for j = 1, jlen do
                b[i][j] = a[jlen - j + 1][i]
            end
        end
        return b
    end

    -- ensure map is horizontal
    local rotation = 5
    if height > width then
        map = rotate(map)
        rotation = rotation - 1

        local temp = width
        width = height
        height = temp
    end

    -- see if current map is top or bottom-heavy.
    local to_mid = math.floor(height * 0.5)
    local wtop = 0     --weight of top half
    local wbottom = 0  --weight of bottom half
    for i = 1, to_mid do
        -- counts blocks in top half, starting from top
        for j,v in pairs(map[i]) do
            if v ~= " " then
                wtop = wtop + 1
            end
        end
        -- counts blocks in bottom half, starting from bottom
        for j,v in pairs(map[height - (i -1)]) do
            if v ~= " " then
                wbottom = wbottom + 1
            end
        end
    end
    local upsidedown = false
    if wtop < wbottom then
        upsidedown = true
        rotation = rotation - 2
    end

    -- add padding to map to make it square
    local pad_total = width - height
    local pad_top
    -- padding errs towards less padding on heavier half
    if upsidedown then
        pad_top = math.ceil(pad_total * 0.5)
    else
        pad_top = math.floor(pad_total * 0.5)
    end
    local pad_bottom = pad_total - pad_top

    -- make a padding row
    local padding = {}
    for i=1, width do table.insert(padding, " ") end

    -- insert padding to top and bottom of map
    for i=1, pad_bottom do table.insert(map, padding) end
    for i=1, pad_top do table.insert(map, 1, padding) end

    -- rotation time (create a list of all map rotations)
    local complete_maps = {}

    for i = 1, 4 do
        if rotation == 5 then rotation = 1 end -- loops back to 1 if goes past 4
        local n = rotation + 1     -- next map
        if n == 5 then n = 1 end   -- also loop back if it goes past 4
        complete_maps[n] = rotate(complete_maps[rotation])
        rotation = rotation + 1
    end
    rotation = rotation + 1
        
    Debug:printmaps(complete_maps)
    print("rotation before remap: "..self.piece.rotation)

    -- update player with new data
    self.piece.width = width
    self.piece.row = yleast - pad_top
    self.piece.col = xleast

    self.piece.rotation = rotation
    self.piece.map = complete_maps
    print("after remap: "..self.piece.rotation)

    self.maxkick = math.ceil(width * 0.5)
    self.piece:findkickmaps()
    self:make_ghost()
    Debug:printfields()
end

function Player:TryNewPiece()
    -- checks if new piece can spawn. If it can't, then don't do anything
    -- print(self.n..": trying piece")
    if not CanSpawn(Maps[Queue.pieces[1]], self.n) then
        -- print("ljkdfsn")
        Player.obstructed = true
        -- print("obstructed from canspawn")
        return
    end

    -- new piece spawns 
    -- print("spawning piece")
    Player.obstructed = false
    self.piece = Tetromino(Maps[Queue:next()], self.n)
    self.piece:mark()
    -- don't forget to make a ghost
    self:make_ghost()
end

-- checks to see if a map of a tetromino can spawn
function CanSpawn(map, player)
    local check = Tetromino(map, player)
    if check.obstructed then
        -- print("canspawn obstructed")
        return false
    end
    return true
end

-- clears rows if they are filled, even if tiles belong to the other player
function TryRowClear()
    local fullrows = {}
    local deletedplayer
    for i = 1, FIELDHEIGHT do
        -- if a row is full of blocks, then keep track of it
        local count = FIELDWIDTH
        for j,block in pairs(Field[i]) do
            if block ~= " " then
                count = count - 1
                if not deletedplayer then 
                    local tileplayer = Playerfield[i][j]
                    if tileplayer ~= " " then deletedplayer = tileplayer end
                end
            end
        end
        if count == 0 then
            table.insert(fullrows, i)
        end
    end

    local linescleared = #fullrows
    -- if there are no full rows, then don't do anything
    if linescleared < 1 then
        return
    end

    -- make an empty row for adding to the field
    local emptyrow = {}
    for i = 1, FIELDWIDTH do
        table.insert(emptyrow, " ")
    end

    -- remove full rows and add new rows for each one removed
    for i,v in pairs(fullrows) do
        table.remove(Field, v)
        table.insert(Field, 1, emptyrow)
        table.remove(Playerfield, v)
        table.insert(Playerfield, 1, emptyrow)
    end

    -- if other player got deleted with the rows, update their map to reflect that
    if deletedplayer == 1 then P1:remap()
    elseif deletedplayer == 2 then P2:remap() end

    -- if 4+ lines are cleared, then do a fun tetris effect
    if linescleared > 3 then
        if Event[2].yes == true then
            Event[2].time = 0
        end
        Event[2].yes = true
        print("tetris")
    end

    -- check for full clear
    local fullclear_mult = 8
    for i,v in pairs(Field) do
        for j,block in pairs(v) do
            if block ~= " " then
                fullclear_mult = 1
            end
        end
    end
    -- effect for full clear (it's the same effect as tetris)
    if fullclear_mult == 8 then
        if Event[2].yes == true then
            Event[2].time = 0
        end
        Event[2].yes = true
        print("full clear")
    end

    -- calculate points for lines (no multipliers yet), more lines more points/line
    local lines_points = 100 
    for i=1, linescleared-1 do
        lines_points = lines_points + LINEPOINTMULT* i
    end
    -- calculate total points (includes multipliers)
    Score.points = Score.points + (lines_points * (Score.level + 1) * Event[1].mult * fullclear_mult)

    -- resets multiplier for spins
    Event[1].mult = 1

    -- keep track of lines cleared
    Score.lines = Score.lines + linescleared

    -- keep track of level and falltime
    while linescleared > 0 do
        Score.tonextlevel = Score.tonextlevel - linescleared
        
        if Score.tonextlevel <= 0 then
            linescleared = -Score.tonextlevel
            Score.level = Score.level + 1
            Score.tonextlevel = (Score.level + 1) * 10

            -- adjust fall and lock times to level
            if Score.level < 20 then
                Falltime = Falltime * 0.8
            elseif Score.level < 30 then
                Locktime = Locktime * 0.9
            end
        else
            linescleared = 0
        end
    end
end


-- make a player.ghost for a player (shows where their piece falls)
--  ghost should be updated when piece spawns or moves
function Player:make_ghost()
    -- if there isn't a piece, then you can't make a ghost for it, dumbass
    if not self.piece then return end

    -- erase piece so it doesn't interfere with ghost
    self.piece:erase()

    local ghost = {}
    ghost.map = self.piece.map[self.piece.rotation]
    ghost.y = self.piece.row
    ghost.x = self.piece.col

    -- move ghost downwards until it can't anymore (would collide if it moved further down)
    while not ForMapOccupiesDo(ghost.map, ghost.x, ghost.y + 1, function(x, y)
        if not Field[y] or Field[y][x] ~= " " then
            return true
        end
    end) do
        ghost.y = ghost.y + 1
    end

    -- the ghost is complete. return it.
    self.ghost = ghost

    -- mark piece now that ghost is found
    self.piece:mark()
end

-- renders a ghost
function Player:render_ghost(colors, blocksize)
    if self.piece and self.ghost then
        ForMapOccupiesDo(self.ghost.map, self.ghost.x, self.ghost.y, function(x, y, block)
            love.graphics.setColor(colors[block])
            love.graphics.rectangle("fill", x * blocksize, y * blocksize, blocksize, blocksize)
        end)
    end
end