# encoding: utf-8

require 'git'

# This is merely an abstract layer to Git
# So far, i intend to have nothing more than a hand capable
# of seizing handlers on the row, on the fly

# My main goal here is to stick as little as possible to the
# underlying git lib. I also want to be able to change if i
# must as painlessly as possible
#
# That's why the code below is a bit of Enumerable fest
# (to deplete the underlying lib of all class instances and
# rather work on arrays of strings naming, paths, branches,
# remotes, etc...)

# As well, as i am hacking at the stuff, i want to present
# exactly what i need of Git and its output in a convenient way

module Git

  class Trifle

    extend Forwardable

    STATUS_LIST = [:changed, :added, :deleted, :untracked].freeze

    # needless to do more than this for the following methods
    # very neat BTW
    DELEGATORS = %W|add branch current_branch commit fetch merge pull push reset remove|.
      map(&:to_sym).
      freeze

    def_delegators :@layer, *DELEGATORS

    attr_reader :layer

    # hands on the handler
    def cover(options)
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
