**flipp.nvim** provides function and method definition generatators for cpp

[Features](#✨-features ) • [Requirements](#📋-requirements) • [Installation](#🔧-installation)

![demo](./demo/demo.gif)

# ✨ Features 

* Generate signatures for definitions of function and method declarations
* Detect declarations that already have definitions and filter from being generated

# 📋 Requirements 

* Neovim >= **v0.5.0**
    * Treesitter cpp parser
* clangd >= **v9.0.0**

# 🔧 Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
    "williamtrojniak/flipp.nvim",
    version = "*"
}

```
