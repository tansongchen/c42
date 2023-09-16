DB_POOL = {}

---comment
---@param path string
---@param dbname string
---@return table | nil
local function opendb(path, dbname)
  local db = DB_POOL[path]
  if not db then
    db = LevelDb(path, dbname)
    if not db then return nil end
    DB_POOL[path] = db
  end
  if not db:loaded() then db:open() end
  return db
end

local function parse_data(value)
  local data = {}
  local i = 1
  for v in string.gmatch(value, "[^;]+") do
    if (i == 1) then
      data[1] = tonumber(v)
    elseif (i == 2) then
      data[2] = {}
      local j = 1
      for x in string.gmatch(v, "[^%s]+") do
        data[2][j] = x
        j = j + 1
      end
    end
    i = i + 1
  end
  data[2] = data[2] or {}
  return data
end

local function dump_data(data)
  local timestamp = data[1]
  local assocs = data[2]
  local value = tostring(timestamp) .. ";"
  for _, v in ipairs(assocs) do
    value = value .. " " .. v
  end
  return value
end

local function safe_get_assocs(db, key)
  local assocs
  local value = db:fetch(key)
  if value then
    assocs = parse_data(value)[2]
  else
    assocs = {}
  end
  return assocs
end

return { opendb = opendb, parse_data = parse_data, dump_data = dump_data, safe_get_assocs = safe_get_assocs }
