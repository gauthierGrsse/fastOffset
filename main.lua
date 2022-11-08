-- FastOffset
-- By Gauthier GRSS

-- Vous pouvez utiliser fastOffset de 2 manières :
--      En cliquant simplement sur le plugin dans la pool Plugin, vous pourrez alors modifier l'offset via un pop up
--      Avec une macro avec un offset pré défini

-- Pour l'utiliser avec une macro il faut une ligne comme celle ci : 'Plugin "fastOffset" "-0.03"'
-- Cette ligne permet de reculer d'une frame d'offset (une frame à 30 FPS)
-- Attention la valeur a donner est en seconde !

-- N'oubliez pas les "" pour donner la valeur de l'offset.

-- Afin d'utiliser le plugin, vous devez donner une variable de numéro de track en cours (qui sert de référence au Timecode du track)
-- Il y a une variable timecodeTrackOffset, cette variable sert si vous avec par exemple le timecode 11 pour le track 1, le 12 pour le track 2... Il faudra alors la mettre a 10

-- Setup :
local timecodeTrackOffset = 10
local songNbrVar = 'currenttrackid'

local haveFeedback = false

-- Shortcut
local cmd = gma.cmd
local setvar = gma.show.setvar
local getvar = gma.show.getvar
local sleep = gma.sleep
local confirm = gma.gui.confirm
local msgbox = gma.gui.msgbox
local textinput = gma.textinput
local progress = gma.gui.progress
local getobj = gma.show.getobj
local property = gma.show.property

local function feedback(text)
    if haveFeedback then
        gma.feedback("Plugin fastOffset : " .. text)
    else
        gma.echo("Plugin fastOffset : " .. text)
    end
end

local function echo(text)
    gma.echo("Plugin fastOffset : " .. text)
end

local function error(text)
    gma.gui.msgbox("Plugin fastOffset ERREUR", text)
    feedback("Plugin fastOffset ERREUR : " .. text)
end

local function blindEdit(mode)
    if mode then
        cmd('BlindEdit On')
    else
        cmd('BlindEdit Off')
    end
end

local function findAvailableMacro(first)
    while getobj.verify(getobj.handle('Macro ' .. first)) do
        first = first + 1
    end
    return first
end

local function assignOffset(timecodeNbr, offset)
    cmd('Assign Timecode ' .. timecodeNbr .. ' /offset=' .. offset)
end

local function getOffset(timecodeNbr)
    return property.get(getobj.child(getobj.handle('Timecode'), timecodeNbr - 1), 'offset')
end

local function toAbsoluteOffset(offsetString)
    if not string.find(offsetString, ':') or not string.find(offsetString, '.') then
        return offsetString
    elseif string.len(offsetString) >= 10 then
        -- exemple 2:00:00.00
        local patern = "(%d+):(%d+):(%d+).(%d+)"
        local hour, minute, sec, frame = offsetString:match(patern)
        return (frame * 3.333333 + sec * 100 + minute * 60 * 100 + hour * 60 * 60 * 100) / 100
    elseif string.len(offsetString) == 8 or string.len(offsetString) == 7 then
        -- exemple 20:00:00
        local patern = "(%d+):(%d+):(%d+)"
        local minute, sec, frame = offsetString:match(patern)
        return (frame * 3.333333 + sec * 100 + minute * 60 * 100) / 100
    elseif string.len(offsetString) == 5 or string.len(offsetString) == 4 then
        -- exemple 20:00
        local patern = "(%d+):(%d+)"
        local sec, frame = offsetString:match(patern)
        return (frame * 3.333333 + sec * 100) / 100
    end
end

local function start(cmdArg)
    local currentTimecode = toint(getvar(songNbrVar) + timecodeTrackOffset)
    feedback('Current timecode : ' .. currentTimecode)
    if not cmdArg then
        local entry = textinput('Changer offset track ' .. getvar(songNbrVar) .. ' ?', getOffset(currentTimecode))
        if entry then
            feedback(toAbsoluteOffset(entry))
            assignOffset(currentTimecode, toAbsoluteOffset(entry))
            feedback('Changement d\'offset effectué a ' .. getOffset(currentTimecode))
        else
            feedback('Changement d\'offset annulé !')
        end
    else
        feedback(cmdArg)
        if string.sub(cmdArg, 1, 1) == '-' then
            local value = string.sub(cmdArg, 2)
            feedback(toAbsoluteOffset(getOffset(currentTimecode)))
            feedback(toAbsoluteOffset(getOffset(currentTimecode)) - value)
            assignOffset(currentTimecode, toAbsoluteOffset(getOffset(currentTimecode)) - value)
            feedback('Changement d\'offset effectué a ' .. getOffset(currentTimecode))
        else
            local value = cmdArg
            feedback(toAbsoluteOffset(getOffset(currentTimecode)))
            feedback(toAbsoluteOffset(getOffset(currentTimecode)) + value)
            assignOffset(currentTimecode, toAbsoluteOffset(getOffset(currentTimecode)) + value)
            feedback('Changement d\'offset effectué a ' .. getOffset(currentTimecode))
        end
    end
end

return start
