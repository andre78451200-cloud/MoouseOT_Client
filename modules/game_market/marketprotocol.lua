MarketProtocol = {}



local silent
local protocol

local browseEvent
local pendingSig
local COALESCE_DELAY_MS = 120
local statistics = runinsandbox('offerstatistic')

local function send(msg)
    if protocol and not silent then
        protocol:send(msg)
    end
end


function initProtocol()
    connect(g_game, {
        onGameStart = MarketProtocol.registerProtocol,
        onGameEnd = MarketProtocol.unregisterProtocol
    })


    if g_game.isOnline() then
        MarketProtocol.registerProtocol()
    end

    MarketProtocol.silent(false)
end

function terminateProtocol()
    disconnect(g_game, {
        onGameStart = MarketProtocol.registerProtocol,
        onGameEnd = MarketProtocol.unregisterProtocol
    })


    MarketProtocol.unregisterProtocol()
    MarketProtocol = nil
end

function MarketProtocol.updateProtocol(_protocol)
    protocol = _protocol
end

function MarketProtocol.registerProtocol()
    MarketProtocol.updateProtocol(g_game.getProtocolGame())
end

function MarketProtocol.unregisterProtocol()
    MarketProtocol.updateProtocol(nil)
end

function MarketProtocol.silent(mode)
    silent = mode
end


function MarketProtocol.clearPendingBrowse()
    if browseEvent then
        removeEvent(browseEvent)
        browseEvent = nil
    end
    pendingSig = nil
end



function MarketProtocol.sendMarketBrowse(browseId, browseType, tier)
    if g_game.getFeature(GamePlayerMarket) then
        local id = tonumber(browseId) or 0
        local bt = tonumber(browseType) or 0
        local t  = tonumber(tier) or 0
        local sig = string.format('%d:%d:%d', id, bt, t)


        if pendingSig == sig and browseEvent then
            print(string.format('[MarketProtocol] sendMarketBrowse: coalesced duplicate sig=%s (skipping)', sig))
            return
        end


        if browseEvent then
            removeEvent(browseEvent)
            browseEvent = nil
        end
        pendingSig = sig
        print(string.format('[MarketProtocol] sendMarketBrowse: schedule id=%d type=%d tier=%d silent=%s', id, bt, t, tostring(silent)))
        browseEvent = scheduleEvent(function()
            browseEvent = nil
            pendingSig = nil

            local msg = OutputMessage.create()
            msg:addU8(ClientOpcodes.ClientMarketBrowse)
            if g_game.getClientVersion() >= 1251 then
                msg:addU8(id)
                if bt > 0 then
                    msg:addU16(bt)


                    if g_game.getFeature and g_game.getFeature(GameThingUpgradeClassification) then
                        local itemCls = 0

                        if g_things and g_things.getThingType then
                            local tt = g_things.getThingType(bt)
                            if tt and tt.getClassification then
                                itemCls = tt:getClassification() or 0
                            end
                        end
                        if itemCls > 0 then
                            msg:addU8(t)
                        end
                    end
                end
            else
                msg:addU16(bt)
            end
            print(string.format('[MarketProtocol] sendMarketBrowse: sending id=%d type=%d tier=%d silent=%s', id, bt, t, tostring(silent)))
            send(msg)
        end, COALESCE_DELAY_MS)
    else
        g_logger.error('MarketProtocol.sendMarketBrowse does not support the current protocol.')
    end
end

function MarketProtocol.sendMarketBrowseMyOffers()
    MarketProtocol.sendMarketBrowse(MarketRequest.MyOffers, 0)
end
function MarketProtocol.sendMarketBrowseOfferHistory()
    MarketProtocol.sendMarketBrowse(MarketRequest.MyHistory, 0)
end
