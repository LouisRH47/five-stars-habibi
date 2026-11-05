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
put('START',{'position':v3(-296,0,-172),'facing':-90.0})
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
put('PLAZA',{'centre':v2(-200,-145),'radius':50.0,'sunken_radius':20.0,'floor_radius':15.0,'depth':0.45,'steps':3,'fountain_radius':2.8,
 # Session 77: one square paved floor from the bike shop (x -284) to Dune Drip (x -134) and from
 # the north restaurant row (front z -187) to the south row (front z -103), with a round hole
 # for the sunken square. The apron goes round Dune Drip to the buggy park behind it, so its
 # north and south strips are the footpaths from the buggy park into the Plaza.
 'floor':rect(-287,-191,153,92),'aprons':[rect(-134,-159,21,28)]})
put('PLAZA_SAILS',[[v3(-224,0,-157),v3(-200,0,-170),v3(-176,0,-157)],[v3(-176,0,-133),v3(-200,0,-120),v3(-224,0,-133)]])
put('PLAZA_BENCHES',[{'position':v3(-200,-.45,-155),'facing':0.0},{'position':v3(-200,-.45,-135),'facing':180.0},{'position':v3(-190,-.45,-145),'facing':-90.0}])
put('SPINE',rect(-145,-35,560,70)); put('STREAM',{'z':25.0,'from_x':-135.0,'to_x':405.0,'width':3.0,'gaps':[v2(93,137)]})  # gaps: under the gym
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
# Session 76: the gate roads start at the highway's middle (a T junction with curved corners);
# they used to poke 8 m out past it and stop.
for z in [-190,190]: road('Gate Road',(-482,z),(-425,z),10.)
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
for i in range(72):  # the roundabout ring in short pieces (Session 76: 72, so its kerb is a true circle)
    a0=2*math.pi*i/72; a1=2*math.pi*(i+1)/72
    road('Institute Roundabout',(round(-132+9*math.cos(a0),2),round(-62+9*math.sin(a0),2)),(round(-132+9*math.cos(a1),2),round(-62+9*math.sin(a1),2)),6.)
put('ROUNDABOUTS',roundabouts)
# Session 62: the Domes Path is gone; the spine road's north red track links the domes now.
# Session 52 (looks pass): the C Institute faces the spine, so its path comes up from the
# spine road along the front and turns in at the door.
# Session 76: the access road is one smooth curve from the spine road up to the door (it
# leaves the spine heading north and arrives at the door heading west), not two straights.
def bezier(p0,p1,p2,p3,steps):
    return [tuple(round((1-t)**3*p0[c]+3*(1-t)**2*t*p1[c]+3*(1-t)*t*t*p2[c]+t**3*p3[c],2) for c in (0,1))
            for t in [j/steps for j in range(steps+1)]]
access=bezier((-186,0),(-186,-24),(-188,-33),(-197,-33),12)
for a,b in zip(access,access[1:]): road('Institute Access',a,b,5.)
# Session 76: where each cluster's front and back cross roads are. The south clusters' front
# road is 1 m further from the spine loop than before, so both sides have the same 1 m kerbed
# island between the front road and the spine loop (it used to touch the loop's edge).
def cluster_front(cz): return cz+79 if cz<0 else cz-78
def cluster_back(cz): return cz-63 if cz<0 else cz+69
LANE_CORNER=6.0   # curved inside corner where a lane (or the spine road) meets a road
ROAD_CORNER=10.0  # curved inside corner where two bigger roads meet
LANE_LOOP_RADIUS=9.0  # middle line; the inside corner of the 6 m lane is then about 6 m round
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
    # Session 76: the two outer lanes and the front and back cross roads are one closed
    # loop with rounded corners (inside corner radius about 6 m), starting and ending in the
    # middle of the back road so it closes on a straight. The three middle lanes join it.
    back=cluster_back(cz); front=cluster_front(cz)
    rounded(cluster+' Lane',[(cx,back),(cx+60,back),(cx+60,front),(cx-60,front),(cx-60,back),(cx,back)],6.,LANE_LOOP_RADIUS,6)
    for offset in [-30,0,30]:
        x=cx+offset
        road(cluster+' Lane',(x,back),(x,front),6.)
        for dx in [-2,2]: bollards.append(v2(x+dx,cz+(74 if cz<0 else -74)))
    road(cluster+' Link',(cx,front),(cx,-40 if cz<0 else 35),6.)
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
# PARKING_AREAS (the car parks off the ring road) are made by fix_pass_car_parks() below (Session 79).
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
put('COMMUNITY_POOL',rect(190,-32,50,20));put('JUMPING_ARENA',rect(-282,65,115,88))  # Session 65: the pool is off the red track, inside its fence
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
# Session 76: road gaps are [x, side, planter half gap, track half gap]: the planter stops
# where the road's curved corner starts (3 m road half + the 6 m corner), and the red track
# stops where it meets that curve. The tracks end where the east junction's corner starts.
put('ROAD_CORNERS',{'lane':LANE_CORNER,'road':ROAD_CORNER,'lane_roads':['Lane','Link','Spine Road','Car Park','Stables']})
put('SPINE_TRACKS',{'from_x':-334.0,'to_x':398.0-3.0-LANE_CORNER,'road_half':3.0,'planter':2.0,'track':2.5,
 'road_gaps':[[-290.0,-1,3.0+LANE_CORNER,3.0+LANE_CORNER-math.sqrt(LANE_CORNER**2-(LANE_CORNER-2.0)**2)+0.1]],
 'path_gaps':[[-186.0,-1,3.0]]+[[x,0,3.0] for x in [-240.0,-145.0,-60.0,20.0,115.0,200.0,290.0,345.0]]})
