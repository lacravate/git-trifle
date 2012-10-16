# encoding: utf-8

require 'git'

module Git

  class Trifle

    attr_reader :layer

    def cover(options)
      @layer = Git::Base.open options[:path]
    end

    def clone(options)
      path, name = File.split options[:path]
      remote = options.delete :remote

      # Dunno why i have to do that, but that's a fact. Ain't workin' without...
      FileUtils.mkdir_p path

      @layer = Git.clone remote, name, options.merge!(path: path)
    end

    def init(options)
      path = options.delete :path
      remote = options.delete :remote
      remote_name = options.delete(:remote_name) { |k| 'origin' }

      @layer = Git.init(path, options).tap do |git|
        git.add_remote remote_name, remote if remote
      end
    end

    def reset(*args)
      layer.reset *args
    end

    def working_directory
      layer.dir.to_s
    end

    def remote(name=nil)
      # yucky ? Maybe... But funny as well...
      layer.remotes.select { |r| name ? r.name == name : true }.map(&:url).first
    end

    def files_paths
      layer.ls_files.keys
    end

    def local_remotes?
      layer.remotes.all? { |r| File.exists? r.url }
    end

    def can_cover?(path)
      File.exists? File.join(path, '.git')
    end

  end

end
