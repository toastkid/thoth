#--
# Copyright (c) 2008 Ryan Grove <ryan@wonko.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   * Neither the name of this project nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#++

require 'json'
require 'open-uri'
require 'timeout'

module Thoth; module Plugin

  # Twitter plugin for Thoth.
  module Twitter

    Configuration.for("thoth_#{Thoth.trait[:mode]}") do
      twitter {

        # Time in seconds to cache results. It's a good idea to keep this nice
        # and high both to improve the performance of your site and to avoid
        # pounding on Twitter's servers. Default is 900 seconds (15 minutes).
        cache_ttl 900 unless Send('respond_to?', :cache_ttl)

        # Request timeout in seconds.
        request_timeout 3 unless Send('respond_to?', :request_timeout)

        # If Twitter fails to respond at least this many times in a row, no new
        # requests will be sent until the failure_timeout expires in order to
        # avoid hindering your blog's performance.
        failure_threshold 3 unless Send('respond_to?', :failure_threshold)

        # After the failure_threshold is reached, the plugin will wait this many
        # seconds before trying again. Default is 600 seconds (10 minutes).
        failure_timeout 600 unless Send('respond_to?', :failure_timeout)

      }
    end

    class << self
      def recent_tweets(user, options = {})
        if @skip_until
          return [] if @skip_until > Time.now
          @skip_until = nil
        end

        cache   = Ramaze::Cache.value_cache
        options = {:count => 5}.merge(options)

        url = "http://twitter.com/statuses/user_timeline/#{user}.json?count=" <<
            options[:count].to_s

        if value = cache[url]
          return value
        end

        tweets = []

        Timeout.timeout(Config.twitter.request_timeout, StandardError) do
          tweets = JSON.parse(open(url).read)
        end

        @failures = 0

        return cache.store(url, tweets, :ttl => Config.twitter.cache_ttl)

      rescue => e
        @failures ||= 0
        @failures += 1

        if @failures >= Config.twitter.failure_threshold
          @skip_until = Time.now + Config.twitter.failure_timeout
          Ramaze::Log.error("Twitter failed to respond #{@failures} times. " <<
              "Will retry after #{@skip_until}.")
        end

        return []
      end
    end

  end
end; end
