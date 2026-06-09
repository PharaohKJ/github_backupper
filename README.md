# GithubBackupper

GitHub のリポジトリ、Wiki、Issue をローカルにバックアップする CLI ツールです。

## 前提条件

- GitHub CLI (`gh`) が必要です（`login` コマンドで使用）
- インストール手順: https://github.com/cli/cli

## インストール

```
$ git clone <this>
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
- GITHUBBACKUPPER_ACCESS_TOKEN_CONTENT

`login` は `gh` コマンド必須です。未インストール時はエラー終了します。
インストール手順: https://github.com/cli/cli

### 5. ヘルプ

```
$ github_backupper help
```

## 他マシンで実行する手順（環境変数でファイル内容を渡す）

このツールで `login` 済みのマシンから、暗号鍵ファイルと暗号化済み資格情報ファイルを別マシンに持ち出して実行できます。

### 1. 元マシンで login

```
$ github_backupper login
```

生成されるファイル:

- `~/.github_backupper_secret.key`
- `~/.github_backupper_access_token`

### 2. ファイル内容を環境変数にセット

```
$ export GITHUBBACKUPPER_SECRET_KEY="$(cat ~/.github_backupper_secret.key)"
$ export GITHUBBACKUPPER_ACCESS_TOKEN_CONTENT="$(cat ~/.github_backupper_access_token)"
```

### 3. 実行先マシンに環境変数を渡す

例: SSH で一時的に環境変数を渡して実行

```
$ ssh user@other-host \
	"export GITHUBBACKUPPER_SECRET_KEY='${GITHUBBACKUPPER_SECRET_KEY}'; \
	 export GITHUBBACKUPPER_ACCESS_TOKEN_CONTENT='${GITHUBBACKUPPER_ACCESS_TOKEN_CONTENT}'; \
	 github_backupper wiki -p ./tmp"
```

### 4. 実行

`-t` や `-u` を渡さなくても、環境変数内の保存済み資格情報を使って実行できます。

```
$ github_backupper wiki -p ./tmp
```

### 5. 注意点

- 2つの環境変数は必ずセットで渡してください（片方だけでは復号不可）。
- ファイル権限は `600` 推奨です。
- 2ファイルを持つ人は実質的に GitHub 資格情報を利用できるため、取り扱いは秘密情報と同等にしてください。
