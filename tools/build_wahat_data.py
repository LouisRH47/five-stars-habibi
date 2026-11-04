"""Generate the committed, deterministic real-size community data from its layout.

Run from any directory. Distances are metres; frontages and IDs remain stable.
The generated file is ordinary Godot constants shared by the world, map and tests.
"""
from pathlib import Path
import json

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
put('START',{'position':v3(-281,0,-168),'facing':-90.0})
put('TREE_BELT',{'inner':v2(463,243),'spacing':8.0})
put('GATES',[{'position':v3(-465,0,z),'facing':-90.0,'name':name} for z,name in [(-190,'North Checkpoint'),(190,'South Checkpoint')]])
put('HORSE_TRACK',{'half':v2(450,230),'width':5.0})
put('BIKE_TRACK',{'half':v2(438,218),'width':4.0})
put('PLAZA',{'centre':v2(-200,-145),'radius':50.0,'sunken_radius':20.0,'floor_radius':15.0,'depth':0.45,'steps':3,'fountain_radius':2.8,'core_half':26.25})  # Session 57: core_half = the paved square round the sunken square
put('PLAZA_SAILS',[[v3(-224,0,-157),v3(-200,0,-170),v3(-176,0,-157)],[v3(-176,0,-133),v3(-206,0,-121),v3(-224,0,-133)]])  # Session 57: the south post moved off the walkway from the middle passage
put('PLAZA_BENCHES',[{'position':v3(-200,-.45,-155),'facing':0.0},{'position':v3(-200,-.45,-135),'facing':180.0},{'position':v3(-190,-.45,-145),'facing':-90.0}])
put('SPINE',rect(-145,-35,560,70)); put('STREAM',{'z':25.0,'from_x':-135.0,'to_x':405.0,'width':3.0})
clusters=[(1,48,-126),(2,203,-126),(3,358,-126),(4,73,126),(5,303,126)]
put('CLUSTERS',[{'id':f'C{n}','area':rect(cx-65,cz-75,130,150),'centre':v2(cx,cz)} for n,cx,cz in clusters])
roads=[]
def road(name,a,b,width=6.0,**extra): roads.append({'name':name,'from':v2(*a),'to':v2(*b),'width':width,**extra})
for a,b in [((-425,-205),(425,-205)),((425,-205),(425,205)),((425,205),(-425,205)),((-425,205),(-425,-205))]: road('Ring Road',a,b,10.)
for z in [-190,190]: road('Gate Road',(-490,z),(-425,z),10.)
road('Highway',(-482,-245),(-482,245),10.)
road('Bus Access',(-420,-170),(-310,-170),8.)
road('Plaza Link',(-310,-170),(-280,-145),8.)
# Session 63 (Appendix D): the spine's two paths, north to south: the domes, the red walking
# track (was "Domes Path", 3 m at z -11), a kerb, a raised planted strip, a kerb, then the
# two-way buggy road (was "Spine Path"). 'kind' tells builders and buggies which is which.
road('Spine Buggy Road',(-350,0),(420,0),6.,kind='buggy_road')
road('Spine Walking Track',(-186,-6.75),(358,-6.75),3.5,kind='walk_track')
road('Western Link',(-290,-200),(-290,0),6.)
road('Plaza to C1',(-290,-40),(420,-40),6.)
road('South Spine Link',(-160,35),(420,35),6.)
road('School Road',(-420,20),(-160,20),8.)
road('School Link',(-350,0),(-350,20),6.)
# Session 52: the C Institute faces the spine (east), so its path comes up from School Road
# along the front and turns in at the door.
road('Institute Access',(-186,20),(-186,-33),5.)
road('Institute Door',(-186,-33),(-197,-33),5.)
road('Stables Road',(-320,195),(-160,195),6.)
road('Stables Link',(-160,20),(-160,200),6.)
RING_KERB=200.0; RING_EAST_KERB=420.0; RING_INNER_GAP=71.0  # the ring road's inner kerb; outer cross lane centre from the cluster centre
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
    # Session 53: the black ring road always wins. Lanes stop at its kerb (|z| = 200) instead
    # of running onto it, and the outer cross lane sits just inside the kerb, not on the road.
    inner=cz+(79 if cz<0 else -79); outer=cz+(-RING_INNER_GAP if cz<0 else RING_INNER_GAP)
    kerb=-RING_KERB if cz<0 else RING_KERB
    for offset in [-60,-30,0,30,60]:
        x=min(cx+offset,RING_EAST_KERB-4)
        road(cluster+' Lane',(x,min(inner,kerb)),(x,max(inner,kerb)),6.)
        for end in [-1,1]:
            for dx in [-2,2]: bollards.append(v2(x+dx,cz+end*74))
    for z in [inner,outer]: road(cluster+' Lane',(cx-60,z),(min(cx+60,RING_EAST_KERB-4),z),6.)
    road(cluster+' Link',(cx,inner),(cx,0),6.)
    # A cross alley between the halves of each row, not through a home.
    z=cz+(68 if cz<0 else -68)
    road(cluster+' Alley',(cx-60,z),(cx+60,z),4.)
    road(cluster+' Cross Row Alley',(cx-60,cz),(cx+60,cz),3.)
    paving.append(rect(cx-65,cz+(65 if cz<0 else -75),130,10))
    pz=cz+(70 if cz<0 else -70)
    plazas.append({'cluster':cluster,'tower':v3(cx-48,0,pz),'playground':v3(cx+45,0,pz),'benches':[{'position':v3(cx+20,0,pz),'facing':90.0}]})
    cats.append({'area':rect(cx+27,pz-2,5,4),'colour':colour(.8,.55,.3),'collection_id':f'cat_{n}','collection_name':['Mango','Mishmish','Shadow','Pearl','Biscuit'][n-1]})
    kids.append({'from':v3(cx-15,0,cz+(-71 if cz<0 else 71)),'to':v3(cx+15,0,cz+(-71 if cz<0 else 71)),'shirt':colour(.2,.45+.05*n,.8)})
    gardeners.append({'position':v3(cx+52,0,pz-3),'facing':-90.0,'level':1})
    plays.append({'points':[v3(cx+40,0,pz-2),v3(cx+50,0,pz-2)],'level':0})
    works.append({'name':cluster+' Lane','centre':v2(cx+30,cz+30),'along':'z','width':6.,'length':10.})
