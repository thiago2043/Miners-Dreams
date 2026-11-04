"""Guia de arte: usa os assets do build e confere portas, alturas e sentidos."""
import copy
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, r'C:\Users\thiagocraft\.codex\visualizations\2026\10\02\01a0fcb7-e891-7ac0-a9b9-cb13f6444603\render-deps')
from PIL import Image, ImageDraw

spec = importlib.util.spec_from_file_location('renderer', ROOT / 'modelos/mineradoras/renderizar.py')
r = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r)
OUT = Path(__file__).resolve().parent
models = json.loads((OUT / 'modelos-do-build.json').read_text(encoding='utf-8'))
parts, nodes, routes = [], [], []

def part(model, name):
    return next(p for p in models[model]['partes'] if p['name'] == name)

def add(model, x, y, z, kind):
    nodes.append(dict(model=model, x=x, y=y, z=z, kind=kind))
    for p in models[model]['partes']:
        if p['name'].startswith(('Hitbox', 'Sensor')):
            continue
        q = copy.deepcopy(p)
        q['cf'][:3] = [p['cf'][0] + x, p['cf'][1] + y, p['cf'][2] + z]
        parts.append(q)

def box(name, pos, size, color, material='Metal'):
    parts.append(dict(name=name, cf=list(pos)+[1,0,0,0,1,0,0,0,1], size=size,
                      shape='Block', color=color, material=material, transparency=0))

def deck(x, top, z0, z1, width):
    box('Pavimento', [x, top-1.5, (z0+z1)/2], [width, 3, z1-z0], [.33,.38,.43])
    for xx in (x-width/2+1.5, x+width/2-1.5):
        for zz in (z0+1.5, z1-1.5):
            if top <= 3:
                continue
            box('Pilar', [xx, (top-3)/2, zz], [1.5, top-3, 1.5], [.18,.23,.28])

def ore(x, y, z):
    box('Minerio', [x,y+.375,z], [.75]*3, [.55,.6,.65], 'Slate')

standard = part('Esteira2x2','Correia')
base_top = standard['cf'][1] + standard['size'][1]/2
assert abs(base_top-.9375) < .001
for suffix, expected in [('Entrada',6+base_top),('Saida',base_top)]:
    p = next(p for p in models['EsteiraDescida']['partes'] if p['name'].startswith('EncaixeEsteira1'+suffix))
    assert abs(p['cf'][1]+p['size'][1]/2-expected)<.001

