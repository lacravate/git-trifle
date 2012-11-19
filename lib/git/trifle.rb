# encoding: utf-8

require 'git'

# This is merely an abstract layer to Git
# So far, i intend to have nothing more than a hand capable
# of seizing handlers on the row, on the fly

# My main goal here is to stick as little as possible to the
# underlying git lib. I also want to be able to change if i
# must, as painlessly as possible
#
# That's why the code below is a bit of Enumerable fest
# (to deplete the underlying lib of all class instances, and
# rather work on arrays of strings naming paths, branches,
# remotes, etc...)

# As well, as i am hacking at the stuff, i want to present
# exactly what i need of Git and its output in a convenient way

module Git

  class Trifle

    extend Forwardable

    STATUS_LIST = [:changed, :added, :deleted, :untracked].freeze

    # needless to do more than this for the following methods
    # very neat BTW
    DELEGATORS = %W|
      add_remote add branch branches
      current_branch commit dir fetch
      log ls_files merge pull push
      reset remotes remove
    |.
    map(&:to_sym).
    freeze

    def_delegators :@layer, *DELEGATORS

    def initialize(options={})
      if options.is_a? String
        cover options
      elsif options[:clone]
        clone options.merge!(remote: options[:clone])
      elsif options[:init]
        init options.merge!(path: options[:init])
      end
    end

    # hands on the handler
    def cover(path, options={})
      reset = options.delete :reset

      cook_layer do
        @dressing = reset && Proc.new { |trifle| trifle.reset if trifle.commits.any? }
        Git::Base.open path if can_cover? path
      end
    end

    def clone(options)
      path, name = File.split options[:path]
      remote = options.delete :remote
      reset = options.delete :reset

      cook_layer do
        # Dunno why i have to do that, but that's a fact. Ain't workin' without...
        FileUtils.mkdir_p path

        @dressing = reset && Proc.new { |trifle| trifle.reset if trifle.commits.any? }
        Git.clone remote, name, options.merge!(path: path)
      end
    end

    def init(options)
      path = options.delete :path
      remote = options.delete :remote
      remote_name = options.delete(:remote_name) { 'origin' }

      cook_layer do
        @dressing = remote && Proc.new { |trifle| trifle.add_remote remote_name, remote }
        Git.init path, options
      end
    end

    def create_branch(name, options={})
      # go to bed Captain, we don't need you here
      options[:track] = remote_branch_for(name) if options.delete :track_remote

      # mere delegation with options
      branch(name, options).create
    end

    def delete_branch(branch)
      # woodsman advice : dude, don't saw the branch you're on
      return if branch == current_branch
      # actual mere delegation
      branch(branch).delete
    end

    def push_branch(branch=nil)
      # we don't need Captain Obvious here
      # Rest Captain, greater tasks await you !
      branch ||= current_branch
      layer.push remote_for(branch), branch
    end

    # not very apt method name...
    # as we actually pull the current branch and
    # get the fresher version of all the other remote branches
    def pull_all_branches(options={})
      cover options[:path] if options[:path]

      # freshen the repo'
      fetch

      # updates the currennt branch and
      # creates a local branch for each on the remote
      pull remote_for(current_branch), current_branch
      all_branches_local
    end

    # there, an apt name. We want an up-to-date local branch
    # for each remote one (hence the violent despotic delete)
    def all_branches_local(options={})
      cover options[:path] if options[:path]

      # freshen the repo'
      fetch

      # creates a local branch for each on the remote
      other_remote_branches.each do |branch|
        local = branch.split('/').last
        delete_branch local if has_local_branch? local
        create_branch local, track: branch
      end
    end

    def checkout(name, options={})
      # avoid crash when repo' was just init'ed
      return false unless can_checkout? name

      # 0 but true
      return true if name == current_branch

      # -b option on command line
      options.merge! new_branch: true unless name.nil? || has_branch?(name)

      # wipe all options to let git to the job and checkout
      # tracking branch. YKWIM ? then DWIM
      options = {} if has_remote_branch? name
      @layer.checkout name, options
    end

    # i know, it exists in Git gem. But i prefer having here
    # with my own checkout method as a pivotal point for all
    # checkouts (as long as it is accurate)
    def checkout_files(files)
      files = Array(files).select { |path| files_paths.include? path }
      checkout nil, files: files if files
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

      # add || rm && commit
      send options[:verb], file
      commit "#{options[:verb]} #{file} (brought to you by #{self.class.name})"

      # Run Forrest, run !
      push options[:remote], options[:branch]
    end

    def commits(options={})
      options[:branch] ||= current_branch

      # yeah, reverse !
      # Because it's only in the Bible that i understand
      # why the first ones will be the last ones.
      log.object(options[:branch]).map(&:sha).reverse rescue []
    end

    def local_branches
      # sorry, what ?
      branches.local.map &:name
    end

    def remote_branches
      # sorry, what now ?
      branches.remote.map &:name
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
      cover options[:path] if options[:path]
      # yucky ? Maybe... But funny as well...
      remotes.select { |r| options[:name] ? r.name == options[:name] : true }.map(&:url).first
    end

    def remote_name(options={})
      # yucky ? Maybe... But funny as well...
      remotes.select { |r| options[:url] ? r.url == options[:url] : true }.map(&:name).first
    end

    def reset_to_remote_branch!
      reset remote_branch_for(current_branch)
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
        s.merge! type => @layer.status.send(type).keys
      end
    end

    def alterations(options={})
      # which files have a status
      # represented as in status above
      cover options[:path] if options[:path]
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
      dir.to_s
    end

    def files_paths
      # for now, need only paths names
      ls_files.keys
    end

    def initial_commit
      # get the repo' initial commit
      # the trinary with master is probably useless
      branch = has_branch?('master') ? 'master' : local_branches.first
      commits(branch: branch).first
    end

    def uncover!
      @layer = nil
    end

    def wipe_directory!
      # not too clever way to do that
      # i remove directories but try to avoid
      # removing the repo'
      files_paths.each do |f|
        f = File.join directory, f
        d = File.dirname f
        FileUtils.rm_rf d == directory ? f : d
      end
    end

    def local_remotes_only?
      # well... yeah, i like to make people laugh
      remotes.all? { |r| File.exists? r.url }
    end

    def can_cover?(path)
      # is there any other way ?
      # dunno for now
      File.exists? File.join(path, '.git')
    end

    def has_updates?(branch=nil)
      branch ||= current_branch
      fetch

      # do and return nothing unless... Well, you can read that
      # all by yourself
      return unless has_local_branch?(branch) && has_remote_branch?(branch)

      # potential difference between local and remote
      commits(branch: branch) != commits(branch: remote_branch_for(branch))
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

    # if i can, i'll think of a more teenily tinily specific
    # used-only-once method later on
    def remote_branch_only?(name)
      has_remote_branch?(name) && !has_local_branch?(name)
    end

    # do we have a remote branch or do we have at least one commit
    # on this repo'
    def can_checkout?(name)
      has_remote_branch?(name) || local_branches.any?
    end

    # Potato Potato method, i love it
    def any_remote?
      remotes.any?
    end

    def covers_anything?
      !!@layer
    end

    def altered?
      get_status != @status
    end

    private

    def cook_layer
      # i like tap. Did i say that already ?
      tap do |trifle|
        @layer = yield
        @status = nil
        @dressing.call(trifle) if @dressing
      end
    end

  end

end
