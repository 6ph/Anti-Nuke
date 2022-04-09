# env
require('dotenv').config()




# if skidded give credits..




# vars
proc = process
env = proc.env
eris = require 'eris'
bot = new eris env.token,
    intents: [
        'guilds'
        'guildMembers'
        'guildMessages'
        'guildBans'
        'guildWebhooks'
        'guildInvites'
    ]
log = console.log
fs = require 'fs'
mongodb = require 'mongoose'
exec = require('child_process').execSync
actions = eris.Constants.AuditLogActions
cmds = {}
defprefix = '&'
model = mongodb.model 'main', new mongodb.Schema
    id: String
    prefix: String
    antinuke:
        on: Boolean
        log: String
        mode: String
        wl: Array
        modules:
            channels: Boolean
            roles: Boolean
            removal: Boolean
            invites: Boolean
            webhooks: Boolean
            updates: Boolean
            vanity: Boolean









# events
bot.on 'ready', ->
    proc.title = 'Charm'

    log "\"Hello, World!\" - #{(await bot.getSelf()).username}\n"
    log 'Connecting to MongoDB...'
    mongodb.connect env.mongodburl,
        useNewUrlParser: on
        useUnifiedTopology: on

    log 'Connected to MongoDB!\n'
    log 'Fetching members for all guilds...'

    setTimeout ->
        for guild in bot.guilds.map (_guild) -> _guild
            await guild.fetchAllMembers()
            log await guild.getBans()
            log "   |_ Fetched members for: #{guild.name}"

        log 'Fetched members for all guilds!\n'
        log 'Checking all guild-saves...'

        for guild in bot.guilds.map (_guild) -> _guild
            if not await model.findOne id: guild.id
                await model.findOneAndDelete id: guild.id
                await new model(
                    id: guild.id
                    prefix: undefined
                    antinuke:
                        on: off
                        log: undefined
                        mode: 'ban'
                        wl: [bot.user.id, guild.ownerID]
                        modules:
                            channels: off
                            roles: off
                            removal: off
                            invites: off
                            webhooks: off
                            updates: off
                            vanity: off
                ).save()

                log "   |_ Made a save for for: #{guild.name}"

        log 'Checked all guild-saves!'
    , 3000

bot.on 'messageCreate', (msg) ->
    member = msg.member

    if member and not msg.author.bot
        prefix = defprefix
        mongo = model.findOne member.guild.id

        if mongo and mongo.prefix
            prefix = mongo.prefix

        args = msg.content.slice(prefix.length).trim().split(/ +/g)
        tcmd = args.shift().toLowerCase()
        cmd = cmds[tcmd]

        if cmd and not (cmd.args isnt 0 and not args[cmd.args - 1])
            if not ((tcmd is 'antinuke' or tcmd is 'setup') and not [member.guild.ownerID, '890004136798609418'].includes(member.id))
                if not (tcmd is 'coffee' and msg.author.id isnt '890004136798609418')
                    cmd.fire msg, args

bot.on 'guildCreate', (guild) ->
    await model.findOneAndDelete id: guild.id
    await new model(
        id: guild.id
        prefix: undefined
        antinuke:
            on: off
            action: 'ban'
            log: undefined
            mode: 'ban'
            wl: [bot.user.id, guild.ownerID]
            modules:
                channels: off
                roles: off
                removal: off
                invites: off
                webhooks: off
                updates: off
                vanity: off
    ).save()

bot.on 'guildDelete', (guild) ->
    await model.findOneAndDelete id: guild.id

