breed [ mammoths mammoth ]
breed [ humans human ]
humans-own [xhome yhome rol xmammoths ymammoths ready?]
turtles-own [ age nreproductions reproduceticks]
patches-own [ncaçadors nexploradors nnormals]

globals [
  mammoths-killed-by-humans         ; counter to keep track of the number of mammoths killed by humans
  mammoths-killed-by-climate-change ; counter to keep track of the number of mammoths killed by climate change
  mammoth-birth-rate
  mammoth-max-age
  human-max-age
  mammoth-max-reproduction
  human-max-reproduction
  reproducecooldown
  human-birth-rate
  min-human-age-to-reproduce
]

to moveToHome
  ask humans with [xhome != max-pxcor + 1 and yhome != max-pycor + 1] [move-to patch xhome yhome]
end
to SETUP

  clear-all
  ask patches [ set pcolor green - 0.25 - random-float 0.25 ]
  ask patches [ set ncaçadors 0 set nnormals 0 set nexploradors 0]

  set mammoth-birth-rate 30
  set mammoth-max-age (60 * 365)
  set mammoth-max-reproduction 1
  set reproducecooldown 100
  set human-max-age (25 * 365)
  set human-max-reproduction 1
  set human-birth-rate 20
  set min-human-age-to-reproduce 12 * 365

  create-mammoths nMamoothsIni [
    set shape "mammoth"
    set size 4
    set color yellow
    set age random (60 * 365)
    set nreproductions 0
    set reproduceticks 0
    move-to one-of patches
  ]

   create-humans nHumansIni [
    set shape "person"
    set size 4
    set color pink - 0.5 - random-float 0.5
    set age random (30 * 365)
    set nreproductions 0
    set reproduceticks 0
    set xhome max-pxcor + 1
    set yhome max-pycor + 1
    set xmammoths max-pxcor + 1
    set ymammoths max-pycor + 1
    set rol 30 ; Inicialment tots son normals
    set ready? false
    move-to one-of patches

  ]
reset-ticks
end

