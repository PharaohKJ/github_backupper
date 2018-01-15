# coding: utf-8

module GithubBackupper
  class CLI < Thor
    desc 'backup', 'backup repositories'
    option :github_token, desc: 'GitHub Access Token', aliases: '-t', default: ENV['GITHUBBACKUPPER_TOKEN']
    option :github_user, desc: 'GitHub user name', aliases: '-u', default: ENV['GITHUBBACKUPPER_USER']
    option :backup_to, desc: 'store directory.', aliases: '-p', default: ENV['GITHUBBACKUPPER_BACKUP_TO'] || '~/backupper'
    option :dryrun, desc: 'dry-run', type: :boolean, default: false
    def backup
      app = App.new(options)
      app.fetch_repositories
      app.check
      app.clone
    end

    desc 'wiki', 'backup wiki repositories'
    option :github_token, desc: 'GitHub Access Token', aliases: '-t', default: ENV['GITHUBBACKUPPER_TOKEN']
    option :github_user, desc: 'GitHub user name', aliases: '-u', default: ENV['GITHUBBACKUPPER_USER']
    option :backup_to, desc: 'store directory.', aliases: '-p', default: ENV['GITHUBBACKUPPER_BACKUP_TO'] || '~/backupper'
    option :dryrun, desc: 'dry-run', type: :boolean, default: false
    def wiki
      app = App.new(options)
      app.fetch_repositories
      app.check
      app.repositories_select! do |x|
        x.has_wiki == true
      end
      app.clone_wiki
    end

    desc 'issue', 'backup wiki repositories'
    option :github_token, desc: 'GitHub Access Token', aliases: '-t', default: ENV['GITHUBBACKUPPER_TOKEN']
    option :github_user, desc: 'GitHub user name', aliases: '-u', default: ENV['GITHUBBACKUPPER_USER']
    option :backup_to, desc: 'store directory.', aliases: '-p', default: ENV['GITHUBBACKUPPER_BACKUP_TO'] || '~/backupper'
    option :dryrun, desc: 'dry-run', type: :boolean, default: false
    def issue
      app = App.new(options)
      app.fetch_repositories
      app.check
      app.repositories_select! do |x|
        x.has_issues == true
      end
      app.backup_issue
    end
  end
end
