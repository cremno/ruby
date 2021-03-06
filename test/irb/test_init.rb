# frozen_string_literal: false
require "test/unit"
require "irb"
require "fileutils"

module TestIRB
  class TestInit < Test::Unit::TestCase
    def setup
      # IRBRC is for RVM...
      @backup_env = %w[HOME XDG_CONFIG_HOME IRBRC].each_with_object({}) do |env, hash|
        hash[env] = ENV.delete(env)
      end
      ENV["HOME"] = @tmpdir = Dir.mktmpdir("test_irb_init_#{$$}")
    end

    def teardown
      ENV.update(@backup_env)
      FileUtils.rm_rf(@tmpdir)
    end

    def test_setup_with_argv_preserves_global_argv
      argv = ["foo", "bar"]
      with_argv(argv) do
        IRB.setup(eval("__FILE__"), argv: %w[-f])
        assert_equal argv, ARGV
      end
    end

    def test_setup_with_minimum_argv_does_not_change_dollar0
      orig = $0.dup
      IRB.setup(eval("__FILE__"), argv: %w[-f])
      assert_equal orig, $0
    end

    def test_rc_file
      tmpdir = @tmpdir
      Dir.chdir(tmpdir) do
        IRB.conf[:RC_NAME_GENERATOR] = nil
        assert_equal(tmpdir+"/.irb#{IRB::IRBRC_EXT}", IRB.rc_file)
        assert_equal(tmpdir+"/.irb_history", IRB.rc_file("_history"))
        IRB.conf[:RC_NAME_GENERATOR] = nil
        FileUtils.touch(tmpdir+"/.irb#{IRB::IRBRC_EXT}")
        assert_equal(tmpdir+"/.irb#{IRB::IRBRC_EXT}", IRB.rc_file)
        assert_equal(tmpdir+"/.irb_history", IRB.rc_file("_history"))
      end
    end

    def test_rc_file_in_subdir
      tmpdir = @tmpdir
      Dir.chdir(tmpdir) do
        FileUtils.mkdir_p("#{tmpdir}/mydir")
        Dir.chdir("#{tmpdir}/mydir") do
          IRB.conf[:RC_NAME_GENERATOR] = nil
          assert_equal(tmpdir+"/.irb#{IRB::IRBRC_EXT}", IRB.rc_file)
          assert_equal(tmpdir+"/.irb_history", IRB.rc_file("_history"))
          IRB.conf[:RC_NAME_GENERATOR] = nil
          FileUtils.touch(tmpdir+"/.irb#{IRB::IRBRC_EXT}")
          assert_equal(tmpdir+"/.irb#{IRB::IRBRC_EXT}", IRB.rc_file)
          assert_equal(tmpdir+"/.irb_history", IRB.rc_file("_history"))
        end
      end
    end

    def test_recovery_sigint
      bundle_exec = ENV.key?('BUNDLE_GEMFILE') ? ['-rbundler/setup'] : []
      status = assert_in_out_err(bundle_exec + %w[-W0 -rirb -e binding.irb;loop{Process.kill("SIGINT",$$)} -- -f --], "exit\n", //, //)
      Process.kill("SIGKILL", status.pid) if !status.exited? && !status.stopped? && !status.signaled?
    end

    private

    def with_argv(argv)
      orig = ARGV.dup
      ARGV.replace(argv)
      yield
    ensure
      ARGV.replace(orig)
    end
  end
end
