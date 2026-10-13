-- Yakiiro forge: anvil strike on :wq in markdown while the yakiiro theme is active.

local M = {}

local HOME = vim.env.HOME or vim.fn.expand("~")
local THEME_NAME_FILE = HOME .. "/.local/state/omarchy/current/theme.name"

local function module_dir()
  local src = debug.getinfo(1, "S").source
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end
  return vim.fn.fnamemodify(src, ":h")
end

-- Theme install leaves the ogg in the yakiiro theme. A checkout of this repo
-- keeps it beside nvim/lua, two directories up.
local function sound_file()
  local dir = module_dir()
  local candidates = {
    dir .. "/../../sounds/anvil.ogg",
    dir .. "/../sounds/anvil.ogg",
    HOME .. "/.config/omarchy/themes/yakiiro/sounds/anvil.ogg",
    HOME .. "/.local/state/omarchy/current/theme/sounds/anvil.ogg",
  }
  for _, path in ipairs(candidates) do
    local full = vim.fn.fnamemodify(path, ":p")
    if vim.fn.filereadable(full) == 1 then
      return full
    end
  end
  return nil
end

local IMPACT_FG = "#E4E0D6"

local STRIKE_COLORS = {
  "#4A8AB0",
  "#C4B48A",
  "#9A4A32",
  "#B86248",
  "#D4C49A",
  "#A08F73",
  "#5A8A7A",
  "#809EA6",
  "#73553D",
  "#386385",
  "#6A6A9A",
  "#96B4BA",
}

-- Resting heated-metal colors for markdown. Skipped when aether owns the colorscheme.
local RESTING = {
  ["@markup.heading"] = { fg = "#C4B48A", bold = true },
  ["@markup.heading.1"] = { fg = "#D4C49A", bold = true },
  ["@markup.heading.2"] = { fg = "#C4B48A", bold = true },
  ["@markup.heading.3"] = { fg = "#A08F73", bold = true },
  ["@markup.heading.4"] = { fg = "#809EA6" },
  ["@markup.heading.5"] = { fg = "#5A8A7A" },
  ["@markup.heading.6"] = { fg = "#7A7368" },
  ["@markup.strong"] = { fg = "#B86248", bold = true },
  ["@markup.italic"] = { fg = "#A08F73", italic = true },
  ["@markup.link"] = { fg = "#4A8AB0", underline = true },
  ["@markup.link.url"] = { fg = "#386385", underline = true },
  ["@markup.link.label"] = { fg = "#4A8AB0" },
  ["@markup.raw"] = { fg = "#5A8A7A" },
  ["@markup.raw.block"] = { fg = "#5A8A7A" },
  ["@markup.quote"] = { fg = "#7A7368", italic = true },
  ["@markup.list"] = { fg = "#809EA6" },
  ["@markup.list.checked"] = { fg = "#5A8A7A" },
  ["@markup.list.unchecked"] = { fg = "#A08F73" },
  ["@markup.strikethrough"] = { fg = "#7A7368", strikethrough = true },
  markdownH1 = { fg = "#D4C49A", bold = true },
  markdownH2 = { fg = "#C4B48A", bold = true },
  markdownH3 = { fg = "#A08F73", bold = true },
  markdownH4 = { fg = "#809EA6" },
  markdownH5 = { fg = "#5A8A7A" },
  markdownH6 = { fg = "#7A7368" },
  markdownBold = { fg = "#B86248", bold = true },
  markdownItalic = { fg = "#A08F73", italic = true },
  markdownCode = { fg = "#5A8A7A" },
  markdownCodeBlock = { fg = "#5A8A7A" },
  markdownLinkText = { fg = "#4A8AB0", underline = true },
  markdownUrl = { fg = "#386385", underline = true },
  markdownListMarker = { fg = "#809EA6" },
  markdownBlockquote = { fg = "#7A7368", italic = true },
}

local GROUPS = {
  "@markup.heading",
  "@markup.heading.1",
  "@markup.heading.2",
  "@markup.heading.3",
  "@markup.heading.4",
  "@markup.heading.5",
  "@markup.heading.6",
  "@markup.heading.1.markdown",
  "@markup.heading.2.markdown",
  "@markup.heading.3.markdown",
  "@markup.heading.4.markdown",
  "@markup.heading.5.markdown",
  "@markup.heading.6.markdown",
  "@markup.strong",
  "@markup.strong.markdown_inline",
  "@markup.italic",
  "@markup.italic.markdown_inline",
  "@markup.link",
  "@markup.link.markdown",
  "@markup.link.markdown_inline",
  "@markup.link.url",
  "@markup.link.url.markdown",
  "@markup.link.url.markdown_inline",
  "@markup.link.label",
  "@markup.link.label.markdown",
  "@markup.link.label.markdown_inline",
  "@markup.raw",
  "@markup.raw.markdown_inline",
  "@markup.raw.block",
  "@markup.raw.block.markdown",
  "@markup.quote",
  "@markup.quote.markdown",
  "@markup.list",
  "@markup.list.markdown",
  "@markup.list.checked",
  "@markup.list.unchecked",
  "@markup.strikethrough",
  "@markup.strikethrough.markdown_inline",
  "markdownH1",
  "markdownH2",
  "markdownH3",
  "markdownH4",
  "markdownH5",
  "markdownH6",
  "markdownBold",
  "markdownItalic",
  "markdownCode",
  "markdownCodeBlock",
  "markdownLinkText",
  "markdownUrl",
  "markdownListMarker",
  "markdownBlockquote",
}

