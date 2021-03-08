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


## Command groups

With the exception of a few global options, most of a lefthook config file
consists of defining command groups. These are sets of commands (technically
'runners', which could be either `commands` or `scripts`) which are executed
together when the command group is called.

### Git hook groups

Typically a command group is named after a git hook, and executed
automatically by that hook. In order for a hook to fire, git must know to call
lefthook, and the hook must be defined in `lefthook.yml`.

For a repo with an existing lefthook config, `lefthook install` is all that is
needed to configure git for all the hooks specified in the lefthook config
file.

If you need to add a new hook to an existing config, you must register the
hook with git:
```bash
lefthook add pre-push
```
and then define a command group in `lefthook.yml`:
```yml
pre-push:
  commands:
    packages-audit:
      run: yarn audit
```

### Run git hook groups directly

You don't have to wait for a git hook to fire to run your command groups. You
can call them directly using:
```bash
lefthook run pre-commit
```

Note that calling a git hook group directly will not include git args (but
will handle globs and file groups, where appropriate).

### Custom groups

It is also possible to create command groups that don't correspond to git
hooks. These are simply named groups of commands that can be run using
`lefthook run`. The following example is an excerpt from the
[discourse](https://github.com/discourse/discourse/blob/master/lefthook.yml#L49)
lefthook config.
```yml
# lefthook.yml

lints:
  parallel: true
  commands:
    rubocop:
      run: bundle exec rubocop --parallel
    prettier:
      glob: "*.{js,es6}"
      include: "app/assets/javascripts|test/javascripts"
      run: yarn pprettier --list-different {all_files}
    eslint-assets-es6:
      run: yarn eslint --ext .es6 app/assets/javascripts
    eslint-assets-js:
      run: yarn eslint app/assets/javascripts
```

This command group will only ever run if it is called directly:
```bash
lefthook run lints
```

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


## Scripts

If the task you need to execute is more than a one-liner then you have the
option to create and execute arbitrary scripts.

Lefthook looks for scripts in subdirectories of the `.lefthook` and
`.lefthook-local` directories by default (both relative to the repository
root). The first is for common project level scripts, while the second is for
local scripts. You probably want to add `.lefthook-local` to `.gitignore`.

Within these directories the scripts themselves are stored in directories named
after the command group they are called by. These directories will be created
automatically if you run `lefthook add` with the `-d` flag. For example
`lefthook add -d commit-msg` will create the `.lefthook/commit-msg` and
`.lefthook-local/commit-msg` directories.

The name of the script should match the script name in the lefthook config
file (it won't be executed unless there's a matching entry in the config
file). Scripts are defined under the `scripts` keyword for a given command
group. Although not strictly required (if your script meets certain
requirements), you will likely need to define a `runner` for your script. This
is the binary that will execute your script, such as `bash`, `node` or `ruby`.

For example, having run the `lefthook add` command above you could create the
scripts `.lefthook/commit-msg/hello.js` and `.lefthook/commit-msg/hi.rb`. The
following config file would then call these when the `commit-msg` hook fires:
```yml
# lefthook.yml

commit-msg:
  scripts:
    "hello.js":
      runner: node
    "hi.rb":
      runner: ruby
```

### Using git hook parameters in scripts

Some git hooks are passed parameters when they are called. Lefthook passes
these on to called scripts by appending them to the argument list. They can be
accessed in the same way as any other command line arguments in your scripting
language of choice. The following example is for a
[`prepare-commit-msg`](https://git-scm.com/docs/githooks#_prepare_commit_msg)
hook:
```bash
COMMIT_MSG_FILE=$1
COMMIT_SOURCE=$2
SHA1=$3

# ...
```

### Storing scripts in a different directory

The directories in which lefthook looks for scripts can be changed from the
defaults of `.lefthook` and `.lefthook-local` by setting the global options
`source_dir` and `source_dir_local`:
```yml
# lefthook.yml

source_dir: "lefthook-scripts"
source_dir_local: "lefthook-scripts.local"
```

### Example script

The following example bash script checks that commit messages match an
expected template format, reading in the name of the file holding the proposed
commit message from the git hook parameters for the
[`commit-msg`](https://git-scm.com/docs/githooks#_commit_msg) hook:
```bash
INPUT_FILE=$1
START_LINE=`head -n1 $INPUT_FILE`
PATTERN="^(TICKET)-[[:digit:]]+: "
if ! [[ "$START_LINE" =~ $PATTERN ]]; then
  echo "Bad commit message, see example: TICKET-123: some text"
  exit 1
fi
```

Storing the above script in `.lefthook/commit-msg/template_checker`, we can
trigger lefthook to run it by adding the following config:
```yml
# lefthook.yml

commit-msg:
  scripts:
    "template_checker":
      runner: bash
```

When you try to commit using a poorly formatted commit message (e.g. `git
commit -m "haha bad commit text"`) the `template_checker` script will be
executed. Since the commit message doesn't match the template pattern the
commit will be aborted.


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
