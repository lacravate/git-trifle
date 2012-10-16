# encoding: utf-8

require File.expand_path('../../lib/git-trifle.rb', __FILE__)

FileUtils.rm_rf '/tmp/spec/git-trifle'
FileUtils.mkdir_p '/tmp/spec/git-trifle'

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.add_setting :fixtures_dir, default: File.expand_path('../fixtures', __FILE__)
end

#

module Git

  class UnremoteRemote < Trifle

    UNREMOTE_DIR = '/tmp/spec/git-trifle/unremote'
    CLONE_DIR = '/tmp/spec/git-trifle/git-trifle'

    def initialize(options={})
      super

      if File.exists?(UNREMOTE_DIR) && can_cover?(UNREMOTE_DIR)
        @urr = cover(UNREMOTE_DIR)
      else
        init_unremote
      end
    end

    def clone_unremote
      FileUtils.cp_r @urr.directory, CLONE_DIR
    end

    def destroy_unremote
      FileUtils.rm_rf CLONE_DIR
    end

    def fresh_start
      destroy_unremote
      clone_unremote
    end

    def clone_dir
      CLONE_DIR
    end

    private

    def init_unremote
      @urr ||= init(path: '/tmp/spec/git-trifle/unremote').tap do |urr|
        File.open(urr.full_path('README.md'), 'w') { |f| f.write 'README.md' }
        urr.add 'README.md'
        urr.commit 'README.md'
      end
    end

  end

end

