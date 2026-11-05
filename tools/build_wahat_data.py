"""Generate the committed, deterministic real-size community data from its layout.

Run from any directory. Distances are metres; frontages and IDs remain stable.
The generated file is ordinary Godot constants shared by the world, map and tests.
"""
from pathlib import Path
import json
import math

ROOT = Path(__file__).resolve().parents[1]
class Raw(str):
    pass
def v2(x,z): return Raw(f'Vector2({x:g}, {z:g})')
def v3(x,y,z): return Raw(f'Vector3({x:g}, {y:g}, {z:g})')
def rect(x,z,w,d): return Raw(f'Rect2({x:g}, {z:g}, {w:g}, {d:g})')
def colour(r,g,b): return Raw(f'Color({r:g}, {g:g}, {b:g}, 1)')
def gd(value):
    if isinstance(value,Raw): return str(value)
    if isinstance(value,str): return json.dumps(value,ensure_ascii=False)
    if isinstance(value,bool): return 'true' if value else 'false'
    if isinstance(value,dict): return '{'+', '.join(gd(k)+': '+gd(v) for k,v in value.items())+'}'
    if isinstance(value,(list,tuple)): return '['+', '.join(gd(v) for v in value)+']'
    return str(value)
constants={}
def put(name,value): constants[name]=value

put('DETAIL_VERSION',1)
put('MAP_HALF',v2(470,250)); put('ROAD_WIDTH',10.0); put('WALL_HEIGHT',2.5); put('GATE_HALF_WIDTH',7.0)
put('START',{'position':v3(-296,0,-160),'facing':-90.0})
put('TREE_BELT',{'inner':v2(463,243),'spacing':8.0})
put('GATES',[{'position':v3(-465,0,z),'facing':-90.0,'name':name} for z,name in [(-190,'North Checkpoint'),(190,'South Checkpoint')]])
# Session 63: both tracks have rounded corners that match the ring road's (same centres).
put('HORSE_TRACK',{'half':v2(450,230),'width':5.0,'radius':37.0})
put('BIKE_TRACK',{'half':v2(438,218),'width':4.0,'radius':25.0})
def rounded_loop(hx,hz,r,steps=8,reverse=False):
    """Points round a rectangle with rounded corners, clockwise from the north-west."""
    pts=[]
    for cx,cz,a0 in [(-hx+r,-hz+r,180),(hx-r,-hz+r,270),(hx-r,hz-r,0),(-hx+r,hz-r,90)]:
        for j in range(steps+1):
            a=math.radians(a0+90*j/steps)
            pts.append((round(cx+r*math.cos(a),2),round(cz+r*math.sin(a),2)))
    return pts[::-1] if reverse else pts
put('PLAZA',{'centre':v2(-200,-145),'radius':50.0,'sunken_radius':20.0,'floor_radius':15.0,'depth':0.45,'steps':3,'fountain_radius':2.8})
put('PLAZA_SAILS',[[v3(-224,0,-157),v3(-200,0,-170),v3(-176,0,-157)],[v3(-176,0,-133),v3(-200,0,-120),v3(-224,0,-133)]])
put('PLAZA_BENCHES',[{'position':v3(-200,-.45,-155),'facing':0.0},{'position':v3(-200,-.45,-135),'facing':180.0},{'position':v3(-190,-.45,-145),'facing':-90.0}])
put('SPINE',rect(-145,-35,560,70)); put('STREAM',{'z':25.0,'from_x':-135.0,'to_x':405.0,'width':3.0})
clusters=[(1,48,-126),(2,203,-126),(3,348,-126),(4,73,120),(5,303,120)]
put('CLUSTERS',[{'id':f'C{n}','area':rect(cx-65,cz-75,130,150),'centre':v2(cx,cz)} for n,cx,cz in clusters])
roads=[]
def road(name,a,b,width=6.0): roads.append({'name':name,'from':v2(*a),'to':v2(*b),'width':width})
import math
def rounded(name,pts,width=6.0,r=14.0,steps=4):
    """A road along a polyline whose corners are rounded with short straight pieces."""
    out=[pts[0]]
    for i in range(1,len(pts)-1):
        p0,p1,p2=pts[i-1],pts[i],pts[i+1]
        l1=math.dist(p0,p1); l2=math.dist(p1,p2); k=min(r,l1/2,l2/2)
        a=(p1[0]+(p0[0]-p1[0])*k/l1,p1[1]+(p0[1]-p1[1])*k/l1)
        b=(p1[0]+(p2[0]-p1[0])*k/l2,p1[1]+(p2[1]-p1[1])*k/l2)
        for j in range(steps+1):
            t=j/steps  # quadratic curve a -> p1 -> b
            out.append(((1-t)**2*a[0]+2*(1-t)*t*p1[0]+t*t*b[0],(1-t)**2*a[1]+2*(1-t)*t*p1[1]+t*t*b[1]))
    out.append(pts[-1])
    pts=[(round(x,2),round(z,2)) for x,z in out]
    for a,b in zip(pts,pts[1:]):
        if math.dist(a,b)>0.05: road(name,a,b,width)
