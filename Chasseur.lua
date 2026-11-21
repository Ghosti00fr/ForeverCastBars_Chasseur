-- ============================================================
--  Forever Cast Bars — pack Chasseur
--  Cadre en bois sculpté à ligatures de cuir (les chevrons gravés
--  s'allument), remplissage ambre et objets des prototypes chasseur :
--  visée, tir de précision, salve, soins et rappel du familier,
--  dressage, effroi, œil de la bête. Exige ForeverCastBars.
-- ============================================================

if not (FCB and FCB.Looks and FCB.Looks.RegisterPack and FCB.Props and FCB.Props.Kit) then return end

local M = "Interface\\AddOns\\ForeverCastBars_Chasseur\\textures\\"
local B = FCB.TEX_PATH .. "crafts\\"
local Props, K = FCB.Props, FCB.Props.Kit
local Put, Line, END, PutWH = Props.Put, Props.Line, Props.END, K.PutWH
local sin, cos, pi, max, min, floor = math.sin, math.cos, math.pi, math.max, math.min, math.floor
local LEAF, AMBER, RED, HEAL, GOLD, PINK = { .55, .8, .25 }, { 1, .85, .4 }, { 1, .25, .15 }, { .45, 1, .5 }, { 1, .9, .55 }, { 1, .55, .85 }
local function Y(c) return c.cy + 4 end
local function EX(c) return END(c) - 12 end
local function Part(slots, Draw, lines) return { slots = slots, lines = lines, Draw = Draw } end
-- RegisterKit ne gère pas les lignes : objets à ligne enregistrés à la main
local function R(name, parts)
    local n, l = 0, 0
    for _, p in ipairs(parts) do n = n + p.slots; l = l + (p.lines or 0) end
    Props.Register("hunt_" .. name, { slots = n, lines = l, Draw = function(st, c)
        local o = 0
        for _, p in ipairs(parts) do p.Draw(st, c, o); o = o + p.slots end
    end })
end
local LEAVES = K.Fall(LEAF, "P_Leaf", 6, { speed = 40, size = 10 })   -- feuilles de forêt sur toutes les barres

-- visée / tir de précision : flèche encochée qui recule, réticule qui se resserre, tir à la fin
local function Aim(sniper)
    local col = sniper and RED or AMBER
    return Part(8, function(st, c, o)
        local tx, ty = EX(c) - 4, Y(c); local k = c.te and 1 or c.p
        if not c.te then
            local r = (34 - 24 * k) * (1 + .04 * sin(c.t * (sniper and 6 or 3)))
            PutWH(st, o + 1, B .. "P_Bubble", tx, ty, r * 2, r * 2, 0, .85, col, true)
            for i = 0, 3 do                                                      -- 4 traits du réticule
                local ang = i * pi / 2 + (sniper and 0 or c.t * .8)
                local d = r * 1.1
                PutWH(st, o + 2 + i, B .. "P_Glow", tx + cos(ang) * d, ty + sin(ang) * d, i % 2 == 0 and 10 or 3, i % 2 == 0 and 3 or 10, 0, .9, col, true)
            end
            if sniper then local hb = (c.t * (1 + 2 * k)) % 1; Put(st, o + 6, B .. "P_Glow", tx, ty, 6 + 8 * (1 - hb), 0, 1 - hb, { 1, .1, .05 }, true) end
            PutWH(st, o + 7, M .. "P_Arrow", min(c.frontX, EX(c) - 34) + 4 - 6 * k, Y(c), 58, 15, 0, 1)
        elseif c.te < .55 then
            local u = min(1, c.te / .2)
            if c.te < .2 then PutWH(st, o + 7, M .. "P_Arrow", EX(c) - 44 + 30 * u, Y(c), 58, 15, 0, 1) end
            if c.te >= .1 then local v = (c.te - .1) / .45; PutWH(st, o + 8, B .. "P_Bubble", tx, ty, 6 + 40 * v, 6 + 40 * v, 0, 1 - v, col, true) end
        end
    end)
end

-- salve : à chaque seconde, une pluie de flèches tombe en diagonale sur la barre
local VOLLEY = Part(9, function(st, c, o)
    local t = c.te and (c.te + 99) or c.t
    local u = (t % 1) / .55
    for i = 0, 8 do
        local x = c.fillLX + c.fillW * (i + .2 + .5 * st.r[i + 1]) / 9
        if u < 1 then PutWH(st, o + i + 1, M .. "P_Arrow", x - 12 + u * 12, Y(c) + 40 - u * 40, 44, 11, -60, 1)
        elseif u < 1.6 then Put(st, o + i + 1, B .. "P_Smoke", x, Y(c) - 6, 14, 0, (1.6 - u) * .8, { .6, .5, .4 }) end
    end
end)

-- guérison du familier : croix et empreintes qui remontent vers l'icône, halo de soin
local MEND = Part(9, function(st, c, o)
    for i = 0, 7 do
        local u = (c.t * .5 + i / 8) % 1; local x0 = c.fillLX + c.fillW * ((i * .37) % 1)
        Put(st, o + i + 1, i % 2 == 1 and B .. "P_Cross" or B .. "P_Paw", x0 + (c.iconX - x0) * u, Y(c) + sin(pi * u) * 16, 6 + 3 * u, 0, sin(pi * u), HEAL, true)
    end
    Put(st, o + 9, B .. "P_Glow", c.iconX, c.iconY, 46, 0, .35 + .25 * sin(c.t * 4), HEAL, true)
end)

-- ressusciter : lumière qui converge, l'esprit de la bête (empreinte) se forme et s'élève
local REVIVE = Part(3, function(st, c, o)
    local k = c.te and 1 or c.p; local x = min(c.frontX, EX(c))
    local rise = c.te and min(1, c.te / .8) * 20 or 0
    Put(st, o + 1, B .. "P_Glow", x, Y(c), 20 + 25 * k, 0, .4 + .4 * k, GOLD, true)
    Put(st, o + 2, B .. "P_Paw", x, Y(c) + rise, 6 + 12 * k, 0, min(1, .2 + k) * (c.te and max(0, 1 - c.te / .8) or 1), { 1, .95, .8 })
    if c.te and c.te < .5 then local u = c.te / .5; PutWH(st, o + 3, B .. "P_Bubble", x, Y(c), 10 + 50 * u, (10 + 50 * u) * .6, 0, 1 - u, GOLD, true) end
end)

-- dressage : la corde part de l'icône, la boucle du lasso se resserre sur la bête
local TAME = Part(11, function(st, c, o)
    local k = c.te and 1 or c.p; local bx, by = EX(c) - 12, Y(c)
    local jit = (1 - k) * 3; local px, py = bx + sin(c.t * 9) * jit, by + cos(c.t * 7) * jit
    Put(st, o + 1, B .. "P_Paw", px, py, 16, sin(c.t * 5) * (1 - k) * 17, 1, { .95, .8, .6 })
    local r = (8 + 24 * (1 - k) ^ 1.3) * (1 + .04 * sin(c.t * 4))
    PutWH(st, o + 2, B .. "P_Bubble", px, py, r * 2, r * 1.24, 0, 1, { .75, .5, .25 })     -- boucle de corde
    Line(st, 1, c.iconX + 14, Y(c), px - r, py, 1, { .6, .4, .2 }, 2)
    Put(st, o + 3, B .. "P_Glow", px, py, 15 + 20 * k, 0, .15 + .5 * k * k, PINK, true)
    if c.te and c.te < .6 then
        local u = c.te / .6
        PutWH(st, o + 4, B .. "P_Bubble", bx, by, 14 + 40 * u, (14 + 40 * u) * .62, 0, 1 - u, PINK, true)
        for i = 0, 6 do
            local ang = i * pi / 3.5
            Put(st, o + 5 + i, B .. "P_Star", bx + cos(ang) * u * 22, by + sin(ang) * u * 14, 7 * (1 - u) + 2, 0, 1 - u, { 1, .75, .9 }, true)
        end
    end
end, 1)

-- renvoyer le familier : des empreintes s'éloignent vers la droite et s'effacent
local DISMISS = Part(9, function(st, c, o)
    for i = 0, 7 do
        local u = (c.t * .35 + i / 8) % 1
        Put(st, o + i + 1, B .. "P_Paw", c.fillLX + c.fillW * u, c.cy - 14 + (i % 2 == 1 and 3 or -3), 7, -90, (1 - u) * .9, { .85, .75, .6 })
    end
    if c.te and c.te < .5 then Put(st, o + 9, B .. "P_Smoke", EX(c) - 10, Y(c), 34, 0, (1 - c.te / .5) * .7, { .8, .75, .65 }) end
end)

-- effrayer une bête : ondes de choc rouges et griffures à la pointe
local SCARE = Part(7, function(st, c, o)
    local x = min(c.frontX, EX(c))
    for j = 0, 2 do
        local u = (c.t * 2.2 + j / 3) % 1; local s = 12 + 56 * u
        PutWH(st, o + j + 1, B .. "P_Bubble", x + s * .2, Y(c), s * .6, s, 0, 1 - u, RED, true)
    end
    if not c.te then for j = 0, 2 do PutWH(st, o + 4 + j, B .. "P_Glow", x - 5 + j * 4, Y(c), 2, 16, -12, c.p, { 1, .3, .2 }, true) end end
    if c.te and c.te < .4 then Put(st, o + 7, B .. "P_Glow", EX(c) - 10, Y(c), 70, 0, 1 - c.te / .4, RED, true) end
end)

-- œil de la bête : un œil de fauve s'ouvre sur la barre, cligne parfois
local EYE = Part(1, function(st, c, o)
    local op = min(1, c.t / .6); local bl = 1 - math.abs(sin(c.t * .9)) ^ 40
    PutWH(st, o + 1, M .. "P_BeastEye", c.fillLX + c.fillW * .5, Y(c), 70, max(1, 26 * op * bl), 0, .8 * op)
end)

R("aimed",   { LEAVES, Aim(false) })
R("sniper",  { LEAVES, Aim(true) })
R("volley",  { LEAVES, VOLLEY })
R("mend",    { LEAVES, MEND })
R("revive",  { LEAVES, K.Converge(GOLD, 12, "P_Glow", 60, .7, 7), REVIVE })
R("tame",    { LEAVES, TAME })
R("dismiss", { LEAVES, DISMISS })
R("scare",   { LEAVES, SCARE })
R("eye",     { LEAVES, EYE })
-- faucon invoqué (Forever) : il plane au-dessus du front, puis pique et se pose au bout de la barre
local HAWK = Part(1, function(st, c, o)
    if not c.te then Put(st, o + 1, B .. "P_Hawk", min(c.frontX, EX(c)), Y(c) + 24 + sin(c.t * 2) * 4, 44 + 16 * c.p, -90 + sin(c.t * 1.5) * 10, 1); return end
    if c.te >= .5 then return end
    local u = c.te / .5
    Put(st, o + 1, B .. "P_Hawk", EX(c) - 6 * u, Y(c) + 24 - 18 * u, 60 - 12 * u, -90 - 40 * sin(pi * u), 1 - u * u)
end)
R("hawk",    { LEAVES, HAWK, K.Ring(AMBER, 160) })

local function S(props, veil, fill)
    return { family = "hunt_wood", fill = fill, props = { "hunt_" .. props }, veil = veil or { .45, .75, .3 }, veilAlpha = { .1, .22 } }
end
FCB.Looks:RegisterPack(M, {
    families = { "hunt_wood" },
    spells = {
        aimedshot  = S("aimed", nil, "Fill_hunt_amber"),
        snipershot = S("sniper", { .8, .3, .2 }, "Fill_hunt_amber"),
        volley     = S("volley", nil, "Fill_hunt_amber"),
        mendpet    = S("mend", HEAL),
        revivepet  = S("revive", { 1, .85, .45 }),
        tamebeast  = S("tame", PINK),
        dismisspet = S("dismiss"),
        scarebeast = S("scare", { 1, .3, .2 }, "Fill_hunt_amber"),
        eyesbeast  = S("eye", { 1, .85, .3 }),
        summonhawk = S("hawk", AMBER),
    },
})
