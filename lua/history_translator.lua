local function translator(inp, seg, env)
  local history_length = {
    ["g"] = 1,
    ["f"] = 2,
    ["d"] = 3,
    ["s"] = 4,
    ["a"] = 5,
  }  
  if inp:match("^[gfdsa]$") then
    local context = env.engine.context
    local length = history_length[inp]
    local text = ""
    for _, record in context.commit_history:iter() do
      if record.text ~= '' then
        text = record.text .. text
        length = length - 1
      end
      if length == 0 then
        local cand = Candidate("history", seg.start, seg._end, text, '')
        cand.initial_quality = 1000
        yield(cand)
        yield(Candidate("history", seg.start, seg._end, "　", ""))
      end
    end
  elseif inp:match("^[hj]$") then
    yield(Candidate("history", seg.start, seg._end, "【导出】", ""))
    yield(Candidate("history", seg.start, seg._end, "　", ""))
  end
end

return translator
