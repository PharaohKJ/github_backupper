# GithubBackupper

GitHub のリポジトリ、Wiki、Issue をローカルにバックアップする CLI ツールです。

## インストール

```
$ clone <this>
$ bundle exec rake build
$ gem install pkg/github_backupper-0.1.0.gem
$ # or
$ bundle exec exe/github_backupper
```

## 使い方

### 1. ログイン（トークン登録）

このツールでは、ログイン時に取得した GitHub トークンとユーザー名をセットで暗号化してローカル保存します。

- 秘密鍵ファイル: ~/.github_backupper_secret.key
- 暗号化トークンファイル: ~/.github_backupper_access_token

明示的に `login` コマンドでトークンを登録してください。

引数なしで実行した場合は、GitHub CLI (`gh`) の案内に沿って認証し、
取得したトークンを自動保存します。

```
$ github_backupper login
```

すでにトークンを持っている場合は明示指定も可能です。

```
$ github_backupper login -t githubaccesstoken
```

補足:

- ~/.github_backupper_secret.key が無い場合は生成されます。
- ただし、すでに ~/.github_backupper_access_token が存在していて秘密鍵が無い場合は復号できないため、
	GITHUBBACKUPPER_SECRET_KEY 環境変数から秘密鍵を与える必要があります。

### 2. バックアップ実行

`login` 実行後は `-t` と `-u` を省略できます。

#### リポジトリのバックアップ

```
$ mkdir -p backuprepo/repo
$ github_backupper backup -p backuprepo/repo
```

#### Wiki のバックアップ

```
$ mkdir -p backuprepo/wiki
$ github_backupper wiki -p backuprepo/wiki
```

#### Issue のバックアップ

```
$ mkdir -p backuprepo/issues
$ github_backupper issues -p backuprepo/issues
```

### 3. 主なオプション

- -u, --github_user: GitHub ユーザー名（通常は省略可能）
- -t, --github_token: GitHub アクセストークン（その場実行用。保存は login で実施）
- -p, --backup_to: バックアップ先ディレクトリ
- --dryrun: 実行せずに動作確認

### 4. 環境変数

以下の環境変数も利用できます。

- GITHUBBACKUPPER_USER
- GITHUBBACKUPPER_TOKEN
- GITHUBBACKUPPER_BACKUP_TO
- GITHUBBACKUPPER_SECRET_KEY

`login` は `gh` コマンド必須です。未インストール時はエラー終了します。
インストール手順: https://github.com/cli/cli

### 5. ヘルプ

```
$ github_backupper help
```
