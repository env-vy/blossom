# =========================
# BASIC EVENTS & LISTENERS
# =========================

bot.button(custom_id: /^helpnav_(\d+)_(\d+)$/) do |event|
  match_data = event.custom_id.match(/^helpnav_(\d+)_(\d+)$/)
  target_uid  = match_data[1].to_i
  target_page = match_data[2].to_i
  
  if event.user.id != target_uid
    event.respond(content: "You can only flip the pages of your own help menu! Use `!help` to open yours.", ephemeral: true)
    next
  end

  new_embed, total_pages, current_page = generate_help_page(event.bot, event.user, target_page)
  new_view = help_view(target_uid, current_page, total_pages)
  
  event.update_message(content: nil, embeds: [new_embed], components: new_view)
end

bot.button(custom_id: /^gw_/) do |event|
  gw_id = event.custom_id
  
  active = DB.get_active_giveaways.any? { |gw| gw['id'] == gw_id }
  unless active
    event.respond(content: "This giveaway has already ended!", ephemeral: true)
    next
  end

  success = DB.add_giveaway_entrant(gw_id, event.user.id)
  
  if success
    event.respond(content: "You successfully entered the giveaway! 🎉", ephemeral: true)
  else
    event.respond(content: "You have already entered this giveaway! Good luck! 🍀", ephemeral: true)
  end
end