require 'drb/drb'

module RSpec
  module Core
    # @private
    module Bisect
      # @private
      BisectFailedError = Class.new(StandardError)

      # @private
      # A DRb server that receives run results from a separate RSpec process
      # started by the bisect process.
      class Server
        def self.run
          server = new
          server.start
          yield server
        ensure
          server.stop
        end

        def capture_run_results(expected_failures=[])
          self.expected_failures  = expected_failures
          self.latest_run_results = nil
          run_output = yield
          latest_run_results || raise_bisect_failed(run_output)
        end

        def start
          # We pass `nil` as the first arg to allow it to pick a DRb port.
          @drb = DRb.start_service(nil, self)
        end

        def stop
          @drb.stop_service
        end

        def drb_port
          @drb_port ||= Integer(@drb.uri[/\d+$/])
        end

        # Fetched via DRb by the BisectFormatter to determine when to abort.
        attr_accessor :expected_failures

        # Set via DRb by the BisectFormatter with the results of the run.
        attr_accessor :latest_run_results

      private

        def raise_bisect_failed(run_output)
          raise BisectFailedError, "Failed to get results from the spec " \
                "run. Spec run output:\n\n#{run_output}"
        end
      end
    end
  end
end
