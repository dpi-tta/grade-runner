require "oj"
require "grade_runner/utils/path_utils"

module GradeRunner
  module Services
    class SpecService
      def initialize
        @path_utils = GradeRunner::Utils::PathUtils
      end

      def run_tests(output_path)
        # Ensure database is migrated if Rails app
        `bin/rails db:migrate RAILS_ENV=test` if defined?(Rails)
        
        # Run tests with JSON formatter
        `RAILS_ENV=test bundle exec rspec --format JsonOutputFormatter --out #{output_path}`
        
        # Load and return test results
        Oj.load(File.read(output_path))
      end

      def sync_specs_with_source(full_reponame, remote_sha, repo_url)
        # Implement spec synchronization logic here
        # Currently commented out in the original
        # This is a placeholder for future implementation
      end

      def prepare_output_directory
        @path_utils.tmp_output_path
      end
    end
  end
end