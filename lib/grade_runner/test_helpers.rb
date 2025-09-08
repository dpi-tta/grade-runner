# lib/grade_runner/test_helpers.rb
require "stringio"

module GradeRunner
  ##
  # TestHelpers provides small utilities for writing exercise specs
  # that need to capture program output. These helpers keep specs
  # short, readable, and consistent across projects.
  #
  # Example usage (RSpec):
  #
  #   RSpec.configure do |config|
  #     config.include GradeRunner::TestHelpers
  #   end
  #
  #   it "captures script output" do
  #     lines = pp_lines_from("./hello.rb")
  #     expect(lines).to eq(["hello, world"])
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
    #   output = capture_stdout { puts "hi" }  # => "hi\n"
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
    # Load a Ruby file (like `ruby file.rb`) and capture its output.
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
    # Shorthand to run a script in the current process and return its STDOUT.
    #
    # @param path [String] the script path (e.g., "./script.rb")
    # @return [String] captured stdout
    #
    # @example
    #   out = run_script("./hello.rb")
    #
    def run_script(path)
      capture_output_of(path)
    end

    ##
    # Normalize output produced via pp/puts by:
    # - removing double quotes (pp wraps strings in quotes),
    # - splitting into lines,
    # - trimming whitespace,
    # - removing empty lines.
    #
    # @param output [String]
    # @return [Array<String>] cleaned lines
    #
    # @example
    #   lines = normalize_output(%("14"\n"lucky"\n))  # => ["14", "lucky"]
    #
    def normalize_output(output)
      output.gsub('"', '').lines.map(&:strip).reject(&:empty?)
    end

    ##
    # Convenience for specs where scripts print with `pp`:
    # Runs the file and returns normalized lines (see #normalize_output).
    #
    # If rand_value is provided, stubs bare `rand(...)` calls by
    # intercepting Kernel#rand as invoked on Object instances
    # (i.e., `rand(1..100)` with no explicit receiver).
    #
    # @param file_path [String]
    # @param rand_value [Integer, nil] optional stub value for rand
    # @return [Array<String>] normalized lines
    #
    # @example
    #   lines = pp_lines_from("./lucky_number.rb", rand_value: 14)
    #   expect(lines).to eq(%w[14 lucky])
    #
    def pp_lines_from(file_path, rand_value: nil)
      if rand_value
        # Requires RSpec mocks (this module is intended to be included in RSpec)
        allow_any_instance_of(Object).to receive(:rand).and_return(rand_value)
      end
      normalize_output(run_script(file_path))
    end
  end
end