put('ROADS',roads);put('PAVED_AREAS',paving);put('BOLLARDS',bollards)
parking=[(-92,-199,42,135),(119,-196,14,132),(274,-196,14,132),(-25,52,23,135),(152,52,60,135),(380,50,32,145)]
# --- Session 62: car parks and kerbs (the layout maths is in tools/carpark_layout.py) ---
import sys; sys.path.insert(0,str(Path(__file__).resolve().parent))
import carpark_layout as cp
put('PARKING_AREAS_OLD',[rect(*r) for r in parking])   # before Session 62, kept for reference
parks,carpark_kerbs,carpark_gardens,carpark_palms,c45_site=cp.build_all(clusters,road)
put('PARKING_AREAS',[rect(*p['area']) for p in parks])
put('CAR_PARKS',[cp.to_data(p,rect,v3) for p in parks])
put('CARPARK_KERBS',[rect(*k) for k in carpark_kerbs])
put('CARPARK_GARDENS',[rect(*g) for g in carpark_gardens])
put('PLOTS',[{'name':'Fair Grade International School','area':rect(-425,35,120,160),'colour':colour(.95,.85,.8)},
 {'name':'C Institute','area':rect(-278,-58,126,48),'colour':colour(.65,.82,.93)},
 {'name':'Mosque','area':rect(-422,-203,70,105),'colour':colour(.93,.92,.88)},
 {'name':'Stables','area':rect(-282,165,115,35),'colour':colour(.86,.75,.55)},
 {'name':'Jumping Arena','area':rect(-282,65,115,88),'colour':colour(.82,.7,.5)},
 {'name':'Building site','area':rect(-135,55,110,135),'colour':colour(.8,.78,.74)}])
put('WELCOME_SIGN',{'name':'Welcome to Wahat Al Shams','arabic':'أهلاً بكم في واحة الشمس','position':v3(-421,0,-180),'facing':-90.0})
put('SPINE_DOMES',[v3(x,0,-20) for x in [-110,-20,70,160,250,340]])
# Session 53: hills are at most 0.5 m and keep 4 m clear of pools, beds, the gym, the farm stall and paths.
put('HILLS_OLD',[{'position':v3(x,0,13),'height':h} for x,h in [(-130,.4),(-60,.5),(32,.35),(55,.5),(330,.45),(392,.5)]])
# Session 63: 12 gentle hills, 0.25 to 0.5 m high, 10 to 18 m across ('radius' is half that),
# at least 4 m from every path, pool, bed, building, court and the stream. Session 60's two hills where the old gym
# and lap pool were (x 112 and 160) are kept, made smaller so they stay 4 m from the buggy road.
put('HILLS',[{'position':v3(x,0,z),'height':h,'radius':r} for x,z,h,r in [
    (-133,13.5,.35,6),(-60,14,.5,7),(25,15,.45,8),(52,14,.3,6),(315,13,.25,5),(334,14,.5,7),(398,13,.4,6),
    (112,13.5,.4,6),(160,14,.35,7),(-86,-23,.4,7),(17,-23,.5,9),(90,-23,.3,5)]])