to go
  ask mammoths [
    move mammoth-speed
    if any? other mammoths-here and [age] of one-of other mammoths-here > (3 * 365) and [reproduceticks] of one-of other mammoths-here = 0 [
        reproduce (3 * 365) mammoth-birth-rate
    ]
    die-naturally-mammoth
    set age age + 1
    if ticks mod 365 = 0 [
      set nreproductions 0
    ]
    if reproduceticks > 0 [
      set reproduceticks reproduceticks - 1
    ]
  ]

  ask humans [

    if not any? other humans-here and not humanHasHome [
      moveNearestHuman
    ]
    if any? other humans in-radius 2 and not humanHasHome [
      let h one-of  other humans in-radius 2
      ;si l'altre huma te casa i jo no, agafo la seva, altrament la creo
      (ifelse
       hasHome [xhome] of h [yhome] of h [takeHumanHome h]
       [createHome]
      )
      setRol
    ]

    ;si trobo un altre huma a prop i tinc casa
    if any? other humans in-radius 2 and humanHasHome [
      let h one-of other humans in-radius 2
      ;en cas que l'altre huma tambe tingui casa i no sigui la meva i es compleixin les condicions per ajuntar cases, les ajuntem
      let xhomeOfH [xhome] of h
      let yhomeOfH [yhome] of h
      if hasHome xhomeOfH yhomeOfH and patch xhome yhome != patch xhomeOfH yhomeOfH and canJoinHomes h [
        joinHomes h
      ]
    ]

    ;Aquesta part només la fan els rositas
    ( ifelse
      rol > 10 and rol <= 40 [
      (ifelse
        humanCanReproduce [humanMoveHome]
        [move human-speed])
      if patch-here = patch xhome yhome and any? other humans-here [
        let humanhere one-of other humans-here
        if otherHumanCanReproduce humanhere [
          reproduceHumans min-human-age-to-reproduce human-birth-rate
          move 0
        ]
      ]
    ]
    ;Aquesta part nomes la fan els exploradors.
      rol <= 10 [
      	move human-speed
        ;Si hi ha un mamooth aprop, guardem la posicio i la pintem
        if any? mammoths in-radius 5 and not mammothsFound [
            set xmammoths pxcor
            set ymammoths pycor
            ask patch-here [set pcolor grey]
         ]
         ;Si no estem a casa, hem trobat mamuts, i encara no estic llest per caçar, anem a casa
      	 if mammothsFound and humanHasHome and not ready? and patch-here != patch xhome yhome[
          	humanMoveHome
         ]
         ;Si estic a casa, he trobat mamuts i encara no estic llest, informo als caçadors de la localitzacio dels mamuts
         if patch-here = patch xhome yhome and mammothsFound and ready? = false [
          reportMammothsLocation
         ]
         ;Si hi han suficients caçadors a casa, estem llestos per caçar el mamut
         if patch-here = patch xhome yhome and enoughHuntersHere  [
              set ready? true
         ]
        ;Si he trobat mamuts i estic llest, anem cap al mamut
        if mammothsFound and ready? = true [
          humanMoveMammoth
        ]
     ]



      ;aixo ho fan els caçadors
        rol > 40 [
        (ifelse
         ;Si se on hi han mamuts pero no estic llest, vaig cap a casa
         mammothsFound and ready? = false [
          humanMoveHome
            ;Si estic a casa i som suficients caçadors, estem llestos per caçar al mamut
            if patch-here = patch xhome yhome and enoughHuntersHere  [
              set ready? true
            ]
          ]
          ;Si se on hi han mamuts i estic llest
           mammothsFound and ready? = true [
              ;Si estic on m'han dit que hi han mamuts
            	(ifelse patch-here = patch xmammoths ymammoths [
              ;trec la zona marcada
              ask patch-here [set pcolor green - 0.25 - random-float 0.25]
              ;lluito contra el mamut si el tinc al costat i m'en oblido de aquesta posicio que m'han dit que hi han mamuts perque si sobrevisc, el mamut haura estat mort
              (ifelse any? mammoths-here [set xmammoths max-pxcor + 1 set ymammoths max-pycor + 1 set ready? false fight]
              ;vaig a per el mamut mes proper si no hi ha cap aqui
              any? mammoths in-radius 5 [
                 face min-one-of mammoths [distance myself]
                 movehuman human-speed
              ]
                ;si no hi veig cap mamut, desisteixo de caçar al mamut
                [set xmammoths max-pxcor + 1 set ymammoths max-pycor + 1 set ready? false])
             ]
              ;Si la zona on m'han dit que hi han mamuts esta marcada i estic llest, anem a aquesta zona
              [pcolor] of patch xmammoths ymammoths = grey and ready? = true[
                humanMoveMammoth
              ]
              ;READY? = TRUE JA ES COMPROVA ADALT I ABANS QUE D'ENTRAR PER AQUI, S'ENTRARIA PER EL ANY? MAMMOTS-HERE D'ADALT NO?
              any? mammoths-here and ready? = true and [pcolor] of patch xmammoths ymammoths != grey [set xmammoths max-pxcor + 1 set ymammoths max-pycor + 1 set ready? false  fight ]
              ;AQUI EL MATEIX, NO ES EL MATEIX AQUESTA LINIA QUE LA D'ADALT QUE TAMBE TE EL RADIUS 5? ENCARA QUE AQUESTA LINIA ES MES RESTRICTIVA PQ TE LO DEL GRIS
              any? mammoths in-radius 5 and ready? = true and [pcolor] of patch xmammoths ymammoths != grey [
                 face min-one-of mammoths [distance myself]
                 movehuman human-speed
              ]
              [set xmammoths max-pxcor + 1 set ymammoths max-pycor + 1 set ready? false ]
             )
          ]
          ;DIRIA QUE AQUESTA LINIA NO ES NECESARIA PERO TAMPOC FA MAL, PER SI DE CAS, JA QUE ES EL QUE HEM POSAT ADALT
            xmammoths = max-pxcor + 1 and ymammoths = max-pycor + 1 and ready? = false [ move human-speed]
           )
        ]
    )

    die-naturally-human
    set age age + 1

     if ticks mod 365 = 0 [
      set nreproductions 0
    ]

    if reproduceticks > 0 [
      set reproduceticks reproduceticks - 1
    ]
  ]

  forceHumanRoles

  tick
