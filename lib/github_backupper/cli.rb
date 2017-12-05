# coding: utf-8

module GithubBackupper
  class CLI < Thor
    desc "list GITHUB_TOKEN", "List repositories"
    option :github_token, desc: 'GitHub Access Token', aliases: '-t', default: ENV['GITHUBBACKUPPER_TOKEN']
    option :github_user, desc: 'GitHub user name', aliases: '-u', default: ENV['GITHUBBACKUPPER_USER']
    option :backup_to, default: '~/backupper'
    def list
      github_token = options[:github_token]
      github_user = options[:github_user]
      backup_to = File.expand_path(options[:backup_to])

      logger = Logger.new(STDOUT, :info)
      logger.info("GitHub Access Token is #{github_token}")
      logger.info("Target User is #{github_user}")
      logger.info("To #{backup_to}")

      Octokit.auto_paginate = true
      client = Octokit::Client.new(
        login:    github_user,
        password: github_token
      )
      logger.info("Target Repositories Count = #{client.repositories.length}")

      # 重複名があるかもしれないのでチェックする
      repositories = client.repositories
      logger.info(repositories.select(&:name).uniq.size)

      client.repositories.each_with_index do |r, i|
        # see https://developer.github.com/v3/repos/#get

        logger.info("#{i+1} : #{r.full_name}")

        cloned_path = "#{backup_to}/#{r.name}"

        do_fetch = false
        do_fetch = true if File.exist?(cloned_path)

        if do_fetch
          logger.info("fetch on #{cloned_path}")
          logger.info(`cd #{cloned_path} && git fetch`)
        else
          logger.info("clone.")
          clone_url = r.clone_url
          clone_url.gsub('https://github.com', "https://#{github_user}:#{github_token}@github.com")
          logger.info(`cd #{options[:backup_to]} && git clone #{clone_url}`)
        end
      end
    end
  end
end