# The north-east corner of the spine lawn (x 376-415, z -37 to -3) is kept free for a future car park (lead, Session 62).
# Session 63: how the spine's paths are laid out (Appendix D). The builders read the track and the
# buggy road from ROADS by these names; kerbs 0.3 m wide and 0.12 m high, the strip 1.4 m wide.
put('SPINE_PATHS',{'track':'Spine Walking Track','road':'Spine Buggy Road','kerb_width':0.3,'kerb_height':0.12,
    'strip_width':1.4,'walk_every':40.0,'dash':1.5,'gap':1.5})
# Session 60: the gym and its lap pool moved to the north side of the spine, between the domes
# at x 70 and 160: the gym's back (rounded, with the door) faces the Plaza to C1 road, its glass
# wall faces the lap pool, and the pool's gate faces the domes path. LAP_POOL is the whole fenced
# deck; the gym's glass wall closes the north side between x 103 and 127.
put('LAP_POOL',rect(100.5,-23.6,29,10.4))
put('LAP_POOL_DETAIL',{'water':rect(102.5,-22,25,7),'lanes':4,'fence':'glass','fence_height':1.2,
    'gate':v2(115,-13.2),'gate_width':1.0,'wall':[v2(103,-23.6),v2(127,-23.6)],'swimmers':3})
# Session 60: the community pool moved east, between the domes at x 250 and 340, so it no longer
# covers the domes path or the C2 link. Plot = the fence line; gate in the south fence.
put('COMMUNITY_POOL_DETAIL',{'water':rect(273,-28.5,25,12),'kids':rect(303,-28.5,8,6),'fence':'bars',
    'fence_height':1.4,'gate':v2(313,-13),'gate_width':1.0,'loungers_z':-31.8,'hut':rect(314,-35,4,3),
    'shower':v2(318.5,-29),'lifeguard':v2(285.5,-14.6),'swimmers':4,'kids_in_pool':3,'lounging':5,'deck_walkers':2})