end

to forceHumanRoles
    ;A tots els patches que son casa
    ask patches with [(ncaçadors + nnormals + nexploradors) > 0] [
    ;Inicialitzem variables per tal de fer mes comode el codi
    let cordenadax [pxcor] of self
    let cordenaday [pycor] of self
    let ne nexploradors
    let nc ncaçadors
    let nn nnormals
    (ifelse
      ;Si la casa te mes de 3 habitants, ajustem els rols per els habitants de la casa
      (ncaçadors + nnormals + nexploradors) >= 3 [
        ask humans with [xhome = cordenadax and yhome = cordenaday] [
          ;Si no la casa no te exploradors fem que es canvii a explorador
          if ne = 0 [
            ifelse nn > 2 or nc > 2 and rol > 10 and rol <= 40  [set rol 5 set color black set ne ne + 1 set nn nn - 1]
            [if nc > 0 and rol > 40 [set rol 5 set color black  set ne ne + 1 set nc nc - 1]]
          ]
          ;Si tenim menys de dos caçadors i ja tenim normals i exploradors, fem canvi a caçador
          ;NO HAURIEM DE POSAR ne>1? HO DIC PQ NORMALMENT AMB UN CAÇADOR TENIM
          if nc < 2 [
            if nn > 2 or ne > 2 and rol > 10 and rol <= 40  [set rol 60 set color yellow set nc nc + 1 set nn nn - 1]
          ]
          ;Si tenim menys de dos normals i tenim 2 exploradors o mes o tenim 2 caçadors o mes, fem canvi a normal del que tingui mes de 2
          if nn < 2 [
            ifelse ne >= 2 and rol <= 10  [set rol 30 set color pink set nn nn + 1 set ne ne - 1]
            [if nc >= 2 and rol > 40  [set rol 30 set color pink set nn nn + 1 set nc nc - 1 ]]
          ]
        ]

    ]

    ;Altrament, la casa ha de tenir 2 normals per tal de reproduir-se i/o agrupar-se i aixi fer creixer la casa
    [ if nn < 2 [ask humans with [xhome = cordenadax and yhome = cordenaday and (rol <= 10 or rol > 40) ] [set rol 30 set color pink  set ne  0 set nc  0 set nn nn + 1]] ])
    ;Actualitzem els atributs del patch
    set nexploradors ne
    set ncaçadors nc
    set nnormals nn
  ]
end

to setRol
  set rol random 100 ; Si es de 0 a 10 explorador. De 0.11 a 40 normal. Caçador 41 a 100
  (ifelse
    rol <= 10 [ set color black ask patch xhome yhome [set nexploradors nexploradors + 1] ]
    rol > 10 and rol <= 40 [ set color pink ask patch xhome yhome [set nnormals nnormals + 1] ]
    rol > 40 [ set color yellow ask patch xhome yhome [set ncaçadors ncaçadors + 1] ]
  )
end

to-report humanHasHome
  report (xhome != (max-pxcor + 1) and yhome != (max-pycor + 1))
end

to-report hasHome [x y]
  report (x != (max-pxcor + 1) and y != (max-pycor + 1))
end

to takeHumanHome [h]
  let xh [xhome] of h
  let yh [yhome] of h
  (ifelse
    rol <= 10 [ask patch xh yh [set nexploradors nexploradors + 1]]
    rol > 10 and rol <= 40 [ask patch xh yh [set nnormals nnormals + 1]]
    [ask patch xh yh [set ncaçadors ncaçadors + 1 ]])
  set xhome xh
  set yhome yh
