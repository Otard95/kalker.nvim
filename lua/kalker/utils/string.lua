M = {}

---@param str string
---@param prefix string
---@return boolean
function M.startswith(str, prefix)
  return str:sub(1, #prefix) == prefix
end

---@param str string
---@param suffix string
---@return boolean
function M.endswith(str, suffix)
  return suffix == '' or str:sub(- #suffix) == suffix
end

return M
