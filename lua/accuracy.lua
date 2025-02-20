local floatwindow = require("floatwindow")

local M = {}

local state = {
  streak = 0,
  target = {
    x = -1,
    y = -1,
  },
  correct = 0,
  wrong = 0,
  start_timer = 0,
  end_timer = 0,
  accuracy = 0,
  cpm = 0,
  map = {
    size = {
      x = 20,
      y = 10,
    },
  },
  window_config = {
    main = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
    footer = {
      floating = {
        buf = -1,
        win = -1,
      },
    },
  },
}

local create_window_config = function()
  local height = vim.o.lines
  local width = vim.o.columns

  return {
    main = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        width = state.map.size.x,
        height = state.map.size.y,
        col = math.floor((width - state.map.size.x) / 2),
        row = math.floor((height - state.map.size.y) / 2),
        border = { "#", "#", "#", "#", "#", "#", "#", "#" },
      },
      enter = true,
    },
    footer = {
      floating = {
        buf = -1,
        win = -1,
      },
      opts = {
        relative = "editor",
        style = "minimal",
        width = state.map.size.x + 2,
        height = 2,
        col = math.floor((width - state.map.size.x) / 2),
        row = math.floor((height + state.map.size.y + 4) / 2),
      },
      enter = false,
    },
  }
end

local foreach_float = function(callback)
  for name, float in pairs(state.window_config) do
    callback(name, float)
  end
end

local set_content = function()
  local lines = {}
  for y = 1, state.map.size.y do
    local line = ""
    for x = 1, state.map.size.x do
      if state.target.x == x and state.target.y == y then
        line = line .. "x"
      else
        line = line .. " "
      end
    end
    table.insert(lines, line)
  end

  local accuracy = string.format(" acc %.2f", state.accuracy)
  local cpm = string.format("cpm %.2f", state.cpm)
  local correct_wrong = string.format(" ✔ %d / ✘ %d", state.correct, state.wrong)
  local streak = string.format("🔥 %d", state.streak)

  local footer = {
    string.format(
      accuracy .. "%s" .. cpm,
      ("."):rep(state.window_config.footer.opts.width - accuracy:len() - cpm:len())
    ),
    string.format(
      correct_wrong .. "%s" .. streak,
      ("."):rep(state.window_config.footer.opts.width - correct_wrong:len() - streak:len() + (("🔥✔✘"):len()) - 4)
    ),
  }

  vim.api.nvim_buf_set_lines(state.window_config.footer.floating.buf, 0, -1, false, footer)

  vim.api.nvim_buf_set_lines(state.window_config.main.floating.buf, 0, -1, true, lines)
end

local check = function()
  local cursor_pos = vim.api.nvim_win_get_cursor(state.window_config.main.floating.win)

  if cursor_pos[2] + 1 == state.target.x and cursor_pos[1] == state.target.y then
    state.correct = state.correct + 1
    state.streak = state.streak + 1
  else
    state.wrong = state.wrong + 1
    state.streak = 0
  end

  state.end_timer = os.time()

  state.accuracy = (state.correct * 100) / (state.correct + state.wrong)

  state.cpm = (state.correct / (state.end_timer - state.start_timer) * 60)

  state.target = {
    x = math.random(1, state.map.size.x),
    y = math.random(1, state.map.size.y),
  }
  vim.api.nvim_win_set_cursor(state.window_config.main.floating.win, {
    math.random(1, state.map.size.y),
    math.random(1, state.map.size.x),
  })

  set_content()
end

local exit_window = function()
  foreach_float(function(_, float)
    pcall(vim.api.nvim_win_close, float.floating.win, true)
  end)
end

local create_remaps = function()
  vim.keymap.set("n", "<ESC><ESC>", function()
    vim.api.nvim_win_close(state.window_config.main.floating.win, true)
  end, {
    buffer = state.window_config.main.floating.buf,
  })

  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(state.window_config.main.floating.win, true)
  end, {
    buffer = state.window_config.main.floating.buf,
  })

  vim.keymap.set("n", "x", function()
    check()
  end, {
    buffer = state.window_config.main.floating.buf,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = state.window_config.main.floating.buf,
    callback = function()
      exit_window()
    end,
  })

  vim.api.nvim_create_autocmd("VimResized", {
    group = vim.api.nvim_create_augroup("present-resized", {}),
    callback = function()
      if
        not vim.api.nvim_win_is_valid(state.window_config.main.floating.win)
        or state.window_config.main.floating.win == nil
      then
        return
      end

      local updated = create_window_config()

      foreach_float(function(name, float)
        float.opts = updated[name].opts
        vim.api.nvim_win_set_config(float.floating.win, updated[name].opts)
      end)

      set_content()
    end,
  })
end

local start_accuracy = function()
  math.randomseed(os.time())

  state.target = {
    x = math.random(1, state.map.size.x),
    y = math.random(1, state.map.size.y),
  }
  state.correct = 0
  state.wrong = 0
  state.start_timer = os.time()

  state.window_config = create_window_config()

  foreach_float(function(_, float)
    float.floating = floatwindow.create_floating_window(float)
  end)

  create_remaps()

  set_content()

  vim.api.nvim_win_set_cursor(state.window_config.main.floating.win, {
    math.random(1, state.map.size.y),
    math.random(0, state.map.size.x),
  })
end

vim.api.nvim_create_user_command("Accuracy", function()
  if not vim.api.nvim_win_is_valid(state.window_config.main.floating.win) then
    start_accuracy()
  else
    vim.api.nvim_win_close(state.window_config.main.floating.win, true)
  end
end, {})

---@class setup.Opts
---@field map_size {x:integer, y:integer}: Set map size. Default {x= 20, y=10}

---Setup type plugin
---@param opts setup.Opts
M.setup = function(opts)
  state.map.size = opts.map_size or { x = 20, y = 10 }
end

return M
