local lib = require "c42.lib"
local this = {}

local XK_Return = 0xff0d

---@param env Env
function this.init(env)
  this.memory = lib.Memory1(env.engine, env.engine.schema, "predictor")
  this.reverse = lib.ReverseLookup(env.engine.schema.schema_id)
  env.engine.context.option_update_notifier:connect(function(ctx, name)
    if name == "encode" then
      local encode = ctx:get_option("encode")
      ctx:set_option("_auto_commit", not encode)
      ctx.commit_history:clear()
    end
  end)
  env.engine.context.commit_notifier:connect(function(ctx)
    if ctx:get_option("encode") then
      ctx:set_option("encode", false)
    end
  end)
end

---@param key_event KeyEvent
---@param env Env
function this.func(key_event, env)
  local context = env.engine.context
  if key_event.keycode == XK_Return and not key_event:release() then
    if context:get_option("encode") then
      local phrase = context:get_commit_text()
      local first_char = utf8.char(utf8.codepoint(phrase))
      local entry = lib.DictEntry()
      entry.text = phrase
      entry.custom_code = first_char .. " "
      this.memory:update_userdict(entry, 1, "")
      return lib.process_results.kNoop
    end
  end
  return lib.process_results.kNoop
end

return this
