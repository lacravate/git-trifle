# encoding: utf-8

# this a helper class to setup test repo's as i
# see fit for the tests
# 'coulda done it otherwise but i like it that way

module Git

  class Trifle

    class UnremoteRemote < Git::Trifle

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

      def fixtures(fixtures, destination)
        FileUtils.cp_r File.join(File.dirname(__FILE__), 'fixtures', 'files', fixtures), destination
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

end