put('DOME_RADIUS',7.0);put('FARM_BEDS',[rect(-115,13,35,8),rect(-40,13,35,8),rect(200,13,35,8)])
put('BEEHIVES',rect(360,13,16,8));put('DONKEY_PEN',{'area':rect(245,12,44,10),'donkeys':2})
put('BASKETBALL_COURT',rect(-145,-33,24,12));put('PLAYGROUND',rect(-70,-33,24,12));put('MINI_PLAZAS',plazas)
put('SCHOOL',{'name':'Fair Grade International School','arabic':'مدرسة فير غريد الدولية','area':rect(-425,35,120,160),'gate_x':-365.,'gate_width':8.,'building':{'position':v3(-365,0,155),'size':v3(100,14,50)}})
put('MOSQUE',{'name':'Wahat Al Shams Mosque','arabic':'مسجد واحة الشمس','position':v3(-387,0,-150),'facing':90.,'size':v3(54,15,60)})
put('BUS_STATION',{'position':v3(-310,0,-174),'area':rect(-336,-202,52,52),'name':'Wahat Bus Station','arabic':'محطة حافلات الواحة'})
put('INSTITUTE',{'position':v3(-215,0,-33),'size':v3(46,14,36),'facing':90.,'name':'C Institute','arabic':'معهد سي'})
GYM_AT=v3(115,0,-30.1); GYM_SIZE=v3(24,6,13)   # Session 60: smaller (was 36 x 22), pool in front
put('GYM',{'position':GYM_AT,'size':GYM_SIZE,'facing':180.,'name':'Wahat Gym','arabic':'نادي الواحة الرياضي'})
put('COMMUNITY_POOL',rect(270,-35.5,50,22.5));put('JUMPING_ARENA',rect(-282,65,115,88))
put('STABLES',{'name':'Wahat Stables','arabic':'إسطبلات الواحة','block':{'position':v3(-224,0,174),'size':v3(100,5,14)},'paddock':rect(-280,157,110,9),'horses':4})
put('BUILDING_SITE',{'area':rect(-135,55,110,135),'crane':v3(-80,0,120),'sign':{'name':'Phase 2 coming soon','arabic':'المرحلة الثانية قريباً','position':v3(-140,0,110),'facing':-90.}})
put('BUILDING_SITES',[rect(-135,55,110,135),rect(*c45_site),rect(-275,-80,105,18),rect(-301,50,15,125),rect(-413,-89,100,84)])
put('CLUSTER_NAMES',{f'C{i}':'المجموعة '+a for i,a in enumerate('١٢٣٤٥',1)})
put('TUTORIAL_ORDER',{'restaurant':'pizza','villa':101})
# Session 57: the Plaza outside (looks pass, Appendix A of docs/looks_pass_detailed_plan.md).
# Lower shops (a 12 x 10 m room, 4.5 m high) in two joined rows with flats on top, a passage
# after every second shop, and walkways, grass beds and palms round the square instead of a
# slab of concrete. PLAZA_LOOKS_PASS = False builds the old layout (the code is kept below).
PLAZA_LOOKS_PASS = True
plaza_rows = []; plaza_landscape = {}; plaza_palms = []
def hex_colour(h): return colour(*(round(int(h[k:k+2],16)/255,3) for k in (1,3,5)))
def old_restaurants():
    put('RESTAURANT_SIZE',v3(18,8,16))
    shops=[('pizza','1000 Pizza','١٠٠٠ بيتزا','pizza'),('gelato','Brain Freeze Gelato','برين فريز جيلاتو','ice cream'),('boba','Spill the Tea','سبيل ذا تي','bubble tea'),('shawarma','Shawarma Supreme','شاورما سوبريم','shawarma'),('bakery','Bread & Zaatar','خبز وزعتر','cake'),('market','Grand Groceries','جراند جروسريز','groceries'),('thai','Tok Tok Thai','توك توك تاي','pad thai'),('sushi','Sushi You','سوشي يو','sushi'),('tacos','Mario Bonito','ماريو بونيتو','tacos'),('burger','Burgerology','برجرولوجي','burgers')]
    found=[]
    for i,(id,name,arabic,food) in enumerate(shops):
        x=-252+(i%5)*26; z=-195 if i<5 else -95; facing=0. if i<5 else 180.
        item={'id':id,'name':name,'arabic':arabic,'food':food,'colour':colour(.35+(i%3)*.2,.3+(i%2)*.15,.3+(i%4)*.1),'position':v3(x,0,z),'facing':facing,'interior':True,'venue_type':id}
        if id=='boba':item['foods']=['bubble tea','coffee']
        if id=='bakery':item['foods']=['cake','manakish']
        found.append(item)
    return found, [{'id':'bikes','name':'Pedal Point Bikes','arabic':'بيدال بوينت','position':v3(-275,0,-145),'facing':90.,'size':v3(20,8,18)}, {'id':'clothes','name':'Dune Drip','arabic':'ديون دريب','position':v3(-125,0,-145),'facing':-90.,'size':v3(20,8,18)}]

ROOM=(12,4.5,10)          # Appendix B: the public room (width, height, depth)
UNIT_DEPTH=14.0           # room + a 4 m storeroom you can't enter
NORTH_FRONT=-186.0        # Appendix A says about -188; 2 m south so the back (-200) stops at the ring road's kerb
SOUTH_FRONT=-104.0        # mirrored: both fronts 41 m from the square's centre
TERRACE=5.0               # outside tables between the front and the promenade
# name, Arabic, food, brand colour (same as its logo in tools/make_logos.py)
PLACE_INFO={
 'pizza':('1000 Pizza','١٠٠٠ بيتزا','pizza','#d7263d'),
 'gelato':('Brain Freeze Gelato','برين فريز جيلاتو','ice cream','#f06fa4'),
 'boba':('Spill the Brew','سبيل ذا برو','bubble tea','#6f4e37'),   # was Spill the Tea; id stays "boba" for old saves
 'shawarma':('Shawarma Supreme','شاورما سوبريم','shawarma','#e89b2e'),
 'bakery':('Bread & Zaatar','خبز وزعتر','cake','#a8742f'),
 'market':('Grand Groceries','جراند جروسريز','groceries','#2e9e4f'),
 'thai':('Tok Tok Thai','توك توك تاي','pad thai','#7b3fa0'),
 'sushi':('Sushi You','سوشي يو','sushi','#1f3a68'),
 'tacos':('Mario Bonito','ماريو بونيتو','tacos','#ff6f59'),
 'burger':('Burgerology','برجرولوجي','burgers','#e8559a'),
 'bikes':('Pedal Point Bikes','بيدال بوينت','','#1e9a9a'),
 'clothes':('Dune Drip','ديون دريب','','#f28c28'),
 'pharmacy':('Wahat Pharmacy','صيدلية الواحة','','#2ba84a'),
}
# Appendix A: west to east. ('passage', width) is a covered walk-through.
ROW_UNITS={'north':(-240.0,NORTH_FRONT,0.0,[('pizza',12),('gelato',12),('passage',4),('boba',12),('shawarma',12),('passage',4),('bakery',12),('bikes',12)]),
           'south':(-254.0,SOUTH_FRONT,180.0,[('market',24),('passage',4),('thai',12),('sushi',12),('passage',4),('tacos',12),('burger',12),('passage',4),('clothes',12),('pharmacy',12)])}
