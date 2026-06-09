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

  def test_store_credentials_creates_and_saves_secret_key_while_encrypting_credentials
    store = build_store(env: {})

    token = 'virtual-token-123'
    user = 'virtual-user'
    stored = store.store_credentials(token: token, github_user: user)
    assert_equal token, stored[:github_token]
    assert_equal user, stored[:github_user]
    assert_path_exists @secret_key_path
    assert_path_exists @access_token_path

    stored_key = Base64.strict_decode64(File.read(@secret_key_path).strip)
    assert_equal GithubBackupper::TokenStore::SECRET_KEY_BYTES, stored_key.bytesize

    reloaded_store = build_store(env: {})
    loaded = reloaded_store.load_credentials
    assert_equal token, loaded[:github_token]
    assert_equal user, loaded[:github_user]
  end

  def test_resolve_token_with_explicit_token_does_not_persist_files
    store = build_store(env: {})

    assert_equal 'ephemeral-token', store.resolve_token('ephemeral-token')
    refute File.exist?(@secret_key_path)
    refute File.exist?(@access_token_path)
  end

  def test_loads_secret_key_from_environment_when_key_file_does_not_exist
    secret_key = SecureRandom.random_bytes(GithubBackupper::TokenStore::SECRET_KEY_BYTES)
    env = {
      GithubBackupper::TokenStore::SECRET_KEY_ENV => Base64.strict_encode64(secret_key)
    }
    store = build_store(env: env)

    store.store_credentials(token: 'env-backed-token', github_user: 'env-user')

    persisted_key = Base64.strict_decode64(File.read(@secret_key_path).strip)
    assert_equal secret_key, persisted_key
    loaded = store.load_credentials
    assert_equal 'env-backed-token', loaded[:github_token]
    assert_equal 'env-user', loaded[:github_user]
  end

  def test_reads_previously_encrypted_credentials_without_explicit_values
    initial_store = build_store(env: {})
    initial_store.store_credentials(token: 'persisted-token', github_user: 'persisted-user')

    reloaded_store = build_store(env: {})
    resolved = reloaded_store.resolve_credentials(explicit_token: nil, explicit_user: nil)

    assert_equal 'persisted-token', resolved[:github_token]
    assert_equal 'persisted-user', resolved[:github_user]
  end

  def test_reads_credentials_from_environment_contents_without_files
    initial_store = build_store(env: {})
    initial_store.store_credentials(token: 'portable-token', github_user: 'portable-user')

    secret_key_content = File.read(@secret_key_path).strip
    encrypted_payload = File.read(@access_token_path)
    env = {
      GithubBackupper::TokenStore::SECRET_KEY_ENV => secret_key_content,
      GithubBackupper::TokenStore::ACCESS_TOKEN_CONTENT_ENV => encrypted_payload
    }

    File.delete(@secret_key_path)
    File.delete(@access_token_path)

    portable_store = build_store(env: env)
    resolved = portable_store.resolve_credentials(explicit_token: nil, explicit_user: nil)
    assert_equal 'portable-token', resolved[:github_token]
    assert_equal 'portable-user', resolved[:github_user]
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