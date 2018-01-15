module GithubBackupper
  # GitHub Access Helpers
  class GitHubHelper
    attr_reader :client

    def initialize(options)
      @github_token = options[:github_token]
      @github_user = options[:github_user]
      Octokit.auto_paginate = true
      @client = Octokit::Client.new(
        login:    @github_user,
        password: @github_token
      )
    end

    def clone_url_with_auth(url)
      url.gsub('https://github.com', "https://#{@github_user}:#{@github_token}@github.com")
    end

    def clone_wiki_url_with_auth(r)
      # see https://help.github.com/articles/adding-and-editing-wiki-pages-locally/
      # git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.wiki.git
      url = "https://github.com/#{r.full_name}.wiki.git"
      clone_url_with_auth(url)
    end
  end
end
