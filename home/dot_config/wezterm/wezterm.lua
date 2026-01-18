local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- ===========================================
-- Shell
-- ===========================================
config.default_prog = { "pwsh", "-NoLogo" }

-- ===========================================
-- Appearance
-- ===========================================
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 0.92
config.win32_system_backdrop = "Acrylic"
config.window_decorations = "RESIZE"

config.window_padding = {
  left = 15,
  right = 15,
  top = 15,
  bottom = 15,
}


-- ===========================================
-- Font
-- ===========================================
config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Medium" })
config.font_size = 11.0
config.line_height = 1.1

-- ===========================================
-- Cursor
-- ===========================================
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

-- ===========================================
-- Tab Bar
-- ===========================================
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 32

config.colors = {
  tab_bar = {
    background = "#1e1e2e",
    active_tab = {
      bg_color = "#cba6f7",
      fg_color = "#1e1e2e",
      intensity = "Bold",
    },
    inactive_tab = {
      bg_color = "#313244",
      fg_color = "#cdd6f4",
    },
    inactive_tab_hover = {
      bg_color = "#45475a",
      fg_color = "#cdd6f4",
    },
    new_tab = {
      bg_color = "#313244",
      fg_color = "#cdd6f4",
    },
    new_tab_hover = {
      bg_color = "#45475a",
      fg_color = "#cdd6f4",
    },
  },
}

-- ===========================================
-- Keybindings (Leader = Ctrl+Space)
-- ===========================================
config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
  -- Pane splitting (like tmux)
  { key = "-", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },
  { key = "\\", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },

  -- Pane navigation (vim-style)
  { key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
  { key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
  { key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
  { key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },

  -- Pane resizing
  { key = "H", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
  { key = "J", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
  { key = "K", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
  { key = "L", mods = "LEADER|SHIFT", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },

  -- Close pane
  { key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },

  -- Tabs
  { key = "c", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },
  { key = "n", mods = "LEADER", action = wezterm.action.ActivateTabRelative(1) },
  { key = "p", mods = "LEADER", action = wezterm.action.ActivateTabRelative(-1) },
  { key = "1", mods = "LEADER", action = wezterm.action.ActivateTab(0) },
  { key = "2", mods = "LEADER", action = wezterm.action.ActivateTab(1) },
  { key = "3", mods = "LEADER", action = wezterm.action.ActivateTab(2) },
  { key = "4", mods = "LEADER", action = wezterm.action.ActivateTab(3) },
  { key = "5", mods = "LEADER", action = wezterm.action.ActivateTab(4) },

  -- Maximize pane (toggle)
  { key = "z", mods = "LEADER", action = wezterm.action.TogglePaneZoomState },

  -- Copy mode (like vim)
  { key = "[", mods = "LEADER", action = wezterm.action.ActivateCopyMode },

  -- Quick actions
  { key = "f", mods = "LEADER", action = wezterm.action.Search({ CaseSensitiveString = "" }) },
  { key = "r", mods = "LEADER", action = wezterm.action.ReloadConfiguration },

  -- Font size
  { key = "+", mods = "CTRL|SHIFT", action = wezterm.action.IncreaseFontSize },
  { key = "-", mods = "CTRL", action = wezterm.action.DecreaseFontSize },
  { key = "0", mods = "CTRL", action = wezterm.action.ResetFontSize },

  -- Window move (hold and drag)
  { key = "m", mods = "LEADER", action = wezterm.action.StartWindowDrag },
}

-- ===========================================
-- Status Bar (right side)
-- ===========================================
wezterm.on("update-status", function(window, pane)
  local workspace = window:active_workspace()
  local time = wezterm.strftime("%H:%M")

  window:set_right_status(wezterm.format({
    { Foreground = { Color = "#89b4fa" } },
    { Text = "  " .. workspace },
    { Foreground = { Color = "#6c7086" } },
    { Text = "  |  " },
    { Foreground = { Color = "#f9e2af" } },
    { Text = "  " .. time .. "  " },
  }))
end)

-- ===========================================
-- Misc
-- ===========================================
config.audible_bell = "Disabled"
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.check_for_updates = false
config.automatically_reload_config = true

-- Windows-specific
config.prefer_egl = true

return config
