Field = Object:extend()

-- creates a field of height, width, and type (what values it may contain)
function Field:new(type)
    self.type = type

    self.height = FIELDHEIGHT
    self.width = FIELDWIDTH

    self.field = {}
    for i = 1, FIELDHEIGHT do
        table.insert(self.field, {})
    end
    self:clear()
end

-- sets everything to " "
function Field:clear()
    for i = 1, self.height do
        for j = 1, self.width do
            self.field[i][j] = " "
        end
    end
end

-- sets a row, col to specified value
function Field:set(row, col, val)
    if val ~= ' ' then
        if self.type == 'player' then
            assert(val == 1 or val == 2, 'error setting '..val..', field player')
        end
        if self.type == 'tetromino' then
            assert(val ~= 1 and val ~= 2, 'error setting '..val..', field tetromino')
        end
    end
    self.field[row][col] = val
end