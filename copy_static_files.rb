#!/usr/bin/env ruby
require 'git'
require 'yaml'

config = File.open('conf.yaml', 'r') do |f|
  YAML.load(f)
end

DEST = config["public_dest"]
DEST.freeze

FileUtils.mkdir_p(DEST)

FileUtils.cp_r(Dir.glob('public/*'), DEST)
