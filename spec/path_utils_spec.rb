require 'spec_helper'
require 'fileutils'
require 'pathname'

describe GradeRunner::Utils::PathUtils do
  describe '.project_root' do
    context 'when Rails is defined' do
      before do
        # Create a mock Rails module
        module Rails
          def self.root
            Pathname.new('/rails/root')
          end
        end
        # Save original constant
        @original_rails = Rails if defined?(Rails)
      end

      after do
        # Clean up our mock
        Object.send(:remove_const, :Rails)
        # Restore original if it existed
        Rails = @original_rails if @original_rails
      end

      it 'returns Rails.root path' do
        expect(GradeRunner::Utils::PathUtils.project_root).to eq(Pathname.new('/rails/root'))
      end
    end

    context 'when Bundler is defined but Rails is not' do
      before do
        # Remove Rails for this test
        if defined?(Rails)
          @original_rails = Rails
          Object.send(:remove_const, :Rails)
        end

        # Create a mock Bundler module
        module Bundler
          def self.root
            Pathname.new('/bundler/root')
          end
        end
        # Save original constant
        @original_bundler = Bundler if defined?(Bundler)
      end

      after do
        # Clean up our mock
        Object.send(:remove_const, :Bundler)
        # Restore original if it existed
        Bundler = @original_bundler if @original_bundler
        # Restore Rails if it was removed
        Rails = @original_rails if @original_rails
      end

      it 'returns Bundler.root path' do
        expect(GradeRunner::Utils::PathUtils.project_root).to eq(Pathname.new('/bundler/root'))
      end
    end

    context 'when neither Rails nor Bundler is defined' do
      before do
        # Remove constants for this test
        if defined?(Rails)
          @original_rails = Rails
          Object.send(:remove_const, :Rails)
        end

        if defined?(Bundler)
          @original_bundler = Bundler
          Object.send(:remove_const, :Bundler)
        end

        allow(Dir).to receive(:pwd).and_return('/current/directory')
      end

      after do
        # Restore constants if they existed
        Rails = @original_rails if @original_rails
        Bundler = @original_bundler if @original_bundler
      end

      it 'returns current directory as Pathname' do
        expect(GradeRunner::Utils::PathUtils.project_root).to eq(Pathname.new('/current/directory'))
      end
    end
  end

  describe '.path_in_project' do
    before do
      allow(GradeRunner::Utils::PathUtils).to receive(:project_root).and_return(Pathname.new('/project/root'))
    end

    it 'joins path with project root' do
      expect(GradeRunner::Utils::PathUtils.path_in_project('subdir')).to eq(Pathname.new('/project/root/subdir'))
    end
  end

  describe '.find_or_create_directory' do
    before do
      allow(GradeRunner::Utils::PathUtils).to receive(:path_in_project).and_return(Pathname.new('/project/root/test_dir'))
      allow(Dir).to receive(:exist?).and_return(false)
      allow(FileUtils).to receive(:mkdir_p)
    end

    it 'creates directory if it does not exist' do
      expect(FileUtils).to receive(:mkdir_p).with(Pathname.new('/project/root/test_dir'))
      result = GradeRunner::Utils::PathUtils.find_or_create_directory('test_dir')
      expect(result).to eq('/project/root/test_dir')
    end

    it 'does not create directory if it exists' do
      allow(Dir).to receive(:exist?).and_return(true)
      expect(FileUtils).not_to receive(:mkdir_p)
      result = GradeRunner::Utils::PathUtils.find_or_create_directory('test_dir')
      expect(result).to eq('/project/root/test_dir')
    end
  end

  describe '.tmp_output_path' do
    before do
      allow(GradeRunner::Utils::PathUtils).to receive(:find_or_create_directory).and_return('/project/root/tmp/output')
      allow(Time).to receive(:now).and_return(Time.at(1234567890))
    end

    it 'returns a timestamped JSON path in the output directory' do
      expect(GradeRunner::Utils::PathUtils.tmp_output_path).to eq('/project/root/tmp/output/1234567890.json')
    end
  end

  describe '.tmp_path' do
    it 'returns the tmp directory path' do
      expect(GradeRunner::Utils::PathUtils).to receive(:find_or_create_directory).with('tmp').and_return('/project/root/tmp')
      expect(GradeRunner::Utils::PathUtils.tmp_path).to eq('/project/root/tmp')
    end
  end
end
