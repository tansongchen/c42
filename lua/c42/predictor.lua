local lib = require "lib"
local this = {}

---@param env Env
function this.init(env)
  this.memory = lib.Memory1(env.engine, env.engine.schema, "predictor")
  this.memory:memorize(this.callback)
end

---@param commit CommitEntry
function this.callback(commit)
  -- 记忆刚上屏的字词
  for _, entry in ipairs(commit:get()) do
    if entry.custom_code then
      this.memory:update_userdict(entry, 1, "")
    end
  end
end

---@param translation Translation
---@param env Env
function this.func(translation, env)
  for candidate in translation:iter() do
    lib.yield(candidate)
    this.memory:user_lookup(candidate.text, false)
    for entry in this.memory:iter_user() do
      local phrase = lib.Phrase(this.memory, "user_table", candidate._start, candidate._end, entry)
      lib.yield(phrase:toCandidate())
    end
  end
end

return this
