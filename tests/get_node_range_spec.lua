local flipp = require('flipp')
local get_decl_nodes = flipp._get_callable_declaration_nodes
local get_node_range = flipp._get_node_range

---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("flipp.get_node_range", function()
  it("fails when given a nil node", function()
    assert(not pcall(get_node_range, nil, ""))
  end)

  it("parses a single line node", function()
    local source = "void foo();"
    ---@type flipp.Range
    local range = {
      ["start"] = { line = 0, character = 0 },
      ["end"] = { line = 0, character = 10 }
    }
    eq(range, get_node_range(get_decl_nodes(source)[1], source))
  end)

  it("parses a multi-line node", function()
    local source = "void \nfoo();"
    ---@type flipp.Range
    local range = {
      ["start"] = { line = 0, character = 0 },
      ["end"] = { line = 1, character = 5 }
    }
    eq(range, get_node_range(get_decl_nodes(source)[1], source))
  end)
end)
