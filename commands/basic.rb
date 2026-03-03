# =========================
# BASIC COMMANDS
# =========================

bot.command(:ping, description: 'Check bot latency', category: 'Utility') do |event|
  time_diff = Time.now - event.message.timestamp
  latency_ms = (time_diff * 1000).round 
  
  send_embed(
    event,
    title: "#{EMOJIS['play']} Pong!",
    description: "My connection to Discord is **#{latency_ms}ms**.\nChat is moving fast!"
  )
  nil
end

bot.command(:kettle, description: 'Pings a specific user with a yay emoji', category: 'Fun') do |event|
  event.respond("#{EMOJIS['sparkle']} <@266358927401287680> #{EMOJIS['sparkle']}")
  nil
end

bot.command(:help, description: 'Shows a paginated list of all available commands', category: 'Utility') do |event|
  target_user = event.user
  embed, total_pages, current_page = generate_help_page(event.bot, target_user, 1)
  view = help_view(target_user.id, current_page, total_pages)
  
  event.channel.send_message(nil, false, embed, nil, { replied_user: false }, event.message, view)
  nil
end

bot.command(:about, description: 'Learn more about Blossom and her creator!', category: 'Utility') do |event|
  fields = [
    {
      name: "#{EMOJIS['play']} The Content Grind",
      value: "We are on that monetization grind! I manage the server's economy so you can earn #{EMOJIS['s_coin']} by hitting that `b!stream` button, getting engagement with a quick `b!post` on socials, or doing a `b!collab` with other chatters.",
      inline: false
    },
    {
      name: "#{EMOJIS['sparkle']} VTuber Gacha",
      value: "Spend your hard-earned stream revenue to `b!summon` your favorite VTubers! Will you pull common indie darlings, or hit the legendary RNG for Gura, Calli, or Ironmouse? Build your `b!collection` and flex your pulls!",
      inline: false
    },
    {
      name: "#{EMOJIS['like']} Just Chatting & Vibes",
      value: "Lurkers don't get XP here! I track your chat activity and reward you with levels the more you type. Plus, you can `b!hug` your friends or `b!slap` a troll.",
      inline: false
    },
    {
      name: "#{EMOJIS['bomb']} A Little Bit of Trolling",
      value: "Sometimes chat gets too cozy, so the admins let me drop a literal `b!bomb` in the channel. You have to scramble to defuse it for a massive coin payout, or the whole chat goes BOOM!",
      inline: false
    },
    {
      name: "#{EMOJIS['developer']} Behind the Scenes",
      value: "Blossom is a Kyvrixon Dev. product. Developed by **Envvy.VT** and written in **.rb** (Ruby).",
      inline: false
    }
  ]

  send_embed(
    event,
    title: "#{EMOJIS['heart']} About Blossom",
    description: "Hey Chat! I'm **Blossom**, your server's dedicated head mod, hype-woman, and resident gacha addict. I'm here to turn your Discord server into the ultimate content creator community.\n\nDrop a `b!help` in chat and let's go live! #{EMOJIS['stream']}#{EMOJIS['neonsparkle']}",
    fields: fields
  )
  nil
end

bot.command(:hug, description: 'Send a hug with a random GIF', category: 'Fun') do |event|
  target = event.message.mentions.first
  
  if target && target.id == event.bot.profile.id
    DB.add_interaction(event.user.id, 'hug', 'sent')
    DB.add_interaction(target.id, 'hug', 'received')
    DB.add_interaction(target.id, 'hug', 'sent')
    DB.add_interaction(event.user.id, 'hug', 'received')

    actor_stats = DB.get_interactions(event.user.id)['hug']
    bot_stats   = DB.get_interactions(target.id)['hug']

    fields = [
      { name: "#{event.user.name}'s Hugs", value: "Sent: **#{actor_stats['sent']}**\nReceived: **#{actor_stats['received']}**", inline: true },
      { name: "Blossom's Hugs", value: "Sent: **#{bot_stats['sent']}**\nReceived: **#{bot_stats['received']}**", inline: true }
    ]

    send_embed(
      event,
      title: "🫂 Hugs for Blossom!",
      description: "Aww, thanks for the love, #{event.user.mention}! Chat's been crazy today, I needed that.\n\n*Blossom hugs you back tightly!*",
      fields: fields,
      image: HUG_GIFS.sample
    )
  else
    interaction_embed(event, 'hug', HUG_GIFS)
  end
  nil
end

