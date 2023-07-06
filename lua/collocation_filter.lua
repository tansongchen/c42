local function load_base(fpath)
  local dict = {}
  for line in io.open(fpath):lines() do
    local i = 1
    local key
    local value = ""
    for v in string.gmatch(line, "[^%s]+") do
      if i == 2 then
        key = v
      elseif i > 2 then
        local token = string.sub(v, utf8.offset(v, 2), #v)
        value = value .. " " .. token
      end
      i = i + 1
    end
    dict[key] = value
  end
  return dict
end

local M = {}
function M.init(env)
  local dir = rime_api.get_user_data_dir()
  env.base = load_base(dir .. "/opencc/phrase.txt")
  env.db = assert(opendb(dir .. "/coll", 'dict'), "leveldb cand not init")
  local da = env.db:query("") -- return obj of DbAccessor
  for k,v in da:iter() do log.error(k,v) end
end

function M.fini(env)
  env.db:close()
end

function M.func(inp, env)
  for cand in inp:iter() do
    yield(cand)
    if (utf8.len(cand.text) == 1 and cand.type ~= "history") then
      local char = cand.text
      local static_colls = env.base[char]
      local dynamic_colls = env.db:fetch(char)
      local table
      if dynamic_colls then
        table = split_string_to_table(dynamic_colls)
        if static_colls then
          local i = 1
          for v in string.gmatch(static_colls, "[^%s]+") do
            if not in_table(table, v) then
              while (table[i] and table[i] ~= '/') do
                i = i + 1
              end
              table[i] = v
            end
          end
        end
      else
        if static_colls then
          table = split_string_to_table(static_colls)
        else
          table = {}
        end
      end
      for _, v in ipairs(table) do
        if (v ~= "/") then
          local type_ = "udata"
          local coll = Candidate(type_, cand._start, cand._end, char .. v, "")
          coll.quality = cand.quality
          yield(coll)
        end
      end
    end
  end
end

return M
