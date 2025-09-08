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
  #     lines = pp_lines_from_run("./hello.rb")
  #     expect(lines).to eq(["hello, world"])
  #   end
  #
  module TestHelpers
    Status = Struct.new(:exitstatus) do
      def success? = exitstatus.to_i == 0
    end

    ##
    # Run a Ruby script in-process (like `ruby file.rb`) while capturing
    # its stdout, stderr, and exitstatus.
    #
    # @param path [String] path to the script (e.g., "./calculator.rb")
    # @param stdin [String] content fed into gets/$stdin (include "\n")
    # @param argv [Array<String>] values to replace ARGV with
    # @return [Array(String, String, Status)] [stdout, stderr, status]
    #
    # @example
    #   out, err, status = run_script("./hello.rb", stdin: "7\n3\n")
    #
    def run_script(path, stdin: "", argv: [])
      orig_stdin, orig_stdout, orig_stderr = $stdin, $stdout, $stderr
      orig_argv = ARGV.dup

      in_buf  = StringIO.new(String(stdin))
      out_buf = StringIO.new
      err_buf = StringIO.new

      $stdin  = in_buf
      $stdout = out_buf
      $stderr = err_buf
      ARGV.replace(Array(argv))

      status = Status.new(0)

      begin
        load path
      rescue SystemExit => e
        status.exitstatus = e.status || 1
      rescue Exception => e
        err_buf.puts("#{e.class}: #{e.message}")
        e.backtrace&.each { |ln| err_buf.puts(ln) }
        status.exitstatus = 1
      ensure
        $stdin  = orig_stdin
        $stdout = orig_stdout
        $stderr = orig_stderr
        ARGV.replace(orig_argv)
      end

      [out_buf.string, err_buf.string, status]
    end

    ##
    # Run a script and return normalized pp/puts lines:
    #   - strips quotes (pp wraps strings in quotes)
    #   - trims whitespace
    #   - drops empty lines
    #
    # @param path [String]
    # @param stdin [String]
    # @return [Array<String>]
    #
    # @example
    #   lines = pp_lines_from_run("./lucky_number.rb", stdin: "14\n")
    #   expect(lines).to eq(%w[14 lucky])
    #
    def pp_lines_from_run(path, stdin: "")
      stdout, _stderr, _status = run_script(path, stdin: stdin)
      normalize_output(stdout)
    end
    alias pp_lines_from_capture3 pp_lines_from_run

    ##
    # Remove quotes, split into lines, strip, and reject empties.
    #
    # @param output [String]
    # @return [Array<String>]
    def normalize_output(output)
      output.gsub('"', "").lines.map(&:strip).reject(&:empty?)
    end

    ##
    # Run a Ruby file and capture its stdout.
    #
    # @param path [String]
    # @return [String]
    #
    def run_file(path)
      capture_stdout { load path }
    end

    ##
    # Capture standard output (and optionally stderr) while running a block.
    #
    # @param capture_stderr [Boolean]
    # @yield block to run
    # @return [String] stdout, or [stdout, stderr] if capture_stderr
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
    # Remove comment-only lines from source.
    #
    # @param src [String]
    # @return [String] source without comments
    #
    # @example
    #   clean = source_without_comments(File.read("calculator.rb"))
    #
    def source_without_comments(src)
      src.lines.reject { |line| line.strip.start_with?("#") }.join
    end
    alias strip_comments source_without_comments
  end
end
