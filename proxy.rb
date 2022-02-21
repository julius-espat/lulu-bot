require "discordrb"
require "sequel"
require 'discordrb/webhooks'
require "json"


module Proxy
    extend Discordrb::EventContainer
    extend Discordrb::Commands::CommandContainer
  
    command :proxy_init do |event|
        channel_id = event.message.channel.id
        response = Discordrb::API::Channel.create_webhook("Bot "+TOKEN,channel_id,"Generic","https://media.discordapp.net/attachments/870400086243414057/945034474796744875/Screenshot_from_2022-02-20_20-06-42.png")
        data = JSON.load(response)
        puts response
        id = data["id"]
        token = data["token"]
        puts id,token
        $WEBHOOK.insert(:name => "Generic", :id => id, :token => token)
        event.respond("Webhook Initialized :lulustare:")
    end    

    command :proxy_create do |event,prefix,*text|
        name = text.join(' ')
        image = event.message.attachments[0].url.to_s
        $PROXIES.insert(:name => name, :prefix => prefix, :pfp => image)
        event.respond("Proxy for #{name} has been created!")
    end

    command :proxy_delete do |event,*text|
        name = text.join(' ')
        $PROXIES.filter(:name => name).delete
        event.respond("Proxy for #{name} has been deleted")
    end
    
    command :proxy_prefix do |event,prefix,*text|
        name = text.join(' ')
        $PROXIES.where(:name => name).update(prefix: prefix)
        event.respond("Prefix for #{name} has been changed to #{prefix}")
    end

    message do |event|
        for item in $PROXIES.all{|row|}
            if event.message.content.start_with? item[:prefix]

                id = $DB[:webhook].where(name: "Generic").get(:id)
                token = $DB[:webhook].where(name: "Generic").get(:token)
                
                builder1 = Discordrb::Webhooks::Client.new(id: id,token: token)
                builder1.execute do |builder|
                    builder.content = event.message.content.reverse.chomp(item[:prefix].reverse).reverse
                    builder.username = item[:name]
                    builder.avatar_url = item[:pfp]
                
                end
                event.message.delete 
            end
        end
    end
end
