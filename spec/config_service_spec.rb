require 'spec_helper'
require 'fileutils'
require 'tempfile'

describe GradeRunner::Services::ConfigService do
  let(:config_service) { GradeRunner::Services::ConfigService.new }
  let(:config_dir) { '.vscode' }
  let(:config_file) { '.ltici_apitoken.yml' }
  let(:config_path) { "#{config_dir}/#{config_file}" }
  let(:default_url) { 'https://example.com' }

  describe '#find_or_create_directory' do
    it 'delegates to PathUtils' do
      expect(GradeRunner::Utils::PathUtils).to receive(:find_or_create_directory).with(config_dir).and_return('/path/to/dir')
      expect(config_service.find_or_create_directory(config_dir)).to eq('/path/to/dir')
    end
  end

  describe '#update_config_file' do
    let(:temp_file) { Tempfile.new(['config', '.yml']) }
    let(:config) { { 'key' => 'value' } }

    after do
      temp_file.close
      temp_file.unlink
    end

    it 'writes YAML to the specified file' do
      expect(File).to receive(:write).with(temp_file.path, YAML.dump(config))
      config_service.update_config_file(temp_file.path, config)
    end
  end

  describe '#load_config' do
    context 'when config file exists' do
      before do
        allow(File).to receive(:exist?).with(config_path).and_return(true)
      end

      it 'loads and returns config data' do
        config_data = { 'submission_url' => 'https://example.com', 'personal_access_token' => 'token123' }
        expect(YAML).to receive(:load_file).with(config_path).and_return(config_data)

        result = config_service.load_config(config_path, default_url)
        expect(result).to eq(config_data)
      end

      it 'handles YAML loading failures' do
        # Add #red method to the String class temporarily
        String.class_eval do
          def red
            self
          end
        end

        # Let YAML.load_file raise an error
        expect(YAML).to receive(:load_file).with(config_path).and_raise(StandardError)

        # Redefine abort to return a value instead of exiting
        original_abort = Kernel.method(:abort)
        begin
          Kernel.define_singleton_method(:abort) do |message|
            # Just return a symbol instead of aborting
            :aborted
          end

          # The method should return nil or not raise an error
          result = config_service.load_config(config_path, default_url)
          expect(result).to eq(:aborted)
        ensure
          # Restore original abort method
          Kernel.define_singleton_method(:abort, original_abort)

          # Remove our temporary method from String
          String.class_eval do
            undef :red
          end
        end
      end
    end

    context 'when config file does not exist' do
      before do
        allow(File).to receive(:exist?).with(config_path).and_return(false)
      end

      it 'returns a hash with default submission URL' do
        result = config_service.load_config(config_path, default_url)
        expect(result).to eq({ 'submission_url' => default_url })
      end
    end
  end

  describe '#get_config_file_path' do
    it 'returns the expected config file path' do
      expect(config_service).to receive(:find_or_create_directory).with(config_dir).and_return("#{config_dir}")
      expect(config_service.get_config_file_path).to eq(config_path)
    end

    it 'accepts custom directory and filename' do
      custom_dir = 'custom_dir'
      custom_file = 'custom_file.yml'
      expect(config_service).to receive(:find_or_create_directory).with(custom_dir).and_return(custom_dir)
      expect(config_service.get_config_file_path(custom_dir, custom_file)).to eq("#{custom_dir}/#{custom_file}")
    end
  end

  describe '#save_token_to_config' do
    let(:token) { 'test_token' }
    let(:submission_url) { 'https://example.com' }
    let(:github_username) { 'testuser' }

    it 'creates a config hash and updates the config file' do
      expected_config = {
        'submission_url' => submission_url,
        'personal_access_token' => token,
        'github_username' => github_username
      }

      expect(config_service).to receive(:update_config_file).with(config_path, expected_config)
      config_service.save_token_to_config(config_path, token, submission_url, github_username)
    end
  end

  describe '#clear_token_in_config' do
    context 'when config file exists' do
      let(:existing_config) { { 'submission_url' => 'https://example.com', 'personal_access_token' => 'old_token' } }

      before do
        allow(File).to receive(:exist?).with(config_path).and_return(true)
        allow(YAML).to receive(:load_file).with(config_path).and_return(existing_config)
      end

      it 'sets the personal_access_token to nil and updates the file' do
        expected_config = existing_config.merge('personal_access_token' => nil)
        expect(config_service).to receive(:update_config_file).with(config_path, expected_config)
        config_service.clear_token_in_config(config_path)
      end
    end

    context 'when config file does not exist' do
      before do
        allow(File).to receive(:exist?).with(config_path).and_return(false)
      end

      it 'does nothing' do
        expect(config_service).not_to receive(:update_config_file)
        config_service.clear_token_in_config(config_path)
      end
    end
  end
end
