# frozen_string_literal: true

require 'fileutils'

class FileStructure
  class << self
    attr_accessor :root

    def have_git
      FileUtils.mkdir_p(File.join(tmp, '.git', 'hooks'))
      # Needed to make git think this is an actual repo. The git command is
      # used to determine the location of the .git directory, for example.
      FileUtils.mkdir_p(File.join(tmp, '.git', 'objects'))
      FileUtils.mkdir_p(File.join(tmp, '.git', 'refs'))
      File.write(File.join(tmp, '.git', 'HEAD'), "ref: refs/heads/master")
    end

    def make_scripts_preset
      FileUtils.mkdir_p(File.join(tmp, '.lefthook', 'pre-commit'))
      FileUtils.cp(
        [ok_script_path, fail_script_path],
        File.join(tmp, '.lefthook', 'pre-commit')
      )

      FileUtils.mkdir_p(File.join(tmp, '.lefthook', 'pre-push'))
      FileUtils.cp(ok_script_path, File.join(tmp, '.lefthook', 'pre-push'))

      FileUtils.cp(pre_push_hook_path, File.join(tmp, '.git', 'hooks'))

      FileUtils.chmod_R 0o777, tmp
    end

    def clean
      FileUtils.remove_dir(tmp)
    end

    def make_config(extension = 'yml')
      FileUtils.cp(config_yaml_path(extension), tmp)
    end


    def tmp
      @tmp ||= File.join(root, 'tmp')
    end

    def config_yaml_path(extension = 'yml')
      File.join(fixtures, "lefthook.#{extension}")
    end

    def ok_script_path
      File.join(fixtures, 'ok_script')
    end

    def fail_script_path
      File.join(fixtures, 'fail_script')
    end

    def pre_commit_hook_path
      File.join(fixtures, 'pre-commit')
    end

    def pre_push_hook_path
      File.join(fixtures, 'pre-push')
    end

    private

    def fixtures
      File.join(root, 'fixtures')
    end
  end
end
