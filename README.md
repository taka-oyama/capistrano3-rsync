# Capistrano3::Rsync

Deploy with Capistrano using Rsync.

Just add the following lines to your `config/deploy`.rb or `config/deploy/[RAILS_ENV].rb`:

    scm: :rsync

## Installation

Add the following to your application's Gemfile:

    gem 'capistrano', '~> 3.2'
    gem 'capistrano3-rsync', '~> 0.1'


## Usage

If you don't want the bundler to query rubygems.org or any other private repos,
you should add the `--local` option to your bundler_flags option like below.

    set :bundle_flags, '--deployment --quiet --local'

