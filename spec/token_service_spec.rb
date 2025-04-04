require 'spec_helper'
require 'net/http'

describe GradeRunner::Services::TokenService do
  let(:submission_url) { 'https://example.com' }
  let(:token_service) { GradeRunner::Services::TokenService.new(submission_url) }
  let(:valid_token) { '2a3b4c5d6e7f8g9h0j2k3m4n5p' }
  let(:invalid_token) { 'invalid-token' }

  describe '#initialize' do
    it 'sets the submission_url attribute' do
      expect(token_service.submission_url).to eq(submission_url)
    end
  end

  describe '#validate_token' do
    let(:uri) { URI.parse("#{submission_url}/submissions/validate_token?token=#{valid_token}") }
    let(:http_response) { instance_double(Net::HTTPResponse, body: '{"success":true}') }
    let(:http) { instance_double(Net::HTTP) }

    before do
      allow(URI).to receive(:parse).and_return(uri)
      allow(Net::HTTP::Get).to receive(:new).and_return(double('request'))
      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(http_response)
      allow(Oj).to receive(:load).with(http_response.body).and_return({ 'success' => true })
    end

    context 'with valid token format' do
      it 'returns true when token is valid according to API' do
        # Directly stub the regex validation
        allow(valid_token).to receive(:=~).with(GradeRunner::Services::TokenService::TOKEN_REGEX).and_return(0)
        expect(token_service.validate_token(valid_token)).to be true
      end

      it 'returns false when API returns success: false' do
        # Directly stub the regex validation
        allow(valid_token).to receive(:=~).with(GradeRunner::Services::TokenService::TOKEN_REGEX).and_return(0)
        allow(Oj).to receive(:load).with(http_response.body).and_return({ 'success' => false })
        expect(token_service.validate_token(valid_token)).to be false
      end

      it 'handles network errors gracefully' do
        # Directly stub the regex validation
        allow(valid_token).to receive(:=~).with(GradeRunner::Services::TokenService::TOKEN_REGEX).and_return(0)
        allow(Net::HTTP).to receive(:start).and_raise(StandardError)
        expect(token_service.validate_token(valid_token)).to be false
      end
    end

    context 'with invalid token format' do
      it 'returns false for nil token' do
        expect(token_service.validate_token(nil)).to be false
      end

      it 'returns false for non-string token' do
        expect(token_service.validate_token(123)).to be false
      end

      it 'returns false for invalid format token' do
        expect(token_service.validate_token(invalid_token)).to be false
      end
    end
  end

  describe '#get_token' do
    let(:config_file) { 'config.yml' }

    context 'when input token is present' do
      it 'returns the input token' do
        expect(token_service.get_token('input_token', 'file_token', config_file)).to eq('input_token')
      end
    end

    context 'when input token is blank but file token is present' do
      it 'returns the file token' do
        expect(token_service.get_token(nil, 'file_token', config_file)).to eq('file_token')
        expect(token_service.get_token('', 'file_token', config_file)).to eq('file_token')
      end
    end

    context 'when both input and file tokens are blank' do
      it 'prompts for token' do
        expect(token_service).to receive(:prompt_for_token).with(config_file).and_return('new_token')
        expect(token_service.get_token(nil, nil, config_file)).to eq('new_token')
      end
    end
  end

  describe '#prompt_for_token' do
    let(:config_file) { 'config.yml' }
    let(:stdin_mock) { StringIO.new(valid_token) }

    before do
      $stdout = StringIO.new
      $stdin = stdin_mock
    end

    after do
      $stdout = STDOUT
      $stdin = STDIN
    end

    it 'prompts for token and returns it when valid' do
      allow(token_service).to receive(:validate_token).with(valid_token).and_return(true)
      expect(token_service.prompt_for_token(config_file)).to eq(valid_token)
    end

    it 'continues prompting until valid token is entered' do
      $stdin = StringIO.new("#{invalid_token}\n#{valid_token}")
      allow(token_service).to receive(:validate_token).with(invalid_token).and_return(false)
      allow(token_service).to receive(:validate_token).with(valid_token).and_return(true)
      expect(token_service.prompt_for_token(config_file)).to eq(valid_token)
    end
  end

  describe '#fetch_upstream_repo' do
    let(:uri) { URI.parse("#{submission_url}/submissions/resource?token=#{valid_token}") }
    let(:http_response) { instance_double(Net::HTTPResponse, body: '{"repo_slug":"org/repo","spec_folder_sha":"abc123","source_code_url":"https://example.com/archive.zip"}') }
    let(:http) { instance_double(Net::HTTP) }
    let(:expected_result) { { 'repo_slug' => 'org/repo', 'spec_folder_sha' => 'abc123', 'source_code_url' => 'https://example.com/archive.zip' } }

    before do
      allow(URI).to receive(:parse).and_return(uri)
      allow(Net::HTTP::Get).to receive(:new).and_return(double('request'))
      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(http_response)
      allow(Oj).to receive(:load).with(http_response.body).and_return(expected_result)
    end

    context 'with valid token format' do
      it 'returns repository information hash' do
        # Directly stub the regex validation
        allow(valid_token).to receive(:=~).with(GradeRunner::Services::TokenService::TOKEN_REGEX).and_return(0)
        expect(token_service.fetch_upstream_repo(valid_token)).to eq(expected_result)
      end

      it 'handles network errors gracefully' do
        # Directly stub the regex validation
        allow(valid_token).to receive(:=~).with(GradeRunner::Services::TokenService::TOKEN_REGEX).and_return(0)
        allow(Net::HTTP).to receive(:start).and_raise(StandardError)
        expect(token_service.fetch_upstream_repo(valid_token)).to be false
      end
    end

    context 'with invalid token format' do
      it 'returns false' do
        expect(token_service.fetch_upstream_repo(invalid_token)).to be false
      end
    end
  end
end
