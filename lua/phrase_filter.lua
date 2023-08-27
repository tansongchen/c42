local M = {}
function M.init(env)
  local dir = rime_api.get_user_data_dir()
  env.db = COLL
  if not env.db:fetch(".init") then
    local base = load_base(dir .. "/phrase.txt")
    for char, assocs in pairs(base) do
      env.db:update(char, dump_data({ 0, assocs }))
    end
    env.db:update(".init", "1")
  end
  local config = env.engine.schema.config
  env.option_name = config:get_string(env.name_space .. "/option_name")
  -- log.error(env.option_name)
  env.tags = config:get_list(env.name_space .. "/tags")
  -- log.error(tostring(env.tags.size))
  for i = 1, env.tags.size do
    local tag = env.tags:get_value_at(i - 1):get_string()
    -- log.error(tag)
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
      local assocs = safe_get_assocs(env.db, char)
      for _, v in ipairs(assocs) do
        local phrase = Candidate("udata", cand._start, cand._end, char .. v, "")
        phrase.quality = cand.quality
        yield(phrase)
      end
    end
  end
end

return M
