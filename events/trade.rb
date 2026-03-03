# =========================
# PLAYER TRADING EVENTS
# =========================

bot.button(custom_id: /^trade_\d+_\d+_(accept|decline)$/) do |event|
  match_data = event.custom_id.match(/^(trade_\d+_\d+)_(accept|decline)$/)
  trade_id = match_data[1]
  action   = match_data[2]

  unless ACTIVE_TRADES.key?(trade_id)
    event.respond(content: 'This trade has expired or already been processed!', ephemeral: true)
    next
  end

  trade_data = ACTIVE_TRADES[trade_id]

  if event.user.id != trade_data[:user_b]
    event.respond(content: "Only the person receiving the trade offer can click this!", ephemeral: true)
    next
  end

  ACTIVE_TRADES.delete(trade_id)

  if action == 'decline'
    declined_embed = Discordrb::Webhooks::Embed.new(title: '🚫 Trade Declined', description: "#{event.user.mention} rejected the trade offer.", color: 0xFF0000)
    event.update_message(content: nil, embeds: [declined_embed], components: Discordrb::Components::View.new)
    next
  end

  uid_a = trade_data[:user_a]
  uid_b = trade_data[:user_b]
  char_a = trade_data[:char_a]
  char_b = trade_data[:char_b]

  coll_a = DB.get_collection(uid_a)
  coll_b = DB.get_collection(uid_b)

  if coll_a[char_a].nil? || coll_a[char_a]['count'] < 1 || coll_b[char_b].nil? || coll_b[char_b]['count'] < 1
    error_embed = Discordrb::Webhooks::Embed.new(title: '❌ Trade Failed', description: "Someone no longer has the character they offered! The trade has been cancelled.", color: 0xFF0000)
    event.update_message(content: nil, embeds: [error_embed], components: Discordrb::Components::View.new)
    next
  end

  rarity_a = coll_a[char_a]['rarity']
  rarity_b = coll_b[char_b]['rarity']

  DB.remove_character(uid_a, char_a, 1)
  DB.remove_character(uid_b, char_b, 1)

  DB.add_character(uid_a, char_b, rarity_b, 1)
  DB.add_character(uid_b, char_a, rarity_a, 1)

  success_embed = Discordrb::Webhooks::Embed.new(
    title: '🎉 Trade Successful!',
    description: "The trade was a success!\n\n<@#{uid_a}> received **#{char_b}**.\n<@#{uid_b}> received **#{char_a}**.",
    color: 0x00FF00
  )
  
  event.update_message(content: nil, embeds: [success_embed], components: Discordrb::Components::View.new)
end