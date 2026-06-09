require 'base64'
require 'securerandom'
require 'tmpdir'
require_relative 'test_helper'

class GithubBackupperTest < Minitest::Test
  def test_has_a_version_number
    refute_nil GithubBackupper::VERSION
  end
end

class TokenStoreTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @secret_key_path = File.join(@tmpdir, 'github_backupper_secret.key')
    @access_token_path = File.join(@tmpdir, 'github_backupper_access_token')
  end

  def teardown
    FileUtils.remove_entry(@tmpdir) if @tmpdir && File.exist?(@tmpdir)
  end

  def test_creates_and_saves_secret_key_while_encrypting_token
    store = build_store(env: {})

    token = 'virtual-token-123'
    assert_equal token, store.resolve_token(token)
    assert_path_exists @secret_key_path
    assert_path_exists @access_token_path

    stored_key = Base64.strict_decode64(File.read(@secret_key_path).strip)
    assert_equal GithubBackupper::TokenStore::SECRET_KEY_BYTES, stored_key.bytesize

    reloaded_store = build_store(env: {})
    assert_equal token, reloaded_store.load_token
  end

  def test_loads_secret_key_from_environment_when_key_file_does_not_exist
    secret_key = SecureRandom.random_bytes(GithubBackupper::TokenStore::SECRET_KEY_BYTES)
    env = {
      GithubBackupper::TokenStore::SECRET_KEY_ENV => Base64.strict_encode64(secret_key)
    }
    store = build_store(env: env)

    store.store_token('env-backed-token')

    persisted_key = Base64.strict_decode64(File.read(@secret_key_path).strip)
    assert_equal secret_key, persisted_key
    assert_equal 'env-backed-token', store.load_token
  end

  def test_reads_previously_encrypted_token_without_explicit_token
    initial_store = build_store(env: {})
    initial_store.store_token('persisted-token')

    reloaded_store = build_store(env: {})

    assert_equal 'persisted-token', reloaded_store.resolve_token(nil)
  end

  private

  def build_store(env:)
    GithubBackupper::TokenStore.new(
      secret_key_path: @secret_key_path,
      access_token_path: @access_token_path,
      env: env
    )
  end

  def assert_path_exists(path)
    assert File.exist?(path), "Expected #{path} to exist"
  end
end