end

to createHome
  set xhome pxcor
  set yhome pycor
  set pcolor red
end

to-report canJoinHomes [h]
  let xhomeOfH [xhome] of h
  let yhomeOfH [yhome] of h
  ;Si la suma d'habitants de les dues cases es major a 20 podem ajuntar cases
  let numHumansHome1 0
  ask patch xhome yhome [set numHumansHome1 (ncaçadors + nnormals + nexploradors)]
  let numHumansHome2 0
  ask patch xhomeOfH yhomeOfH [set numHumansHome2 (ncaçadors + nnormals + nexploradors)]
  report ((numHumansHome1 + numHumansHome2 < 20) and (numHumansHome1 <= numHumansHome2))
end

to joinHomes [h]
  ask patch xhome yhome [ set pcolor green - 0.25 - random-float 0.25 ]
  let xhomemine xhome
  let yhomemine yhome
  let xhomeOfH [xhome] of h
  let yhomeOfH [yhome] of h
  ask other humans with [xhome = xhomemine and yhome = yhomemine] [set xhome xhomeOfH set yhome yhomeOfH]
  let ncPatch [ncaçadors] of patch xhome yhome
  let nePatch [nexploradors] of patch xhome yhome
  let nnPatch [nnormals] of patch xhome yhome
  ask patch xhomemine yhomemine [set ncaçadors 0 set nnormals 0 set nexploradors 0]
  set xhome xhomeOfH
  set yhome yhomeOfH
  ask patch xhomeOfH yhomeOfH [set ncaçadors ncaçadors + ncPatch set nexploradors nexploradors + nePatch set nnormals nnormals + nnPatch]

end

to humanMoveHome
  face patch xhome yhome
  movehuman human-speed
end

to movehuman [dist]
  forward dist
end

to moveNearestHuman
  if any? humans[face min-one-of other humans [distance myself] ];s'encara cap on hi ha la persona més propera
  movehuman human-speed
end

to move [dist];
  right random 50
  left random 50
  while [patch-ahead dist = nobody] [
     right random 50
     left random 50
  ]

  forward dist
end

to humanMoveMammoth
	face patch xmammoths ymammoths
	movehuman human-speed
end

to reportMammothsLocation
  let xmam xmammoths
  let ymam ymammoths
  let xh xhome
  let yh yhome
  ask humans with [rol > 40 and ready? = false and xhome = xh and yhome = yh] [ set xmammoths xmam  set ymammoths ymam ]
end

to-report mammothsFound
  report (xmammoths != max-pxcor + 1 and ymammoths != max-pycor + 1)
end

to-report enoughHuntersHere
  report (count (humans-here with [rol > 40  and xhome = [xhome] of self and yhome = [yhome] of self ] ) >= 1)
end

to-report humanCanReproduce
   report (reproduceticks = 0  and humanHasHome and patch-here != patch xhome yhome and nreproductions < human-max-reproduction and age >= min-human-age-to-reproduce)
end

to-report otherHumanCanReproduce [h]
  report ([age] of h > min-human-age-to-reproduce and [nreproductions] of h < human-max-reproduction and [reproduceticks] of h = 0)
end

to reproduce [ min-age birth-rate ]
  if age >= min-age and (random 100) < birth-rate and nreproductions < mammoth-max-reproduction and reproduceticks = 0 [
    hatch 1 [set age 0 move mammoth-speed]
    set nreproductions nreproductions + 1
    set reproduceticks reproduceticks + reproducecooldown
  ]
end

