load File.expand_path(File.dirname(__FILE__) + "/tasks/rsync.rake")

require 'capistrano/scm'

class Capistrano::Rsync < Capistrano::SCM
  module DefaultStrategy
    def test
      test! " [ -f #{repo_path}/.rsync ] "
    end

    def check
      context.execute :git, "ls-remote --heads", repo_url
    end

    def clone
      context.execute :mkdir, "--parents", repo_path
      system(`mkdir --parents #{local_build_path}`)
    end

    def update(server)
      if !File.directory?(local_build_path)
        context.execute :git, "clone", "--mirror --recursive", repo_url, local_build_path
      end
      context.execute :git, "remote update --prune"
      context.execute :git, "submodule update --init --recursive"
      context.execute :touch, ".rsync"

      if defined?(Bundler)
        Bundler.with_clean_env do
          context.execute :bundle, "package --all --quiet"
        end
      end

      user = !server.user.nil? ? "#{server.user}@" : ""
      rsync_cmd = [:rsync]
      rsync_cmd << %w[--archive --recursive --delete --delete-excluded --exclude .git*]
      rsync_cmd << "#{local_build_path}/"
      rsync_cmd << "#{user}#{server.hostname}:#{repo_path}/"
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
      context.capture :git, "rev-parse --short #{fetch(:branch)}"
    end
  end
end
