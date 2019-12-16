require 'twitter'

class TwitterClient
  def initialize
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = ENV["TWITTER_CONSUMER_KEY"]
      config.consumer_secret     = ENV["TWITTER_CONSUMER_SECRET"]
      config.access_token        = ENV["TWITTER_ACCESS_TOKEN"]
      config.access_token_secret = ENV["TWITTER_ACCESS_TOKEN_SECRET"]
    end
  end

  def home_timeline(unix_timestamp = nil)
    # within 5 minutes
    unix_timestamp ||= Time.now.to_i - 300
    @client.home_timeline(count: 30).reverse.select {|tweet| tweet.created_at.to_i > unix_timestamp + 61}
  end

  def tweet(text)
    @client.update(text)
  end

  def favorite(id)
    @client.favorite(id)
  end

  def retweet(id)
    @client.retweet(id)
  end
end
