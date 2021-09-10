import Sword
import Foundation

guard let token = ProcessInfo.processInfo.environment["DISCORD_BOT_TOKEN"] else {
    preconditionFailure("No token detected in environment at value DISCORD_BOT_TOKEN")
}

print("Starting with token \(token)")

let mainChannel: Snowflake?
if let mainChannelStr = (ProcessInfo.processInfo.environment["DISCORD_BOT_MAIN_CHANNEL"]) {
    mainChannel = Snowflake(mainChannelStr)
} else {
    mainChannel = nil
}

let bot = Sword(token: token)

bot.editStatus(to: "online", playing: "With Sword !")

let actions: [String: (Message, [Substring]) -> Void] = [
    "!ping": { message, _ in
        message.reply(with: "PONG BITCH")
    },
    "!out": { message, _ in
        message.reply(with: "yes... yes... okay... bye")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            bot.disconnect()
            exit(0)
        }
    },
    "!chucknorris": { message, _ in
        let dataTask = URLSession.shared.dataTask(with: URL(string: "https://api.chucknorris.io/jokes/random")!) { (data, response, error) in
            
            guard let data = data, error == nil else {
                return message.reply(with: "I don't know any chuck norris fact sorry :(")
            }
            let jsonResult = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            message.reply(with: jsonResult["value"] as! String)
        }
        dataTask.resume()
    },
    "!whoami": { message, _ in
        if let author = message.author {
            var reply = Embed()
            reply.color = (256*256) * 255 + (256) * 255 + 0
            reply.title = "Discord identity"
            reply.url = "https://discord.js.org/"
            reply.author = .init(
                iconUrl: author.imageUrl()?.description,
                name: "\(author.username ?? "<unknown>")#\(author.discriminator ?? "----")",
                url: nil)
            reply.description = "description"
//            reply.provider = .init(name: "Me", url: author.imageUrl()?.description)
            reply.thumbnail = .init(height: 50,
                                    proxyUrl: "https://youtube.com",
                                    url: "https://youtube.com", width: 60)
            reply.addField("username", value: author.username ?? "❌", isInline: true)
            reply.addField("id", value: "\(author.id)", isInline: true)
            reply.addField("discriminator", value: author.discriminator ?? "❌", isInline: true)
            reply.addField("verified", value: author.isVerified == true ? "✅" : "❌", isInline: true)
            reply.addField("email", value: author.email ?? "❌", isInline: true)
            reply.addField("bot", value: author.isBot == true ? "🤖" : "👤", isInline: true)
            reply.addField("avatar", value: author.avatar ?? "❌", isInline: false)
            reply.addField("imageUrl", value: author.imageUrl()?.description ?? "❌", isInline: false)
            if let imageUrl = author.imageUrl() {
                reply.footer = .init(text: "image",
                                     iconUrl: imageUrl.description,
                                     proxyIconUrl: imageUrl.description)
            } else {
                reply.footer = .init(text: "imageUrl: ❌")
            }
            message.reply(with: reply)
        } else {
            message.reply(with: "No clue lol")
        }
    },
    "!whereami": { message, _ in
        let channel = message.channel
        
        let typeStr: String
        switch channel.type {
            case .guildText: typeStr = "guildText"
            case .dm: typeStr = "dm"
            case .guildVoice: typeStr = "guildVoice"
            case .groupDM: typeStr = "groupDM"
            case .guildCategory: typeStr = "guildCategory"
        }
        message.reply(with: "Channel id: \(channel.id), type: \(typeStr)")
    },
    "!say": { message, args in
        message.reply(with: args.dropFirst().map(String.init).reduce("", { $0 + $1 + " " }))
    }
]

bot.on(.messageCreate) { data in
    if let message = data as? Message {
        let arguments = message.content.split(separator: " ")
        if let first = arguments.first {
            actions[String(first)]?(message, arguments)
        }
    }
}

bot.on(.messageUpdate) { data in
    let message = data as! [String: Any]
    print("update: \(message)")
}

bot.on(.typingStart) { data in
    let (channel, userID, timestamp) = data as! (TextChannel, Snowflake, Date)
    if Int.random(in: 0...5) == 0 {
        bot.send("Next person to talk is gay !", to: channel.id)
    }
    print("channel: \(channel)")
    print("user: \(userID)")
    print("date: \(timestamp)")
}

bot.on(.ready) { _ in
    print("Ready !")
    if let chan = mainChannel {
        bot.send("Connected !", to: chan)
    }
}

bot.connect()
