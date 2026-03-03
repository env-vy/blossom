# =========================
# LEVELING COMMANDS
# =========================

bot.command(:level, description: 'Show a user\'s level and XP for this server', category: 'Fun') do |event|
  unless event.server
    event.respond("#{EMOJIS['x_']} This command can only be used in a server!")
    next
  end

  target_user = event.message.mentions.first || event.user
  sid  = event.server.id
  uid  = target_user.id
  user = DB.get_user_xp(sid, uid)
  needed = user['level'] * 100

  dev_badge = (uid == DEV_ID) ? "#{EMOJIS['developer']} **Verified Bot Developer**" : ""

  send_embed(
    event,
    title: "#{EMOJIS['crown']} #{target_user.display_name}'s Server Level",
    description: dev_badge, 
    fields: [
      { name: 'Level', value: user['level'].to_s, inline: true },
      { name: 'XP', value: "#{user['xp']}/#{needed}", inline: true },
      { name: 'Coins', value: "#{DB.get_coins(uid)} #{EMOJIS['s_coin']}", inline: true }
    ]
  )
  nil
end

bot.command(:leaderboard, description: 'Show top users by level for this server', category: 'Fun') do |event|
  unless event.server
    event.respond("#{EMOJIS['x_']} This command can only be used in a server!")
    next
  end

  sid = event.server.id
  raw_top = DB.get_top_users(sid, 50) 
  
  active_humans = []
  raw_top.each do |row|
    user_obj = event.bot.user(row['user_id'])
    if user_obj && !user_obj.bot_account? && event.server.member(user_obj.id)
      active_humans << row
      break if active_humans.size >= 10
    end
  end

  if active_humans.empty?
    send_embed(event, title: "#{EMOJIS['crown']} Level Leaderboard", description: 'No humans have gained XP yet!')
  else
    desc = active_humans.each_with_index.map do |row, index|
      user_obj = event.bot.user(row['user_id'])
      name = user_obj.display_name
      "##{index + 1} — **#{name}**: Level #{row['level']} | #{row['xp']} XP"
    end.join("\n")

    send_embed(event, title: "#{EMOJIS['crown']} Level Leaderboard", description: desc)
  end
  nil
end

bot.command(:levelup, description: 'Configure where level-up messages go (Admin Only)', category: 'Admin') do |event, arg|
  unless event.user.id == DEV_ID || event.user.permission?(:administrator, event.channel)
    send_embed(event, title: "❌ Access Denied", description: "You need administrator permissions to configure this.")
    next
  end

  if arg.nil? || arg.downcase == 'on'
    DB.set_levelup_config(event.server.id, nil, true)
    send_embed(event, title: "✅ Level-Ups Enabled", description: "Level-up messages will now be sent as a direct reply to the user.")
  elsif arg.downcase == 'off'
    DB.set_levelup_config(event.server.id, nil, false)
    send_embed(event, title: "🔇 Level-Ups Disabled", description: "Level-up messages have been completely turned off for this server.")
  elsif arg =~ /<#(\d+)>/
    channel_id = $1.to_i
    channel = event.bot.channel(channel_id, event.server)
    
    if channel
      DB.set_levelup_config(event.server.id, channel_id, true)
      send_embed(event, title: "📣 Level-Up Channel Set", description: "Level-up messages will now be automatically sent to #{channel.mention}!")
    else
      send_embed(event, title: "⚠️ Error", description: "I couldn't find that channel in this server.")
    end
  else
    send_embed(event, title: "⚠️ Invalid Usage", description: "Usage:\n`#{PREFIX}levelup #channel` - Send to a specific channel\n`#{PREFIX}levelup off` - Turn off completely\n`#{PREFIX}levelup on` - Default replies")
  end
  nil
end