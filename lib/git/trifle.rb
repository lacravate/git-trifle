# encoding: utf-8

require 'git'

# This is merely an abstract layer to Git to enable me to switch to
# any other underlying lib' that would do the job
# ... And present exactly what i need of Git in a convenient way

module Git

  class Trifle

    attr_reader :layer

    def cover(options)
      # handler
      # Raise ?
      @layer = Git::Base.open options[:path] if can_cover?(options[:path])
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

      # i like tap
      # set the remote if we have it
      @layer = Git.init(path, options).tap do |git|
        git.add_remote remote_name, remote if remote
      end
    end

    def reset(*args)
      # mere delegation here
      layer.reset *args
    end

    def working_directory
      # explanation here ?
      # Really ?
      layer.dir.to_s
    end

    def remote(name=nil)
      # yucky ? Maybe... But funny as well...
      layer.remotes.select { |r| name ? r.name == name : true }.map(&:url).first
    end

    def files_paths
      # for now, don't need the Git::StatusFile
      # only paths names
      layer.ls_files.keys
    end

    def local_remotes?
      # well... yeah, i like to make people laugh
      layer.remotes.all? { |r| File.exists? r.url }
    end

    def can_cover?(path)
      # is there any other way ?
      # dunno for now
      File.exists? File.join(path, '.git')
    end

  end

end
