require 'logger'
require 'thor'
require 'octokit'
require 'dotenv'
require 'yaml'
Dotenv.load
require 'github_backupper/version'
require 'github_backupper/logger'
require 'github_backupper/git_hub_helper'
require 'github_backupper/runner'
require 'github_backupper/cli'
module GithubBackupper
  # Your code goes here...
  class App
    attr_reader :repositories

    def initialize(options)
      @dryrun = options[:dryrun]
      @backup_to = File.expand_path(options[:backup_to])

      @logger = Logger.logger
      Logger.dump(options)
      @logger.info("To #{@backup_to}")

      @github_helper = GitHubHelper.new(options)
      @client = @github_helper.client
      @runner = Runner.new(options)
    end

    def fetch_repositories
      @repositories = @client.repositories
    end

    def check
      @logger.info('verifying.')
      @logger.info("Unique size = #{@repositories.select(&:name).uniq.size}. ")
    end

    def repositories_select!(&select_block)
      before = @repositories.size
      @repositories.select!(&select_block)
      after = @repositories.size
      @logger.info("filtered: #{before} => #{after}")
    end

    def clone
      repositories_each do |r, _i|
        # see https://developer.github.com/v3/repos/#get
        cloned_path = "#{@backup_to}/#{r.full_name}"
        do_fetch = File.exist?(cloned_path)
        if do_fetch
          @logger.info("fetch on #{cloned_path}")
          @runner.set("cd #{cloned_path} && git pull origin master")
        else
          @logger.info("clone to #{cloned_path}")
          clone_url = @github_helper.clone_url_with_auth(r.clone_url)
          @runner.set("mkdir -p #{cloned_path} && git clone #{clone_url} #{cloned_path}")
        end
        @runner.run
      end
    end

    def clone_wiki
      repositories_each do |r, _i|
        # see https://developer.github.com/v3/repos/#get
        cloned_path = "#{@backup_to}/#{r.full_name}"
        dotgit_path = "#{cloned_path}/.git"
        @logger.info("#{dotgit_path} : #{File.exist?(dotgit_path)}")
        do_fetch = File.exist?(dotgit_path)
        if do_fetch
          @logger.info("fetch on #{cloned_path}")
          @runner.set("cd #{cloned_path} && git pull origin master")
        else
          @logger.info("clone to #{cloned_path}")
          clone_url = @github_helper.clone_wiki_url_with_auth(r)
          @runner.set("mkdir -p #{cloned_path} && git clone #{clone_url} #{cloned_path}")
        end
        @runner.run
      end
    end

    def backup_issue
      repositories_each do |r, _i|
        begin
          repository_name = r.full_name
          backup_dir  = "#{@backup_to}/#{repository_name}"
          backup_path = "#{backup_dir}/issues.yml"
          yaml = YAML.dump(
            @client.issues(repository_name, state: :all)
          )
          @runner.set("mkdir -p #{backup_dir}")
          @runner.run
          if @dryrun == true
            @logger.info(yaml)
          else
            File.open(backup_path, 'w') do |f|
              f.write(yaml)
            end
          end
          @logger.info("save to #{backup_path}")
        rescue => e
          @logger.fatal(e)
          raise e
        end
      end
    end

    private

    def repositories_each
      @repositories.each_with_index do |r, i|
        @logger.info("#{i + 1} : #{r.full_name}")
        yield(r, i)
      end
    end
  end
end
