local flipp = require('flipp')
local get_decl_nodes = flipp._get_callable_declaration_nodes

---@diagnostic disable-next-line: undefined-field
local eq = assert.are.same

describe("flipp.get_decl_nodes", function()
  it("parses an empty string", function()
    eq({}, get_decl_nodes(""), "Should be empty")
  end)

  it("parses a declaration", function()
    eq(1, #get_decl_nodes("void foo();"))
  end)

  it("parses multiple declarations", function()
    eq(2, #get_decl_nodes("void foo(); int bar();"))
  end)

  it("ignores function definitions", function()
    eq(0, #get_decl_nodes("void foo(){}"))
  end)

  it("ignores non-callable declarations", function()
    eq(0, #get_decl_nodes("int a; char* v; std::vector<int> a;"))
  end)

  it("ignores pure virtual functions", function()
    eq(0, #get_decl_nodes("virtual void foo() = 0;"))
  end)

  it("parses constructor and destructor declarations", function()
    eq(1, #get_decl_nodes("class ClassA { ClassA(); };"))
    eq(1, #get_decl_nodes("class ClassA { ~ClassA(); };"))
  end)

  it("ignores defaulted and deleted constructors and destructors", function()
    eq(0, #get_decl_nodes("class ClassA { ClassA() = delete; };"))
    eq(0, #get_decl_nodes("class ClassA { ClassA() = default; };"))
    eq(0, #get_decl_nodes("class ClassA { ClassA() {}; };"))
    eq(0, #get_decl_nodes("class ClassA { ~ClassA() = default;};"))
  end)
end)
