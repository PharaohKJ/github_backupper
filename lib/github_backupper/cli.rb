# coding: utf-8

module GithubBackupper
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    desc 'login', 'store encrypted GitHub token locally'
    option :github_token, desc: 'GitHub Access Token', aliases: '-t', default: ENV['GITHUBBACKUPPER_TOKEN']
    def login
      ensure_github_cli_installed!

      token = options[:github_token]
      token = fetch_token_with_github_cli if token.nil? || token.empty?
      raise Thor::Error, 'Failed to obtain GitHub token. Pass -t/--github_token or authenticate with `gh auth login`.' if token.nil? || token.empty?
      github_user = fetch_user_with_token(token)

      TokenStore.new.store_credentials(token: token, github_user: github_user)
      puts "Login completed as #{github_user}. Encrypted credentials have been saved."
    end

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

    desc 'issues', 'backup issues repositories'
    option :github_token, desc: 'GitHub Access Token', aliases: '-t', default: ENV['GITHUBBACKUPPER_TOKEN']
    option :github_user, desc: 'GitHub user name', aliases: '-u', default: ENV['GITHUBBACKUPPER_USER']
    option :backup_to, desc: 'store directory.', aliases: '-p', default: ENV['GITHUBBACKUPPER_BACKUP_TO'] || '~/backupper'
    option :dryrun, desc: 'dry-run', type: :boolean, default: false
    def issues
      app = App.new(options)
      app.fetch_repositories
      app.check
      app.repositories_select! do |x|
        x.has_issues == true
      end
      app.backup_issue
    end

    no_commands do
      def ensure_github_cli_installed!
        return if system('command -v gh >/dev/null 2>&1')

        raise Thor::Error, 'GitHub CLI (`gh`) is required. Please install gh first: https://cli.github.com/'
      end

      def fetch_token_with_github_cli
        token = `gh auth token 2>/dev/null`.to_s.strip
        return token unless token.empty?

        puts 'No GitHub CLI session detected. Starting `gh auth login`...'
        ok = system('gh auth login -h github.com -p https -w')
        raise Thor::Error, 'GitHub CLI login was not completed.' unless ok

        token = `gh auth token 2>/dev/null`.to_s.strip
        return token unless token.empty?

        raise Thor::Error, 'GitHub CLI did not return a token. Please run `gh auth token` manually and retry with -t.'
      end

      def fetch_user_with_token(token)
        client = Octokit::Client.new(access_token: token)
        user = client.user
        login = user.respond_to?(:login) ? user.login : nil
        raise Thor::Error, 'Unable to resolve GitHub user from token.' if login.nil? || login.empty?

        login
      rescue StandardError => e
        raise Thor::Error, "Unable to resolve GitHub user from token: #{e.message}"
      end
    end
  end
end