local function read_theme_name()
  local f = io.open(THEME_NAME_FILE, "r")
  if not f then
    return nil
  end
  local name = f:read("*l")
  f:close()
  if not name then
    return nil
  end
  return (name:gsub("%s+", ""))
end

function M.theme_is_yakiiro()
  local name = read_theme_name()
  return name ~= nil and name:lower() == "yakiiro"
end

function M.is_markdown()
  return vim.bo.filetype == "markdown"
end

function M.should_forge()
  return M.theme_is_yakiiro() and M.is_markdown()
end

local function copy_attrs(hl)
  return {
    bold = hl.bold or nil,
    italic = hl.italic or nil,
    underline = hl.underline or nil,
    strikethrough = hl.strikethrough or nil,
    undercurl = hl.undercurl or nil,
  }
end

local function snapshot()
  local snap = {}
  for _, name in ipairs(GROUPS) do
    snap[name] = {
      linked = vim.api.nvim_get_hl(0, { name = name, link = true }),
      resolved = vim.api.nvim_get_hl(0, { name = name, link = false }),
    }
  end
  return snap
end

local function restore(snap)
  for name, cap in pairs(snap) do
    local linked = cap.linked
    if linked.link then
      vim.api.nvim_set_hl(0, name, { link = linked.link })
    else
      vim.api.nvim_set_hl(0, name, linked)
    end
  end
end

local function apply_fg(snap, fg, extra_bold)
  for _, name in ipairs(GROUPS) do
    local cap = snap[name]
    local attrs = copy_attrs(cap and cap.resolved or {})
    attrs.fg = fg
    if extra_bold then
      attrs.bold = true
    end
    vim.api.nvim_set_hl(0, name, attrs)
  end
end

