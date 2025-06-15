local flipp = require('flipp')
local is_intersect = flipp._is_range_intersect

---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("flipp.range_intersect", function()
  it("errors when given a nil or incomplete value", function()
    ---@diagnostic disable-line
    assert(not pcall(is_intersect, nil, nil))
    ---@diagnostic disable-line
    assert(not pcall(is_intersect, {}, nil))
    ---@diagnostic disable-line
    assert(not pcall(is_intersect, nil, {}))
    ---@diagnostic disable-line
    assert(not pcall(is_intersect, {}, {}))
  end)

  it("intersects two non-block ranges on the same line", function()
    ---@type flipp.Range
    local r1 = {
      ["start"] = { line = 0, character = 0 },
      ["end"] = { line = 0, character = 5 }
    }
    ---@type flipp.Range
    local r2 = {
      ["start"] = { line = 0, character = 1 },
      ["end"] = { line = 0, character = 3 }
    }
    ---@type flipp.Range
    local r3 = {
      ["start"] = { line = 0, character = 0 },
      ["end"] = { line = 0, character = 2 }
    }
    ---@type flipp.Range
    local r4 = {
      ["start"] = { line = 0, character = 2 },
      ["end"] = { line = 0, character = 4 }
    }
    ---@type flipp.Range
    local r5 = {
      ["start"] = { line = 0, character = 8 },
      ["end"] = { line = 0, character = 10 }
    }
    assert(is_intersect(r1, r2))
    assert(is_intersect(r2, r3))
    assert(is_intersect(r2, r4))
    assert(is_intersect(r3, r4))
    assert(not is_intersect(r4, r5))
  end)

  it("intersects two non-block ranges on different lines", function()
    ---@type flipp.Range
    local r1 = {
      ["start"] = { line = 0, character = 5 },
      ["end"] = { line = 0, character = 4 }
    }
    ---@type flipp.Range
    local r2 = {
      ["start"] = { line = 0, character = 1 },
      ["end"] = { line = 1, character = 3 }
    }
    ---@type flipp.Range
    local r3 = {
      ["start"] = { line = 2, character = 0 },
      ["end"] = { line = 2, character = 2 }
    }
    assert(is_intersect(r1, r2))
    assert(not is_intersect(r2, r3))
  end)

  it("intersects two block ranges on different lines", function()
    ---@type flipp.Range
    local r1 = {
      ["start"] = { line = 0, character = 0 },
      ["end"] = { line = 3, character = 4 },
      block = true
    }
    ---@type flipp.Range
    local r2 = {
      ["start"] = { line = 1, character = 1 },
      ["end"] = { line = 5, character = 5 },
      block = true
    }
    ---@type flipp.Range
    local r3 = {
      ["start"] = { line = 0, character = 4 },
      ["end"] = { line = 3, character = 7 },
      block = true
    }
    ---@type flipp.Range
    local r4 = {
      ["start"] = { line = 0, character = 5 },
      ["end"] = { line = 3, character = 7 },
      block = true
    }
    ---@type flipp.Range
    local r5 = {
      ["start"] = { line = 1, character = 2 },
      ["end"] = { line = 4, character = 4 },
      block = true
    }
    assert(is_intersect(r1, r2))
    assert(is_intersect(r1, r3))
    assert(not is_intersect(r1, r4))
    assert(not is_intersect(r4, r5))
  end)


  it("intersects one block range with a block range", function()
    ---@type flipp.Range
    local r1 = {
      ["start"] = { line = 1, character = 0 },
      ["end"] = { line = 3, character = 4 },
      block = true
    }
    ---@type flipp.Range
    local r2 = {
      ["start"] = { line = 1, character = 1 },
      ["end"] = { line = 5, character = 5 },
      block = false
    }
    ---@type flipp.Range
    local r3 = {
      ["start"] = { line = 0, character = 5 },
      ["end"] = { line = 0, character = 7 },
      block = false
    }
    ---@type flipp.Range
    local r4 = {
      ["start"] = { line = 0, character = 5 },
      ["end"] = { line = 1, character = 7 },
      block = false
    }
    local r5 = {
      ["start"] = { line = 1, character = 8 },
      ["end"] = { line = 5, character = 12 },
      block = true
    }
    ---@type flipp.Range
    local r6 = {
      ["start"] = { line = 0, character = 2 },
      ["end"] = { line = 12, character = 4 },
      block = false
    }
    assert(is_intersect(r1, r2))
    assert(not is_intersect(r1, r3))
    assert(is_intersect(r1, r4))
    assert(not is_intersect(r4, r5))
    assert(is_intersect(r5, r6))
  end)
end)
