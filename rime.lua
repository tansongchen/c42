DB_POOL = {}

---comment
---@param path string
---@param dbname string
---@return table | nil
function opendb(path, dbname)
  local db = DB_POOL[path]
  if not db then
    db = LevelDb(path, dbname)
    if not db then return nil end
    DB_POOL[path] = db
  end
  if not db:loaded() then db:open() end
  return db
end

COLL = assert(opendb(rime_api.get_user_data_dir() .. "/coll", 'coll'), "leveldb cannot initialize")

function split_string_to_table(s)
  local t = {}
  local i = 1
  for v in string.gmatch(s, "[^%s]+") do
    t[i] = v
    i = i + 1
  end
  return t
end

function in_table(table, value)
  for k, v in ipairs(table) do
    if v == value then
      return k
    end
  end
  return nil
end

function parse_data(value)
  local data = {}
  local i = 1
  for v in string.gmatch(value, "[^;]+") do
    if (i == 1) then
      data[i] = tonumber(v)
    elseif (i == 2) then
      data[i] = split_string_to_table(v)
    end
    i = i + 1
  end
  data[2] = data[2] or {}
  return data
end

function dump_data(data)
  local timestamp = data[1]
  local assocs = data[2]
  local value = tostring(timestamp) .. ";"
  for _, v in ipairs(assocs) do
    value = value .. " " .. v
  end
  return value
end

function safe_get_assocs(db, key)
  local assocs
  local value = db:fetch(key)
  if value then
    assocs = parse_data(value)[2]
  else
    assocs = {}
  end
  return assocs
end

function load_base(fpath)
  local dict = {}
  local file = io.open(fpath)
  if not file then return dict end
  for line in file:lines() do
    local i = 1
    local key
    local value = {}
    for v in string.gmatch(line, "[^%s]+") do
      if i == 1 then
        key = v
      elseif i > 1 then
        table.insert(value, v)
      end
      i = i + 1
    end
    dict[key] = value
  end
  file:close()
  return dict
end

date = require("date_translator")
phrase_edit = require("phrase_edit_processor")
phrase = require("phrase_filter")
history = require("history_translator")