local function apply_random(snap)
  for _, name in ipairs(GROUPS) do
    local cap = snap[name]
    local attrs = copy_attrs(cap and cap.resolved or {})
    attrs.fg = STRIKE_COLORS[math.random(#STRIKE_COLORS)]
    vim.api.nvim_set_hl(0, name, attrs)
  end
end

function M.apply_resting()
  if not M.theme_is_yakiiro() then
    return
  end
  if vim.g.colors_name == "aether" then
    return
  end
  vim.opt.termguicolors = true
  for name, spec in pairs(RESTING) do
    vim.api.nvim_set_hl(0, name, spec)
  end
  -- Language-specific treesitter groups inherit the generic resting color.
  local inherit = {
    ["@markup.heading.1.markdown"] = "@markup.heading.1",
    ["@markup.heading.2.markdown"] = "@markup.heading.2",
    ["@markup.heading.3.markdown"] = "@markup.heading.3",
    ["@markup.heading.4.markdown"] = "@markup.heading.4",
    ["@markup.heading.5.markdown"] = "@markup.heading.5",
    ["@markup.heading.6.markdown"] = "@markup.heading.6",
    ["@markup.strong.markdown_inline"] = "@markup.strong",
    ["@markup.italic.markdown_inline"] = "@markup.italic",
    ["@markup.link.markdown"] = "@markup.link",
    ["@markup.link.markdown_inline"] = "@markup.link",
    ["@markup.link.url.markdown"] = "@markup.link.url",
    ["@markup.link.url.markdown_inline"] = "@markup.link.url",
    ["@markup.link.label.markdown"] = "@markup.link.label",
    ["@markup.link.label.markdown_inline"] = "@markup.link.label",
    ["@markup.raw.markdown_inline"] = "@markup.raw",
    ["@markup.raw.block.markdown"] = "@markup.raw.block",
    ["@markup.quote.markdown"] = "@markup.quote",
    ["@markup.list.markdown"] = "@markup.list",
    ["@markup.strikethrough.markdown_inline"] = "@markup.strikethrough",
  }
  for name, target in pairs(inherit) do
    vim.api.nvim_set_hl(0, name, { link = target })
  end
end

local function play_anvil()
  local sound = sound_file()
  if not sound then
    return
  end
  local cmd
  if vim.fn.executable("pw-play") == 1 then
    cmd = { "pw-play", sound }
  elseif vim.fn.executable("paplay") == 1 then
    cmd = { "paplay", sound }
  elseif vim.fn.executable("mpv") == 1 then
    cmd = { "mpv", "--no-video", "--really-quiet", "--volume=80", sound }
  else
    return
  end
  pcall(vim.system, cmd, { detach = true })
end

local function knock_to(view, dy, dx)
  local last = vim.fn.line("$")
  local top = view.topline + dy
  if top < 1 then
    top = 1
  elseif top > last then
    top = last
  end
  local left = view.leftcol + dx
  if left < 0 then
    left = 0
  end
  vim.fn.winrestview({
    lnum = view.lnum,
    col = view.col,
    topline = top,
    leftcol = left,
    curswant = view.curswant,
    skipcol = view.skipcol,
  })
end

local function frame(ms)
  vim.cmd.redraw()
  vim.wait(ms, function()
    return false
  end)
end

--- Play sound + flash + knock. Calls `done` after restore (or immediately on skip).
function M.strike(opts)
  opts = opts or {}
  if not M.should_forge() then
    if opts.notify_skip then
      if not M.theme_is_yakiiro() then
        local name = read_theme_name() or "(unknown)"
        vim.notify("Yakiiro forge: theme is " .. name .. ", not yakiiro", vim.log.levels.INFO)
      else
        vim.notify("Yakiiro forge: not a markdown buffer", vim.log.levels.INFO)
      end
    end
    if opts.done then
      opts.done()
    end
    return false
  end

  vim.opt.termguicolors = true
  M.apply_resting()

  local view = vim.fn.winsaveview()
  local snap = snapshot()
  local wrap = vim.wo.wrap
  local dx = wrap and 0 or 1

  play_anvil()

  -- Impact: white-hot spark + knock away.
  apply_fg(snap, IMPACT_FG, true)
  knock_to(view, 1, dx)
  frame(40)

  -- Scatter: each group a random temper color + reverse knock.
  apply_random(snap)
  knock_to(view, -1, -dx)
  frame(140)

  restore(snap)
  vim.fn.winrestview(view)
  frame(80)

  if opts.done then
    opts.done()
  end
  return true
end

local function do_write(opts)
  local bang = opts.bang and "!" or ""
  local args = opts.args or ""
  if args ~= "" then
    vim.cmd("write" .. bang .. " " .. args)
    return
  end
  if opts.always_write then
    vim.cmd("write" .. bang)
  else
    vim.cmd("update" .. bang)
  end
end

local function do_quit(opts)
  vim.cmd("quit" .. (opts.bang and "!" or ""))
end

local function builtin_write_quit(opts)
  local cmd = opts.always_write and "wq" or "exit"
  if opts.bang then
    cmd = cmd .. "!"
  end
  if opts.args and opts.args ~= "" then
    cmd = cmd .. " " .. opts.args
  end
  vim.cmd(cmd)
end

function M.write_strike_quit(opts)
  opts = opts or {}
  if not M.should_forge() then
    builtin_write_quit(opts)
    return
  end

  local ok, err = pcall(do_write, opts)
  if not ok then
    vim.notify(err:gsub("^Vim%(.-%):", ""), vim.log.levels.ERROR)
    return
  end

  M.strike({
    done = function()
      do_quit(opts)
    end,
  })
end

function M.setup()
  if vim.g.loaded_yakiiro_forge_setup then
    return
  end
  vim.g.loaded_yakiiro_forge_setup = true

  vim.opt.termguicolors = true
  math.randomseed(vim.uv.hrtime())

  local group = vim.api.nvim_create_augroup("YakiiroForge", { clear = true })
  vim.api.nvim_create_autocmd({ "VimEnter", "ColorScheme", "FileType", "BufEnter" }, {
    group = group,
    callback = function()
      if M.is_markdown() then
        M.apply_resting()
      end
    end,
  })

  vim.api.nvim_create_user_command("YakiiroWq", function(opts)
    M.write_strike_quit({
      always_write = true,
      bang = opts.bang,
      args = opts.args,
    })
  end, {
    bang = true,
    nargs = "*",
    complete = "file",
    desc = "Write, yakiiro forge strike, quit",
  })

  vim.api.nvim_create_user_command("YakiiroX", function(opts)
    M.write_strike_quit({
      always_write = false,
      bang = opts.bang,
      args = opts.args,
    })
  end, {
    bang = true,
    nargs = "*",
    complete = "file",
    desc = "Like :x with yakiiro forge strike",
  })

  vim.api.nvim_create_user_command("YakiiroStrike", function()
    M.strike({ notify_skip = true })
  end, { desc = "Preview yakiiro forge strike without quitting" })

  vim.cmd([[cnoreabbrev <expr> wq (getcmdtype() == ':' && getcmdline() ==# 'wq') ? 'YakiiroWq' : 'wq']])
  vim.cmd([[cnoreabbrev <expr> x (getcmdtype() == ':' && getcmdline() ==# 'x') ? 'YakiiroX' : 'x']])

  vim.keymap.set("n", "ZZ", function()
    M.write_strike_quit({ always_write = false, bang = false })
  end, { desc = "Write if needed, yakiiro forge strike, quit" })
end

return M
