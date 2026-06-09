require 'base64'
require 'digest'
require 'json'
require 'openssl'
require 'securerandom'

module GithubBackupper
  class TokenStore
    SECRET_KEY_PATH = File.expand_path('~/.github_backupper_secret.key')
    ACCESS_TOKEN_PATH = File.expand_path('~/.github_backupper_access_token')
    SECRET_KEY_ENV = 'GITHUBBACKUPPER_SECRET_KEY'
    SECRET_KEY_BYTES = 32
    IV_BYTES = 12

    def initialize(secret_key_path: SECRET_KEY_PATH, access_token_path: ACCESS_TOKEN_PATH, env: ENV)
      @secret_key_path = secret_key_path
      @access_token_path = access_token_path
      @env = env
    end

    def resolve_token(explicit_token)
      if explicit_token && !explicit_token.empty?
        store_token(explicit_token)
        return explicit_token
      end

      token = load_token
      return token if token

      raise 'GitHub access token not found. Pass --github_token or set GITHUBBACKUPPER_TOKEN once to bootstrap encrypted storage.'
    end

    def load_token
      return nil unless File.exist?(@access_token_path)

      decrypt_token(File.binread(@access_token_path))
    end

    def store_token(token)
      write_file(@access_token_path, encrypt_token(token))
      token
    end

    private

    def secret_key
      if File.exist?(@secret_key_path)
        decode_secret_key(File.read(@secret_key_path, mode: 'r:UTF-8').strip)
      else
        bootstrap_secret_key
      end
    end

    def bootstrap_secret_key
      env_secret = @env[SECRET_KEY_ENV]
      if env_secret && !env_secret.empty?
        key = normalize_secret_key(env_secret)
        write_file(@secret_key_path, Base64.strict_encode64(key) + "\n")
        return key
      end

      if File.exist?(@access_token_path)
        raise "Secret key not found at #{@secret_key_path}. Set #{SECRET_KEY_ENV} to the original key before starting."
      end

      key = SecureRandom.random_bytes(SECRET_KEY_BYTES)
      write_file(@secret_key_path, Base64.strict_encode64(key) + "\n")
      key
    end

    def normalize_secret_key(value)
      decoded = decode_base64(value)
      return decoded if decoded && decoded.bytesize == SECRET_KEY_BYTES

      return value if value.bytesize == SECRET_KEY_BYTES

      Digest::SHA256.digest(value)
    end

    def decode_secret_key(value)
      key = decode_base64(value.strip)
      return key if key && key.bytesize == SECRET_KEY_BYTES

      raise "Invalid secret key stored in #{@secret_key_path}"
    end

    def encrypt_token(token)
      cipher = OpenSSL::Cipher.new('aes-256-gcm')
      cipher.encrypt
      cipher.key = secret_key
      iv = SecureRandom.random_bytes(IV_BYTES)
      cipher.iv = iv

      ciphertext = cipher.update(token.to_s) + cipher.final
      payload = {
        version: 1,
        iv: Base64.strict_encode64(iv),
        tag: Base64.strict_encode64(cipher.auth_tag),
        ciphertext: Base64.strict_encode64(ciphertext)
      }

      JSON.generate(payload)
    end

    def decrypt_token(payload)
      data = JSON.parse(payload)
      cipher = OpenSSL::Cipher.new('aes-256-gcm')
      cipher.decrypt
      cipher.key = secret_key
      cipher.iv = Base64.decode64(data.fetch('iv'))
      cipher.auth_tag = Base64.decode64(data.fetch('tag'))

      cipher.update(Base64.decode64(data.fetch('ciphertext'))) + cipher.final
    rescue JSON::ParserError, KeyError, OpenSSL::Cipher::CipherError => e
      raise "Unable to decrypt access token from #{@access_token_path}: #{e.message}"
    end

    def decode_base64(value)
      Base64.strict_decode64(value)
    rescue ArgumentError
      nil
    end

    def write_file(path, content)
      File.open(path, File::WRONLY | File::CREAT | File::TRUNC, 0o600) do |file|
        file.write(content)
      end
    end
  end
end