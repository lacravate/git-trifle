# encoding: utf-8

require 'spec_helper'

describe Git::Trifle do

  let(:trifle) { described_class.new }

  # characteristics of the un-remote remote
  let(:remote_url) { 'https://github.com/lacravate/git-trifle.git' }
  let(:remote_dir) { '/tmp/spec/git-trifle/git-trifle' }
  let(:remote_clone) { trifle.clone remote: remote_url, path: remote_dir }

  # git-trifle arch'
  let(:clone_remote) { '/tmp/spec/git-trifle/try' }
  let(:clone_local) { '/tmp/spec/git-trifle/foal' }
  let(:remote) { remote_dir }

  # setup from scratch with that
  let(:git-trifle_options) { Hash[ clone_remote: clone_remote, clone_local: clone_local, remote: remote ] }
  let(:git-trifle_from_scratch) { Git::Impartor.new.tap { |w| w.impart git-trifle_options } }

  #

  before {
    FileUtils.rm_rf remote_dir
    remote_clone
  }

  describe 'cover' do
    before { git-trifle_from_scratch }

    it "can open already existing repository" do
      p = subject.cover clone_local
      # Trifle handles the last repository it opened
      subject.directory.should == clone_local

      h = subject.cover clone_remote
      # Trifle handles the last repository it opened
      subject.directory.should == clone_remote

      # Git::Base instances are different each time cover
      # is called
      p.should_not == h
      p.should_not == subject.cover(clone_local)
    end

    it "doesn't blow itself off when asked to cover a directory that's not a repo'" do
      subject.cover(File.basename(clone_remote)).should be_nil
    end
  end

  describe 'init' do
    it "inits a directory as a git repo'" do
      subject.init path: clone_remote

      # this is repo'
      subject.can_cover?('/tmp/spec/git-trifle/try').should be_true
      subject.directory.should == '/tmp/spec/git-trifle/try'
      subject.remote_url.should be_nil
    end

    it "inits a directory as a git repo' with a remote" do
      subject.init remote: remote, path: clone_remote

      # how about we do a little more ?
      subject.directory.should == '/tmp/spec/git-trifle/try'
      # Wow ! Man !
      subject.remote_url.should == remote
    end
  end

  describe 'clone' do
    it "clones a remote repo'" do
      subject.clone remote: remote, path: clone_remote

      # Ta Dah !
      subject.can_cover?('/tmp/spec/git-trifle/try').should be_true
      subject.directory.should == '/tmp/spec/git-trifle/try'
    end

    it "accepts swicthes to clone command" do
      # clones repo with no file in it, only the .git files
      # -n => no checkout
      subject.clone remote: remote, path: clone_remote, switches: ['-n']

      subject.can_cover?('/tmp/spec/git-trifle/try').should be_true
      subject.directory.should == '/tmp/spec/git-trifle/try'
      Dir['/tmp/spec/git-trifle/try/*'].size.should == 0

      # ruby git lib here, hurl that away when you can
      subject.branch('Plop').create

      # clones repo and checkout to Plop
      # -b Plop
      subject.clone remote: clone_remote, path: "#{clone_remote}_Plop", switches: ['-b', 'Plop']
      subject.current_branch.should == 'Plop'
    end
  end

  describe 'checkout and branches' do
    before {
      git-trifle_from_scratch
      subject.cover clone_local
      # creates a Plop branch
      subject.checkout 'Plop'
      # HMV
      subject.checkout 'master'
    }

    it "gives a list of remote branches names except current" do
      # useful and self-explanatory
      # otherwise i really can't do anything for you
      subject.other_remote_branches.should == ["origin/__w_all"]
    end

    it "can retrieve the remote branch name" do
      # master was pushed on remote named origin
      # if you have two master branches, you have
      # a problem, buddy
      subject.remote_branch_for('master').should == 'origin/master'
      # nil when it dunno
      subject.remote_branch_for('Plop').should be_nil
    end

    it "can retrieve the remote name for a branch" do
      # same as above with remote_branch_for
      # with same potential problem
      subject.remote_for('master').should == 'origin'
      # first remote when it dunno (but branch exists)
      subject.remote_for('Plop').should == 'origin'
      # nil when it dunno nothin', samo' samo'
      subject.remote_for('Plap').should be_nil
    end

    it "knows whether a branch exists or not" do
      # whether it is local or remote
      subject.has_branch?('Plop').should be_true
    end

    it "should not blast off when asked to checkout on a repo' with no commit" do
      FileUtils.mkdir_p '/tmp/spec/git-trifle/plop'
      t = described_class.new
      t.init path: '/tmp/spec/git-trifle/plop'
      # didn't do it, didn't die
      t.checkout('plopinette').should be_false
    end

    it "should be able to switch to another existing branch" do
      # checks out initial context
      subject.has_branch?('Plop').should be_true
      subject.current_branch.should == 'master'

      subject.checkout 'Plop'

      # i am quite a chatterbox, but i am out of words here
      # let me call captain Obvious...
      # Captain !?
      subject.current_branch.should == 'Plop'
    end

    it "should be able to switch to another branch it created" do
      subject.has_branch?('Plip').should be_false
      subject.current_branch.should == 'master'

      subject.checkout 'Plip'

      # another example of the DWIM
      subject.has_branch?('Plip').should be_true
      subject.current_branch.should == 'Plip'
    end

    it "should return the list of local branches" do
      subject.local_branches.should =~ ['Plop', 'master', '__w_all']
    end

    it "should return the list of remote branches" do
      subject.remote_branches.should =~ ['origin/HEAD', 'origin/master', 'origin/__w_all']
    end

    context 'branch tracking and branch pulling' do
      before {
        subject.cover clone_local
        subject.checkout 'Ploup'
        subject.push 'origin', 'Ploup'
        subject.checkout 'master'
        subject.branch('Ploup').delete
      }

      it "creates a local branch tracking a remote" do
        # initial context check
        current = subject.current_branch
        subject.has_local_branch?('Ploup').should be_false

        subject.create_branch 'Ploup', track: 'origin/Ploup'

        # it did that without checking out to the created branch
        current.should == subject.current_branch
        # tracking branch is created
        subject.has_local_branch?('Ploup').should be_true
        subject.has_remote_branch?('Ploup').should be_true
        subject.commits(branch: 'Ploup').should =~ subject.commits(branch: 'origin/Ploup')
      end

      it "creates a local branch tracking a remote for every remote branch" do
        subject.pull_all_branches

        # for all the remote branches, an up-to-date local one is created
        subject.other_remote_branches.each do |branch|
          # well, yeah... That has to be amended
          local = branch.split('/').last
          # tracking branch is created
          subject.has_local_branch?(local).should be_true
          subject.commits(branch: branch).should =~ subject.commits(branch: local)
        end
      end
    end

    context "checkout from a certain commit" do
      it "should create a local branch with one commit" do
        subject.checkout 'Plip', commit: subject.commits.first

        # Yatta !
        subject.current_branch.should == 'Plip'
        subject.commits.size.should == 1
      end
    end

    context "remote branch exists and local does not" do
      before {
        FileUtils.touch File.join(subject.directory, "Plep")
        subject.push_file "Plep", branch: "Plop"
        subject.checkout 'master'
        subject.branch('Plop').delete
      }

      it "should know when local branch does not exists" do
        # and it does
        subject.has_local_branch?('Plop').should be_false
      end

      it "should know when remote branch exists" do
        # and it does
        subject.has_remote_branch?('Plop').should be_true
      end

      it "should know when branch exists, remote or local" do
        # and it does
        subject.has_branch?('Plop').should be_true
      end

      it "should create a tracking branch when remote branch exists" do
         subject.checkout 'Plop'

         # DWIM again
         # simple checkout with a branch name reflecting a remote one
         # creates a tracking one
         subject.has_local_branch?('Plop').should be_true
         subject.commits.size.should == 2
      end
    end

    context 'checkout_w_branch' do
      before {
        FileUtils.touch File.join(subject.directory, "Plep")
        subject.push_file "Plep", branch: "Plop"
        subject.checkout 'master'
        subject.branch('Plop').delete
      }

      it "should create a new branch with one initial commit" do
        # git-trifle branch are named differently
        # but it's not a design so far, and it's irrelevant here
        subject.checkout_w_branch 'Plip'
        subject.current_branch.should == 'Plip'
        # design is there, a git-trifle branch stems from the initial commit
        subject.commits.size.should == 1
        subject.commits.first.should == subject.commits(branch: 'master').first
      end

      it "should checkout a branch tracking the remote one of the same name" do
        subject.has_local_branch?('Plop').should be_false

        subject.checkout_w_branch 'Plop'

        # checkout_w_branch behaves like a mere checkout when
        # remote branch exists
        subject.current_branch.should == 'Plop'
        subject.commits.size.should == 2
        subject.commits.last.should_not == subject.commits(branch: 'master').first
        subject.commits(branch: 'origin/Plop').should =~ subject.commits
      end
    end
  end

  describe 'status and alterations' do
    before {
      git-trifle_from_scratch
      File.truncate File.join(clone_local, 'README.md'), 0
      FileUtils.touch File.join(clone_local, 'Plopinou')
    }

    it "should be able to get the current status of a repo'" do
      subject.cover clone_local
      # files status as a Hash
      subject.status.should ==  { changed: ["README.md"], added: [], deleted: [], untracked: ['Plopinou'] }
      # a chosen subset of it
      subject.status(:changed).should == { changed: ["README.md"] }
    end

    it "should give a list of files according to git status" do
      subject.cover clone_local

      subject.cover clone_local
      # other subsets of the status, returning only the files list
      subject.files_with_status(:untracked).should == ['Plopinou']
      subject.files_with_status(:added).should == []
      subject.files_with_status(:changed).should == ['README.md']
      subject.files_with_status(:deleted).should == []
    end

    it "should list the alterations by type" do
      # same as before, except that the filter is on files presence in lists
      subject.cover clone_local
      subject.alterations.should == { untracked: ['Plopinou'], changed: ['README.md'] }
      # another subset of the above-mentionned subset
      subject.alterations(status: :changed).should == { changed: ['README.md'] }
    end
  end

  describe 'push file' do
    before {
      git-trifle_from_scratch

      subject.cover clone_local
      subject.checkout 'Plop'
      File.truncate File.join(clone_local, 'README.md'), 0
      # add, commit, and push a file alteration to a new branch
      subject.push_file 'README.md'
    }

    it "adds a file, commits and push the alteration on the remote" do
      # and it shows
      subject.commits.size.should == 2
      # nothing left to be done
      subject.alterations.should == {}
      # pushed
      subject.has_remote_branch?('Plop').should be_true
      subject.commits(branch: 'origin/Plop').should =~ subject.commits
    end
  end

  describe 'directory' do
    before { git-trifle_from_scratch }

    it "should be able to give the repo working directory" do
      # bleeding edge feature... Trifle instance knows how to
      # render a parameter passed to one of its methods
      subject.cover '/tmp/spec/git-trifle/try'
      subject.directory.should == '/tmp/spec/git-trifle/try'
      subject.cover'/tmp/spec/git-trifle/foal'
      subject.directory.should == '/tmp/spec/git-trifle/foal'
    end
  end

  describe 'remote_url' do
    before { git-trifle_from_scratch }

    it "should return the first, possibly matching, remote url" do
      subject.cover '/tmp/spec/git-trifle/try'
      # finds the remote url, gives away the first one if several are
      # found and you were not specific enough
      subject.remote_url.should == remote
      # now you are specific enough
      subject.remote_url(name: 'origin').should == remote
      # dunno that one buddy...
      subject.remote_url(name: 'plop').should be_nil
      # gold fish memory
      subject.cover'/tmp/spec/git-trifle/foal'
      subject.remote_url.should == '/tmp/spec/git-trifle/try'
    end

    it "should be able to retrieve the remote name" do
      subject.cover '/tmp/spec/git-trifle/try'
      # once more, not specific enough buddy, i did what i could
      subject.remote_name.should == 'origin'
      # there you go !
      subject.remote_name(url: '/tmp/spec/git-trifle/git-trifle').should == 'origin'
      # there you go... away.
      subject.remote_name(url: 'plop').should be_nil
    end
  end

  describe 'commits and push_branch' do
    before { git-trifle_from_scratch }
    let(:lousy_commit) {
      File.truncate File.join(clone_local, 'README.md'), 0
      subject.add 'README.md'
      subject.commit "lousy test commit"
    }

    it "lists the commits chronologically" do
      # check initial context
      subject.cover clone_local
      first = subject.commits.first
      subject.commits.size.should == 1

      # lousy commit
      lousy_commit

      # everything's there, represented the way
      # i want and understand
      subject.commits.size.should == 2
      subject.commits.first.should == first
    end

    it "lists the commits of another branch" do
      subject.cover clone_local

      # lousy commit
      lousy_commit

      subject.checkout 'Plop'

      subject.current_branch.should == 'Plop'
      subject.commits.size.should == 2
      # incredible feature isn't it ?
      # but it's useful
      subject.commits(branch: '__w_all').size.should == 2
    end

    it "knows how to push a branch with no paramter" do
      subject.cover clone_local
      # this only to avoid pushing on remote current branch :
      # when remote is non-bare, git refuses pushes on remote current branch
      subject.checkout 'Plop'
      # lousy commit
      lousy_commit

      subject.push_branch

      # local and remote are sync'ed
      subject.commits(branch: subject.current_branch).should =~ subject.commits(branch: subject.remote_branch_for(subject.current_branch))
    end

    it "knows how to push a branch with minimal paramters" do
      subject.cover clone_local
      # this only to avoid pushing on remote current branch :
      # when remote is non-bare, git refuses pushes on remote current branch
      subject.checkout 'Plop'
      # lousy commit
      lousy_commit

      subject.push_branch 'Plop'

      # local and remote are sync'ed
      subject.commits(branch: '__w_all').should =~ subject.commits(branch: subject.remote_branch_for('__w_all'))
    end
  end

  describe 'files_paths related' do
    before {
      git-trifle_from_scratch
      FileUtils.cp_r File.join(RSpec.configuration.fixtures_dir, 'files', 'Plip'), clone_remote
      # subject not available here ? Ok...
      # i like tap... Though it's perfectly unnecessary here. But i like it.
      described_class.new.tap { |t| t.cover '/tmp/spec/git-trifle/try'; t.add 'Plip' }
    }

    it "should give all the files tracked by git" do
      subject.cover '/tmp/spec/git-trifle/try'
      # lists the files, not the directories
      subject.files_paths.should =~ ['README.md', "Plip/Plap", "Plip/Plop"]
    end

    it "should wipe out all file in directory" do
      subject.cover '/tmp/spec/git-trifle/try'
      # everything must disappear
      subject.wipe_directory!
      Dir['/tmp/spec/git-trifle/try/*'].empty?.should be_true
    end
  end

  describe 'can_cover?' do
    before { git-trifle_from_scratch }

    it "should be able to tell if a path given holds a git repository" do
      # to avoid blowing out in the ether, dirty, when false
      subject.can_cover?('/tmp/spec/git-trifle/try').should be_true
      subject.can_cover?('/tmp').should be_false
    end
  end

  describe 'local_remotes_only?' do
    before { git-trifle_from_scratch }

    it "should be able to tell if a path given holds a git repository" do
      # another a teenily tinily little shrivel short scope method
      # to wrap this select/map/reject/inject fest
      subject.cover '/tmp/spec/git-trifle/foal'
      subject.local_remotes_only?.should be_true
    end
  end

  after {
    FileUtils.rm_rf '/tmp/spec/git-trifle/try'
    FileUtils.rm_rf '/tmp/spec/git-trifle/foal'
  }

end
