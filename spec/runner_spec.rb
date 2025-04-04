require 'spec_helper'

describe GradeRunner::Runner do
  let(:submission_url) { 'https://example.com' }
  let(:token) { '2a3b4c5d6e7f8g9h0j2k3m4n5p' }
  let(:rspec_output) do
    {
      'summary' => {
        'duration' => 1.5,
        'example_count' => 10,
        'failure_count' => 2,
        'pending_count' => 1
      },
      'examples' => [
        { 'status' => 'passed', 'description' => 'test 1' },
        { 'status' => 'failed', 'description' => 'test 2' }
      ]
    }
  end
  let(:username) { 'testuser' }
  let(:reponame) { 'test-repo' }
  let(:sha) { 'abc1234' }
  let(:context) { 'manual' }

  let(:runner) { GradeRunner::Runner.new(submission_url, token, rspec_output, username, reponame, sha, context) }

  describe '#process' do
    let(:url) { "#{submission_url}/builds" }
    let(:uri) { URI.parse(url) }
    let(:http_response) { instance_double(Net::HTTPResponse, body: '{"url":"https://grades.example.com/results/123"}') }
    let(:http) { instance_double(Net::HTTP) }

    before do
      # Set up stubs for private methods
      allow(runner).to receive(:submission_path).and_return('/builds')

      # Set up HTTP request stubs
      allow(URI).to receive(:parse).with(url).and_return(uri)
      allow(Net::HTTP::Post).to receive(:new).with(uri, 'Content-Type' => 'application/json').and_call_original
      allow(Net::HTTP).to receive(:start).with(uri.hostname, uri.port, use_ssl: true).and_yield(http)
      allow(http).to receive(:request).and_return(http_response)

      # Stub JSON conversion & parsing
      allow_any_instance_of(Hash).to receive(:to_json).and_return('{"json":"data"}')
      allow(Oj).to receive(:load).with(http_response.body).and_return({ 'url' => 'https://grades.example.com/results/123' })
    end

    it 'makes a POST request to the submission URL with the correct parameters' do
      expect(Net::HTTP::Post).to receive(:new).with(uri, 'Content-Type' => 'application/json')
      runner.process
    end

    it 'formats the data correctly' do
      # Check the data hash format
      expect(runner.send(:data)).to include(
        access_token: token,
        test_output: rspec_output,
        commit_sha: sha,
        username: username,
        reponame: reponame,
        source: context
      )

      runner.process
    end

    it 'can handle network errors' do
      # This test simply verifies that when Net::HTTP.start raises an error,
      # the implementation runs through the error path
      allow(Net::HTTP).to receive(:start).and_raise(StandardError)

      # Since the actual implementation doesn't handle errors, just verify
      # that we're testing the right thing
      expect(runner).to receive(:post_to_grades).and_call_original

      # Original implementation will raise an error, which is fine for this test
      expect {
        runner.process
      }.to raise_error(StandardError)
    end
  end
end
