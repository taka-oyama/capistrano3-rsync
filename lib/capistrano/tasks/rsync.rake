namespace :rsync do
  def strategy
    @strategy ||= Capistrano::Rsync.new(self, fetch(:rsync_strategy, Capistrano::Rsync::DefaultStrategy))
  end

  def local_build_path
    @local_build_path||= "#{fetch(:tmp_dir)}/#{fetch(:application)}/deploy"
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
    on release_roles(:all) do
      run_locally do
        with fetch(:git_environmental_variables) do
          strategy.check
        end
      end
    end
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
        with fetch(:git_environmental_variables) do
          if Dir["#{local_build_path}/*"].empty?
            execute :git, "clone", "--recursive", repo_url, local_build_path
            if defined?(Bundler)
              Bundler.with_clean_env do
                execute :bundle, "install --path vendor/bundle"
              end
            end
          end
          execute :git, "remote update --prune"
          execute :git, "submodule update --init"
          execute :touch, ".rsync"

          if defined?(Bundler)
            Bundler.with_clean_env do
              execute :bundle, "package --all --quiet"
            end
          end
        end

        on release_roles(:all) do |server|
          strategy.update(server)
        end
      end
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

  Rake::Task["deploy:cleanup"].enhance do
    run_locally do
      execute :rm, "-rf", local_build_path
    end
  end
end
