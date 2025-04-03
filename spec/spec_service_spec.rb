require 'spec_helper'
require 'fileutils'
require 'tempfile'
require 'tmpdir'

describe GradeRunner::Services::SpecService do
  let(:spec_service) { GradeRunner::Services::SpecService.new }

  describe '#sync_specs_with_source' do
    before do
      # Mock the path utils
      allow(GradeRunner::Utils::PathUtils).to receive(:tmp_path).and_return('/tmp/mock_path')
      allow(GradeRunner::Utils::PathUtils).to receive(:find_or_create_directory).and_return('/tmp/mock_path')
      allow(GradeRunner::Utils::PathUtils).to receive(:project_root).and_return('/tmp/mock_project')
      allow(FileUtils).to receive(:rm_rf)
      allow(FileUtils).to receive(:mkdir_p)
      allow(FileUtils).to receive(:mv)
      allow(FileUtils).to receive(:cp_r)
      allow(FileUtils).to receive(:rm)
      allow(Dir).to receive(:exist?).and_return(false)
      allow(Dir).to receive(:glob).and_return([])
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:join) { |*args| args.join('/') }
    end

    it 'returns false when required parameters are missing' do
      expect(spec_service.sync_specs_with_source(nil, 'sha123', 'url')).to be false
      expect(spec_service.sync_specs_with_source('org/repo', nil, 'url')).to be false
      expect(spec_service.sync_specs_with_source('org/repo', 'sha123', nil)).to be false
    end

    # Test for git operations and spec syncing
    it 'handles git operations properly' do
      # Mock all the git shell commands
      allow(spec_service).to receive(:`).with(any_args).and_return('')

      # Mock URI.open and zip extraction
      allow(spec_service).to receive(:download_file).and_return(true)
      allow(spec_service).to receive(:extract_zip).and_return('/tmp/mock_path/extracted')
      allow(spec_service).to receive(:overwrite_spec_folder).and_return(true)

      # Force the method to update specs by making SHA comparison fail
      allow(spec_service).to receive(:`).with(/git ls-tree/).and_return("blob 100644 different-sha spec")

      # Test the method
      expect(spec_service.sync_specs_with_source('org/repo', 'sha123', 'url')).to be true
    end
  end
end
