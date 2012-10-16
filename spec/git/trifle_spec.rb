# encoding: utf-8

require 'spec_helper'

describe Git::Trifle do

  let(:clone_remote) { '/tmp/spec/git-trifle/git-trifle' }
  let(:public_dir) { '/tmp/spec/git-trifle/Git' }
  let(:remote) { 'https://github.com/lacravate/git-trifle.git' }
  let(:git-trifle_from_scratch) {
    {
      clone_remote: clone_remote,
      public_dir: public_dir,
      remote: remote
    }
  }

  describe 'cover' do
    before { Git::Impartor.new.from_scratch git-trifle_from_scratch }

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
  end

  describe 'init' do
    it "inits a directory as a git repo'" do
      subject.init remote: remote, path: clone_remote

      subject.working_directory.should == '/tmp/spec/git-trifle/git-trifle'
      subject.remote.should == remote
    end
  end

  describe 'clone' do
    it "clones a remote repo'" do
      subject.clone remote: remote, path: clone_remote

      subject.working_directory.should == '/tmp/spec/git-trifle/git-trifle'
      File.exists?('/tmp/spec/git-trifle/git-trifle/.git').should be_true
    end

    it "accepts swicthes to clone command" do
      # clones repo with no file in it, only the .git files
      # -n => no checkout
      subject.clone remote: remote, path: clone_remote, switches: ['-n']

      subject.working_directory.should == '/tmp/spec/git-trifle/git-trifle'
      File.exists?('/tmp/spec/git-trifle/git-trifle/.git').should be_true
      Dir['/tmp/spec/git-trifle/git-trifle/*'].size.should == 0
    end
  end

  describe 'reset' do
    let(:public_repo) { Git.open public_dir }

    before { 
      Git::Impartor.new.from_scratch git-trifle_from_scratch

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
    before { Git::Impartor.new.from_scratch git-trifle_from_scratch }

    it "should be able to give the repo working directory" do
      subject.cover path: '/tmp/spec/git-trifle/git-trifle'
      subject.working_directory.should == '/tmp/spec/git-trifle/git-trifle'
      subject.cover path:'/tmp/spec/git-trifle/Git'
      subject.working_directory.should == '/tmp/spec/git-trifle/Git'
    end
  end

  describe 'remote' do
    before { Git::Impartor.new.from_scratch git-trifle_from_scratch }

    it "should return the first, possibly matching, remote url" do
      subject.cover path: '/tmp/spec/git-trifle/git-trifle'
      subject.remote.should == remote
      subject.remote('origin').should == remote
      subject.remote('plop').should be_nil
      subject.cover path:'/tmp/spec/git-trifle/Git'
      subject.remote.should == '/tmp/spec/git-trifle/git-trifle'
    end
  end

  describe 'files_paths' do
    before { Git::Impartor.new.from_scratch git-trifle_from_scratch }

    it "should give all the files tracked by git" do
      subject.cover path: '/tmp/spec/git-trifle/git-trifle'
      subject.files_paths.should =~ ['README.md']
    end
  end

  describe 'can_cover?' do
    before { Git::Impartor.new.from_scratch git-trifle_from_scratch }

    it "should be able to tell if a path given holds a git repository" do
      subject.can_cover?('/tmp/spec/git-trifle/git-trifle').should be_true
      subject.can_cover?('/tmp').should be_false
    end
  end

  describe 'local_remotes?' do
    before { Git::Impartor.new.from_scratch git-trifle_from_scratch }

    it "should be able to tell if a path given holds a git repository" do
      subject.cover path: '/tmp/spec/git-trifle/git-trifle'
      subject.local_remotes?.should be_false
      subject.cover path: '/tmp/spec/git-trifle/Git'
      subject.local_remotes?.should be_true
    end
  end

  after {
    FileUtils.rm_rf '/tmp/spec/git-trifle'
  }

end
