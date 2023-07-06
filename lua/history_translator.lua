local function translator(inp, seg, env)
  local history_length = {
    ["g"] = 1,
    ["f"] = 2,
    ["d"] = 3,
    ["s"] = 4,
    ["a"] = 5,
  }  
  if not seg:has_tag("history") or not inp:match("^[gfdsa]$") then
    return
  end
  local context = env.engine.context
  local length = history_length[inp]
  local text = ""
  for _, record in context.commit_history:iter() do
    if record.text ~= '' then
      text = record.text .. text
      length = length - 1
    end
    if length == 0 then
      local cand = Candidate(record.type, seg.start, seg._end, text, '')
      cand.initial_quality = 1000
      yield(cand)
    end
  end
end

return translator
