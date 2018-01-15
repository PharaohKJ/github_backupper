# GithubBackupper

## Install

```
$ clone <this>
$ bundle exec rake build
$ gem install pkg/github_backupper-0.1.0.gem
$ # or
$ bundle exec exe/github_backupper
```

## usage

Please see `github backupper help`

example

```
$ mkdir -p backuprepo/repo
$ github_backupper backup -u githubuser -t githubaccesstoken -p backuprepo/repo --no-dryrun
$ mkdir -p backuprepo/wiki
$ github_backupper wiki -u githubuser -t githubaccesstoken -p backuprepo/wiki --no-dryrun
$ mkdir -p backuprepo/issues
$ github_backupper issues -u githubuser -t githubaccesstoken -p backuprepo/issues --no-dryrun
```
