## Installation

You can add Lefthook to your system via packages or build it from sources.

* [Node.js](./node.md)
* [Ruby](./ruby.md)
* [Other environments](./other.md)

NOTE: if you install Lefthook via NPM then you should call it via `npx` or
`yarn` in all the examples below. For example: `lefthook install` -> `npx
lefthook install`


## Getting started

### First time user

Initialize lefthook with the following command:
```bash
lefthook install
```
which will create `lefthook.yml` in the project root directory.

Register your hook (you can choose any hook from [this
list](https://git-scm.com/docs/githooks)). In our example we choose a
`pre-push` hook:
```bash
lefthook add pre-push
```

Finally, describe pre-push commands in `lefthook.yml`:
```yml
pre-push:               # githook name
  commands:             # list of commands
    packages-audit:     # command name
      run: yarn audit   # command for execution
```

That's all! Now on `git push` the `yarn audit` command will be run. If it
fails then the `git push` will be interrupted.

### If you already have a lefthook config file

Just initialize lefthook to make it work :)

```bash
lefthook install
```

### Examples

We have a directory with a few examples. You can check it out
[here](../examples).


## More options

## Use glob patterns to choose what files you want to check

```yml
# lefthook.yml

pre-commit:
  commands:
    lint:
      glob: "*.{js,ts}"
      run: yarn eslint
```

## Select specific file groups

In some cases you want to run checks only against some specific file group.
For example: you may want to run eslint for staged files only.

There are two shorthands for such situations:
`{staged_files}` - staged git files which you try to commit

`{all_files}` - all tracked files by git

```yml
# lefthook.yml

pre-commit:
  commands:
    frontend-linter:
      glob: "*.{js,ts}" # glob filter for list of files
      run: yarn eslint {staged_files} # {staged_files} - list of files
    backend-linter:
      glob: "*.rb" # glob filter for list of files
      exclude: "application.rb|routes.rb" # regexp filter for list of files
      run: bundle exec rubocop --force-exclusion {all_files} # {all_files} - list of files
```

Note: If using `all_files` with RuboCop, it will ignore RuboCop's `Exclude` configuration setting. To avoid this, pass `--force-exclusion`.

## Custom file list

Lefthook can be even more specific in selecting files.
If you want to choose diff of all changed files between the current branch and master branch you can do it this way:

```yml
# lefthook.yml

pre-push:
  commands:
    frontend-style:
      files: git diff --name-only master # custom list of files
      glob: "*.js"
      run: yarn stylelint {files}
```

`{files}` - shorthand for a custom list of files

## Git hook argument shorthands in commands

If you want to use the original Git hook arguments in a command you can do it
using the indexed shorthands:

```yml
# lefthook.yml

# Note: commit-msg hook takes a single parameter,
# the name of the file that holds the proposed commit log message.
# Source: https://git-scm.com/docs/githooks#_commit_msg
commit-msg:
  commands:
    multiple-sign-off:
      run: 'test $(grep -c "^Signed-off-by: " {1}) -lt 2'
```
`{0}` - shorthand for the single space-joint string of Git hook arguments

`{i}` - shorthand for the i-th Git hook argument

## Managing scripts

If you run `lefthook add` command with `-d` flag, lefthook will create two directories where you can put scripts and reference them from `lefthook.yml` file.

Example:
Let's create `commit-msg` hook with `-d` flag

```bash
lefthook add -d commit-msg
```

This command will create `.lefthook/commit-msg` and `.lefthook-local/commit-msg` dirs.

The first one is for common project level scripts.
The second one is for personal scripts. It would be a good idea to add dir`.lefthook-local` to `.gitignore`.

Create scripts `.lefthook/commit-msg/hello.js` and `.lefthook/commit-msg/hi.rb`

```yml
# lefthook.yml

commit-msg:
  scripts:
    "hello.js":
      runner: node
    "hi.rb":
      runner: ruby
```

### Bash script example

Let's create a bash script to check commit templates `.lefthook/commit-msg/template_checker`:

```bash
INPUT_FILE=$1
START_LINE=`head -n1 $INPUT_FILE`
PATTERN="^(TICKET)-[[:digit:]]+: "
if ! [[ "$START_LINE" =~ $PATTERN ]]; then
  echo "Bad commit message, see example: TICKET-123: some text"
  exit 1
fi
```

Now we can ask lefthook to run our bash script by adding this code to
`lefthook.yml` file:

```yml
# lefthook.yml

commit-msg:
  scripts:
    "template_checker":
      runner: bash
```

When you try to commit `git commit -m "haha bad commit text"` script `template_checker` will be executed. Since commit text doesn't match the described pattern the commit process will be interrupted.

## Config files

### Main config

The main config file for lefthook is `lefthook.yml`, which must be located
at the root of your git repo. This file would usually be committed and thus
shared by other developers on the project.

### Local config

Lefthook config can be overridden locally by using `lefthook-local.yml`.
Options in this file will override options in `lefthook.yml`. As these are
intended as local overrides, you should probably add this file to
`.gitignore`.

### Extends option

If you need to extend config from some another place, just add top level:
```yml
# lefthook.yml

extends:
  - $HOME/work/lefthook-extend.yml
  - $HOME/work/lefthook-extend-2.yml
```
NOTE: Filenames specified under the `extends` keyword must be unique (and
cannot be either `lefthook.yml` or `lefthook-local.yml`).


## Runners

Lefthook supports two kinds of 'runners' - `scripts` and `commands`. `scripts`
are just that - script files that are stored in the repo (typically under
`.lefthook/<hook>`) - while `commands` are defined entirely within config.

### Execution order

By default all runners will be executed in a defined sequence, regardless of
the success or failure of previous runners. The order of execution is:
1. scripts in the main script directory (`.lefthook/<hook>`), sorted by
   filename;
2. scripts in the local script directory (`.lefthook-local/<hook>`), sorted by
   filename;
3. commands, in the order they appear in config files (first `lefthook.yml`,
   then `lefthook-local.yml`, then any files listed under the `extends` config
   key).

#### Parallel execution

You can enable parallel execution if you want to speed up your checks. Runners
will be kicked off in the same order as before, but will execute in parallel.
This must be enabled individually for each hook, by setting `parallel: true`.
This option is mutually exclusive with the `piped` option.

```yml
# lefthook.yml

pre-commit:
  parallel: true
  commands:
    rubocop:
      run: bundle exec rubocop --parallel
    danger:
      run: bundle exec danger
    eslint-assets:
      run: yarn eslint --ext .es6 app/assets/javascripts
    eslint-test:
      run: yarn eslint --ext .es6 test/javascripts
```

#### Piped execution

You can enable piped execution if later runners depend upon previous runners
executing successfully. If any runner in the sequence fails, subsequent
runners will not be executed. This must be enabled individually for each hook,
by setting `piped: true`. This option is mutually exclusive with the
`parallel` option.

```yml
# lefthook.yml

database:
  piped: true
  commands:
    1_create:
      run: rake db:create
    2_migrate:
      run: rake db:migrate
    3_seed:
      run: rake db:seed
```


## Skipping commands

### Skipping specific commands

You can prevent certain commands from running by setting `skip` to true in
your config file:
```yml
# lefthook-local.yml

pre-push:
  commands:
    packages-audit:
      skip: true
```

### Skipping commands by tags

If we have a lot of commands and scripts then we can apply tags and then skip
commands with a specific tag.

For example, if we have a `lefthook.yml` like this:
```yml
# lefthook.yml

pre-push:
  commands:
    packages-audit:
      tags: frontend security
      run: yarn audit
    gems-audit:
      tags: backend security
      run: bundle audit
```
then we can skip all commands tagged 'frontend':
```yml
# lefthook-local.yml

pre-push:
  exclude_tags:
    - frontend
```

### Skipping commands by tags (on the fly)

In addition to specifying tags to skip via config (such as
`lefthook-local.yml`), it is also possible to disable a list of tag groups on
the fly using the `LEFTHOOK_EXCLUDE` environment variable:
```bash
LEFTHOOK_EXCLUDE=frontend,security git commit -am "Skip some tag checks"
```

### Skipping lefthook execution entirely

To completely disable lefthook for the current git operation, simply set the
environment variable `LEFTHOOK` to zero:
```bash
LEFTHOOK=0 git commit -am "Lefthook skipped"
```

## Referencing commands from lefthook.yml

If you have the following config

```yml
# lefthook.yml

pre-commit:
  scripts:
    "good_job.js":
      runner: node
```

You can wrap it in docker runner locally:

```yml
# lefthook-local.yml

pre-commit:
  scripts:
    "good_job.js":
      runner: docker run -it --rm <container_id_or_name> {cmd}
```

`{cmd}` - shorthand for the command from `lefthook.yml`

## Run githook group directly

```bash
lefthook run pre-commit
```

## Custom command groups

Lets get example from [discourse](https://github.com/discourse/discourse/blob/master/.travis.yml#L77-L83) project.

```
bundle exec rubocop --parallel && \
bundle exec danger && \
yarn eslint --ext .es6 app/assets/javascripts && \
yarn eslint --ext .es6 test/javascripts && \
yarn eslint --ext .es6 plugins/**/assets/javascripts && \
yarn eslint --ext .es6 plugins/**/test/javascripts && \
yarn eslint app/assets/javascripts test/javascripts
```

Rewrite it in lefthook custom group. We call it `lint`:

```yml
# lefthook.yml

lint:
  parallel: true
  commands:
    rubocop:
      run: bundle exec rubocop --parallel
    danger:
      run: bundle exec danger
    eslint-assets:
      run: yarn eslint --ext .es6 app/assets/javascripts
    eslint-test:
      run: yarn eslint --ext .es6 test/javascripts
    eslint-plugins-assets:
      run: yarn eslint --ext .es6 plugins/**/assets/javascripts
    eslint-plugins-test:
      run: yarn eslint --ext .es6 plugins/**/test/javascripts
    eslint-assets-tests:
      run: yarn eslint app/assets/javascripts test/javascripts
```

Then call this group directly:

```
lefthook run lint
```

## Complete example

```yml
# lefthook.yml
color: false
extends: $HOME/work/lefthook-extend.yml

pre-commit:
  commands:
    eslint:
      glob: "*.{js,ts}"
      run: yarn eslint {staged_files}
    rubocop:
      tags: backend style
      glob: "*.rb"
      exclude: "application.rb|routes.rb"
      run: bundle exec rubocop --force-exclusion {all_files}
    govet:
      tags: backend style
      files: git ls-files -m
      glob: "*.go"
      run: go vet {files}

  scripts:
    "hello.js":
      runner: node
    "any.go":
      runner: go run

  parallel: true
```

```yml
# lefthook-local.yml

pre-commit:
  exclude_tags:
    - backend

  scripts:
    "hello.js":
      runner: docker run -it --rm <container_id_or_name> {cmd}
  commands:
    govet:
      skip: true
```

## Concurrent files overrides

To prevent concurrent problems with read/write files try `flock`
utility.

```yml
# lefthook.yml

graphql-schema:
  glob: "{Gemfile.lock,app/graphql/**/*}"
  run: flock webpack/application/typings/graphql-schema.json yarn typings:update && git diff --exit-code --stat HEAD webpack/application/typings
frontend-tests:
  glob: "**/*.js"
  run: flock -s webpack/application/typings/graphql-schema.json yarn test --findRelatedTests {files}
frontend-typings:
  glob: "**/*.js"
  run: flock -s webpack/application/typings/graphql-schema.json yarn run flow focus-check {files}
```

## Capture ARGS from git in the script

Example script for `prepare-commit-msg` hook:

```bash
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2
SHA1=$3

# ...
```

## Change directory for script files

You can do this through this config keys:

```yml
# lefthook.yml

source_dir: ".lefthook"
source_dir_local: ".lefthook-local"
```

## CI integration

Enable `CI` env variable if it doens't exists on your service by default.


## Output control

### Make lefthook less verbose

By default lefthook can be quite verbose, producing output as each command is
processed (whether skipped, successful or failed), followed at the end by a
status summary of all the commands that were actually run.

This output can be controlled using the `skip_output` config key. It takes an
array of output classes to skip, including:
* *meta* - version information, and which hook is running
* *success* - any output from runners with an exit code of 0 (success)

To make lefthook as quiet as possible:
```yml
# lefthook.yml

skip_output:
  - meta
  - success
```

### Disable colors

Using args:
```bash
lefthook --no-colors run pre-commit
```
Using config:
```yml
# lefthook.yml

colors: false
```

## Version

```bash
lefthook version
```

## Uninstall

```bash
lefthook uninstall
```

## More info
Have a question? Check the [wiki](https://github.com/Arkweid/lefthook/wiki).