# Session 63: no bare sand. Sand stays only where the horses ride (the stables, the jumping
# arena and the horse track); GroundType uses these for the tyre dust.
put('SAND_AREAS',[rect(-282,65,115,88),rect(-282,157,115,43)])
put('EDGE_GREENERY',{'half':v2(433,213),'radius':20.0,'width':6.0,'spacing':9.0})
put('PALM_TREES',palms);put('PARKED_CAR_SIZE',v3(1.9,1.5,4.3))
# PARKED_CARS and SCHOOL_PARKING are made by fix_pass_car_parks() below (Session 79).
# --- World polish pass Sessions 64 to 66 (signs wave) -------------------------------------
# Session 64's stables car park bays are now part of the Session 79 layout (fix_pass_car_parks).
# Session 64: the bus station platform island inside the loop. Two shelters face the bay
# lane (west, facing -90); people wait in front of them and board at the bus door.
put('BUS_PLATFORM',{'area':rect(-328.1,-199.6,22.2,28.4),'shelters':[v3(-325.4,0,-191.6),v3(-325.4,0,-180.4)],
 'facing':-90.,'door':v3(-328.7,0,-183.4),'arrive':v3(-316,0,-198.5),
 'waiting':[v3(-327.4,0,z) for z in [-194.2,-190.4,-186.9,-178.6,-176.2]]})
# Session 65: cluster entrances. One green cluster sign, one police sign and one STOP sign
# where each cluster's middle lane meets its front road (beside the lane, never in it).
# out: +1 when the spine is to the south (+z) of the cluster. Facing: 0 = the board's front
# points +z. The bins stand at the back, on the far side of the back cross road.
entrances=[]
for n,cx,cz in clusters:
    out=1 if cz<0 else -1
    back=cz-63 if cz<0 else cz+69
    # Riders come in heading -out; villas 1-50 are west of the middle lane (x < cx).
    rows=[['Villa 1–50','فيلا ١–٥٠'],['Villa 51–100','فيلا ٥١–١٠٠']]
    front=cluster_front(cz)
    entrances.append({'cluster':f'C{n}','lane_x':float(cx),'out':out,'front_z':float(front),
        'sign':v3(cx+5.0*out,0,front-5.6*out),'sign_facing':0. if out>0 else 180.,
        'police':v3(cx-5.6*out,0,front-7.4*out),'police_facing':0. if out>0 else 180.,
        'stop':v3(cx-4.3*out,0,front-3.8*out),'stop_facing':180. if out>0 else 0.,
        'left':rows[0] if out>0 else rows[1],'right':rows[1] if out>0 else rows[0],
        'bins':v3(cx-8,0,back-4.6*out)})
