#!/usr/bin/env lua

local lyaml = require("lyaml")
local lfs = require("lfs")

-- debug --

local function tprint(tbl, indent)
  indent = indent or 0
  local prefix = string.rep("  ", indent)
  for k, v in pairs(tbl) do
    if type(v) == "table" then
      print(prefix .. tostring(k) .. " = {")
      tprint(v, indent + 1)
      print(prefix .. "}")
    else
      print(prefix .. tostring(k) .. " = " .. tostring(v))
    end
  end
end

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


local main_compose = "docker-compose.yml"
local override_compose = "docker-compose.override.yml"
local output_file = "docker-compose.flat.yml"

info("Reading main compose: " .. main_compose)
local main = read_yaml(main_compose)
tprint(main)
