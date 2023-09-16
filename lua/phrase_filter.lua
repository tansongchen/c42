local utils = require("utils");

local M = {}
function M.init(env)
  local dir = rime_api.get_user_data_dir()
  local config = env.engine.schema.config
  env.option_name = config:get_string(env.name_space .. "/option_name")
  env.tags = config:get_list(env.name_space .. "/tags")
  env.db = assert(utils.opendb(dir .. "/coll", 'coll'), "LevelDb error")
  if not env.db:fetch(".init") then
    env.db:update(".init", "1")
    local file = io.open(dir .. "/phrase.txt")
    if not file then return end
    for line in file:lines() do
      local key = string.sub(line, 1, utf8.offset(line, 2) - 1)
      local value = string.sub(line, utf8.offset(line, 2) + 1, #line)
      env.db:update(key, value)
    end
  end
end

function M.fini(env)
  env.db:close()
end

function M.func(inp, env)
  local enabled = env.engine.context:get_option(env.option_name)
  local match_tag = false
  local seg = env.engine.context.composition:back()
  for i = 1, env.tags.size do
    local tag = env.tags:get_value_at(i - 1):get_string()
    if seg:has_tag(tag) then
      match_tag = true
      break
    end
  end
  for cand in inp:iter() do
    yield(cand)
    if (utf8.len(cand.text) == 1 and enabled and match_tag) then
      local char = cand.text
      local assocs = utils.safe_get_assocs(env.db, char)
      for _, v in ipairs(assocs) do
        local phrase = Candidate("udata", cand._start, cand._end, char .. v, "")
        phrase.quality = cand.quality
        yield(phrase)
      end
    end
  end
end

return M
