local M = {}
function M.init(env)
  local dir = rime_api.get_user_data_dir()
  env.db = assert(opendb(dir .. "/coll", 'dict'), "leveldb cand not init")
end

function M.fini(env)
  env.db:close()
end

local kRejected = 0
local kAccepted = 1
local kNoop = 2

local function export_legacy_phrase(db)
  local dir = rime_api.get_user_data_dir()
  local file = io.open(dir .. "/opencc/legacyphrase.txt", "w")
  if not file then return end
  local da = db:query("")
  for char, value in da:iter() do
    if utf8.len(char) == 1 then
      local assocs = parse_data(value)[2]
      local line = char .. "\t" .. char
      for _, v in ipairs(assocs) do
        line = line .. " " .. char .. v
      end
      file:write(line .. "\n")
    end
  end
  file:close()
end

local function export_phrase(db)
  local dir = rime_api.get_user_data_dir()
  local file = io.open(dir .. "/phrase_export.txt", "w")
  if not file then return end
  local da = db:query("")
  for char, value in da:iter() do
    log.error(char .. " " .. value)
    if utf8.len(char) == 1 then
      local t = parse_data(value)
      local timestamp = t[1]
      local assocs = t[2]
      local line = char .. " " .. timestamp
      for _, v in ipairs(assocs) do
        line = line .. " " .. v
      end
      file:write(line .. "\n")
    end
  end
  file:close()
end

local function add_colloc(db, text, index)
  if utf8.len(text) == 1 then return end
  local key = string.sub(text, 1, utf8.offset(text, 2) - 1)
  local new_colloc = string.sub(text, utf8.offset(text, 2), #text)
  local assocs = safe_get_assocs(db, key)
  local previous_index = in_table(assocs, new_colloc)
  if previous_index then
    table.remove(assocs, previous_index)
  end
  local table_index = math.min(index - 1, #assocs + 1)
  table.insert(assocs, table_index, new_colloc)
  if #assocs > 5 then
    table.remove(assocs)
  end
  log.error("add_colloc: " .. text .. ", " .. tostring(index))
  db:update(key, dump_data({ os.time(), assocs }))
end

local function delete_colloc(db, text)
  if utf8.len(text) == 1 then return end
  local key = string.sub(text, 1, utf8.offset(text, 2) - 1)
  local new_colloc = string.sub(text, utf8.offset(text, 2), #text)
  local assocs = safe_get_assocs(db, key)
  local previous_index = in_table(assocs, new_colloc)
  if previous_index then
    log.error("delete_colloc: " .. text)
    table.remove(assocs, previous_index)
    db:update(key, dump_data({ os.time(), assocs }))
  end
end

local function up_colloc(db, text, index)
  add_colloc(db, text, index - 1)
end

local function down_colloc(db, text, index)
  add_colloc(db, text, index + 1)
end

function M.func(key_event, env)
  if key_event:release() then return kNoop end
  local keycode = key_event.keycode
  local context = env.engine.context
  if not context:has_menu() then return kNoop end
  if context.input:match("^[gfdsa]$") then
    local select_table = { [0xff0d] = 0, [0x20] = 2, [0x30] = 2, [0x39] = 3, [0x38] = 4, [0x37] = 5, [0x36] = 6 }
    local index = select_table[keycode]
    if not index then return kNoop end
    local cand = context:get_selected_candidate()
    local text = cand.text
    if index > 0 then
      add_colloc(env.db, text, index)
    elseif index == 0 then
      delete_colloc(env.db, text)
    end
    context:clear()
    return kAccepted
  elseif context.input:match("^h$") then
    if keycode == 0x20 then
      export_legacy_phrase(env.db)
      context:clear()
      return kAccepted
    else
      return kNoop
    end
  elseif context.input:match("^j$") then
    if keycode == 0x20 then
      export_phrase(env.db)
      context:clear()
      return kAccepted
    else
      return kNoop
    end
  else
    local composition = context.composition
    local segment = composition:back()
    local menu = segment.menu
    local index = -1
    local left_table = { [0x32] = 2, [0x33] = 3, [0x34] = 4, [0x35] = 5, [0x31] = 6 }
    local right_table = { [0x30] = 2, [0x39] = 3, [0x38] = 4, [0x37] = 5, [0x31] = 6 }
    local fly_table = { [0x30] = 2, [0x39] = 3, [0x38] = 4, [0x37] = 5 }
    local up_table = { [0x33] = 3, [0x34] = 4, [0x35] = 5, [0x36] = 6 }
    local down_table = { [0x30] = 2, [0x39] = 3, [0x38] = 4, [0x37] = 5 }
    if key_event:ctrl() and up_table[keycode] then
      index = up_table[keycode] -- to up
      up_colloc(env.db, menu:get_candidate_at(index - 1).text, index)
      context:refresh_non_confirmed_composition()
      return kAccepted
    elseif key_event:ctrl() and down_table[keycode] then
      index = down_table[keycode] -- to down
      down_colloc(env.db, menu:get_candidate_at(index - 1).text, index)
      context:refresh_non_confirmed_composition()
      return kAccepted
    elseif context.input:match("[qwertasdfgzxcvb]$") and left_table[keycode] then
      index = left_table[keycode] -- to delete
    elseif context.input:match("[yuiophjkl;nm,./]$") and right_table[keycode] then
      index = right_table[keycode] -- to delete
    elseif context.input:match("[qwertasdfgzxcvb]$") and fly_table[keycode] then
      index = fly_table[keycode] -- to commit
      local cand = menu:get_candidate_at(index - 1)
      if cand then
        local text = cand.text
        context:clear()
        env.engine:commit_text(text)
        return kAccepted
      else
        return kRejected
      end
    else
      return kNoop
    end
    local cand = menu:get_candidate_at(index - 1)
    if cand then
      local text = cand.text
      delete_colloc(env.db, text)
      context:refresh_non_confirmed_composition()
      return kAccepted
    end
  end
  return kNoop
end

return M
