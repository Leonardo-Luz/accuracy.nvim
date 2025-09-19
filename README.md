## accuracy.nvim

*A Neovim Plugin for Accuracy Practice*

This plugin provides a practice tool inspired by `ThePrimeagen/vim-be-good` hjkl game.

**Features:**

* Tracks accuracy and statistics.
* Provides a dedicated interface for practice.

**Dependencies:**

* `leonardo-luz/floatwindow.nvim`

**Installation:**  Add `leonardo-luz/accuracy.nvim` to your Neovim plugin manager (e.g., `init.lua` or `plugins/accuracy.lua`).

```lua
{ 
    'leonardo-luz/accuracy.nvim',
    opts = {
        map_size = {
            x = 20, -- default: 20
            y = 10 -- default: 10
            -- tip: lock x in 1 and enable relative number to train jump
        },
    },
}
```

**Usage:**

* Start practicing with the command `:Accuracy`.
    * normal mode, `<ESC><ESC>` or `q`: Quit
    * normal mode, `x`: Check if cursor is in the correct position
