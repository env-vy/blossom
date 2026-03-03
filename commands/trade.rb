# =========================
# PLAYER TRADING COMMAND
# =========================

bot.command(:trade, description: 'Trade a character with someone (Usage: !trade @user <My Char> for <Their Char>)', category: 'Gacha') do |event, *args|
  target_user = event.message.mentions.first
  
  if target_user.nil? || target_user.id == event.user.id
    send_embed(
      event, 
      title: "#{EMOJIS['confused']} Invalid Trade", 
      description: "You must ping the person you want to trade with!\n**Usage:** `#{PREFIX}trade @user <Your Character> for <Their Character>`"
    )
    next
  end

  full_text = args.join(' ')
  clean_text = full_text.gsub(/<@!?#{target_user.id}>/, '').strip
  parts = clean_text.split(/ for /i)
  
  if parts.size != 2
    send_embed(
      event, 
      title: "#{EMOJIS['error']} Trade Formatting", 
      description: "Please format it exactly like this:\n`#{PREFIX}trade @user Gawr Gura for Filian`"
    )
    next
  end

  my_char_search = parts[0].strip.downcase
  their_char_search = parts[1].strip.downcase

  uid_a = event.user.id
  uid_b = target_user.id

  coll_a = DB.get_collection(uid_a)
  coll_b = DB.get_collection(uid_b)

  my_char_real = coll_a.keys.find { |k| k.downcase == my_char_search }
  their_char_real = coll_b.keys.find { |k| k.downcase == their_char_search }

  if my_char_real.nil? || coll_a[my_char_real]['count'] < 1
    send_embed(event, title: "#{EMOJIS['x_']} Missing Character", description: "You don't own **#{parts[0].strip}** to trade!")
    next
  end

  if their_char_real.nil? || coll_b[their_char_real]['count'] < 1
    send_embed(event, title: "#{EMOJIS['x_']} Missing Character", description: "#{target_user.mention} doesn't own **#{parts[1].strip}**!")
    next
  end

  expire_time = Time.now + 120
  trade_id = "trade_#{expire_time.to_i}_#{rand(1000)}"

  ACTIVE_TRADES[trade_id] = {
    user_a: uid_a,
    user_b: uid_b,
    char_a: my_char_real,
    char_b: their_char_real,
    expires: expire_time
  }

  embed = Discordrb::Webhooks::Embed.new(
    title: '🤝 Trade Offer!',
    description: "#{target_user.mention}, #{event.user.mention} wants to trade with you!\n\nThey are offering **#{my_char_real}** in exchange for your **#{their_char_real}**.\n\nDo you accept? (Offer expires <t:#{expire_time.to_i}:R>)",
    color: NEON_COLORS.sample
  )

  view = Discordrb::Components::View.new do |v|
    v.row do |r|
      r.button(custom_id: "#{trade_id}_accept", label: 'Accept', style: :success, emoji: '✅')
      r.button(custom_id: "#{trade_id}_decline", label: 'Decline', style: :danger, emoji: '❌')
    end
  end

  msg = event.channel.send_message(nil, false, embed, nil, nil, event.message, view)

  Thread.new do
    sleep 120
    if ACTIVE_TRADES.key?(trade_id)
      ACTIVE_TRADES.delete(trade_id)
      failed_embed = Discordrb::Webhooks::Embed.new(title: '⏳ Trade Expired', description: 'The trade offer timed out.', color: 0x808080)
      msg.edit(nil, failed_embed, Discordrb::Components::View.new)
    end
  end

  nil
end