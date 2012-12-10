# encoding: utf-8

require File.expand_path('../../lib/git-trifle.rb', __FILE__)

require 'unremote_remote'

FileUtils.rm_rf '/tmp/spec/git-trifle'
FileUtils.mkdir_p '/tmp/spec/git-trifle'

RSpec.configure do |config|
  # --init
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
