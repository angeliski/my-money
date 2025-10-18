# frozen_string_literal: true

# SafeBroadcast concern provides error-safe ActionCable broadcasting methods
#
# ActionCable is used for real-time UI updates but should never block or fail
# critical business operations. All broadcasts are wrapped in rescue blocks
# that log errors but allow normal operation to continue.
#
# Usage:
#   class MyModel < ApplicationRecord
#     include SafeBroadcast
#
#     def some_method
#       safe_broadcast_append_to("my_channel", target: "list", partial: "item")
#     end
#   end
module SafeBroadcast
  extend ActiveSupport::Concern

  private

  # Safely broadcasts an append action
  # Wraps broadcast_append_to with error handling
  #
  # @param stream_name [String] The broadcast stream name
  # @param options [Hash] Options passed to broadcast_append_to (target, partial, locals, etc.)
  # @return [Boolean] true if broadcast succeeded, false otherwise
  def safe_broadcast_append_to(stream_name, **options)
    broadcast_append_to(stream_name, **options)
    true
  rescue => e
    log_broadcast_error("append", stream_name, e)
    false
  end

  # Safely broadcasts a replace action
  # Wraps broadcast_replace_to with error handling
  #
  # @param stream_name [String] The broadcast stream name
  # @param options [Hash] Options passed to broadcast_replace_to (target, partial, locals, etc.)
  # @return [Boolean] true if broadcast succeeded, false otherwise
  def safe_broadcast_replace_to(stream_name, **options)
    broadcast_replace_to(stream_name, **options)
    true
  rescue => e
    log_broadcast_error("replace", stream_name, e)
    false
  end

  # Safely broadcasts a remove action
  # Wraps broadcast_remove_to with error handling
  #
  # @param stream_name [String] The broadcast stream name
  # @param options [Hash] Options passed to broadcast_remove_to (target, etc.)
  # @return [Boolean] true if broadcast succeeded, false otherwise
  def safe_broadcast_remove_to(stream_name, **options)
    broadcast_remove_to(stream_name, **options)
    true
  rescue => e
    log_broadcast_error("remove", stream_name, e)
    false
  end

  # Safely broadcasts an update action
  # Wraps broadcast_update_to with error handling
  #
  # @param stream_name [String] The broadcast stream name
  # @param options [Hash] Options passed to broadcast_update_to (target, partial, locals, etc.)
  # @return [Boolean] true if broadcast succeeded, false otherwise
  def safe_broadcast_update_to(stream_name, **options)
    broadcast_update_to(stream_name, **options)
    true
  rescue => e
    log_broadcast_error("update", stream_name, e)
    false
  end

  # Logs broadcast errors for debugging without disrupting operation
  #
  # @param action [String] The broadcast action that failed (append, replace, remove, etc.)
  # @param stream_name [String] The broadcast stream name
  # @param error [Exception] The exception that occurred
  def log_broadcast_error(action, stream_name, error)
    Rails.logger.warn(
      "ActionCable broadcast failed - Operation continues normally. " \
      "Action: #{action}, Stream: #{stream_name}, " \
      "Error: #{error.class} - #{error.message}"
    )

    # Log backtrace in development/test for debugging
    if Rails.env.development? || Rails.env.test?
      Rails.logger.debug("Broadcast error backtrace:\n#{error.backtrace.join("\n")}")
    end
  end
end
