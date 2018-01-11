# coding: utf-8
module GithubBackupper
  # コマンド実行の実装 OS上のコマンド実行を行う
  class Runner
    def initialize(options)
      @dryrun = options[:dryrun] || false
    end

    def set(cmd)
      @cmd = cmd
    end

    # 実実行
    def run
      if @dryrun
        puts @cmd
      else
        `#{@cmd}`
      end
    end
  end
end