to reproduceHumans [min-age birth-rate]
   if age >= min-age and nreproductions < human-max-reproduction and reproduceticks = 0 [
    ask one-of other humans-here[ set nreproductions nreproductions + 1 set reproduceticks reproducecooldown ]
    set nreproductions nreproductions + 1
    set reproduceticks reproducecooldown
    hatch 1 [
      set age 0
      set xhome [xhome] of myself
      set yhome [yhome] of myself
      set nreproductions 0
      set reproduceticks 0
      set rol random 100 ; Si es de 0 a 10 explorador. De 11 a 40 normal. Caçador 41 a 100
           ifelse rol <= 10
          [ set color black ask patch xhome yhome [set nexploradors nexploradors + 1] ]
          [ ifelse rol > 10 and rol <= 40
            [ set color pink ask patch xhome yhome [set nnormals nnormals + 1]]
            [ set color yellow ask patch xhome yhome [set ncaçadors ncaçadors + 1]]
          ]
      move human-speed]

   ]

end

to die-naturally-mammoth
  if age >= mammoth-max-age [
    die
  ]
end


to fight
  if any? mammoths-here [
    (ifelse random  100 > 40 [ask one-of mammoths in-radius 1 [die]]
    [
    let rolturtle [rol] of self
    if hasHome xhome yhome [ask patch xhome yhome [
      (ifelse
        rolturtle <= 10 [set nexploradors nexploradors - 1]
        rolturtle > 10 and rolturtle <= 40 [ set nnormals nnormals - 1]
        [set ncaçadors ncaçadors - 1])
      ]]
    if hasHome xhome yhome [ask patch xhome yhome [if (nnormals + ncaçadors + nexploradors) <= 0 [set pcolor green - 0.25 - random-float 0.25  ]]]
    die ]  )
  ]
end

to die-naturally-human
  if age >= human-max-age [
   let rolturtle [rol] of self
    if hasHome xhome yhome [ask patch xhome yhome [
      (ifelse
        rolturtle <= 10 [set nexploradors nexploradors - 1]
        rolturtle > 10 and rolturtle <= 40 [ set nnormals nnormals - 1]
        [set ncaçadors ncaçadors - 1])
      ]]
    if hasHome xhome yhome [ask patch xhome yhome [if (nnormals + ncaçadors + nexploradors) <= 0 [set pcolor green - 0.25 - random-float 0.25  ]]]
    die
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
232
68
683
520
-1
-1
7.2623
1
10
1
1
1
0
0
0
1
-30
30
-30
30
1
1
1
days
30.0

BUTTON
25
41
96
74
NIL
SETUP
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
125
42
188
75
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
13
157
206
190
mammoth-speed
mammoth-speed
0
1
0.05
0.05
1
patches
HORIZONTAL

PLOT
13
284
213
434
num mammoths
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count mammoths"

SLIDER
12
115
195
148
human-speed
human-speed
0
1
1.0
0.1
1
NIL
HORIZONTAL

PLOT
10
446
210
596
num humans
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count humans"

SLIDER
13
199
185
232
nHumansIni
nHumansIni
2
50
14.0
1
1
NIL
HORIZONTAL

PLOT
796
74
996
224
num cazadores
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count humans with [rol >= 51]"

PLOT
1047
77
1247
227
num normals
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count humans with [rol <= 50 and rol > 10]"

PLOT
929
261
1129
411
num exploradors
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count humans with [rol <= 10]"

BUTTON
745
449
851
482
moveToHome
moveToHome
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
17
243
189
276
nMamoothsIni
nMamoothsIni
0
100
9.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

mammoth
false
0
Polygon -6459832 true false 195 196 180 211 165 211 166 193 151 163 151 178 136 193 61 193 45 211 30 211 16 193 16 178 1 148 16 118 46 103 106 88 166 73 196 43 226 43 255 93 271 208 256 208 241 133 226 133 211 148
Rectangle -6459832 true false 165 195 180 225
Rectangle -6459832 true false 30 195 45 225
Rectangle -16777216 true false 165 225 180 240
Rectangle -16777216 true false 30 225 45 240
Line -16777216 false 255 90 240 90
Polygon -6459832 true false 0 165 0 135 15 135 0 165
Polygon -1 true false 224 122 234 129 242 135 260 138 272 135 287 123 289 108 283 89 276 80 267 73 276 96 277 109 269 122 254 127 240 119 229 111 225 100 214 112

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
