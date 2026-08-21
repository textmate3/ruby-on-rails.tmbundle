require 'test/unit'
require "fileutils"
$:.push __dir__
$:.push File.expand_path('../lib', __dir__)
FIXTURE_PATH = File.expand_path('app_fixtures', __dir__)

def ruby(command)
  `/usr/bin/env ruby #{command}`
end