# Session 61: the ring road's four corners are rounded (radius 12 m) like the inside roads.
# It starts and ends in the middle of the north side so the loop closes on a straight.
RING_RADIUS=12.0
rounded('Ring Road',[(0,-205),(425,-205),(425,205),(-425,205),(-425,-205),(0,-205)],10.,RING_RADIUS,6)
put('RING_ROAD',{'half':v2(425,205),'radius':RING_RADIUS,'width':10.0})
for z in [-190,190]: road('Gate Road',(-490,z),(-425,z),10.)
road('Highway',(-482,-245),(-482,245),10.)
# Session 60 road plan (docs/road_plan_2026-11-05.svg). The ring road is the only main road:
# it meets the two gates, the bus loop and the stables car park, nothing else.
rounded('Bus Loop',[(-332,-205),(-332,-160),(-302,-160),(-302,-205)],7.,12.)
put('BUS_LOOP',{'entry':v2(-332,-205),'exit':v2(-302,-205),'bay':v3(-332,0,-186),
 'points':[v3(x,0,z) for x,z in [(-332,-205),(-332,-186),(-332,-170),(-328,-162),(-317,-159),(-306,-162),(-302,-170),(-302,-205)]]})
road('Stables Car Park Road',(-144.5,205),(-144.5,196),8.)
# The inside roads: one connected network with rounded corners and no dead ends.
road('Spine Road',(-330,0),(398,0),6.)
rounded('Spine Loop',[(-125.6,-55.6),(-113,-40),(398,-40),(398,35),(-142,35),(-172,20),(-352,20),(-352,0),(-330,0)],6.)
rounded('Institute Back Road',[(-141,-63),(-290,-63),(-290,0)],6.)
rounded('Plaza Road',[(-132,-71),(-132,-126),(-152,-126)],6.,16.)
roundabouts=[{'centre':v2(-132,-62),'radius':9.0,'island':5.6}]
for i in range(24):  # the roundabout ring, 24 short pieces (Session 61: was 10, now a smooth circle)
    a0=2*math.pi*i/24; a1=2*math.pi*(i+1)/24
    road('Institute Roundabout',(round(-132+9*math.cos(a0),2),round(-62+9*math.sin(a0),2)),(round(-132+9*math.cos(a1),2),round(-62+9*math.sin(a1),2)),6.)