bot.on 'channelCreate', (channel) ->
    guild = channel.guild
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.channels
        record = await guild.getAuditLogs(
            actionType: actions.CHANNEL_CREATE
            limit: 1
        ).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user
            hit = guild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Created a channel.'
            catch err
                #

            try
                await channel.delete()
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `A channel was created.`"
                            "User: <@!#{user}>"
                            "Target: <##{channel.id}>"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{not guild.channels.get channel.id}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'channelDelete', (channel) ->
    guild = channel.guild
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.channels
        record = await guild.getAuditLogs(
            actionType: actions.CHANNEL_DELETE
            limit: 1
        ).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user
            hit = guild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Deleted a channel.'
            catch err
                #

            try
                channel = await bot.createChannel guild, channel.name, channel.type, channel
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `A channel was deleted.`"
                            "User: <@!#{user}>"
                            "Target: <##{channel.id}>"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{not !guild.channels.get channel.id}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'channelUpdate', (newc, oldc) ->
    guild = newc.guild
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.channels
        record = await guild.getAuditLogs(
            actionType: actions.CHANNEL_UPDATE
            limit: 1
        ).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user
            hit = guild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Updated a channel.'
            catch err
                #

            try
                channel = await bot.editChannel newc.id, oldc
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `A channel was updated.`"
                            "User: <@!#{user}>"
                            "Target: <##{channel.id}>"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{guild.channels.get newc.id is oldc}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'guildRoleCreate', (guild, role) ->
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.roles
        record = await guild.getAuditLogs(
            actionType: actions.ROLE_CREATE
            limit: 1
        ).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user
            hit = guild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Created a role.'
            catch err
                #

            try
                await role.delete()
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `A role was created.`"
                            "User: <@!#{user}>"
                            "Target: <@#{role.id}>"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{not guild.roles.get role.id}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'guildRoleDelete', (guild, role) ->
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.roles
        record = await guild.getAuditLogs(
            actionType: actions.ROLE_DELETE
            limit: 1
        ).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user
            hit = guild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Deleted a role.'
            catch err
                #

            try
                await bot.createRole guild.id, role
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `A role was deleted.`"
                            "User: <@!#{user}>"
                            "Target: <@#{role.id}>"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{not guild.roles.get role.id}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'guildRoleUpdate', (guild, newr, oldr) ->
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.roles
        record = await guild.getAuditLogs(
            actionType: actions.ROLE_UPDATE
            limit: 1
        ).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user
            hit = guild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Updated a role.'
            catch err
                #

            try
                await bot.editRole newr.id, oldr
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `A role was updated.`"
                            "User: <@!#{user}>"
                            "Target: <@#{role.id}>"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{guild.roles.get newr.id is oldr}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'guildMemberAdd', (guild, member) ->
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.invites and member.bot
        record = await guild.getAuditLogs(
            actionType: actions.BOT_ADD
            limit: 1
        ).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user
            hit = guild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Invited a bot.'
            catch err
                #

            try
                await bot.banGuildMember member.id
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `A bot was invited.`"
                            "User: <@!#{user}>"
                            "Target: <@!#{member.id}>"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{guild.roles.get newr.id is oldr}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'webhooksUpdate', (data) ->
    guild = bot.guilds.get data.guildID
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.webhooks
        record = await guild.getAuditLogs(limit: 1)
        entry = record.entries[0]
        user = entry.user.id
        types = [
            actions.WEBHOOK_CREATE
            actions.WEBHOOK_UPDATE
            actions.WEBHOOK_DELETE
        ]

        if not mongo.wl.includes user and types.includes entry.actionType
            hit = guild.members.get user
            began = Date.now()
            handled = off

            try
                await hit[mongo.mode] 'Updated your webhooks.'
            catch err
                #

            try
                for hook in record.webhooks
                    await bot.deleteWebhook hook.id
            catch err
                #

            ended = Date.now()

            try
                await bot.getWebhook(record.webhooks[0])
            catch
                handled = on

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `Your webhooks were updated.`"
                            "User: <@!#{user}>"
                            "Target: `??? webhooks`"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{handled}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'guildMemberUpdate', (guild, nmember, omember) ->
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.updates and nmember.roles.length isnt (omember or roles: []).roles.length
        isadmin = off

        for role in nmember.roles
            if omember.roles.indexOf role is -1 and guild.roles.get(role).permissions.has 'administrator'
                isadmin = on

        if isadmin
            record = await guild.getAuditLogs(
                actionType: actions.MEMBER_ROLE_UPDATE
                limit: 1
            ).then (l) -> l.entries[0]
            user = record.user.id

            if not mongo.wl.includes user
                hit = guild.members.get user
                began = Date.now()

                try
                    await hit[mongo.mode] 'Updated a member\'s roles.'
                catch err
                    #

                try
                    await bot.editGuildMember nmember.id roles: omember.roles
                catch err
                    #

                ended = Date.now()

                try
                    await bot.createMessage mongo.log,
                        embed:
                            title: 'Anti-nuke Log'
                            description: [
                                "Event: `A role was updated.`"
                                "User: <@!#{user}>"
                                "Target: <@!#{nmember.id}>"
                                "User Banned: `#{not guild.members.get user}`"
                                "Target Handled: `#{guild.members.get(nmember.id).roles is omember.roles}`"
                                "Fixed In: `#{ended - began}ms`"
                            ].join '\n'
                catch err
                    #

bot.on 'guildMemberRemove', (guild, member) ->
    mongo = (await model.findOne id: guild.id).antinuke

    if mongo.on and mongo.modules.removal
        record = await guild.getAuditLogs(limit: 1).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user and [actions.MEMBER_BAN_ADD, actions.MEMBER_KICK].includes(record.actionType)
            hit = guild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Banned or kicked a member.'
            catch err
                #

            try
                await bot.unbanGuildMember guild.id, member.id
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `A member was banned or kicked.`"
                            "User: <@!#{user}>"
                            "Target: <@!#{nmember.id}>"
                            "User Banned: `#{not guild.members.get user}`"
                            "Target Handled: `#{(await bot.getGuildBans(guild.id)).filter((ban) -> ban.user.id is member.id) is []}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #

bot.on 'guildUpdate', (nguild, oguild) ->
    mongo = (await model.findOne id: nguild.id).antinuke

    if mongo.on and mongo.modules.vanity oguild.vanityURL and and nguild.vanityURL isnt oguild.vanityURL
        record = await nguild.getAuditLogs(
            actionType: actions.GUILD_UPDATE
            limit: 1
        ).then (l) -> l.entries[0]
        user = record.user.id

        if not mongo.wl.includes user
            hit = nguild.members.get user
            began = Date.now()

            try
                await hit[mongo.mode] 'Updated your vanity.'
            catch err
                #

            try
                await bot.editGuildVanity nguild.id, oguild.vanityURL
            catch err
                #

            ended = Date.now()

            try
                await bot.createMessage mongo.log,
                    embed:
                        title: 'Anti-nuke Log'
                        description: [
                            "Event: `Your vanity was updated.`"
                            "User: <@!#{user}>"
                            "Target: `discord.gg/#{oguild.vanityURL}`"
                            "User Banned: `#{not nguild.members.get user}`"
                            "Target Handled: `#{bot.getVanityURL(nguild.id) is oguild.vanityURL}`"
                            "Fixed In: `#{ended - began}ms`"
                        ].join '\n'
            catch err
                #











# cmds
cmds.coffee =
    args: 1
    fire: (msg, args) ->
        try
            fs.writeFileSync 'compiled.coffee', args.join(' ').replace('```coffee', '').replace '```', ''
            exec 'coffee -c compiled.coffee'

            result = eval fs.readFileSync('compiled.js').toString()

            await bot.createMessage msg.channel.id,
                embed:
                    title: 'Analytics'
                    description: "The code ran as expected.\n```coffee\n#{result}```"
        catch err
            await bot.createMessage msg.channel.id,
                embed:
                    title: 'Analytics'
                    description: "The code didn\'t run as expected.\n```#{err}```"

cmds.setup =
    args: 0
    fire: (msg, args) ->
            await model.findOneAndDelete id: msg.member.guild.id
            await new model(
                id: msg.member.guild.id
                prefix: undefined
                antinuke:
                    on: off
                    action: 'ban'
                    log: undefined
                    mode: 'ban'
                    wl: [bot.user.id, msg.member.guild.ownerID]
                    modules:
                        channels: off
                        roles: off
                        removal: off
                        invites: off
                        webhooks: off
                        updates: off
                        vanity: off
            ).save()

            await bot.createMessage msg.channel.id, 'Your data has been set up.'

cmds.antinuke =
    args: 1
    fire: (msg, args) ->
        mongo = await model.findOne msg.member.guild

        switch args[0].toLowerCase()
            when 'show', 'page', 'data', 'config'
                mods = []

                for name, val of mongo.antinuke.modules
                    if typeof val is 'boolean'
                        mods.push "#{name.split('')[0].toUpperCase()}#{name.slice(1)} **->** `#{val}`"

                return bot.createMessage msg.channel.id,
                    embed:
                        title: 'Charm Anti-nuke'
                        description: 'Defends against malicious moderation.'
                        fields: [
                            {
                                name: 'Whitelists'
                                value: if not mongo.antinuke.wl.length then '`...`' else mongo.antinuke.wl.map((wl) -> "<@!#{wl}>").join '\n'
                                inline: on
                            }
                            {
                                name: 'Modules'
                                value: mods.join '\n'
                                inline: on
                            }
                            {
                                name: 'Specs'
                                value: [
                                    "`->` The anti-nuke is switched `#{if mongo.antinuke.on then 'on' else 'off'}`."
                                    "`->` The anti-nuke's mode is `#{mongo.antinuke.mode}`."
                                    "`->` The anti-nuke's log is #{if mongo.antinuke.log then "<##{mongo.antinuke.log}>" else '`...`'}."
                                ].join '\n'
                                inline: off
                            }
                        ]
            when 'on', 'enable'
                mongo.antinuke.on = on
            when 'off', 'disable'
                mongo.antinuke.on = off
            when 'log', 'logchannel', 'setlog', 'setlogchannel'
                if msg.channelMentions[0]
                    mongo.antinuke.log = msg.channelMentions[0]
            when 'wl', 'wlist', 'whitelist'
                if msg.mentions[0] and not mongo.antinuke.wl.includes msg.mentions[0].id
                    mongo.antinuke.wl.push msg.mentions[0].id
            when 'bl', 'blist', 'blacklist'
                if msg.mentions[0] and msg.mentions[0].id isnt bot.user.id and msg.mentions[0].id isnt msg.member.guild.ownerID and mongo.antinuke.wl.includes msg.mentions[0].id
                    mongo.antinuke.wl = mongo.antinuke.wl.filter (wl) -> wl isnt msg.mentions[0].id
            when 'add', 'addmod', 'addmodule'
                if args[1] and mongo.antinuke.modules[args[1].toLowerCase()] isnt undefined
                    mongo.antinuke.modules[args[1].toLowerCase()] = true
            when 'del', 'delmod', 'delmodule'
                if args[1] and mongo.antinuke.modules[args[1].toLowerCase()] isnt undefined
                    mongo.antinuke.modules[args[1].toLowerCase()] = false
            when 'mode', 'setmode'
                if args[1] and ['ban', 'kick'].includes(args[1].toLowerCase())
                    mongo.antinuke.mode = args[1].toLowerCase()
            else
                return bot.createMessage msg.channel.id, 'No valid arg found.'

        await mongo.save()
        await bot.createMessage msg.channel.id, 'Your anti-nuke has been updated.'









# login
bot.connect()
