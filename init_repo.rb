#!/usr/bin/env ruby
require 'git'
require 'yaml'

config = File.open('conf.yaml', 'r') do |f|
  YAML.load(f)
end

REPO = config["source_repogitory"]
REPO.freeze

if Dir.exists?(REPO) then
  STDERR.puts "[ERROR] 既に #{REPO} ディレクトリが存在します。何もせずに終了します。"
  exit -1
end

g = Git.init(REPO)

FileUtils.mkdir_p(REPO+"/src")
FileUtils.mkdir_p(REPO+"/img")
FileUtils.touch(REPO+"/src/.gitkeep")
FileUtils.touch(REPO+"/img/.gitkeep")

g.add
g.commit('Initial commit')
