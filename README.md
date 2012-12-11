# Git Trifle

Trifle is yet another layer around ruby git libs. It intends to stick as
little as possible to the said underlying lib' (a slightly modified version of
schacon's ruby-git at the moment).

## Installation

Ruby 1.9.2 is required.

Install it with rubygems:

    gem install git-trifle

With bundler, add it to your `Gemfile`:

``` ruby
gem "git-trifle"
```

## Use


``` ruby
require 'git-trifle'

# to open an already existing git repo'
t = Git::Trifle.new 'repo_path'

# to clone this gem source repo' to 'path' folder
t = Git::Trifle.new clone: 'https://github.com/lacravate/git-trifle', path: 'path'

# to init a new local git repo' and set remote to this gem source repo
t = Git::Trifle.new init: 'path', remote: 'https://github.com/lacravate/git-trifle' 

# you don't need an instance per repo' (up to you)
# and switch the handler from one repo' to the other
t.cover 'repo_path'
t.alterations do |type, file|
  puts "#{file} was created in working directory" if type == :untracked
end

```

then :

``` ruby
if t.has_remote_branch? 'new_branch'
  t.checkout 'new_branch', track_remote: true
  t.push_file 'plop.txt' # to add, commit, and push to newly created branch
end
```

Take a look at the code, not for its beauty (it's a bit of an Enumarable fest),
to have an idea of the API.


## Why oh why ?!

`There is already ruby-git, grit, rugged, and miner's comming up, are you kidding me ?!`

But exactly, you just said it : it looks like the status of ruby git libraries
(whatever their approach) is not stabilised. Therefore you can have hard times
at finding one single library that does all you need (let alone you can trust
the project perspectives).

So...

So, i decided i would write a little something (so long for the little). It
allowed me to do what i need, without the fear of having to rewrite everything,
if ever an unavoidable Git Ruby wrapper emerges.


Copyright
---------

I was tempted by the WTFPL, but i have to take time to read it.
So far see LICENSE.