deck(1.5,24,-36,-9,57)
for x, miner, mods, furnace in [
    (-18,'MineradoraBasica',['CamaraMagnetica','RefinadorMolecular'],'FornalhaReforcada'),
    (0,'MineradoraCobre',['ProcessadorTermico','RessonadorPlasma'],'FornalhaTermica'),
    (18,'MineradoraQuantica',['LaserDuplo','CamaraPlasma'],'FornalhaMolecular'),
]:
    source = models[miner]['saida']
    add(miner,x-source[0],24,-7.5-source[2],'miner')
    assert abs(source[2]+nodes[-1]['z']+7.5)<.001
    add('Esteira2x2',x,12,-6,'belt')
    deck(x,12,-9,-3,6)
    segments = [dict(z0=-9,z1=-3,h0=12+base_top,h1=12+base_top,model='Esteira2x2')]
    ore(x,12+base_top,-7.5)
    ore(x,24+source[1]-5,-7.5)
    cursor = -3
    for model in mods:
        p = part(model,'Correia')
        assert abs(p['size'][0]-6)<.001, 'A passagem precisa manter dois blocos de largura.'
        top = p['cf'][1]+p['size'][1]/2
        y = 12+base_top-top
        assert abs(y/3-round(y/3)) < .001, 'Base fora da grade vertical.'
        length = p['size'][2]
        z = cursor+length/2-p['cf'][2]
        add(model,x-p['cf'][0],y,z,'modifier')
        assert abs(p['cf'][0]+nodes[-1]['x']-x)<.001
        assert abs(p['cf'][1]+y+p['size'][1]/2-(12+base_top))<.001
        deck(x,y,cursor,cursor+length,part(model,'HitboxConstrucao')['size'][0])
        segments.append(dict(z0=cursor,z1=cursor+length,h0=12+base_top,h1=12+base_top,model=model))
        ore(x,12+base_top,cursor+length/2)
        cursor += length
    for y in (6,0):
        add('EsteiraDescida',x,y,cursor+3,'descent')
        segments.append(dict(z0=cursor,z1=cursor+6,h0=y+6+base_top,h1=y+base_top,model='EsteiraDescida'))
        for dz in (1.5,4.5):
            ore(x,y+6+base_top-dz,cursor+dz)
        cursor += 6
    add('Esteira2x2',x,0,cursor+3,'belt')
    segments.append(dict(z0=cursor,z1=cursor+6,h0=base_top,h1=base_top,model='Esteira2x2'))
    cursor += 6
    tray = part(furnace,'BandejaEntrada')
    offset_z = cursor-(tray['cf'][2]-tray['size'][2]/2)
    add(furnace,x-tray['cf'][0],base_top-tray['cf'][1]-tray['size'][1]/2,offset_z,'furnace')
    ore(x,base_top,cursor+tray['size'][2]/2)
    for a,b in zip(segments,segments[1:]):
        assert abs(a['z1']-b['z0'])<.001, (a,b)
        assert abs(a['h1']-b['h0'])<.001, (a,b)
    assert abs(segments[-1]['z1']-(offset_z+tray['cf'][2]-tray['size'][2]/2))<.001
    routes.append(dict(x=x,source=miner,segments=segments,furnace=furnace))

(OUT/'rotas-3d-conferidas.json').write_text(json.dumps(dict(nodes=nodes,routes=routes),indent=2),encoding='utf-8')
r.render(parts,1920,1080,camera=(-2.8,2.1,1.6)).save(OUT/'guia-3d-rotas-conferidas.png')

image = Image.new('RGB',(1500,1040),(242,245,248))
draw = ImageDraw.Draw(image)
titles = ['EXTRAÇÃO | ALTURA 8 BLOCOS','MODIFICAÇÃO | ALTURA 4 BLOCOS','VENDA | ALTURA 0']
colors = dict(miner='#334155',modifier='#158573',belt='#1978a9',descent='#a56b16',furnace='#bc4835')
for panel,title in enumerate(titles):
    left = panel*500
    draw.text((left+15,15),title,font=r.font(19,True),fill='#243346')
    for node in nodes:
        if (node['kind']=='miner' and panel!=0) or (node['kind'] in ('modifier','descent') and panel!=1) or (node['kind']=='furnace' and panel!=2):
            continue
        if node['kind']=='belt' and panel!=(1 if node['y']>0 else 2):
            continue
        p=part(node['model'],'HitboxConstrucao')
        x=left+250+node['x']*7
        z=75+(node['z']+39)*9
        w,d=p['size'][0]*7,p['size'][2]*9
        draw.rectangle((x-w/2,z-d/2,x+w/2,z+d/2),fill=colors[node['kind']],outline='white',width=2)
    for route in routes:
        x=left+250+route['x']*7
        start,end=(-9,-5) if panel==0 else (-9,route['segments'][-2]['z1']) if panel==1 else (route['segments'][-1]['z0'],route['segments'][-1]['z1']+4)
        for z in range(int(start),int(end),5):
            y=75+(z+39)*9
            draw.line((x,y,x,y+23),fill='#ffce55',width=4)
            draw.polygon([(x-6,y+16),(x+6,y+16),(x,y+25)],fill='#ffce55')
draw.text((20,994),'Guia de composição: setas apenas para conferir o sentido. Todas as rotas são independentes e terminam nas bandejas.',font=r.font(18),fill='#243346')
image.save(OUT/'planta-por-altura.png')
print('ROTAS_3D_OK: 3 linhas, 12 maquinas; saidas, larguras e alturas conferidas nos RBXM do build; seis descidas reais de 45 graus, sem curvas ou bifurcacoes inventadas.')