def walk(x0,z0,x1,z1): return (x0,z0,x1,z1)
def r4(t): return rect(t[0],t[1],t[2]-t[0],t[3]-t[1])
def overlap(a,b,eps=0.01): return min(a[2],b[2])-max(a[0],b[0])>eps and min(a[3],b[3])-max(a[1],b[1])>eps
def plaza_layout():
    found=[]; shops=[]
    for row_name,(x,front,facing,units) in ROW_UNITS.items():
        side=1 if facing==0.0 else -1          # north row: fronts face +z (south), to the square
        centre_z=front-side*ROOM[2]*0.5
        row={'name':row_name.capitalize()+' row','from_x':x,'front_z':front,'facing':facing,'depth':UNIT_DEPTH,'units':[]}
        count=0
        for id,width in units:
            unit={'kind':'passage' if id=='passage' else 'scenery' if id=='pharmacy' else 'shop' if id in ('bikes','clothes') else 'restaurant',
                  'id':id,'from_x':x,'to_x':x+width}
            if id!='passage':
                count+=1
                name,arabic,food,brand=PLACE_INFO[id]
                unit.update({'name':name,'arabic':arabic,'colour':hex_colour(brand),'logo':f'res://assets/logos/{id}_badge.svg'})
                place={'id':id,'name':name,'arabic':arabic,'position':v3(x+width/2,0,centre_z),'facing':facing}
                if unit['kind']=='restaurant':
                    place.update({'food':food,'colour':hex_colour(brand),'interior':True,'venue_type':id,'row':row_name})
                    if id=='boba':place['foods']=['bubble tea','coffee']
                    if id=='bakery':place['foods']=['cake','manakish']
                    if width!=ROOM[0]:place['size']=v3(width,ROOM[1],ROOM[2])
                    found.append(place)
                elif unit['kind']=='shop':
                    place.update({'size':v3(*ROOM),'colour':hex_colour(brand),'row':row_name})
                    shops.append(place)
            row['units'].append(unit)
            x+=width
        row['to_x']=x
        plaza_rows.append(row)
    order={id:i for i,id in enumerate(['pizza','gelato','boba','shawarma','bakery','market','thai','sushi','tacos','burger'])}
    found.sort(key=lambda p:order[p['id']])   # keep the old list order (tutorial, tests, saves)
    # Walkways 3.5 m wide (x0, z0, x1, z1). The square in the middle (core) is paved by PlazaBuilder.
    walks=[walk(-284,-181,-142,-177.5),walk(-258,-112.5,-142,-109),          # the promenades in front of the terraces
           walk(-229.75,-177.5,-226.25,-112.5),walk(-173.75,-177.5,-170.25,-112.5),  # along the square's sides
           walk(-215.75,-177.5,-212.25,-171.25),walk(-187.75,-177.5,-184.25,-171.25), # from the north passages to the square
           walk(-201.75,-118.75,-198.25,-112.5),                               # from the middle south passage
           walk(-281,-146.75,-229.75,-143.25),walk(-170.25,-146.75,-92,-143.25),  # west to the bus road, east to the car park
           walk(-258,-177.5,-254,-86.5),walk(-146,-177.5,-142,-86.5),          # the two ends
           walk(-287,-90,-142,-86.5),                                          # behind the south row, to the Western Link
           walk(-254,-161.75,-229.75,-158.25),walk(-170.25,-161.75,-146,-158.25),
           walk(-254,-131.75,-229.75,-128.25),walk(-170.25,-131.75,-146,-128.25),
           walk(-243.75,-177.5,-240.25,-112.5),walk(-159.75,-177.5,-156.25,-112.5),
           walk(-272.75,-200,-269.25,-181),walk(-272.75,-143.25,-269.25,-90)]  # from the ring road and to the back walk
    terraces=[]; passages=[]
    for row in plaza_rows:
        side=1 if row['facing']==0.0 else -1
        f=row['front_z']; back=f-side*UNIT_DEPTH
        terraces.append(walk(row['from_x'],min(f,f+side*TERRACE),row['to_x'],max(f,f+side*TERRACE)))
        for u in row['units']:
            if u['kind']=='passage':
                passages.append(walk(u['from_x'],min(f,back),u['to_x'],max(f,back)))
    core=26.25
    beds=[walk(-226.25,-177.5,-215.75,-171.25),walk(-212.25,-177.5,-187.75,-171.25),walk(-184.25,-177.5,-173.75,-171.25),
          walk(-226.25,-118.75,-201.75,-112.5),walk(-198.25,-118.75,-173.75,-112.5)]
    for x0,x1 in [(-254,-243.75),(-240.25,-229.75),(-170.25,-159.75),(-156.25,-146)]:
        for z0,z1 in [(-177.5,-161.75),(-158.25,-146.75),(-143.25,-131.75),(-128.25,-112.5)]:
            beds.append(walk(x0,z0,x1,z1))
    beds+=[walk(-258,-200,-240,-181),walk(-160,-200,-142,-181),walk(-269.25,-200,-258,-181),walk(-284,-200,-272.75,-181),
           walk(-274,-177.5,-258,-150),walk(-284,-138,-272.75,-90),walk(-269.25,-143.25,-258,-90)]
    # Checks: nothing overlaps anything else.
    rows_rects=[walk(r['from_x'],min(r['front_z'],r['front_z']-(1 if r['facing']==0 else -1)*UNIT_DEPTH),r['to_x'],max(r['front_z'],r['front_z']-(1 if r['facing']==0 else -1)*UNIT_DEPTH)) for r in plaza_rows]
    core_rect=walk(-200-core,-145-core,-200+core,-145+core)
    for b in beds:
        for other in walks+terraces+rows_rects+[core_rect]+[x for x in beds if x is not b]:
            assert not overlap(b,other),(b,other)
    # Date palms every 8 to 10 m along the middle of each bed; low shrubs round the edges come from district_detail.gd.
    for x0,z0,x1,z1 in beds:
        w=x1-x0; d=z1-z0
        nx=max(1,int((w-4)//9)+1); nz=max(1,int((d-4)//9)+1)
        for i in range(nx):
            for k in range(nz):
                px=x0+w/2 if nx==1 else x0+2+i*(w-4)/(nx-1)
                pz=z0+d/2 if nz==1 else z0+2+k*(d-4)/(nz-1)
                plaza_palms.append(v3(round(px,2),0,round(pz,2)))
    # Benches on the cross walks, facing the bed next to them (Appendix G rule 10).
    benches=[]
    for x0,z0,x1,z1 in [walk(-254,-161.75,-229.75,-158.25),walk(-170.25,-161.75,-146,-158.25),walk(-254,-131.75,-229.75,-128.25),walk(-170.25,-131.75,-146,-128.25)]:
        for x in [x0+5.0,x1-5.0]:
            benches.append({'position':v3(x,0,z0+0.35),'facing':180.0})   # looks north at the bed
            benches.append({'position':v3(x,0,z1-0.35),'facing':0.0})     # looks south at the bed
    planters=[]; bins=[]; racks=[]; lights=[]
    for row in plaza_rows:
        side=1 if row['facing']==0.0 else -1
        f=row['front_z']; edge=f+side*(TERRACE-0.7)
        units=row['units']
        for a,b in zip(units,units[1:]):
            if a['kind']!='passage' and b['kind']!='passage':
                planters.append(v3(a['to_x'],0,edge))       # between the two shops of a pair
            if b['kind']=='passage':
                planters.append(v3(b['from_x']-0.7,0,edge)); planters.append(v3(b['to_x']+0.7,0,edge))
        for u in units:
            if u['kind']=='passage':
                mid=f-side*UNIT_DEPTH*0.5
                racks.append({'position':v3(u['from_x']+0.45,0,f-side*3.5),'facing':90.0,'length':3.0})
                bins.append(v3(u['to_x']-0.4,0,mid))
                lights.append(v3((u['from_x']+u['to_x'])/2,4.4,mid))
    bins+=[v3(-226.6,0,-176),v3(-173.4,0,-114),v3(-231,0,-146.4),v3(-169,0,-143.6)]   # at walkway edges by the junctions
    # Round planters with a palm in the four corners of the paved square (outside the sails).
    core_planters=[v3(-200+dx,0,-145+dz) for dz in (-21.5,21.5) for dx in (-21.5,21.5)]
    plaza_palms.extend(core_planters)
    plaza_landscape.update({'core_half':core,'core_planters':core_planters,'walks':[r4(w) for w in walks],'terraces':[r4(t) for t in terraces],
        'passages':[r4(p) for p in passages],'beds':[r4(b) for b in beds],'benches':benches,'planters':planters,
        'bins':bins,'bike_racks':racks,'passage_lights':lights})
    for t in walks+terraces+passages:
        paving.append(r4(t))
    return found, shops
if PLAZA_LOOKS_PASS:
    put('RESTAURANT_SIZE',v3(*ROOM))
    restaurants, plaza_shops = plaza_layout()
else:
    restaurants, plaza_shops = old_restaurants()
restaurants.append({'id':'farm','name':'Wahat Farm Stall','arabic':'كشك مزرعة الواحة','food':'farm juice','foods':['farm juice','salad box'],'colour':colour(.35,.65,.25),'position':v3(4,0,17),'facing':180.,'style':'stall','size':v3(9,4,6)})
put('RESTAURANTS',restaurants)
put('SHOPS',plaza_shops)
put('PLAZA_ROWS',plaza_rows);put('PLAZA_LANDSCAPE',plaza_landscape)
put('VILLA_SIZE',v3(9,8.5,8))
homes += [
 # Session 61: the glass security booth stands beside the school gate (it stood in the gateway).
 {'number':901,'house':0,'cluster':'','address':'Fair Grade School · Gate','map_address':'School Gate','kind':'spot','look':'booth','position':v3(-357.4,0,30.6),'facing':180.,'size':v3(3.2,2.9,3.2),'who':'teacher'},
 # Session 61: the stable office moved 1.5 m north so it no longer pokes into Stables Road.
 {'number':902,'house':0,'cluster':'','address':'Wahat Stables · Office','map_address':'Stables Office','kind':'spot','position':v3(-224,0,188.5),'facing':0.,'size':v3(7,4,6),'who':'groom'},
 # "counter": where you stand at the reception desk, in the building's own directions (Sessions 60-61).
 {'number':903,'house':0,'cluster':'','address':'C Institute · Reception','map_address':'C Institute','kind':'spot','position':v3(-215,0,-33),'facing':90.,'size':v3(46,14,36),'interior':True,'who':'staff','counter':v3(0,0,9.6)},
 {'number':904,'house':0,'cluster':'','address':'Wahat Gym · Reception','map_address':'Gym','kind':'spot','position':GYM_AT,'facing':180.,'size':GYM_SIZE,'interior':True,'who':'gym_goer','counter':v3(0,0,4.0)},
]
put('VILLAS',homes)
put('REGULARS',[{'id':'mariam','name':'Auntie Mariam','villa':207,'shop':'boba','food':'bubble tea','who':'resident','look':1},{'id':'rashid','name':'Mr Rashid','villa':503,'shop':'shawarma','food':'shawarma','who':'resident','look':0},{'id':'dana','name':'Ms Dana','villa':901,'shop':'bakery','food':'cake','who':'teacher','look':-1},{'id':'hamdan','name':'Hamdan','villa':902,'shop':'farm','food':'farm juice','who':'groom','look':-1}])
# Session 63: the spine's north palm row moved off the red track (was z -7).
palms=[v3(x,0,z) for z in [-10.5,7] for x in range(-130,411,45) if not (z<0 and (x==230 or x>=376))] +[v3(-210,-.45,-155),v3(-190,-.45,-155),v3(-210,-.45,-135),v3(-190,-.45,-135)]
palms+=plaza_palms  # Session 57: date palms in the Plaza's grass beds
palms+=[v3(x,0,z) for x,z in carpark_palms]   # Session 62: palms in the car parks' grass beds
put('PALM_TREES',palms);put('PARKED_CAR_SIZE',v3(1.9,1.5,4.3))
put('PARKED_CARS_OLD',[{'position':v3(x+3,0,z+8+k*9),'facing':90.,'bay':True} for x,z,w,d in parking for k in range(8)])
# Session 62: about half the bays have a car; 'park' is the car park, 'model' the Kenney car, 'paint' its colour.
put('PARKED_CARS',[{'position':v3(c['x'],0,c['z']),'facing':c['facing'],'bay':True,'park':c['park'],'model':c['model'],'paint':colour(*c['paint'])} for c in cp.parked_cars(parks)])
put('SPEED_BUMP_SIZE',v3(10,.12,.5))
put('SPEED_BUMPS',[{'position':v3(x,0,z),'facing':90.} for z in [-205,205] for x in [-180,50,300]]+[{'position':v3(x,0,z),'facing':0.} for x in [-425,425] for z in [-80,80]])
put('CATS',cats);put('SCOOTER_KIDS',kids)
put('BUGGIES',[{'points':[v3(cx-60,0,cz),v3(cx+(30 if n==3 else 60),0,cz),v3(cx+(30 if n==3 else 60),0,-185 if cz<0 else 185)],'colour':colour(.85,.85,.76),'level':(n-1)%3} for n,cx,cz in clusters]+[{'points':[v3(-140,0,-1),v3(410,0,-1)],'colour':colour(.3,.5,.5),'level':1}])
put('HORSE_RIDERS',[{'points':[v3(-450,0,-230),v3(450,0,-230),v3(450,0,230),v3(-450,0,230)],'loop':True,'colour':colour(.45,.28,.15),'coat':'brown','level':0,'collection_id':'horse_sultan','collection_name':'Sultan'},{'points':[v3(450,0,230),v3(-450,0,230),v3(-450,0,-230),v3(450,0,-230)],'loop':True,'colour':colour(.62,.61,.6),'coat':'grey','level':1,'collection_id':'horse_noor','collection_name':'Noor'}])
put('PEOPLE_ROUTES',[{'points':[v3(-438,0,-218),v3(438,0,-218),v3(438,0,218),v3(-438,0,218)],'loop':True,'jog':True,'look':2,'level':0}]+[{'points':[v3(-180,0,z),v3(352,0,z)],'jog':False,'look':i,'level':i%3} for i,z in enumerate([-6.0,-7.6,-6.9])])  # Session 63: walkers on the red walking track
put('GARDENERS',gardeners);put('PLAY_KIDS',plays)
put('DUCKS',[{'from_x':x,'to_x':x+65,'side':.4 if i%2 else -.4,'level':i%3} for i,x in enumerate([-100,0,160,310])])  # Session 53: clear of the stream bridges at x 73 and 303
put('BIRD_FLOCKS',[{'centre':v3(x,30,z),'radius':r,'birds':4,'level':i} for i,(x,z,r) in enumerate([(-180,-100,70),(180,80,90),(0,0,160)])])
works += [{'name':'Ring Road '+name,'centre':v2(x,z),'along':along,'width':10.,'length':12.} for name,x,z,along in [('north',260,-205,'x'),('east',425,-90,'z'),('south',-200,205,'x'),('west',-425,-60,'z')]]
put('ROAD_WORKS',works)
put('HORSE_CROSSINGS',[{'name':'the stable lane','from':v3(-244,0,184),'to':v3(-244,0,205)},{'name':'the south ring road','from':v3(-170,0,192),'to':v3(-170,0,235)}])

lines=['class_name WahatAlShams','## Real-size Wahat Al Shams: generated by tools/build_wahat_data.py.','## Coordinates in metres; stable IDs and explicit human addresses are separate.','']
for name,value in constants.items():
    if isinstance(value,list):
        lines.append(f'const {name} := [')
        lines += ['\t'+gd(item)+',' for item in value]
        lines.append(']')
    else:lines.append(f'const {name} := '+gd(value))
    lines.append('')
(ROOT/'data/wahat_al_shams.gd').write_text('\n'.join(lines).rstrip()+'\n')
# Session 62: real car parks are at most 85 m from any home. Report the homes further away.
far=[(h['cluster'],h['house'],round(d)) for h,d in zip([h for h in homes if h['kind']!='spot'],cp.reach(parks,[(float(h['position'].split('(')[1].split(',')[0]),float(h['position'].split(',')[2].rstrip(')'))) for h in homes if h['kind']!='spot'])) if d>85]
print('Car parks:',len(parks),'parks,',sum(len(p['rows'])*p['bays'] for p in parks),'bays,',len(constants['PARKED_CARS']),'parked cars; homes over 85 m from a car park:',len(far),sorted({c for c,_,_ in far}),max([d for *_,d in far],default=0),'m')
assert len([v for v in homes if v['kind']!='spot'])==500
assert len({v['number'] for v in homes})==504
print('Generated 500 homes, 4 venues, 11 pickups and',len(roads),'road/path segments')