put('CLUSTER_ENTRANCES',entrances)
# A few police signs beside the spine's red tracks, just off the park side of the track.
put('POLICE_SIGNS',[{'position':v3(x,0,z),'facing':0. if z<0 else 180.} for x,z in [(-100,-8.8),(150,-8.8),(-200,8.8),(60,8.8),(320,8.8)]])
# Big end houses: a larger house (same kit) at a row end where 10 m of ground is free
# before the next road (decoration, not addresses: all 500 homes stay as they are).
end_houses=[]
for n,cx,cz in clusters:
    front=cluster_front(cz); back=cluster_back(cz); alley=cz+(68 if cz<0 else -68)
    edges=[(front,3.),(back,3.),(alley,2.)]
    for row,count in enumerate([13,12,13,12]):
        rx=cx-45+row*30
        ends={-1:cz-56.,1:cz+6.5+(count-count//2-1)*9+4.5}
        for d,edge in ends.items():
            beyond=[z-d*w for z,w in edges if (z-edge)*d>0]
            free=min(abs(b-edge) for b in beyond)
            if free<9.8: continue
            for side in [-1,1]:
                end_houses.append({'cluster':f'C{n}','number':9000+n*100+len(end_houses),'position':v3(rx+side*4.2,0,edge+d*4.9),
                    'facing':side*90.,'size':v3(9.6,8.5,8.4),'kind':'courtyard','row_mode':True,'house':0})
put('END_HOUSES',end_houses)
# Session 65: the community pool is fenced. Its gate is on the south side, where the
# crossing from the spine road's red track comes in (x 200), and the pool sign stands
# outside the fence beside the gate, facing the track. The sunbeds are along the north side.
put('POOL_GATE',{'fence':rect(187.6,-35.4,54.8,25.2),'gate_x':200.,'gate_width':3.,'sign':v3(203.6,0,-9.3),'facing':0.})
# Session 66: Majlis Gardens, the strip of park between the C1-west car park (x -92..-50)
# and Cluster 1 (its paving starts at x -17). A fountain on a round paved plaza, palms, a
# shaded majlis, benches, a community garden bed and curving paver paths that join the
# cluster's alleys and back road, the car park and the spine loop road.
def smooth(ctrl,steps=6):
    """Catmull-Rom curve through the control points, as short straight pieces."""
    pts=[ctrl[0]]+list(ctrl)+[ctrl[-1]]; out=[]
    for k in range(1,len(pts)-2):
        p0,p1,p2,p3=pts[k-1],pts[k],pts[k+1],pts[k+2]
        for j in range(steps):
            t=j/steps
            out.append(tuple(round(0.5*((2*p1[c])+(-p0[c]+p2[c])*t+(2*p0[c]-5*p1[c]+4*p2[c]-p3[c])*t*t+(-p0[c]+3*p1[c]-3*p2[c]+p3[c])*t**3),2) for c in (0,1)))
    out.append(ctrl[-1])
    return [v2(x,z) for x,z in out]
mx,mz=-33.5,-117.0  # the fountain
majlis_paths=[
 smooth([(-31,-43.5),(-29,-60),(-37,-78),(-31,-96),(mx,mz+5.5)]),          # south: from the spine loop road
 smooth([(mx,mz-5.5),(-38,-134),(-30,-152),(-36,-170),(-27,-178),(-14.5,-177)]),  # north: to Cluster 1's west lane (Session 76: the lane's corner is round now)
 smooth([(mx+5.5,mz-1),(-23,-121),(-14.5,-126)]),                       # east: the C1 cross row alley
 smooth([(mx-5.5,mz),(-44,-114),(-50.5,-112)]),                          # west: the car park
]
def on_path(path,z):
    """The point of a path (a list of v2 strings) nearest to this z, as (x, z)."""
    pts=[tuple(float(c) for c in str(p)[8:-1].split(', ')) for p in path]
    return min(pts,key=lambda q:abs(q[1]-z))
majlis_paths.append(smooth([on_path(majlis_paths[0],-62),(-22,-59),(-14.5,-58)]))      # to the C1 alley
majlis_paths.append(smooth([on_path(majlis_paths[1],-158),(-42,-156),(-50.5,-152)]))  # to the car park's north end
bench_ring=[{'position':v3(round(mx+7.4*math.cos(math.radians(a)),2),0,round(mz+7.4*math.sin(math.radians(a)),2)),
 'facing':round(math.degrees(math.atan2(-math.cos(math.radians(a)),-math.sin(math.radians(a)))),1)} for a in [40,140,220,300]]
put('MAJLIS_GARDENS',{'area':rect(-48,-186,29,138),'name':'Majlis Gardens','arabic':'حدائق المجلس',
 'fountain':v3(mx,0,mz),'plaza_radius':6.5,'path_width':2.4,'paths':majlis_paths,
 'benches':bench_ring+[{'position':v3(-25.5,0,-84),'facing':-90.},{'position':v3(-41.5,0,-140),'facing':90.}],
 'palms':[v3(round(mx+10*math.cos(math.radians(a)),2),0,round(mz+10*math.sin(math.radians(a)),2)) for a in [45,135,225,315]]+[v3(-43,0,-70),v3(-23,0,-100),v3(-44,0,-130),v3(-22,0,-165),v3(-42,0,-180)],
 'majlis':v3(-41,0,-92),'bed':rect(-45,-178,9,12),'sign':v3(-26.5,0,-51),'sign_facing':0.,
 'walk':[v3(x,0,z) for x,z in [(-30.5,-50),(-31,-96),(mx,mz+7),(mx+7,mz),(mx,mz-7),(-30,-152),(-27,-178),(-30,-152),(mx,mz-7),(mx-7,mz),(mx,mz+7),(-31,-96)]]})
# Session 76: kerb gaps where paths that aren't in ROADS meet a road (RoadMesh reads this list;
# car park entrances can go in CAR_PARK_ENTRANCES the same way).
put('KERB_GAPS',[{'at':v2(-31,-43.5),'half':1.5,'kind':'path'},{'at':v2(-14.5,-177),'half':1.5,'kind':'path'}])
# Session 66: the phase 3 building site south of the mosque, dressed like phase 2.
put('PHASE3_SITE',{'area':rect(-413,-89,100,76),'crane':v3(-372,0,-55),'sign':{'name':'Phase 3 coming soon','arabic':'المرحلة الثالثة قريباً','position':v3(-363,0,-12.2),'facing':0.}})
put('SPEED_BUMP_SIZE',v3(10,.12,.5))
# Session 75: speed bumps only on the ring road (the inside roads' bumps are gone).
put('SPEED_BUMPS',[{'position':v3(x,0,z),'facing':90.} for z in [-205,205] for x in [-180,50,300]]+[{'position':v3(x,0,z),'facing':0.} for x in [-425,425] for z in [-80,80]])
put('CATS',cats);put('SCOOTER_KIDS',kids)
# Session 75: golf buggies only drive on the roads. Each route is found on the road network
# (the asphalt ROADS pieces, joined where they meet) through a few waypoints, with its turns
# rounded. 'points' is the road's middle line: the buggy keeps 'lane' metres to the right of
# it (its side of the yellow line). It slows down near the 'slow' spots (junctions and the
# roundabout).
NO_BUGGY=['Ring Road','Gate Road','Highway','Bus Loop','Stables Car Park Road']
ONE_WAY={'Institute Roundabout':-1}
def road_graph():
    pieces=[r for r in roads if r['width']>=6 and r['name'] not in NO_BUGGY]
    pts=lambda r:(tuple(float(c) for c in str(r['from'])[8:-1].split(', ')),tuple(float(c) for c in str(r['to'])[8:-1].split(', ')))
    segs=[(pts(r),r['name']) for r in pieces]
    # Split a piece where another piece's end lands in its middle (a T junction).
    ends={q for (a,b),_ in segs for q in (a,b)}
    split=[]
    for (a,b),name in segs:
        cuts=[a,b]
        for q in ends:
            ab=(b[0]-a[0],b[1]-a[1]); L=math.hypot(*ab)
            t=((q[0]-a[0])*ab[0]+(q[1]-a[1])*ab[1])/(L*L)
            if 0.001<t<0.999 and math.dist(q,(a[0]+ab[0]*t,a[1]+ab[1]*t))<0.25: cuts.append(q)  # 0.25: the roundabout is short straight bits
        cuts.sort(key=lambda q:math.dist(a,q))
        split += [((c,d),name) for c,d in zip(cuts,cuts[1:]) if math.dist(c,d)>0.01]
    key=lambda q:(round(q[0],1),round(q[1],1))
    graph={}
    for (a,b),name in split:
        way=ONE_WAY.get(name,0)
        if way>=0: graph.setdefault(key(a),[]).append((key(b),math.dist(a,b)))
        if way<=0: graph.setdefault(key(b),[]).append((key(a),math.dist(a,b)))
    return graph
def shortest(graph,a,b):
    import heapq
    best={a:0.0}; came={}; todo=[(0.0,a)]
    while todo:
        d,q=heapq.heappop(todo)
        if q==b: break
        if d>best[q]: continue
        for r,l in graph.get(q,[]):
            if d+l<best.get(r,1e18): best[r]=d+l; came[r]=q; heapq.heappush(todo,(d+l,r))
    path=[b]
    while path[-1]!=a: path.append(came[path[-1]])
    return path[::-1]
def nearest_node(graph,q): return min(graph,key=lambda n:math.dist(n,q))
def buggy_route(graph,via,turn=5.0):
    """A loop through the waypoints along the roads, its sharp turns rounded."""
    nodes=[nearest_node(graph,q) for q in via]
    line=[]
    for a,b in zip(nodes,nodes[1:]+nodes[:1]):
        line += shortest(graph,a,b)[:-1]
    out=[]
    for i,p1 in enumerate(line):
        p0=line[i-1]; p2=line[(i+1)%len(line)]
        d1=(p1[0]-p0[0],p1[1]-p0[1]); d2=(p2[0]-p1[0],p2[1]-p1[1])
        l1=math.hypot(*d1); l2=math.hypot(*d2)
        cross=abs(d1[0]*d2[1]-d1[1]*d2[0])/max(l1*l2,1e-9)
        if cross<0.5: out.append(p1); continue  # a gentle bend: keep the point
        k=min(turn,l1/2,l2/2)
        a=(p1[0]-d1[0]/l1*k,p1[1]-d1[1]/l1*k); b=(p1[0]+d2[0]/l2*k,p1[1]+d2[1]/l2*k)
        for j in range(5):
            t=j/4
            out.append(((1-t)**2*a[0]+2*(1-t)*t*p1[0]+t*t*b[0],(1-t)**2*a[1]+2*(1-t)*t*p1[1]+t*t*b[1]))
    clean=[out[0]]
    for q in out[1:]:
        if math.dist(q,clean[-1])>0.3: clean.append(q)
    return [v3(round(x,2),0,round(z,2)) for x,z in clean]
def junctions_on(graph,route_pts):
    """Junctions (3 or more roads meet) the route passes, for slowing down."""
    degree={}
    for q,nexts in graph.items():
        for r,_ in nexts:
            degree.setdefault(q,set()).add(r); degree.setdefault(r,set()).add(q)
    pts=[tuple(float(c) for c in str(p)[8:-1].split(', ')[::2]) for p in route_pts]
    out=[]
    for q,ns in degree.items():
        if len(ns)>=3 and min(math.dist(q,p) for p in pts)<4.0 and not any(math.dist(q,o)<6 for o in out): out.append(q)
    return out
graph=road_graph()
buggies=[]
for n,cx,cz in clusters:
    back=cluster_back(cz); front=cluster_front(cz)
    route=buggy_route(graph,[(cx+60,back),(cx+60,front),(cx-60,front),(cx-60,back)])
    slow=[{'at':v3(x,0,z),'radius':8.0} for x,z in junctions_on(graph,route)]
    buggies.append({'points':route,'loop':True,'lane':1.5,'slow':slow,'colour':colour(.85,.85,.76),'level':(n-1)%3})
# The teal buggy: east along the spine road, back west along the spine loop, round the
# roundabout and home along the road behind the C Institute.
route=buggy_route(graph,[(-290,0),(398,0),(203,-40),(-132,-71),(-141,-63),(-290,-63)])
slow=[{'at':v3(x,0,z),'radius':8.0} for x,z in junctions_on(graph,route) if math.dist((x,z),(-132,-62))>15]
slow.append({'at':v3(-132,0,-62),'radius':20.0})  # the roundabout
buggies.append({'points':route,'loop':True,'lane':1.5,'slow':slow,'colour':colour(.3,.5,.5),'level':1})
put('BUGGIES',buggies)
put('HORSE_RIDERS',[{'points':[v3(x,0,z) for x,z in rounded_loop(450,230,37)],'loop':True,'colour':colour(.45,.28,.15),'level':0,'collection_id':'horse_sultan','collection_name':'Sultan'},{'points':[v3(x,0,z) for x,z in rounded_loop(450,230,37,reverse=True)],'loop':True,'colour':colour(.85,.82,.78),'level':1,'collection_id':'horse_noor','collection_name':'Noor'}])
put('PEOPLE_ROUTES',[{'points':[v3(x,0,z) for x,z in rounded_loop(438,218,25)],'loop':True,'jog':True,'look':2,'level':0}]+[{'points':[v3(-326,0,z),v3(386,0,z)],'jog':jog,'look':i,'level':i%3} for i,(z,jog) in enumerate([(-6.6,True),(-5.9,False),(6.6,True),(5.9,False)])])
put('GARDENERS',gardeners);put('PLAY_KIDS',plays)
put('DUCKS',[{'from_x':x,'to_x':x+65,'side':.4 if i%2 else -.4,'level':i%3} for i,x in enumerate([-100,30,160,290])])
put('BIRD_FLOCKS',[{'centre':v3(x,30,z),'radius':r,'birds':4,'level':i} for i,(x,z,r) in enumerate([(-180,-100,70),(180,80,90),(0,0,160)])])
works += [{'name':'Ring Road '+name,'centre':v2(x,z),'along':along,'width':10.,'length':12.} for name,x,z,along in [('north',260,-205,'x'),('east',425,-90,'z'),('south',-200,205,'x'),('west',-425,-60,'z')]]
put('ROAD_WORKS',works)
put('HORSE_CROSSINGS',[{'name':'the stables yard','from':v3(-244,0,184),'to':v3(-244,0,205)},{'name':'the south ring road','from':v3(-170,0,192),'to':v3(-170,0,235)}])

# --- Fix pass Sessions 77 and 79 (lane R2): the buggy park and every car park -----------------
# Every car park uses one layout (car_park below), seen from the entrance: a row of bays along
# one side, two rows in the middle parked nose to nose, a row across the far end, aisles in
# between, a solar roof over every row and a car in most bays. The car parks off the ring road
# keep their entrances: the access road still leaves the ring road at the same x.
BAY_WIDTH=2.6; BAY_DEPTH=4.8; AISLE=5.7; ACCESS=6.0; EDGE=0.3
def heading(d):
    """The facing in degrees of something pointing along d = (x, z): 0 points +z (south)."""
    return round(math.degrees(math.atan2(d[0],d[1])),1)+0.0
def cut(a,b):
    """The parts of rect a (x, z, w, d) outside rect b, as up to four rects."""
    ax0,az0,ax1,az1=a[0],a[1],a[0]+a[2],a[1]+a[3]
    bx0,bz0,bx1,bz1=max(ax0,b[0]),max(az0,b[1]),min(ax1,b[0]+b[2]),min(az1,b[1]+b[3])
    if bx0>=bx1 or bz0>=bz1: return [a]
    parts=[(ax0,az0,ax1-ax0,bz0-az0),(ax0,bz1,ax1-ax0,az1-bz1),(ax0,bz0,bx0-ax0,bz1-bz0),(bx1,bz0,ax1-bx1,bz1-bz0)]
    return [tuple(round(n,2) for n in p) for p in parts if p[2]>0.05 and p[3]>0.05]
def car_park(name,corner,across,along,columns,length,gap,end_bays=-1,depth=BAY_DEPTH,clear=(),drawn=None,entrances=(),kind='cars',fill=0.8,seed=0):
    """One car park. corner: (x, z) of the corner at the entrance end where the first column
    starts. across/along: unit (x, z) steps across the columns and away from the entrance.
    columns, from the corner across: ('row', +1 or -1: noses point along +across or -across,
    roof posts?) or ('aisle', width, is it the access road?). length: metres away from the
    entrance; gap: free metres at the entrance end before the first bays. end_bays: bays in
    the row across the far end (-1 = as many as fit, 0 = none). clear: [(x, z, radius)] spots
    that must stay free. drawn: the part DecorBuilder already paves (PARKING_AREAS rect)."""
    def at(u,v): return (round(corner[0]+u*across[0]+v*along[0],2),round(corner[1]+u*across[1]+v*along[1],2))
    def free(p): return all(math.dist(p,(x,z))>r for x,z,r in clear)
    end_depth=depth if end_bays!=0 else 0.0
    v_end=length-EDGE-(end_depth+AISLE if end_depth else 0.0)
    n=int((v_end-gap)//BAY_WIDTH)
    v0=gap+((v_end-gap)-n*BAY_WIDTH)/2+BAY_WIDTH/2
    rows=[];arrows=[];u=EDGE;access_u=None;plain_u=None
    def add_row(cells,nose,posts):
        run=[]
        for p in cells+[None]:  # a spot that must stay free splits the row in two
            if p is not None and free(p): run.append(p); continue
            if run: rows.append({'bays':run,'facing':heading(nose),'depth':depth,'posts':posts})
            run=[]
    for col in columns:
        if col[0]=='row':
            nose=across if col[1]>0 else (-across[0],-across[1])
            add_row([at(u+depth/2,v0+k*BAY_WIDTH) for k in range(n)],nose,col[2])
            u+=depth
        else:
            if col[2]: access_u=u+col[1]/2
            else: plain_u=u+col[1]/2
            u+=col[1]
    width=round(u+(0.5 if columns[-1][0]=='aisle' and columns[-1][2] else EDGE if columns[-1][0]=='row' else 0.0),2)
    if end_depth:
        count=end_bays if end_bays>0 else int((width-3.2)//BAY_WIDTH)
        first=width/2-(count-1)*BAY_WIDTH/2
        add_row([at(first+k*BAY_WIDTH,length-EDGE-depth/2) for k in range(count)],along,True)
    # Painted arrows: back towards the entrance in the plain aisle, and across the far end
    # from the access road to the plain aisle (the access road gets its arrows from RoadMesh).
    back=(-along[0],-along[1])
    if plain_u is not None:
        for v in range(int(gap)+6,int(v_end)-3,18): arrows.append({'position':v2(*at(plain_u,v)),'facing':heading(back)})
        if end_depth and access_u is not None:
            way=across if plain_u>access_u else (-across[0],-across[1])
            arrows.append({'position':v2(*at((access_u+plain_u)/2,v_end+AISLE/2)),'facing':heading(way)})
    elif kind=='buggies':
        arrows.append({'position':v2(*at(access_u,gap+2)),'facing':heading(along)})
    a=at(0,0);b=at(width,length)
    area=(round(min(a[0],b[0]),2),round(min(a[1],b[1]),2),round(abs(b[0]-a[0]),2),round(abs(b[1]-a[1]),2))
    # A car in `fill` of the bays (8 in 10), picked at random but the same every time.
    bays=[(x,z,row['facing']) for row in rows for x,z in row['bays']]
    taken=set(random.Random(seed).sample(range(len(bays)),round(len(bays)*fill)))
    filled=[{'position':v3(x,0,z),'facing':f,'bay':False} for i,(x,z,f) in enumerate(bays) if i in taken]
    for row in rows: row['bays']=[v2(*p) for p in row['bays']]
    lot={'name':name,'kind':kind,'area':rect(*area),'pads':[rect(*p) for p in (cut(area,drawn) if drawn else [area])],
         'rows':rows,'arrows':arrows,'entrances':list(entrances),'access':v2(*at(access_u,0))}
    return lot,area,filled
import random
def fix_pass_car_parks():
    lots=[];parked=[];areas=[]
    def entrance(x,ring_z,lot_z,road='Ring Road'):
        """Where a car park's access road leaves a road (the kerbs leave a gap here) and where
        it reaches the car park."""
        return {'road':road,'at':v2(x,ring_z),'lot_at':v2(x,lot_z),'width':ACCESS}
    standard=[('row',-1,True),('aisle',AISLE,False),('row',1,True),('row',-1,False),('aisle',ACCESS,True)]
    beside=[('row',-1,True),('aisle',ACCESS,True),('row',1,True),('row',-1,False),('aisle',AISLE,False)]  # access next to the side row
    narrow=[('row',-1,True),('aisle',ACCESS,True)]  # C2-C3: only 15 m between the clusters
    W_STANDARD=EDGE+3*BAY_DEPTH+AISLE+ACCESS+0.5;W_BESIDE=EDGE+3*BAY_DEPTH+ACCESS+AISLE;W_NARROW=EDGE+BAY_DEPTH+ACCESS+0.5
    # (name, access road x, entrance edge z, length, layout). North car parks start 1-4 m
    # inside the ring road and run south; south ones end inside it and run north.
    specs=[('C1 West',-53.5,-199,90,'standard'),('C1-C2',129.5,-196,60,'beside'),('C2-C3',278.5,-196,60,'narrow'),
           ('C4 West',-5.5,187,60,'beside'),('C4-C5',208.5,187,60,'standard'),('C5 East',408.5,195,60,'standard'),
           ('Stables',-144.5,196,50,'standard')]
    for i,(name,xa,edge,length,style) in enumerate(specs):
        north=edge<0
        along=(0,1) if north else (0,-1)
        if style=='beside':  # side row on the east, so the far aisle is on the west
            x1=round(xa+EDGE+BAY_DEPTH+ACCESS/2,2);x0=round(x1-W_BESIDE,2);corner=(x1,edge);across=(-1,0);cols=beside
            drawn=(x0,min(edge,edge+length*along[1]),round(xa+3.5-x0,2),length)
        else:
            w=W_STANDARD if style=='standard' else W_NARROW
            x0=round(xa+3.5-w,2);corner=(x0,edge);across=(1,0);cols=standard if style=='standard' else narrow
            drawn=(x0,min(edge,edge+length*along[1]),round(w,2),length)
        areas.append(drawn)
        z0=drawn[1];z1=drawn[1]+drawn[3];end_x=drawn[0]+drawn[2]
        # Keep free: where the visiting car parks (DistrictTraffic), the pay machine and the
        # little posts by the entrance (DistrictDetail).
        clear=[(x0+4,z1-9,4.2),(x0+1,z0+2,2.2),(end_x-1,z0+4.5,2.4)]
        lot,area,cars=car_park(name,corner,across,along,cols,length,7.0 if north else 12.0,clear=clear,drawn=drawn,
            entrances=[entrance(xa,-200 if north else 200,edge)],seed=79+i)
        lots.append(lot);parked+=cars
    put('PARKING_AREAS',[rect(*a) for a in areas])
    # The school car park: west of the spine loop road's turn, in front of the school gate,
    # entered from that road. The gate and the security booth stay clear.
    # (DistrictDetail paves it as SCHOOL_PARKING, so CarParkBuilder adds no pad of its own.)
    lot,area,cars=car_park('School',(-356,35),(0,-1),(-1,0),standard,44,7.0,clear=[(-365,32,6.5),(-357.5,33,2.0)],
        drawn=(-400,8.1,44,26.9),entrances=[entrance(-352,11.6,11.6,'Spine Loop')],seed=91)
    lot['entrances'][0].update({'at':v2(-352,11.6),'lot_at':v2(-356,11.6)})
    lot['pay_machine']=v3(-357.5,0,33);lots.append(lot);parked+=cars
    put('SCHOOL_PARKING',rect(*area))
    road('School Car Park Road',(-352,11.6),(-391,11.6),ACCESS)
    # Session 79: the mosque car park, in front of the mosque (its door faces east), joined to
    # the north ring road by its own road past the front of the mosque. About 12 bays.
    lot,area,cars=car_park('Mosque',(-325.1,-148),(-1,0),(0,1),standard,25.6,7.0,end_bays=4,
        entrances=[entrance(-348.5,-200,-148)],seed=92)
    lot['pay_machine']=v3(-326,0,-146.5);lots.append(lot);parked+=cars
    put('MOSQUE_PARKING',rect(*area))
    road('Mosque Car Park Road',(-348.5,-205),(-348.5,-131.4),ACCESS)
    # Session 77: the Plaza road from the roundabout no longer stops inside the Plaza: it turns
    # east before the Plaza and ends in a small buggy park behind Dune Drip (6 bays, 2 buggies).
    roads[:]=[r for r in roads if r['name']!='Plaza Road']
    rounded('Plaza Road',[(-132,-71),(-132,-96),(-105.7,-96),(-105.7,-126)],6.,10.)
    lot,area,bays=car_park('Buggy Park',(-113,-126),(1,0),(0,-1),[('row',-1,True),('aisle',ACCESS,True),('row',1,True)],11,2.0,
        end_bays=0,depth=4.0,entrances=[{'road':'Plaza Road','at':v2(-105.7,-126),'lot_at':v2(-105.7,-126),'width':ACCESS}],kind='buggies',fill=0.0)
    lot['buggies']=[{'position':row['bays'][k],'facing':row['facing']} for row,k in [(lot['rows'][0],1),(lot['rows'][1],2)]]
    lots.append(lot)
    put('PARKING_LOTS',lots)
    put('PARKED_CARS',parked)
fix_pass_car_parks()

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
