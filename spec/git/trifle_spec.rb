# encoding: utf-8

require 'spec_helper'

describe Git::Trifle do

  let(:clone_remote) { '/tmp/spec/git-trifle/try' }
  let(:public_dir) { '/tmp/spec/git-trifle/foal' }
  let(:remote) { 'https://github.com/lacravate/git-trifle.git' }
  let(:clone) { '/tmp/spec/git-trifle/clone' }

  let(:git-trifle_options) {
    Hash[ clone_remote: clone_remote, public_dir: public_dir, remote: remote ]
  }

  let(:git-trifle_from_scratch) {
    impartor = Git::Impartor.new
    # clone from github if not done already
    impartor.trifle.clone remote: remote, path: clone unless File.exists? clone
    # remove previous copy of clone
    FileUtils.rm_rf clone_remote
    # and put a fresh one
    FileUtils.cp_r clone, clone_remote
    # Git with wis and domous
    impartor.from_repository git-trifle_options
  }

  describe 'cover' do
    before { git-trifle_from_scratch }

    it "can open already existing repository" do
      p = subject.cover path: public_dir
      # Trifle handles the last repository it opened
      subject.working_directory.should == public_dir

      h = subject.cover path: clone_remote
      # Trifle handles the last repository it opened
      subject.working_directory.should == clone_remote

      # Git::Base instances are different each time cover
      # is called
      p.should_not == h
      p.should_not == subject.cover(path: public_dir)
    end

    it "doesn't blow itself off when asked to cover a directory that's not a repo'" do
      subject.cover(path: File.basename(clone_remote)).should be_nil
    end
  end

  describe 'init' do
    it "inits a directory as a git repo' with a remote" do
      subject.init remote: remote, path: clone_remote

      subject.working_directory.should == '/tmp/spec/git-trifle/try'
      subject.remote.should == remote
    end

    it "inits a directory as a git repo'" do
      subject.init path: clone_remote

      subject.can_cover?('/tmp/spec/git-trifle/try').should be_true
      subject.working_directory.should == '/tmp/spec/git-trifle/try'
    end
  end

  describe 'clone' do
    it "clones a remote repo'" do
      subject.clone remote: remote, path: clone_remote

      subject.can_cover?('/tmp/spec/git-trifle/try').should be_true
      subject.working_directory.should == '/tmp/spec/git-trifle/try'
    end

    it "accepts swicthes to clone command" do
      # clones repo with no file in it, only the .git files
      # -n => no checkout
      subject.clone remote: remote, path: clone_remote, switches: ['-n']

      subject.can_cover?('/tmp/spec/git-trifle/try').should be_true
      subject.working_directory.should == '/tmp/spec/git-trifle/try'
      Dir['/tmp/spec/git-trifle/try/*'].size.should == 0
    end
  end

  describe 'reset' do
    #
    # hurl Git lib away from the spec's
    #
    let(:public_repo) { Git.open public_dir }

    before { 
      git-trifle_from_scratch

      File.truncate File.join(public_dir, 'README.md'), 0
      public_repo.add 'README.md'
    }

    it "performs a git reset on the handled repo'" do
      public_repo.status.added['README.md'].type.should == 'A'

      subject.cover path: public_dir
      subject.reset # HEAD

      public_repo.status.added['README.md'].should be_nil
      public_repo.status.changed['README.md'].type.should == 'M'
    end
  end

  describe 'working_directory' do
    before { git-trifle_from_scratch }

    it "should be able to give the repo working directory" do
      subject.cover path: '/tmp/spec/git-trifle/try'
      subject.working_directory.should == '/tmp/spec/git-trifle/try'
      subject.cover path:'/tmp/spec/git-trifle/foal'
      subject.working_directory.should == '/tmp/spec/git-trifle/foal'
    end
  end

  describe 'remote' do
    before { git-trifle_from_scratch }

    it "should return the first, possibly matching, remote url" do
      subject.cover path: '/tmp/spec/git-trifle/try'
      subject.remote.should == remote
      subject.remote('origin').should == remote
      subject.remote('plop').should be_nil
      subject.cover path:'/tmp/spec/git-trifle/foal'
      subject.remote.should == '/tmp/spec/git-trifle/try'
    end
  end

  describe 'files_paths' do
    before { git-trifle_from_scratch }

    it "should give all the files tracked by git" do
      subject.cover path: '/tmp/spec/git-trifle/try'
      subject.files_paths.should =~ ['README.md']
    end
  end

  describe 'can_cover?' do
    before { git-trifle_from_scratch }

    it "should be able to tell if a path given holds a git repository" do
      subject.can_cover?('/tmp/spec/git-trifle/try').should be_true
      subject.can_cover?('/tmp').should be_false
    end
  end

  describe 'local_remotes?' do
    before { git-trifle_from_scratch }

    it "should be able to tell if a path given holds a git repository" do
      subject.cover path: '/tmp/spec/git-trifle/try'
      subject.local_remotes?.should be_false
      subject.cover path: '/tmp/spec/git-trifle/foal'
      subject.local_remotes?.should be_true
    end
  end

  after {
    FileUtils.rm_rf '/tmp/spec/git-trifle/try'
    FileUtils.rm_rf '/tmp/spec/git-trifle/foal'
  }

end