put('ROUNDABOUTS',roundabouts)
# Session 62: the Domes Path is gone; the spine road's north red track links the domes now.
# Session 52 (looks pass): the C Institute faces the spine, so its path comes up from the
# spine road along the front and turns in at the door.
road('Institute Access',(-186,0),(-186,-33),5.)
road('Institute Door',(-186,-33),(-197,-33),5.)
homes=[]; plazas=[]; paving=[]; bollards=[]; cats=[]; kids=[]; gardeners=[]; plays=[]; works=[]
for n,cx,cz in clusters:
    cluster=f'C{n}'; number=1
    # Four joined double rows; the 13/12 pattern yields exactly 100 homes.
    for row,count in enumerate([13,12,13,12]):
        rx=cx-45+row*30
        for side in [-1,1]:
            for index in range(count):
                z=cz-6.5-(count//2-1-index)*9 if index<count//2 else cz+6.5+(index-count//2)*9
                kind='signature' if number in [1,100] else 'garden' if number in [13,14,26,27,50,51,75,76] else 'courtyard'
                homes.append({'number':n*100+number,'house':number,'cluster':cluster,'address':f'Villa {number}, Cluster {n}',
                    'map_address':f'C{n} · Villa {number}','kind':kind,'row':f'{cluster}_R{row+1}','row_mode':True,
                    'position':v3(rx+side*4,0,z),'facing':side*90.0,'size':v3(9,8.5,8),
                    'approach':v3(rx+side*12,0,z)})
                number+=1
    assert number==101
    for offset in [-60,-30,0,30,60]:
        x=cx+offset
        back=cz-63 if cz<0 else cz+69; front=cz+79 if cz<0 else cz-79
        road(cluster+' Lane',(x,back),(x,front),6.)
        for dx in [-2,2]: bollards.append(v2(x+dx,cz+(74 if cz<0 else -74)))
    for z in [cz-63,cz+79] if cz<0 else [cz-79,cz+69]: road(cluster+' Lane',(cx-60,z),(cx+60,z),6.)
    road(cluster+' Link',(cx,cz+(79 if cz<0 else -79)),(cx,-40 if cz<0 else 35),6.)
    # A cross alley between the halves of each row, not through a home.
    z=cz+(68 if cz<0 else -68)
    road(cluster+' Alley',(cx-60,z),(cx+60,z),4.)
    road(cluster+' Cross Row Alley',(cx-60,cz),(cx+60,cz),3.)
    paving.append(rect(cx-65,cz+(65 if cz<0 else -75),130,10))
    pz=cz+(70 if cz<0 else -70)
    plazas.append({'cluster':cluster,'tower':v3(cx-48,0,pz),'playground':v3(cx+45,0,pz),'benches':[{'position':v3(cx+20,0,pz),'facing':0.0}]})
    cats.append({'area':rect(cx+27,pz-2,5,4),'colour':colour(.8,.55,.3),'collection_id':f'cat_{n}','collection_name':['Mango','Mishmish','Shadow','Pearl','Biscuit'][n-1]})
    kids.append({'from':v3(cx-15,0,cz+79),'to':v3(cx+15,0,cz+79),'shirt':colour(.2,.45+.05*n,.8)})
    gardeners.append({'position':v3(cx+52,0,pz-3),'facing':-90.0,'level':1})
    plays.append({'points':[v3(cx+40,0,pz-2),v3(cx+50,0,pz-2)],'level':0})
    works.append({'name':cluster+' Lane','centre':v2(cx+30,cz+30),'along':'z','width':6.,'length':10.})
put('ROADS',roads);put('PAVED_AREAS',paving);put('BOLLARDS',bollards)
parking=[(-92,-199,42,135),(119,-196,14,132),(270,-196,12,132),(-25,52,23,135),(152,52,60,135),(380,50,32,145),(-165,146,24,50)]
put('PARKING_AREAS',[rect(*r) for r in parking])
put('PLOTS',[{'name':'Fair Grade International School','area':rect(-425,35,120,160),'colour':colour(.95,.85,.8)},
 {'name':'C Institute','area':rect(-278,-58,126,48),'colour':colour(.65,.82,.93)},
 {'name':'Mosque','area':rect(-422,-203,70,105),'colour':colour(.93,.92,.88)},
 {'name':'Stables','area':rect(-282,165,115,35),'colour':colour(.86,.75,.55)},
 {'name':'Jumping Arena','area':rect(-282,65,115,88),'colour':colour(.82,.7,.5)},
 {'name':'Building site','area':rect(-135,55,110,135),'colour':colour(.8,.78,.74)}])
put('WELCOME_SIGN',{'name':'Welcome to Wahat Al Shams','arabic':'أهلاً بكم في واحة الشمس','position':v3(-421,0,-180),'facing':-90.0})
put('SPINE_DOMES',[v3(x,0,-20) for x in [-110,-20,70,160,250,340]])
# Session 62: the hills moved 4 m south and stay flat near the road, so they don't cover the red track.
put('HILLS',[{'position':v3(x,0,z),'height':h,'clear':v2(8.5,10.5)} for x,z,h in [(20,12,.8),(65,12,1.1),(160,12,.6),(315,12,1.2)]])
put('LAP_POOL',rect(140,13,42,9))
put('DOME_RADIUS',7.0);put('FARM_BEDS',[rect(-115,13,35,8),rect(-40,13,35,8),rect(200,13,35,8)])
put('BEEHIVES',rect(360,13,16,8));put('DONKEY_PEN',{'area':rect(245,12,44,10),'donkeys':2})
put('BASKETBALL_COURT',rect(-145,-33,24,12));put('PLAYGROUND',rect(-70,-33,24,12));put('MINI_PLAZAS',plazas)
put('SCHOOL',{'name':'Fair Grade International School','arabic':'مدرسة فير غريد الدولية','area':rect(-425,35,120,160),'gate_x':-365.,'gate_width':8.,'building':{'position':v3(-365,0,155),'size':v3(100,14,50)}})
put('MOSQUE',{'name':'Wahat Al Shams Mosque','arabic':'مسجد واحة الشمس','position':v3(-387,0,-150),'facing':90.,'size':v3(54,15,60)})
put('BUS_STATION',{'position':v3(-310,0,-174),'area':rect(-336,-202,52,52),'name':'Wahat Bus Station','arabic':'محطة حافلات الواحة'})
put('INSTITUTE',{'position':v3(-215,0,-33),'size':v3(46,14,36),'facing':90.,'name':'C Institute','arabic':'معهد سي'})
put('GYM',{'position':v3(115,0,22),'size':v3(36,8,22),'facing':180.,'name':'Wahat Gym','arabic':'نادي الواحة الرياضي'})
put('COMMUNITY_POOL',rect(190,-30,50,24));put('JUMPING_ARENA',rect(-282,65,115,88))
put('STABLES',{'name':'Wahat Stables','arabic':'إسطبلات الواحة','block':{'position':v3(-224,0,174),'size':v3(100,5,14)},'paddock':rect(-280,157,110,9),'horses':4})
put('BUILDING_SITE',{'area':rect(-135,55,110,135),'crane':v3(-80,0,120),'sign':{'name':'Phase 2 coming soon','arabic':'المرحلة الثانية قريباً','position':v3(-140,0,110),'facing':-90.}})
put('BUILDING_SITES',[rect(-135,55,110,135),rect(217,56,16,132),rect(-275,-86,105,18),rect(-301,50,15,125),rect(-413,-89,100,76)])  # Session 62: the last one ends 13 m north of the spine road
put('CLUSTER_NAMES',{f'C{i}':'المجموعة '+a for i,a in enumerate('١٢٣٤٥',1)})
put('TUTORIAL_ORDER',{'restaurant':'pizza','villa':101})
put('RESTAURANT_SIZE',v3(18,8,16))
shops=[('pizza','1000 Pizza','١٠٠٠ بيتزا','pizza'),('gelato','Brain Freeze Gelato','برين فريز جيلاتو','ice cream'),('boba','Spill the Tea','سبيل ذا تي','bubble tea'),('shawarma','Shawarma Supreme','شاورما سوبريم','shawarma'),('bakery','Bread & Zaatar','خبز وزعتر','cake'),('market','Grand Groceries','جراند جروسريز','groceries'),('thai','Tok Tok Thai','توك توك تاي','pad thai'),('sushi','Sushi You','سوشي يو','sushi'),('tacos','Mario Bonito','ماريو بونيتو','tacos'),('burger','Burgerology','برجرولوجي','burgers')]
restaurants=[]
for i,(id,name,arabic,food) in enumerate(shops):
    x=-252+(i%5)*26; z=-195 if i<5 else -95; facing=0. if i<5 else 180.
    item={'id':id,'name':name,'arabic':arabic,'food':food,'colour':colour(.35+(i%3)*.2,.3+(i%2)*.15,.3+(i%4)*.1),'position':v3(x,0,z),'facing':facing,'interior':True,'venue_type':id}
    if id=='boba':item['foods']=['bubble tea','coffee']
    if id=='bakery':item['foods']=['cake','manakish']
    restaurants.append(item)
restaurants.append({'id':'farm','name':'Wahat Farm Stall','arabic':'كشك مزرعة الواحة','food':'farm juice','foods':['farm juice','salad box'],'colour':colour(.35,.65,.25),'position':v3(-20,0,18),'facing':180.,'style':'stall','size':v3(9,4,6)})
# Session 69: the beekeeper's stall beside the hives (BEEHIVES), honey jars and wax candles.
restaurants.append({'id':'honey','name':'Wahat Bee Farm','arabic':'مزرعة نحل الواحة','food':'honey jars','foods':['honey jars','wax candles'],'colour':colour(.9,.62,.12),'position':v3(352,0,18),'facing':180.,'style':'stall','goods':'honey','size':v3(8,4,6)})
put('RESTAURANTS',restaurants)
put('SHOPS',[{'id':'bikes','name':'Pedal Point Bikes','arabic':'بيدال بوينت','position':v3(-275,0,-145),'facing':90.,'size':v3(20,8,18)}, {'id':'clothes','name':'Dune Drip','arabic':'ديون دريب','position':v3(-125,0,-145),'facing':-90.,'size':v3(20,8,18)}])
put('VILLA_SIZE',v3(9,8.5,8))
homes += [
 {'number':901,'house':0,'cluster':'','address':'Fair Grade School · Gate','map_address':'School Gate','kind':'spot','look':'booth','position':v3(-365,0,32),'facing':180.,'size':v3(4,3,4),'who':'teacher'},
 {'number':902,'house':0,'cluster':'','address':'Wahat Stables · Office','map_address':'Stables Office','kind':'spot','position':v3(-224,0,190),'facing':0.,'size':v3(7,4,6),'who':'groom'},
 {'number':903,'house':0,'cluster':'','address':'C Institute · Reception','map_address':'C Institute','kind':'spot','position':v3(-215,0,-33),'facing':90.,'size':v3(46,14,36),'interior':True,'who':'staff'},
 {'number':904,'house':0,'cluster':'','address':'Wahat Gym · Reception','map_address':'Gym','kind':'spot','position':v3(115,0,22),'facing':180.,'size':v3(36,8,22),'interior':True,'who':'gym_goer'},
]
put('VILLAS',homes)
put('REGULARS',[{'id':'mariam','name':'Auntie Mariam','villa':207,'shop':'boba','food':'bubble tea','who':'resident','look':1},{'id':'rashid','name':'Mr Rashid','villa':503,'shop':'shawarma','food':'shawarma','who':'resident','look':0},{'id':'dana','name':'Ms Dana','villa':901,'shop':'bakery','food':'cake','who':'teacher','look':-1},{'id':'hamdan','name':'Hamdan','villa':902,'shop':'farm','food':'farm juice','who':'groom','look':-1}])
# Session 62: the spine road's palms stand in the planters (z +-4), all along the road.
palms=[v3(x,0,z) for z in [-4,4] for x in range(-310,381,45)] +[v3(-210,-.45,-155),v3(-190,-.45,-155),v3(-210,-.45,-135),v3(-190,-.45,-135)]
# Session 62: the spine road's cross-section, both sides: asphalt, a planter (kerb, grass,
# shrubs) and a raised red walking track. Gaps: where a road joins (side -1 north, 1 south,
# 0 both) the planter and track stop; at a path the planter becomes a marked crossing.
put('SPINE_TRACKS',{'from_x':-334.0,'to_x':390.0,'road_half':3.0,'planter':2.0,'track':2.5,
 'road_gaps':[[-290.0,-1,6.0]],
 'path_gaps':[[-186.0,-1,3.0]]+[[x,0,1.6] for x in [-240.0,-145.0,-60.0,20.0,110.0,200.0,290.0,345.0]]})
# Session 63: no bare sand. Sand stays only where the horses ride (the stables, the jumping
# arena and the horse track); GroundType uses these for the tyre dust.
put('SAND_AREAS',[rect(-282,65,115,88),rect(-282,157,115,43)])
put('EDGE_GREENERY',{'half':v2(433,213),'radius':20.0,'width':6.0,'spacing':9.0})
put('PALM_TREES',palms);put('PARKED_CAR_SIZE',v3(1.9,1.5,4.3))
put('PARKED_CARS',[{'position':v3(x+3,0,z+8+k*9),'facing':90.,'bay':True} for x,z,w,d in parking[:6] for k in range(8)]
 +[{'position':v3(x,0,30),'facing':0.,'bay':True} for x in [-412,-403,-394,-385,-376,-354,-345,-336,-327,-318]])
put('SCHOOL_PARKING',rect(-417,25,104,10))
put('SPEED_BUMP_SIZE',v3(10,.12,.5))
put('SPEED_BUMPS',[{'position':v3(x,0,z),'facing':90.} for z in [-205,205] for x in [-180,50,300]]+[{'position':v3(x,0,z),'facing':0.} for x in [-425,425] for z in [-80,80]]
 # Session 61: narrower bumps on the inside roads (spine loop north and south, spine road).
 +[{'position':v3(x,0,z),'facing':90.,'size':v3(6,.12,.5)} for x,z in [(-20,-40),(280,-40),(-60,35),(260,35),(-250,0),(150,0)]])
put('CATS',cats);put('SCOOTER_KIDS',kids)
put('BUGGIES',[{'points':[v3(cx-60,0,cz),v3(cx+(30 if n==3 else 60),0,cz),v3(cx+(30 if n==3 else 60),0,-189 if cz<0 else 189)],'colour':colour(.85,.85,.76),'level':(n-1)%3} for n,cx,cz in clusters]+[{'points':[v3(-140,0,-1),v3(410,0,-1)],'colour':colour(.3,.5,.5),'level':1}])
put('HORSE_RIDERS',[{'points':[v3(x,0,z) for x,z in rounded_loop(450,230,37)],'loop':True,'colour':colour(.45,.28,.15),'level':0,'collection_id':'horse_sultan','collection_name':'Sultan'},{'points':[v3(x,0,z) for x,z in rounded_loop(450,230,37,reverse=True)],'loop':True,'colour':colour(.85,.82,.78),'level':1,'collection_id':'horse_noor','collection_name':'Noor'}])
put('PEOPLE_ROUTES',[{'points':[v3(x,0,z) for x,z in rounded_loop(438,218,25)],'loop':True,'jog':True,'look':2,'level':0}]+[{'points':[v3(-326,0,z),v3(386,0,z)],'jog':jog,'look':i,'level':i%3} for i,(z,jog) in enumerate([(-6.6,True),(-5.9,False),(6.6,True),(5.9,False)])])
put('GARDENERS',gardeners);put('PLAY_KIDS',plays)
put('DUCKS',[{'from_x':x,'to_x':x+65,'side':.4 if i%2 else -.4,'level':i%3} for i,x in enumerate([-100,30,160,290])])
put('BIRD_FLOCKS',[{'centre':v3(x,30,z),'radius':r,'birds':4,'level':i} for i,(x,z,r) in enumerate([(-180,-100,70),(180,80,90),(0,0,160)])])
works += [{'name':'Ring Road '+name,'centre':v2(x,z),'along':along,'width':10.,'length':12.} for name,x,z,along in [('north',260,-205,'x'),('east',425,-90,'z'),('south',-200,205,'x'),('west',-425,-60,'z')]]
put('ROAD_WORKS',works)
put('HORSE_CROSSINGS',[{'name':'the stables yard','from':v3(-244,0,184),'to':v3(-244,0,205)},{'name':'the south ring road','from':v3(-170,0,192),'to':v3(-170,0,235)}])

lines=['class_name WahatAlShams','## Real-size Wahat Al Shams: generated by tools/build_wahat_data.py.','## Coordinates in metres; stable IDs and explicit human addresses are separate.','']
for name,value in constants.items():
    if isinstance(value,list):
        lines.append(f'const {name} := [')
        lines += ['\t'+gd(item)+',' for item in value]
        lines.append(']')
    else:lines.append(f'const {name} := '+gd(value))
    lines.append('')
(ROOT/'data/wahat_al_shams.gd').write_text('\n'.join(lines).rstrip()+'\n')
assert len([v for v in homes if v['kind']!='spot'])==500
assert len({v['number'] for v in homes})==504
print('Generated 500 homes, 4 venues, 12 pickups and',len(roads),'road/path segments')
