
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

local function select_index(key)
  local ch = key.keycode
  log.error(ch)
  local index = -1
  if ch >= 0x31 and ch <= 0x36 then
    index = ch - 0x30
  elseif ch > 0x36 and ch <= 0x39 then
    index = 0x3b - ch
  elseif ch == 0x30 then
    index = 2
  elseif ch == 0x20 then
    index = 1
  elseif ch == 0xff0d then
    index = 0
  end
  return index
end

local function add_colloc(db, text, index)
  log.error("add_colloc: " .. text .. ", " .. tostring(index))
  local key = string.sub(text, 1, utf8.offset(text, 2) - 1)
  local new_colloc = string.sub(text, utf8.offset(text, 2), #text)
  local value = db:fetch(key)
  if not value then
    value = "/ / / / /"
  end
  log.error("previous: " .. key .. ", " .. value)
  local table = split_string_to_table(value)
  local previous_index = in_table(table, new_colloc)
  if previous_index then
    table[previous_index] = "/"
  end
  local old = table[index]
  table[index] = new_colloc
  while old and old ~= "/" and index <= 5 do
    new_colloc = old
    index = index + 1
    old = table[index]
    table[index] = new_colloc
  end
  local new_value = ""
  for _, v in ipairs(table) do
    new_value = new_value .. " " .. v
  end
  log.error("new: " .. key .. ", " .. new_value)
  db:update(key, new_value)
end

local function delete_colloc(db, text)
  log.error("delete_colloc: " .. text)
  local key = string.sub(text, 1, utf8.offset(text, 2) - 1)
  local new_colloc = string.sub(text, utf8.offset(text, 2), #text)
  local value = db:fetch(key)
  if not value then
    value = "/ / / / /"
  end
  log.error("previous: " .. key .. ", " .. value)
  local table = split_string_to_table(value)
  local previous_index = in_table(table, new_colloc)
  if previous_index then
    table[previous_index] = "/"
    local new_value = ""
    for _, v in ipairs(table) do
      new_value = new_value .. " " .. v
    end
    log.error("new: " .. key .. ", " .. new_value)
    db:update(key, new_value)
  end
end

function M.func(key_event, env)
  if key_event:release() then return kNoop end
  local keycode = key_event.keycode
  local context = env.engine.context
  if not context:has_menu() then return kNoop end
  if context.input:match("^[gfdsa]$") then
    local index = select_index(key_event)
    if index > 0 then
      local cand = context:get_selected_candidate()
      local text = cand.text
      add_colloc(env.db, text, index)
    elseif index == 0 then
      local cand = context:get_selected_candidate()
      local text = cand.text
      delete_colloc(env.db, text)
    else
      return kNoop
    end
    context:clear()
    return kAccepted
  else
    local composition = context.composition
    local segment = composition:back()
    local menu = segment.menu
    local index = -1
    if context.input:match("[qwertasdfgzxcvb]$") and keycode >= 0x31 and keycode <= 0x35 then
      index = keycode == 0x31 and 6 or keycode - 0x30
    elseif (keycode >= 0x36 and keycode <= 0x39) or keycode == 0x30 then
      index = keycode == 0x30 and 2 or 0x3b - keycode
    else
      return kNoop
    end
    -- log.error(context.input .. " " .. tostring(index))
    local cand = menu:get_candidate_at(index - 1)
    if cand then
      local text = cand.text
      log.error(text)
      delete_colloc(env.db, text)
      context:refresh_non_confirmed_composition()
      return kAccepted
    end
  end
  return kNoop
end

return M
