M = {}

---Filters the provided list based on the given predicate.
---Creates a new list of elements where predicate returns true.
---
---@param list table
---@param predicate function
---@return table
function M.filter(list, predicate)
  local result = {}
  for k, v in pairs(list) do
    if predicate(v, k) then
      table.insert(result, v)
    end
  end
  return result
end

---Creates a new list where the elements are the result of calling the
---transformer on each of them.
---@param list table
---@param transformer function
---@return table
function M.map(list, transformer)
  local result = {}
  for k, v in pairs(list) do
    table.insert(result, transformer(v, k))
  end
  return result
end

---comment
---@param list table
---@param cb function
function M.foreach(list, cb)
  for k, v in pairs(list) do
    cb(v, k)
  end
end

return M
