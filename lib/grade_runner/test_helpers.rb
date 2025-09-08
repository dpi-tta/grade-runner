# lib/grade_runner/test_helpers.rb
require "stringio"

module GradeRunner
  ##
  # TestHelpers provides small utilities for writing exercise specs
  # that need to capture program output or temporarily modify the
  # runtime environment. These helpers are designed to make specs
  # shorter, clearer, and more consistent across projects.
  #
  # Example usage (RSpec):
  #
  #   RSpec.configure do |config|
  #     config.include GradeRunner::TestHelpers
  #   end
  #
  #   it "captures script output" do
  #     output = capture_output_of("./hello.rb")
  #     expect(output).to eq("\"hello, world\"\n")
  #   end
  #
  module TestHelpers
    ##
    # Capture standard output (and optionally standard error) while
    # executing a block.
    #
    # @param capture_stderr [Boolean] whether to also capture $stderr
    # @yield block of code to execute
    # @return [String] captured STDOUT if capture_stderr: false
    # @return [Array<String,String>] [STDOUT, STDERR] if capture_stderr: true
    #
    # @example
    #   output = capture_stdout { puts "hi" }
    #   # => "hi\n"
    #
    #   out, err = capture_stdout(capture_stderr: true) do
    #     puts "ok"
    #     warn "oops"
    #   end
    #   # out = "ok\n"
    #   # err = "oops\n"
    #
    def capture_stdout(capture_stderr: false)
      orig_out, orig_err = $stdout, $stderr
      out_buf = StringIO.new
      err_buf = capture_stderr ? StringIO.new : nil

      $stdout = out_buf
      $stderr = err_buf if capture_stderr

      yield

      capture_stderr ? [out_buf.string, err_buf.string] : out_buf.string
    ensure
      $stdout = orig_out
      $stderr = orig_err if capture_stderr
    end

    ##
    # Convenience alias for capture_stdout with capture_stderr: true.
    #
    # @yield block of code to execute
    # @return [Array<String,String>] [STDOUT, STDERR]
    #
    # @example
    #   out, err = capture_io { puts "ok"; warn "oops" }
    #
    def capture_io(&block)
      capture_stdout(capture_stderr: true, &block)
    end

    ##
    # Load a Ruby file (like "ruby file.rb") and capture its output.
    #
    # This is especially useful for testing beginner exercises
    # where the code lives in a standalone script and prints with pp/puts.
    #
    # @param file_path [String] path to the file to load
    # @param capture_stderr [Boolean] whether to also capture $stderr
    # @return [String, Array<String,String>] captured output
    #
    # @example
    #   output = capture_output_of("./hello.rb")
    #   expect(output).to eq("\"hello, world\"\n")
    #
    def capture_output_of(file_path, capture_stderr: false)
      capture_stdout(capture_stderr: capture_stderr) { load file_path }
    end

    ##
    # Temporarily set environment variables within a block.
    #
    # Original values are restored afterward, even if the block raises.
    #
    # @param hash [Hash{String,Symbol=>String,nil}] ENV vars to override
    # @yield block to run with modified ENV
    #
    # @example
    #   with_env("LUCKY" => "14") do
    #     output = capture_output_of("./lucky_number.rb")
    #     expect(output).to include("14")
    #   end
    #
    def with_env(hash)
      old = {}
      hash.each { |k, v| old[k] = ENV[k]; ENV[k] = v }
      yield
    ensure
      old.each { |k, v| ENV[k] = v }
    end

    ##
    # Temporarily change the current working directory for a block.
    #
    # Useful when testing scripts that assume a particular relative path.
    #
    # @param dir [String] directory to change into
    # @yield block to run inside the directory
    #
    # @example
    #   with_chdir("examples") do
    #     output = capture_output_of("./script.rb")
    #   end
    #
    def with_chdir(dir)
      old = Dir.pwd
      Dir.chdir(dir)
      yield
    ensure
      Dir.chdir(old)
    end
  end
end
