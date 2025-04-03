require 'spec_helper'

describe GradeRunner::Services::GradeService do
  let(:grade_service) { GradeRunner::Services::GradeService.new }
  
  before do
    # Save original value
    @original_override_value = GradeRunner.override_local_specs
    
    # Mock dependencies
    allow_any_instance_of(GradeRunner::Services::ConfigService).to receive(:get_config_file_path).and_return('config_file.yml')
    allow_any_instance_of(GradeRunner::Services::ConfigService).to receive(:load_config).and_return({ 'personal_access_token' => 'token' })
    allow_any_instance_of(GradeRunner::Services::TokenService).to receive(:get_token).and_return('valid_token')
    allow_any_instance_of(GradeRunner::Services::TokenService).to receive(:validate_token).and_return(true)
    allow_any_instance_of(GradeRunner::Services::GithubService).to receive(:retrieve_github_username).and_return('username')
  end
  
  after do
    # Restore original value
    GradeRunner.override_local_specs = @original_override_value
  end
  
  describe '#process_grade_all' do
    context 'when specs synchronization is enabled' do
      it 'calls sync_specs_with_source when override_local_specs is true' do
        # Set up configuration
        GradeRunner.override_local_specs = true
        
        # Mock token fetch to avoid API calls
        resource_info = {
          'repo_slug' => 'org/repo',
          'spec_folder_sha' => 'sha123',
          'source_code_url' => 'url'
        }
        
        allow_any_instance_of(GradeRunner::Services::TokenService).to receive(:fetch_upstream_repo).and_return(resource_info)
        
        # Expectations
        expect_any_instance_of(GradeRunner::Services::GithubService).to receive(:set_upstream_remote).with('org/repo')
        expect_any_instance_of(GradeRunner::Services::SpecService).to receive(:sync_specs_with_source).with('org/repo', 'sha123', 'url')
        
        # Skip the actual test running and submission
        allow_any_instance_of(GradeRunner::Services::SpecService).to receive(:prepare_output_directory).and_return('output.json')
        allow_any_instance_of(GradeRunner::Services::SpecService).to receive(:run_tests).and_return({})
        allow_any_instance_of(GradeRunner::Runner).to receive(:process).and_return(true)
        
        grade_service.process_grade_all
      end
    end
    
    context 'when specs synchronization is disabled' do
      it 'does not call sync_specs_with_source when override_local_specs is false' do
        # Set up configuration
        GradeRunner.override_local_specs = false
        
        # Expectations
        expect_any_instance_of(GradeRunner::Services::TokenService).not_to receive(:fetch_upstream_repo)
        expect_any_instance_of(GradeRunner::Services::GithubService).not_to receive(:set_upstream_remote)
        expect_any_instance_of(GradeRunner::Services::SpecService).not_to receive(:sync_specs_with_source)
        
        # Skip the actual test running and submission
        allow_any_instance_of(GradeRunner::Services::SpecService).to receive(:prepare_output_directory).and_return('output.json')
        allow_any_instance_of(GradeRunner::Services::SpecService).to receive(:run_tests).and_return({})
        allow_any_instance_of(GradeRunner::Runner).to receive(:process).and_return(true)
        
        grade_service.process_grade_all
      end
    end
  end
end