module GithubBackupper
  class Runner
    def initialize(options)
      @dryrun = options[:dryrun] || false
    end
    def set(cmd)
      @cmd = cmd
    end
    def run
      if (@dryrun)
        puts @cmd
      else
        `#{@cmd}`
      end
    end
  end
end
