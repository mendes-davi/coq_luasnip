# coq_luasnip

[luasnip](https://github.com/L3MON4D3/LuaSnip) completion source for [coq_nvim](https://github.com/ms-jpq/coq_nvim)

```lua
-- Installation
use { 'L3MON4D3/LuaSnip' }

-- coq
use {
  'ms-jpq/coq_nvim',
  setup = function ()
    vim.g.coq_settings = {
      keymap = {
          jump_to_mark = "", -- no jump_to_mark mapping
      },
      clients = {
          snippets = { enabled = false }, -- disable coq snippets
      },
    }
  end
}

use { 'mendes-davi/coq_luasnip' }
```

# Thanks to

[saadparwaiz1/cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) for the most part of the
code
