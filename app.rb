require 'sinatra'
require './slack_client'
require './twitter_client'


# router
post '/event' do
  params = JSON.parse(request.body.read)
  return  {challenge: params["challenge"]}.to_json if params["type"] == 'url_verification'
  return if params["token"] != ENV["SLACK_VERIFICATION_TOKEN"]

  if params["event"]["type"] == "app_home_opened" && params["event"]["tab"] == "messages"
    handle_messages_opened(params)
  elsif params["event"]["type"] == "app_home_opened" && params["event"]["tab"] == "home"
    handle_tab_opened(params)
  elsif params["event"]["type"] == "message" && params["event"]["subtype"] != "bot_message"
    handle_message(params)
  end
  status :ok
end

post '/interaction' do
  params = JSON.parse(request.params["payload"])
  return if params["token"] != ENV["SLACK_VERIFICATION_TOKEN"]

  if params["actions"][0]["action_id"] == "favo"
    handle_favo_button(params)
  elsif params["actions"][0]["action_id"] == "retweet"
    handle_retweet_button(params)
  end
end

# handle events
def handle_messages_opened(params)
  twitter_client = TwitterClient.new
  slack_client = SlackClient.new
  channel = params["event"]["channel"]

  latest_timestamp = slack_client.latest_timestamp(channel)
  tweets = twitter_client.home_timeline(latest_timestamp)

  tweets.each do |tweet|
    block = [
      {
        type: "section",
        text: {
          type: "mrkdwn",
          text: tweet.full_text
        }
      },
      {
        type: "context",
        elements: [
          {
            type: "mrkdwn",
            text: Time.at(tweet.created_at).getlocal.strftime("%-H時%-M分・%Y年%-m月%-d日")
          }
        ]
      },
      {
        type: "actions",
        elements: [
          {
            type: "button",
            text: {
              type: "plain_text",
              emoji: true,
              text: "♡ #{tweet.favorite_count}"
            },
            value: tweet.id.to_s,
            action_id: "favo"
          },
          {
            type: "button",
            text: {
              type: "plain_text",
              emoji: true,
              text: "RT #{tweet.retweet_count}"
            },
            value: tweet.id.to_s,
            action_id: "retweet"
          }
        ]
      }
    ]

    slack_client.post_message(
      channel,
      block,
      "#{tweet.user.name} tweet",
      "#{tweet.user.name} / @#{tweet.user.screen_name}",
      tweet.user.profile_image_uri.to_s
    )
  end
end

def handle_tab_opened(params)
  block = [
    {
      "type": "section",
      "text": {
                "type": "mrkdwn",
                "text": "HOME"
              }
    },
    {
      "type": "divider"
    }
  ]
end

def handle_message(params)
  TwitterClient.new.tweet(params["event"]["text"])
end

def handle_favo_button(params)
  tc = TwitterClient.new
  tc.favorite(params["actions"][0]["value"])
end

def handle_retweet_button(params)
  tc = TwitterClient.new
  tc.retweet(params["actions"][0]["value"])
end
