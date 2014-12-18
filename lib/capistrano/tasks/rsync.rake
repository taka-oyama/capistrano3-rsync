namespace :rsync do
  def strategy
    @strategy ||= Capistrano::Rsync.new(self, fetch(:rsync_strategy, Capistrano::Rsync::DefaultStrategy))
  end

  def local_build_path
    @local_build_path||= "#{fetch(:tmp_dir)}/#{fetch(:application)}/deploy"
  end

  def bundle(*args)
    Bundler.with_clean_env do
      args.unshift :bundle
      execute *args
    end
  end

  def git(*args)
    with fetch(:git_environmental_variables) do
      args.unshift :git
      execute *args
    end
  end

  set :git_environmental_variables, ->() {
    {
      git_askpass: "/bin/echo",
      git_ssh: "#{fetch(:tmp_dir)}/#{fetch(:application)}/git-ssh.sh"
    }
  }

  desc "Upload the git wrapper script, this script guarantees that we can script git without getting an interactive prompt"
  task :git_wrapper do
    on release_roles(:all) do
      run_locally do
        execute :mkdir, "-p", local_build_path
        File.open("#{fetch(:tmp_dir)}/#{fetch(:application)}/git-ssh.sh", "w") do |f|
          f.write("#!/bin/sh -e\nexec /usr/bin/ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no \"$@\"\n")
          f.chmod(0755)
        end
      end
    end
  end

  task check: :git_wrapper do
    strategy.check
  end

  task clone: :check do
    on release_roles(:all) do
      if strategy.test
        info t(:mirror_exists, at: repo_path)
      else
        strategy.clone
      end
    end
  end

  desc "Stage and rsync to the server (or its cache)."
  task update: :clone do
    run_locally do
      within local_build_path do
        if Dir["#{local_build_path}/*"].empty?
          git :clone, repo_url, local_build_path
          bundle :install, "--path vendor/bundle" if defined?(Bundler)
        end
        git :reset, "--hard", fetch(:branch)
        git :pull, "--all"
        bundle :package, "--all --quiet" if defined?(Bundler)
        execute :touch, ".rsync"
      end
    end
    on release_roles(:all) do |server|
      strategy.update(server)
    end
  end

  desc "Copy the code to the releases directory."
  task create_release: :update do
    on release_roles(:all) do
      within repo_path do
        strategy.release
      end
    end
  end

  # internally needed by capistrano's "deploy.rake"
  task :set_current_revision do
    run_locally do
      within local_build_path do
        set :current_revision, strategy.fetch_revision
      end
    end
  end
end
