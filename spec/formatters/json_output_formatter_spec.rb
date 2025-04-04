require 'spec_helper'
require 'stringio'
require 'tempfile'
require 'json'

describe JsonOutputFormatter do
  let(:output) { StringIO.new }
  let(:formatter) { JsonOutputFormatter.new(output) }
  let(:example_group) { RSpec::Core::ExampleGroup.describe('TestGroup') }

  before do
    # Set up GradeRunner.default_points
    allow(GradeRunner).to receive(:default_points).and_return(1)
  end

  describe '#dump_summary' do
    let(:summary) do
      instance_double(
        RSpec::Core::Notifications::SummaryNotification,
        duration: 1.5,
        example_count: 3,
        failure_count: 1,
        pending_count: 1,
        errors_outside_of_examples_count: 0,
        examples: [
          double('example1',
            metadata: { points: 2 },
            execution_result: double('result1', status: :passed)
          ),
          double('example2',
            metadata: { points: 3 },
            execution_result: double('result2', status: :failed)
          ),
          double('example3',
            metadata: {},
            execution_result: double('result3', status: :pending)
          )
        ]
      )
    end

    before do
      formatter.instance_variable_set(:@output_hash, { examples: [] })
    end

    it 'calculates and formats the summary correctly' do
      formatter.dump_summary(summary)
      formatter.close(nil)

      result = Oj.load(output.string)

      expect(result['summary']).to include(
        'duration' => 1.5,
        'example_count' => 3,
        'failure_count' => 1,
        'pending_count' => 1,
        'total_points' => 6, # 2 + 3 + 1 (default)
        'earned_points' => 2  # only the passed test counts
      )

      expect(result['summary']['score']).to be_within(0.0001).of(0.3333)
      expect(result['summary_line']).to include('3 tests')
      expect(result['summary_line']).to include('1 failures')
      expect(result['summary_line']).to include('2/6 points')
      expect(result['summary_line']).to include('33.33%')
    end

    context 'when there are errors outside examples' do
      let(:summary_with_errors) do
        instance_double(
          RSpec::Core::Notifications::SummaryNotification,
          duration: 1.5,
          example_count: 3,
          failure_count: 1,
          pending_count: 1,
          errors_outside_of_examples_count: 1,
          examples: []
        )
      end

      it 'sets a special error message in the result' do
        formatter.dump_summary(summary_with_errors)
        formatter.close(nil)

        result = Oj.load(output.string)
        expect(result['summary_line']).to include('An error occurred while running tests')
      end
    end
  end
end
