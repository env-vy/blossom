# =========================
# ECONOMY EVENTS & LISTENERS
# =========================

bot.button(custom_id: /^collab_/) do |event|
  collab_id = event.custom_id

  if ACTIVE_COLLABS.key?(collab_id)
    author_id = ACTIVE_COLLABS[collab_id]

    if event.user.id == author_id
      event.respond(content: "You can't accept your own collab request!", ephemeral: true)
      next
    end

    ACTIVE_COLLABS.delete(collab_id)
    
    author_final = award_coins(event.bot, author_id, COLLAB_REWARD)
    user_final = award_coins(event.bot, event.user.id, COLLAB_REWARD)

    author_user = event.bot.user(author_id)
    author_mention = author_user ? author_user.mention : "<@#{author_id}>"

    success_embed = Discordrb::Webhooks::Embed.new(
      title: "#{EMOJIS['neonsparkle']} Collab Stream Started!",
      description: "#{event.user.mention} accepted the collab with #{author_mention}!\n\nBoth streamers got a baseline of **#{COLLAB_REWARD}** #{EMOJIS['s_coin']} for an awesome stream! *(Subscribers received a 10% bonus!)*",
      color: 0x00FF00
    )

    event.update_message(content: nil, embeds: [success_embed], components: Discordrb::Components::View.new)
  else
    event.respond(content: 'This collab request has already expired or been accepted!', ephemeral: true)
  end
end

bot.message do |event|
  next unless event.server
  next if event.author.bot_account?

  sid = event.server.id
  config = server_bomb_configs[sid]
  next unless config && config['enabled']

  uid = event.author.id

  if config['last_user_id'] != uid
    config['message_count'] += 1
    config['last_user_id'] = uid

    DB.save_bomb_config(sid, true, config['channel_id'], config['threshold'], config['message_count'])

    if config['message_count'] >= config['threshold']
      target_channel = bot.channel(config['channel_id'], event.server)
      
      if target_channel
        embed = Discordrb::Webhooks::Embed.new(
          title: "#{EMOJIS['bomb']} INCOMING BOMB!",
          description: "A rogue bomb just dropped into the chat!\nQuick, click the button below to defuse it and steal the coins inside!",
          color: 0xFF0000
        )
        
        view = Discordrb::Components::View.new do |v|
          v.row { |r| r.button(custom_id: "defuse_drop_#{sid}", label: 'Cut the Wire!', style: :danger, emoji: '✂️') }
        end
        
        target_channel.send_message(nil, false, embed, nil, nil, nil, view)
      end

      config['message_count'] = 0
      config['last_user_id'] = nil
      config['threshold'] = rand(BOMB_MIN_MESSAGES..BOMB_MAX_MESSAGES)
      
      DB.save_bomb_config(sid, true, config['channel_id'], config['threshold'], 0)
    end
  end
end

bot.button(custom_id: /^bomb_/) do |event|
  bomb_id = event.custom_id

  if ACTIVE_BOMBS[bomb_id]
    ACTIVE_BOMBS.delete(bomb_id)
    reward = rand(50..150)
    final_reward = award_coins(event.bot, event.user.id, reward)

    defused_embed = Discordrb::Webhooks::Embed.new(
      title: "#{EMOJIS['surprise']} Bomb Defused!",
      description: "The bomb was successfully defused by #{event.user.mention}!\nThey earned **#{final_reward}** #{EMOJIS['s_coin']} for their bravery.",
      color: 0x00FF00 
    )
    event.update_message(content: nil, embeds: [defused_embed], components: Discordrb::Components::View.new)
  else
    event.respond(content: 'This bomb has already exploded or been defused!', ephemeral: true)
  end
end

bot.button(custom_id: /^defuse_drop_(\d+)$/) do |event|
  uid = event.user.id
  reward = rand(100..500)
  final_reward = award_coins(event.bot, uid, reward)

  embed = Discordrb::Webhooks::Embed.new(
    title: "#{EMOJIS['coins']} Bomb Defused!",
    description: "#{event.user.mention} successfully cut the wire!\nThey looted **#{final_reward}** #{EMOJIS['s_coin']} from the casing.",
    color: 0x00FF00
  )
  event.update_message(content: nil, embeds: [embed], components: [])
end