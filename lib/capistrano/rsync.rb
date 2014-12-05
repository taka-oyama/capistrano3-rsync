load File.expand_path(File.dirname(__FILE__) + "/tasks/rsync.rake")

require 'capistrano/scm'

class Capistrano::Rsync < Capistrano::SCM
  module DefaultStrategy
    def test
      test! " [ -f #{repo_path}/.rsync ] "
    end

    def check
      true
    end

    def clone
      context.execute :mkdir, "-p", repo_path
    end

    def test_local
      test! File.directory?(local_build_path)
    end

    def clone_local
      context.execute :git, "clone", repo_url, local_build_path, "--recursive"
    end

    def update_local
      context.execute :git, "fetch --quiet --all --prune"
      context.execute :git, "reset --hard origin/#{fetch(:branch)}"
      context.execute :git, "submodule update --init --recursive"
      context.execute :touch, ".rsync"

      if defined?(Bundler)
        Bundler.with_clean_env do
          context.execute :bundle, "package --all --quiet"
        end
      end
    end

    def update(server)
      user = server.user + "@" if !server.user.nil?
      host = server.hostname
      rsync_cmd = [:rsync]
      rsync_cmd << %w[--archive --recursive --delete --delete-excluded --exclude .git*]
      rsync_cmd << "#{local_build_path}/"
      rsync_cmd << "#{user}#{host}:#{repo_path}/"
      context.execute *rsync_cmd
    end

    def release
      rsync_cmd = [:rsync]
      rsync_cmd << %w[--archive --acls --xattrs]
      rsync_cmd << "#{repo_path}/"
      rsync_cmd << "#{release_path}/"
      context.execute *rsync_cmd
    end

    def fetch_revision
      context.capture(:git, "rev-parse --short #{fetch(:branch)}")
    end
  end
end
