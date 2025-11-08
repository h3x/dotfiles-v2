#!/usr/bin/env lua
-- ----------------------------------------------------------
-- Flatten a multi-file Docker Compose setup using pure Lua.
-- ----------------------------------------------------------
require("lldebugger").start()
local lyaml = require("lyaml")
local lfs = require("lfs")

-- --- Utility logging ---
local function color(code, text)
  return string.format("\27[%sm%s\27[0m", code, text)
end
local function info(msg) print(color("36", "🔍 " .. msg)) end
local function success(msg) print(color("32", "✔ " .. msg)) end
local function fail(msg)
  io.stderr:write(color("31", "❌ " .. msg .. "\n"))
  os.exit(1)
end

-- --- Helper functions ---
local function file_exists(path)
  local f = io.open(path, "r")
  if f then f:close() return true end
  return false
end

local function read_yaml(path)
  local f, err = io.open(path, "r")
  if not f then return nil, err end
  local content = f:read("*a")
  f:close()
  local ok, result = pcall(lyaml.load, content)
  if not ok then
    fail("Failed to parse YAML file: " .. path)
  end
  return result
end

local function write_yaml(path, tbl)
  local f = assert(io.open(path, "w"))
  f:write(lyaml.dump({ tbl }))
  f:close()
end

local function deep_merge(base, override)
  for k, v in pairs(override) do
    if type(v) == "table" and type(base[k]) == "table" then
      deep_merge(base[k], v)
    else
      base[k] = v
    end
  end
  return base
end

-- --- Paths ---
local main_compose = "docker-compose.yml"
local override_compose = "docker-compose.override.yml"
local output_file = "docker-compose.flat.yml"

if not file_exists(main_compose) then
  fail(main_compose .. " not found.")
end

-- --- Parse main compose file ---
info("Reading main compose: " .. main_compose)
local main = read_yaml(main_compose)

-- Extract includes
local includes = {}
if main.include then
  for _, inc in ipairs(main.include) do
    table.insert(includes, inc)
  end
else
  fail("No includes found in " .. main_compose)
end

-- --- Merge included files ---
local merged = { services = {}, volumes = {}, networks = {}, secrets = {} }

for _, inc in ipairs(includes) do
  if not file_exists(inc) then
    info("Skipping missing include: " .. inc)
  else
    info("Merging include: " .. inc)
    local inc_yaml = read_yaml(inc)
    if inc_yaml.services then
      for svc, cfg in pairs(inc_yaml.services) do
        -- If service extends another file, resolve it
        if cfg.extends and cfg.extends.file and cfg.extends.service then
          local ext_file = cfg.extends.file
          local ext_service = cfg.extends.service
          if file_exists(ext_file) then
            local ext_yaml = read_yaml(ext_file)
            local ext_cfg = ext_yaml.services and ext_yaml.services[ext_service]
            if ext_cfg then
              cfg.extends = nil
              cfg = deep_merge(ext_cfg, cfg)
            end
          end
        end
        merged.services[svc] = deep_merge(merged.services[svc] or {}, cfg)
      end
    end

    if inc_yaml.volumes then
      merged.volumes = deep_merge(merged.volumes, inc_yaml.volumes)
    end
    if inc_yaml.networks then
      merged.networks = deep_merge(merged.networks, inc_yaml.networks)
    end
    if inc_yaml.secrets then
      merged.secrets = deep_merge(merged.secrets, inc_yaml.secrets)
    end
  end
end

-- --- Merge override file ---
if file_exists(override_compose) then
  info("Applying override: " .. override_compose)
  local override_yaml = read_yaml(override_compose)
  merged = deep_merge(merged, override_yaml)
end

-- --- Preserve networks & secrets from main compose ---
if main.networks then
  info("Preserving networks from main compose")
  merged.networks = deep_merge(merged.networks, main.networks)
end
if main.secrets then
  info("Preserving secrets from main compose")
  merged.secrets = deep_merge(merged.secrets, main.secrets)
end

-- --- Write output ---
write_yaml(output_file, merged)
success("Flattened compose written to " .. output_file)
print("Run with: docker compose -f " .. output_file .. " up -d")
