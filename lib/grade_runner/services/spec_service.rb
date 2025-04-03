require "oj"
require "fileutils"
require "grade_runner/utils/path_utils"
require "active_support/core_ext/object/blank"

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
        # Return if required parameters are missing
        return false unless full_reponame && remote_sha && repo_url
    
        # Create a temporary directory for clone
        temp_dir = File.join(@path_utils.tmp_path, "upstream_repo")
        FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
        FileUtils.mkdir_p(temp_dir)
    
        Dir.chdir(temp_dir) do
          # Clone the upstream repository
          `git clone https://github.com/#{full_reponame} .`
      
          # Checkout the specific SHA if provided
          `git checkout #{remote_sha}` if remote_sha.present?
      
          # Copy spec directory if it exists
          if Dir.exist?("spec")
            # Remove existing specs in project
            FileUtils.rm_rf("#{@path_utils.project_root}/spec")
        
            # Copy specs from upstream to project
            FileUtils.cp_r("spec", "#{@path_utils.project_root}/")
            return true
          end
        end
    
        false
      ensure
        # Clean up temporary directory
        FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exist?(temp_dir)
      end

      def prepare_output_directory
        @path_utils.tmp_output_path
      end
    end
  end
end