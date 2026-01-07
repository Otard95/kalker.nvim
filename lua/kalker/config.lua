local function null_coalescing(lhs, rhs)
  if lhs == nil then
    return rhs
  end
  return lhs
end

---@class KalkerOptions_Calculations
---@field timeout integer | nil

---@class KalkerOptions
---@field calculations KalkerOptions_Calculations
---@field debounce integer | nil
---@field log_level integer | nil
---@field log_file string | nil

---@type KalkerOptions
local M = {
  calculations = {
    timeout = 300,
  },
  debounce = 300,
}

---@param opts ?KalkerOptions
function M.apply(opts)
  if opts == nil then return end

  M.calculations = vim.tbl_deep_extend('force', M.calculations or {}, opts.calculations or {})
  M.log_level    = null_coalescing(opts.debounce, M.debounce)
  M.log_level    = null_coalescing(opts.log_level, M.log_level)
  M.log_file     = null_coalescing(opts.log_file, M.log_file)
end

return M
