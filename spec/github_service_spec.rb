require 'spec_helper'
require 'octokit'
require 'yaml'

describe GradeRunner::Services::GithubService do
  let(:github_service) { GradeRunner::Services::GithubService.new }
  let(:config_file_path) { '/path/to/config.yml' }

  describe '#retrieve_github_username' do
    context 'when username is in config file' do
      before do
        allow(File).to receive(:exist?).with(config_file_path).and_return(true)
        allow(YAML).to receive(:load_file).with(config_file_path).and_return({
          'github_username' => 'config_username'
        })
      end

      it 'returns username from config file' do
        expect(github_service.retrieve_github_username(config_file_path)).to eq('config_username')
      end
    end

    context 'when username is not in config file' do
      before do
        allow(File).to receive(:exist?).with(config_file_path).and_return(true)
        allow(YAML).to receive(:load_file).with(config_file_path).and_return({})
        allow(github_service).to receive(:`).with('git config user.email').and_return("user@example.com\n")
        allow(github_service).to receive(:`).with('git config user.name').and_return("Local Username\n")
      end

      it 'searches GitHub for email and returns GitHub username if found' do
        search_response = {
          items: [
            { login: 'github_username' }
          ]
        }
        allow(Octokit).to receive(:search_users).with('user@example.com in:email').and_return(search_response)

        expect(github_service.retrieve_github_username(config_file_path)).to eq('github_username')
      end

      it 'returns git config username if GitHub search returns no results' do
        search_response = { items: [] }
        allow(Octokit).to receive(:search_users).with('user@example.com in:email').and_return(search_response)

        expect(github_service.retrieve_github_username(config_file_path)).to eq('Local Username')
      end

      it 'returns empty string if git email is blank' do
        allow(github_service).to receive(:`).with('git config user.email').and_return("\n")

        expect(github_service.retrieve_github_username(config_file_path)).to eq('')
      end
    end

    context 'when config file does not exist' do
      before do
        allow(File).to receive(:exist?).with(config_file_path).and_return(false)
        allow(github_service).to receive(:`).with('git config user.email').and_return("user@example.com\n")
        allow(github_service).to receive(:`).with('git config user.name').and_return("Local Username\n")
      end

      it 'falls back to git config and GitHub search' do
        search_response = {
          items: [
            { login: 'github_username' }
          ]
        }
        allow(Octokit).to receive(:search_users).with('user@example.com in:email').and_return(search_response)

        expect(github_service.retrieve_github_username(config_file_path)).to eq('github_username')
      end
    end
  end

  describe '#set_upstream_remote' do
    let(:repo_slug) { 'organization/repo-name' }
    let(:upstream_url) { "https://github.com/#{repo_slug}" }

    context 'when upstream remote does not exist' do
      before do
        allow(github_service).to receive(:`).with('git remote -v | grep -w upstream').and_return('')
      end

      it 'adds a new upstream remote' do
        expect(github_service).to receive(:`).with("git remote add upstream #{upstream_url}")
        github_service.set_upstream_remote(repo_slug)
      end
    end

    context 'when upstream remote already exists' do
      before do
        allow(github_service).to receive(:`).with('git remote -v | grep -w upstream').and_return('upstream https://github.com/old/repo (fetch)')
      end

      it 'updates the existing upstream remote' do
        expect(github_service).to receive(:`).with("git remote set-url upstream #{upstream_url}")
        github_service.set_upstream_remote(repo_slug)
      end
    end
  end

  describe '#get_commit_sha' do
    it 'returns the first 8 characters of the current commit SHA' do
      allow(github_service).to receive(:`).with('git rev-parse HEAD').and_return('1234567890abcdef1234567890abcdef12345678')
      expect(github_service.get_commit_sha).to eq('12345678')
    end
  end

  describe '#get_repo_name' do
    it 'returns the repository name from the project path' do
      allow(GradeRunner::Utils::PathUtils).to receive(:project_root).and_return(Pathname.new('/path/to/repository-name'))
      expect(github_service.get_repo_name).to eq('repository-name')
    end
  end
end
