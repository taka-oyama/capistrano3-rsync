namespace :rsync do
  def strategy
    @strategy ||= Capistrano::Rsync.new(self, fetch(:rsync_strategy, Capistrano::Rsync::DefaultStrategy))
  end

  def local_build_path
    @local_build_path||= fetch(:tmp_dir) + "/_deploy"
  end

  task :check do
    # Everything's a-okay inherently!
  end

  task :prepare do
    on release_roles :all do
      if strategy.test
        info t(:mirror_exists, at: repo_path)
      else
        strategy.clone
      end
    end
  end

  task clone: :check do
    run_locally do
      if strategy.test_local
        info t(:mirror_exists, at: local_build_path)
      else
        strategy.clone_local
      end
    end
  end

  desc "Stage and rsync to the server (or its cache)."
  task update: [:prepare, :clone] do
    on release_roles(:all) do
      run_locally do
        within local_build_path do
          strategy.update_local
          strategy.update
        end
      end
    end
  end

  desc "Copy the code to the releases directory."
  task create_release: :update do
    on release_roles :all do
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
