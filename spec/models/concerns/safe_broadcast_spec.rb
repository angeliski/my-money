# frozen_string_literal: true

require "rails_helper"

# Test model that includes SafeBroadcast for testing
class TestBroadcastModel < ApplicationRecord
  include SafeBroadcast

  self.table_name = "users" # Use existing table for testing

  # Public methods that call the safe broadcast methods for testing
  def test_safe_append(stream, **options)
    safe_broadcast_append_to(stream, **options)
  end

  def test_safe_replace(stream, **options)
    safe_broadcast_replace_to(stream, **options)
  end

  def test_safe_remove(stream, **options)
    safe_broadcast_remove_to(stream, **options)
  end

  def test_safe_update(stream, **options)
    safe_broadcast_update_to(stream, **options)
  end

  # Mock the broadcast methods to simulate errors
  def broadcast_append_to(stream, **options)
    raise StandardError, "Broadcast append failed" if options[:should_fail]
  end

  def broadcast_replace_to(stream, **options)
    raise StandardError, "Broadcast replace failed" if options[:should_fail]
  end

  def broadcast_remove_to(stream, **options)
    raise StandardError, "Broadcast remove failed" if options[:should_fail]
  end

  def broadcast_update_to(stream, **options)
    raise StandardError, "Broadcast update failed" if options[:should_fail]
  end
end

RSpec.describe SafeBroadcast, type: :model do
  let(:model) { TestBroadcastModel.new }

  describe "#safe_broadcast_append_to" do
    context "when broadcast succeeds" do
      it "returns true" do
        expect(model.test_safe_append("test_channel", target: "test")).to be true
      end
    end

    context "when broadcast fails" do
      it "returns false and logs error" do
        allow(Rails.logger).to receive(:warn)

        result = model.test_safe_append("test_channel", should_fail: true)

        expect(result).to be false
        expect(Rails.logger).to have_received(:warn).with(/ActionCable broadcast failed/)
      end

      it "does not raise exception" do
        expect {
          model.test_safe_append("test_channel", should_fail: true)
        }.not_to raise_error
      end
    end
  end

  describe "#safe_broadcast_replace_to" do
    context "when broadcast succeeds" do
      it "returns true" do
        expect(model.test_safe_replace("test_channel", target: "test")).to be true
      end
    end

    context "when broadcast fails" do
      it "returns false and logs error" do
        allow(Rails.logger).to receive(:warn)

        result = model.test_safe_replace("test_channel", should_fail: true)

        expect(result).to be false
        expect(Rails.logger).to have_received(:warn).with(/ActionCable broadcast failed/)
      end

      it "does not raise exception" do
        expect {
          model.test_safe_replace("test_channel", should_fail: true)
        }.not_to raise_error
      end
    end
  end

  describe "#safe_broadcast_remove_to" do
    context "when broadcast succeeds" do
      it "returns true" do
        expect(model.test_safe_remove("test_channel", target: "test")).to be true
      end
    end

    context "when broadcast fails" do
      it "returns false and logs error" do
        allow(Rails.logger).to receive(:warn)

        result = model.test_safe_remove("test_channel", should_fail: true)

        expect(result).to be false
        expect(Rails.logger).to have_received(:warn).with(/ActionCable broadcast failed/)
      end

      it "does not raise exception" do
        expect {
          model.test_safe_remove("test_channel", should_fail: true)
        }.not_to raise_error
      end
    end
  end

  describe "#safe_broadcast_update_to" do
    context "when broadcast succeeds" do
      it "returns true" do
        expect(model.test_safe_update("test_channel", target: "test")).to be true
      end
    end

    context "when broadcast fails" do
      it "returns false and logs error" do
        allow(Rails.logger).to receive(:warn)

        result = model.test_safe_update("test_channel", should_fail: true)

        expect(result).to be false
        expect(Rails.logger).to have_received(:warn).with(/ActionCable broadcast failed/)
      end

      it "does not raise exception" do
        expect {
          model.test_safe_update("test_channel", should_fail: true)
        }.not_to raise_error
      end
    end
  end

  describe "error logging" do
    it "includes action, stream name, and error details in log message" do
      allow(Rails.logger).to receive(:warn)

      model.test_safe_append("test_stream", should_fail: true)

      expect(Rails.logger).to have_received(:warn).with(
        a_string_including("Action: append", "Stream: test_stream", "StandardError")
      )
    end

    context "in development or test environment" do
      it "logs backtrace for debugging" do
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:debug)
        allow(Rails.env).to receive(:development?).and_return(true)

        model.test_safe_append("test_channel", should_fail: true)

        expect(Rails.logger).to have_received(:debug).with(/backtrace/i)
      end
    end
  end
end