bot.command(:slap, description: 'Send a playful slap with a random GIF', category: 'Fun') do |event|
  target = event.message.mentions.first
  
  if target && target.id == event.bot.profile.id
    DB.add_interaction(event.user.id, 'slap', 'sent')
    DB.add_interaction(target.id, 'slap', 'received')
    DB.add_interaction(target.id, 'slap', 'sent')
    DB.add_interaction(event.user.id, 'slap', 'received')

    actor_stats = DB.get_interactions(event.user.id)['slap']
    bot_stats   = DB.get_interactions(target.id)['slap']

    fields = [
      { name: "#{event.user.name}'s Slaps", value: "Sent: **#{actor_stats['sent']}**\nReceived: **#{actor_stats['received']}**", inline: true },
      { name: "Blossom's Slaps", value: "Sent: **#{bot_stats['sent']}**\nReceived: **#{bot_stats['received']}**", inline: true }
    ]

    send_embed(
      event,
      title: "💢 Bot Abuse Detected!",
      description: "Hey! #{event.user.mention} just slapped me?! Chat, clip that! That is literal bot abuse.\n\n*Blossom smacks you right back!*",
      fields: fields,
      image: SLAP_GIFS.sample
    )
  else
    interaction_embed(event, 'slap', SLAP_GIFS)
  end
  nil
end

bot.command(:interactions, description: 'Show your hug/slap stats', category: 'Fun') do |event|
  data = DB.get_interactions(event.user.id)

  hug  = data['hug']
  slap = data['slap']

  send_embed(
    event,
    title: "#{event.user.display_name}'s Interaction Stats",
    description: '',
    fields: [
      {
        name: "#{EMOJIS['hearts']} Hugs",
        value: "Sent: **#{hug['sent']}**\nReceived: **#{hug['received']}**",
        inline: true
      },
      {
        name: "#{EMOJIS['bonk']} Slaps",
        value: "Sent: **#{slap['sent']}**\nReceived: **#{slap['received']}**",
        inline: true
      }
    ]
  )
  nil
end

bot.command(:support, description: 'Get a link to the official support server', category: 'Utility') do |event|
  send_embed(
    event,
    title: "🛠️ Support Server",
    description: "Need assistance, have questions, or want to report a bug?\nJoin the official Blossom Support Server here:\n\n**https://discord.gg/nGGcNS6gNW**"
  )
  nil
end

bot.command(:premium, description: 'View the benefits of Blossom Premium!', category: 'Utility') do |event|
  desc = "Support Blossom's development and unlock amazing global perks!\n\n"
  desc += "**💎 Premium Bonuses:**\n"
  desc += "⏱️ **50% Faster Cooldowns** on `!work`, `!stream`, and `!post`\n"
  desc += "💰 **+10% Coin Boost** from all sources (daily, work, streams, bombs, collabs!)\n"
  desc += "🍀 **Boosted Gacha Odds** (Much higher chance to pull Rares, Legendaries, and Goddesses)\n"
  desc += "✨ **1% Secret Chance** to instantly pull a Shiny Ascended character from the portal!\n\n"
  desc += "To unlock these perks, join the Support Server and subscribe via the Server Shop:\n**https://discord.gg/nGGcNS6gNW**"

  send_embed(
    event,
    title: "💎 Blossom Premium",
    description: desc
  )
  nil
end

# =========================
# GIVEAWAY COMMAND
# =========================

bot.command(:giveaway, description: 'Start a giveaway (Admin only)', min_args: 3, usage: 'b!giveaway #channel 10m Prize Name', category: 'Admin') do |event, channel_mention, time_str, *prize_args|
  unless event.user.permission?(:administrator, event.channel) || event.user.id == DEV_ID
    send_embed(event, title: "❌ Permission Denied", description: 'You need Administrator permissions to start a giveaway!')
    next
  end

  channel_id = channel_mention.gsub(/[^0-9]/, '').to_i
  target_channel = event.bot.channel(channel_id, event.server)
  unless target_channel
    send_embed(event, title: "⚠️ Error", description: "I couldn't find that channel!")
    next
  end

  duration = 0
  if time_str =~ /^(\d+)(m|h|d)$/i
    amount = $1.to_i
    unit = $2.downcase
    duration = amount * 60 if unit == 'm'
    duration = amount * 3600 if unit == 'h'
    duration = amount * 86400 if unit == 'd'
  else
    send_embed(event, title: "⚠️ Invalid Time Format", description: "Example: `10m` or `2d`")
    next
  end

  prize = prize_args.join(' ')
  expire_time = Time.now + duration
  giveaway_id = "gw_#{expire_time.to_i}_#{rand(10000)}"
  discord_timestamp = "<t:#{expire_time.to_i}:R>"

  embed = Discordrb::Webhooks::Embed.new(
    title: "🎉 **GIVEAWAY: #{prize}** 🎉",
    description: "Hosted by: #{event.user.mention}\nEnds: **#{discord_timestamp}**\n\nClick the button below to enter!",
    color: 0xFFD700 
  )

  view = Discordrb::Components::View.new do |v|
    v.row { |r| r.button(custom_id: giveaway_id, label: 'Enter Giveaway', style: :success, emoji: '🎉') }
  end

  msg = target_channel.send_message(nil, false, embed, nil, nil, nil, view)
  
  DB.create_giveaway(giveaway_id, target_channel.id, msg.id, event.user.id, prize, expire_time.to_i)
  
  event.respond("✅ Giveaway successfully saved to the database and started in #{target_channel.mention}!")
  nil
end