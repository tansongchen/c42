local lib = require "c42.lib"
local this = {}

---@class PredictorEnv: Env
---@field memory Memory

---@param env PredictorEnv
function this.init(env)
  env.memory = lib.Memory1(env.engine, env.engine.schema, "predictor")
  -- 记忆刚上屏的字词
  env.memory:memorize(function(commit)
    for _, entry in ipairs(commit:get()) do
      if entry.custom_code:len() >= 3 then
        lib.errorf("联想词：%s → %s", entry.custom_code, entry.text)
        env.memory:update_userdict(entry, 1, "")
      end
    end
  end)
end

---@param translation Translation
---@param env PredictorEnv
function this.func(translation, env)
  for candidate in translation:iter() do
    lib.yield(candidate)
    if not env.engine.context:get_option("prediction") then
      goto continue
    end
    env.memory:user_lookup(candidate.text, false)
    for entry in env.memory:iter_user() do
      local phrase = lib.Phrase(env.memory, "user_table", candidate._start, candidate._end, entry)
      lib.yield(phrase:toCandidate())
    end
    ::continue::
  end
end

---@param segment Segment
---@param env Env
function this.tags_match(segment, env)
  return segment:has_tag("abc") and not segment:has_tag("wildcard")
end

return this
