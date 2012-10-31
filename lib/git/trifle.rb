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

    def create_branch(name, options={})
      layer.branch(name, options).create
    end

    def delete_branch(branch)
      # woodsman advice : dude, don't saw the branch you're on
      return if branch == current_branch
      layer.branch(branch).delete
    end

    def push_branch(branch=nil)
      branch ||= current_branch
      layer.push remote_for(branch), branch
    end

    def pull_all_branches(options={})
      cover path: options[:path] if options[:path]

      # freshen the repo'
      fetch
      # updates the currennt branch
      pull remote_for(current_branch), current_branch
      # creates a local branch for each on the remote
      other_remote_branches.each do |branch|
        local = branch.split('/').last
        delete_branch local if has_local_branch? local
        create_branch local, track: branch
      end
    end

    def checkout(name, options={})
      # avoid crash when repo' was just init'ed
      return false unless any_commits?
      # 0 but true
      return true if name == current_branch

      # -b option on command line
      options.merge! new_branch: true unless has_branch? name

      # wipe all options to let git to the job and checkout
      # tracking branch. YKWIM ? then DWIM
      options = {} if has_remote_branch? name
      layer.checkout name, options
    end

    def checkout_w_branch(branch, options={})
      # a git-trifle branch always stems from initial commit
      # so enforce this if it does not exist yet
      options.merge!(commit: initial_commit) unless has_branch? branch
      checkout branch, options
    end

    def push_file(file, options={})
      # yeah yeah i allow to push on another branch in one line
      # not sure it's a good idea. We'll see...
      options[:branch] ||= current_branch
      options[:remote] ||= remote_for(options[:branch])
      # not sure of the option name. Well...
      options[:verb] ||= 'add'

      # not always a good idea to actually perform
      # a checkout here but i let checkout method know that
      checkout options[:branch]
      # add || rm
      send options[:verb], file
      commit "#{options[:verb]} #{file} (brought to you by #{self.class.name})"
      # Run Forrest, run !
      push options[:remote], options[:branch]
    end

    def commits(options={})
      # yeah, reverse !
      # Because it's only in the Bible that i understand
      # why the first ones will be the last ones.
      layer.log.object(options[:branch] || current_branch).map{ |commit| commit.sha }.reverse
    end

    def local_branches
      layer.branches.local.map &:name
    end

    def remote_branches
      layer.branches.remote.map &:name
    end

    def remote_for(branch)
      # get out of here if i don't know you at all
      return unless has_branch? branch
      # ok you got me... I Perl'ed when i was younger
      remote_branches.
        map { |b| b.split '/' }. # returns a list of remote branch name elements
        map { |elements| elements[-2] if elements.last == branch }. # list of nil or remote names
        compact.first || remote_name
    end

    def remote_branch_for(branch)
      # that one's even funnier
      remote_branches.
        map { |b| b.split '/' }. # returns a list of remote branch name elements
        map { |elements| "#{elements[-2]}/#{elements[-1]}" if elements.last == branch }. # list of nil or remote branch names
        compact.first
    end

    def remote_url(options={})
      cover path: options[:path] if options[:path]
      # yucky ? Maybe... But funny as well...
      layer.remotes.select { |r| options[:name] ? r.name == options[:name] : true }.map(&:url).first
    end

    def remote_name(options={})
      # yucky ? Maybe... But funny as well...
      layer.remotes.select { |r| options[:url] ? r.url == options[:url] : true }.map(&:name).first
    end

    def other_remote_branches
      # i like to make myself laugh as well
      remote_branches.reject { |branch| branch == 'origin/HEAD' || branch == remote_branch_for(current_branch) }
    end

    def status(type=nil)
      types = (type && STATUS_LIST.include?(type)) ? [type] : STATUS_LIST

      # Status as Hash of arrays, keys are statuses
      types.inject({}) do |s, type|
        # i.g layer.status.changed and keys only to get the filenames
        s.merge! type => layer.status.send(type).keys
      end
    end

    def alterations(options={})
      # which files have a status
      # represented as in status above
      cover path: options[:path] if options[:path]
      status(options[:status]).select { |t, files| files.any? }
    end

    def files_with_status(s)
      # i like being specific
      status(s).values.flatten
    end

    def ls_tree(options={})
      # do i use that ?
      sha = options.delete(:sha) { current_branch }
      layer.ls_tree(sha, options).values.map(&:keys).flatten
    end

    def directory
      # explanation here ?
      # Really ?
      layer.dir.to_s
    end

    def files_paths
      # for now, need only paths names
      layer.ls_files.keys
    end

    def initial_commit
      # get the repo' initial commit
      # the trinary with master is probably useless
      branch = has_branch?('master') ? 'master' : local_branches.first
      commits(branch: branch).first
    end

    def wipe_directory!
      # not too clever way to do that
      # i remove directories but try to avoid
      # removinng the repo'
      files_paths.each do |f|
        f = File.join directory, f
        d = File.dirname f
        FileUtils.rm_rf d == directory ? f : d
      end
    end

    def local_remotes_only?
      # well... yeah, i like to make people laugh
      layer.remotes.all? { |r| File.exists? r.url }
    end

    def can_cover?(path)
      # is there any other way ?
      # dunno for now
      File.exists? File.join(path, '.git')
    end

    def has_branch?(name)
      # whether local or remote
      has_local_branch?(name) || has_remote_branch?(name)
    end

    def has_local_branch?(name)
      local_branches.include? name
    end

    def has_remote_branch?(name)
      remote_branches.map { |b| b.split('/').last }.include? name
    end

    def any_commits?
      local_branches.any?
    end

  end

end
