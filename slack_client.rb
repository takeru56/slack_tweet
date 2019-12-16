require 'slack-ruby-client'

class SlackClient
  def initialize
    @access_token = ENV["SLACK_ACCESS_TOKEN"]
    @client = Slack::Web::Client.new(token: @access_token)
  end

  # send blocks to channel by the user[name, icon_url]
  def post_message(channel, blocks, text, name, icon_url)
    return unless channel && blocks && text && name && icon_url
    @client.chat_postMessage(
      channel: channel,
      blocks: blocks,
      text: text,
      username: name,
      icon_url: icon_url
    )
  end

  def latest_timestamp(channel)
    timestamp = @client.conversations_history(channel: channel, limit: 1)&.messages&.first&.blocks&.second&.elements&.first&.text
    Time.strptime(timestamp, "%H時%M分・%Y年%m月%d日").to_i if timestamp
  end
end
