require 'spec_helper'
require 'stringio'

describe HintFormatter do
  let(:output) { StringIO.new }
  let(:formatter) { HintFormatter.new(output) }
  let(:example) { double('example') }
  let(:exception) { double('exception') }
  let(:notification) { RSpec::Core::Notifications::FailedExampleNotification.new(example) }

  before do
    allow(example).to receive(:metadata).and_return({})
    allow(example).to receive(:execution_result).and_return(double('result', exception: exception, status: :failed))
    allow(example).to receive(:description).and_return('test example')
    allow(example).to receive(:location_rerun_argument).and_return('location')
    allow(example).to receive(:full_description).and_return('full test example')
    allow(exception).to receive(:message).and_return('error message')
    allow(exception).to receive(:class).and_return(StandardError)
    allow(exception).to receive(:backtrace).and_return(['line 1', 'line 2'])
  end

  describe '#example_failed' do
    context 'when hint is present in metadata' do
      before do
        # We need to use an array for the hint since that's how it's checked in the actual code
        allow(example).to receive(:metadata).and_return({ hint: ['This is a hint'] })
        allow_any_instance_of(Array).to receive(:present?).and_return(true)
      end

      it 'displays the hint' do
        formatter.example_failed(notification)
        expect(output.string).to include('HINT:')
        expect(output.string).to include('This is a hint')
      end
    end

    context 'when hint is not present in metadata' do
      before do
        allow_any_instance_of(NilClass).to receive(:present?).and_return(false)
      end

      it 'does not display any hint' do
        formatter.example_failed(notification)
        expect(output.string).not_to include('HINT:')
      end
    end
  end
end
