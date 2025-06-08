local get_defs = require('flipp')._get_defs
local eq = assert.are.same

describe("treesitter cpp parser", function()
  it("should be installed", function()
    assert(require('flipp.text.treesitter').has_lang("cpp"))
  end)
end)

describe("flipp.get_defs", function()
  it("parses an empty string", function()
    eq({}, get_defs(""), "Should be empty")
  end)

  it("parses a declaration", function()
    eq({ "void foo() {}" }, get_defs("void foo();"))
  end)

  it("ignores function definitions", function()
    eq({}, get_defs("void foo(){}"))
  end)

  it("parses multiple declarations", function()
    eq({ "void foo() {}", "int bar() {}" }, get_defs("void foo(); int bar();"))
  end)

  it("parses methods returning pointers to pointers", function()
    eq({ "void **foo() {}", "int *const *bar() {}" }, get_defs("void **foo(); int *const *bar();"))
  end)

  it("parses methods returning references to references", function()
    eq({ "void &&foo() {}", "int &const &bar() {}" }, get_defs("void &&foo(); int &const &bar();"))
  end)

  it("removes 'virtual' and 'final' qualifiers", function()
    eq({ "void foo() {}", }, get_defs("virtual void foo();"))
    eq({ "void foo() {}", }, get_defs("void foo() final;"))
    eq({ "void foo() {}", }, get_defs("virtual void foo() final;"))
  end)

  it("ignores pure virtual functions", function()
    eq({}, get_defs("virtual void foo() = 0;"))
  end)

  it("removes 'static' qualifiers", function()
    eq({ "void foo() {}", }, get_defs("static void foo();"))
  end)

  it("keeps 'const' and 'noexcept' qualifiers", function()
    eq({ "void foo() const {}", }, get_defs("void foo() const;"))
    eq({ "void foo() noexcept {}", }, get_defs("void foo() noexcept;"))
    eq({ "void foo() const noexcept {}", }, get_defs("void foo() const noexcept;"))
  end)

  it("parses constructor and destructor declarations", function()
    eq({ "ClassA::ClassA() {}", }, get_defs("class ClassA { ClassA(); };"))
    eq({ "ClassA::~ClassA() {}", }, get_defs("class ClassA { ~ClassA(); };"))
  end)

  it("ignores defaulted and deleted constructors and destructors", function()
    eq({}, get_defs("class ClassA { ClassA() = delete; };"))
    eq({}, get_defs("class ClassA { ClassA() = default; };"))
    eq({}, get_defs("class ClassA { ClassA() {}; };"))
    eq({}, get_defs("class ClassA { ~ClassA() = default;};"))
  end)

  it("appends class namespace to methods", function()
    eq({ "void ClassA::foo() {}", }, get_defs("class ClassA { void foo(); };"))
  end)

  it("appends namespaces to methods", function()
    eq({ "void NamespaceA::foo() {}", }, get_defs("namespace NamespaceA { void foo(); };"))
  end)
end)
