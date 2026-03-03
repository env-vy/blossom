# =========================
# GACHA & SHOP EVENTS
# =========================

bot.button(custom_id: /^shop_catalog_(\d+)_(\d+)$/) do |event|
  match_data = event.custom_id.match(/^shop_catalog_(\d+)_(\d+)$/)
  uid  = match_data[1].to_i
  page = match_data[2].to_i
  
  if event.user.id != uid
    event.respond(content: "You cannot use someone else's shop menu! Type `!shop` to open your own.", ephemeral: true)
    next
  end

  new_embed, new_view = build_shop_catalog(uid, page)
  event.update_message(content: nil, embeds: [new_embed], components: new_view)
end

bot.button(custom_id: /^shop_home_(\d+)$/) do |event|
  uid = event.custom_id.match(/^shop_home_(\d+)$/)[1].to_i
  
  if event.user.id != uid
    event.respond(content: "You cannot use someone else's shop menu!", ephemeral: true)
    next
  end

  new_embed, new_view = build_shop_home(uid)
  event.update_message(content: nil, embeds: [new_embed], components: new_view)
end

bot.button(custom_id: /^shop_sell_(\d+)$/) do |event|
  uid = event.custom_id.match(/^shop_sell_(\d+)$/)[1].to_i
  
  if event.user.id != uid
    event.respond(content: "You cannot sell someone else's characters!", ephemeral: true)
    next
  end

  user_collection = DB.get_collection(uid)
  total_earned = 0
  dupes_sold = 0

  user_collection.each do |name, data|
    if data['count'] > 1
      sell_amount = data['count'] - 1
      rarity = data['rarity']
      coins_earned = sell_amount * SELL_PRICES[rarity]
      
      total_earned += coins_earned
      dupes_sold += sell_amount
      
      DB.remove_character(uid, name, sell_amount)
    end
  end

  embed = Discordrb::Webhooks::Embed.new
  view = Discordrb::Components::View.new do |v|
    v.row { |r| r.button(custom_id: "shop_home_#{uid}", label: 'Back to Shop', style: :secondary, emoji: '🔙') }
  end

  if dupes_sold > 0
    DB.add_coins(uid, total_earned)
    embed.title = "#{EMOJIS['rich']} Duplicates Sold!"
    embed.description = "You converted **#{dupes_sold}** duplicate characters into **#{total_earned}** #{EMOJIS['s_coin']}!\n\nNew Balance: **#{DB.get_coins(uid)}** #{EMOJIS['s_coin']}."
    embed.color = 0x00FF00
  else
    embed.title = "#{EMOJIS['confused']} No Duplicates"
    embed.description = "You don't have any duplicate characters to sell right now! You currently have 1 or 0 copies of everyone."
    embed.color = 0xFF0000 
  end

  event.update_message(content: nil, embeds: [embed], components: view)
end

bot.button(custom_id: /^shop_blackmarket_(\d+)$/) do |event|
  begin
    uid = event.custom_id.match(/^shop_blackmarket_(\d+)$/)[1].to_i
    
    if event.user.id != uid
      event.respond(content: "You cannot use someone else's shop menu!", ephemeral: true)
      next
    end

    new_embed, new_view = build_blackmarket_page(uid)
    event.update_message(content: nil, embeds: [new_embed], components: new_view)
  rescue => e
    puts "!!! [ERROR] in Black Market Button !!!"
    puts e.message
  end
end

# =========================
# COLLECTION PAGINATION LISTENER
# =========================

bot.button(custom_id: /^col_/) do |event|
  _, uid_str, page_str = event.custom_id.split('_')
  uid = uid_str.to_i
  target_page = page_str.to_i
  
  title = event.message.embeds.first.title
  
  pages = get_collection_pages(uid)
  
  target_page = 0 if target_page < 0
  target_page = pages.size - 1 if target_page >= pages.size

  rarity_names = ["Commons", "Rares", "Legendaries", "Goddess"]

  embed = Discordrb::Webhooks::Embed.new(
    title: title,
    description: pages[target_page],
    color: NEON_COLORS.sample,
    footer: Discordrb::Webhooks::EmbedFooter.new(text: "#{rarity_names[target_page]} | Page #{target_page + 1} of #{pages.size}")
  )

  view = Discordrb::Components::View.new
  view.row do |r|
    r.button(custom_id: "col_#{uid}_#{target_page - 1}", label: "◀ Prev", style: :secondary, disabled: target_page <= 0)
    r.button(custom_id: "col_#{uid}_#{target_page + 1}", label: "Next ▶", style: :secondary, disabled: target_page >= (pages.size - 1))
  end

  event.update_message(content: nil, embeds: [embed], components: view)
end