# Uses Guard to listen for changes on the host filesystem, which it queues
# for review and transfer to the guest.
#
# @author Andrew Coulton < andrew@ingenerator.com >

require 'listen'

module Vagrant
  module Mirror
    module Listener
      class Host

        def initialize(path, queue)
          @path = path
          @queue = queue
        end

        # Makes a blocking call to Guard to listen on the configured path
        def listen!
          Listen.to(@path, :relative_paths => true) do | modified, added, removed |
            @queue << {
              :source   => :host,
              :added    => added,
              :modified => modified,
              :removed  => removed
            }
          end
        end

        # Runs listen! in a separate thread and returns the thread handle
        #
        # @return [Thread] The listener thread
        def listen
          Thread.new do
            listen!
          end
        end

      end
    end
  end
end