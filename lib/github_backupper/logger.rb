# coding: utf-8
module GithubBackupper
  # Logger を提供する
  class Logger
    @logger = ::Logger.new(STDOUT, :info)

    # Logger の実体を返す。
    def self.logger
      @logger
    end

    def self.dump(options)
      options.each do |k, v|
        logger.info("#{k} : #{v}")
      end
    end

    def logger
      self.class.logger
    end
  end
end
