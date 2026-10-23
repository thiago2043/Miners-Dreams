"""Renderiza a geometria exportada dos RBXM; nao usa imagens conceituais no lugar dos modelos."""
from pathlib import Path
import json
import math
import hashlib
import copy
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent
PREVIAS = ROOT/'previas'/hashlib.sha256((ROOT/'geometria.json').read_bytes()).hexdigest()[:10]
PREVIAS.mkdir(parents=True, exist_ok=True)
WORK = Path('C:/Users/thiagocraft/.codex/visualizations/2026/10/02/01a0fcb7-e891-7ac0-a9b9-cb13f6444603/mineradoras-work')
WORK.mkdir(parents=True, exist_ok=True)
VIEW = np.array([1.15, 0.95, 1.5], dtype=float)
VIEW /= np.linalg.norm(VIEW)
RIGHT = np.cross([0., 1., 0.], VIEW)
RIGHT /= np.linalg.norm(RIGHT)
UP = np.cross(VIEW, RIGHT)
LIGHT = np.array([-0.5, 1.0, 0.65])
LIGHT /= np.linalg.norm(LIGHT)
FILL = np.array([0.8, 0.45, -0.4])
FILL /= np.linalg.norm(FILL)
HALF = (VIEW + LIGHT) / np.linalg.norm(VIEW + LIGHT)


def mesh(shape):
    if shape == 'Block':
        v = np.array([[-1,-1,-1],[1,-1,-1],[1,1,-1],[-1,1,-1],[-1,-1,1],[1,-1,1],[1,1,1],[-1,1,1]], dtype=float)/2
        faces = [[0,3,2,1],[4,5,6,7],[0,4,7,3],[1,2,6,5],[0,1,5,4],[3,7,6,2]]
        tris = [(f[0],f[i],f[i+1]) for f in faces for i in (1,2)]
    elif shape == 'WedgePart':
        v=np.array([[-1,-1,-1],[1,-1,-1],[-1,-1,1],[1,-1,1],[-1,1,1],[1,1,1]],dtype=float)/2
        faces=[[0,1,3,2],[2,3,5,4],[0,2,4],[1,5,3],[0,4,5,1]]
        tris=[(f[0],f[i],f[i+1]) for f in faces for i in range(1,len(f)-1)]
    elif shape == 'Cylinder':
        n=16
        v=np.array([[x, math.cos(a*2*math.pi/n)/2, math.sin(a*2*math.pi/n)/2] for x in [-.5,.5] for a in range(n)]+[[-.5,0,0],[.5,0,0]])
        tris=[]
        for a in range(n):
            b=(a+1)%n
            tris.extend([(a,b,b+n),(a,b+n,a+n),(2*n,b,a),(2*n+1,a+n,b+n)])
    else:
        n,k=16,10
        v=np.array([[.5*math.sin(j*math.pi/k)*math.cos(i*2*math.pi/n), .5*math.cos(j*math.pi/k), .5*math.sin(j*math.pi/k)*math.sin(i*2*math.pi/n)] for j in range(k+1) for i in range(n)])
        tris=[]
        for j in range(k):
            for i in range(n):
                a=j*n+i; b=j*n+(i+1)%n; c=b+n; d=a+n
                tris.extend([(a,d,c),(a,c,b)])
    tris=np.array(tris, dtype=int)
    # Todas as faces exportadas usam normais para fora, inclusive nas primitivas curvas.
    for i,t in enumerate(tris):
        p=v[t]; normal=np.cross(p[1]-p[0],p[2]-p[0])
        if np.dot(normal,p.mean(axis=0)-v.mean(axis=0))<0:
            tris[i]=t[[0,2,1]]
    return v,tris


MESH={s:mesh(s) for s in ['Block','WedgePart','Cylinder','Ball']}


def geometria(parts):
    result=[]
    for p in parts:
        if p['transparency']>.99:
            continue
        local,faces=MESH[p['shape']]
        cf=p['cf']; rot=np.array(cf[3:]).reshape(3,3)
        vertices=(local*np.array(p['size']))@rot.T+np.array(cf[:3])
        result.append((vertices,faces,np.array(p['color']),p['material'],p['transparency']))
    return result


def hull(points):
    ps=sorted(set((float(x),float(y)) for x,y in points))
    def cross(o,a,b): return (a[0]-o[0])*(b[1]-o[1])-(a[1]-o[1])*(b[0]-o[0])
    halves=[]
    for seq in [ps,list(reversed(ps))]:
        row=[]
        for p in seq:
            while len(row)>=2 and cross(row[-2],row[-1],p)<=0: row.pop()
            row.append(p)
        halves.append(row[:-1])
    return halves[0]+halves[1]


def render(parts, width=720, height=600, grid=False, camera=None, reserva=None):
    camera_dir=VIEW if camera is None else np.array(camera,dtype=float)/np.linalg.norm(camera)
    right=np.cross([0.,1.,0.],camera_dir); right/=np.linalg.norm(right)
    up=np.cross(camera_dir,right)
    half=(camera_dir+LIGHT)/np.linalg.norm(camera_dir+LIGHT)
    geo=sorted(geometria(parts),key=lambda g:(g[4]>0,float(g[0].mean(axis=0)@camera_dir)))
    allv=np.concatenate([g[0] for g in geo])
    x,y=allv@right,allv@up
    lo=np.array([x.min(),y.min()]); hi=np.array([x.max(),y.max()])
    scale=min((width-90)/(hi[0]-lo[0]),(height-75)/(hi[1]-lo[1]))
    center=(lo+hi)/2
    def project(v):
        return np.column_stack(((v@right-center[0])*scale+width/2, height/2-(v@up-center[1])*scale))
    image=Image.new('RGB',(width,height),(224,230,237))
    shadow=Image.new('L',(width,height),0)
    sd=ImageDraw.Draw(shadow)
    for vertices,_,_,_,alpha in geo:
        if alpha>0: continue
        floor=vertices-LIGHT[None,:]*(vertices[:,1:2]/LIGHT[1])
        poly=hull(project(floor))
        if len(poly)>=3: sd.polygon(poly,fill=65)
    shadow=shadow.filter(ImageFilter.GaussianBlur(6))
    image=Image.composite(Image.new('RGB',image.size,(61,74,91)),image,shadow)
    if reserva:
        w,d=reserva[0]*4,reserva[1]*4
        cantos=np.array([[-w/2,.03,-d/2],[w/2,.03,-d/2],[w/2,.03,d/2],[-w/2,.03,d/2],[-w/2,.03,-d/2]])
        ImageDraw.Draw(image).line([tuple(p) for p in project(cantos)],fill=(207,116,41),width=2)
    if grid:
        draw=ImageDraw.Draw(image)
        offset_x=allv[:,0].min()%4
        offset_z=allv[:,2].min()%4
        for n in range(-24,25,4):
            for axis in [0,2]:
                pts=np.array([[n+offset_x,0,-24],[n+offset_x,0,24]] if axis==0 else [[-24,0,n+offset_z],[24,0,n+offset_z]])
                draw.line([tuple(p) for p in project(pts)],fill=(203,212,222),width=1)
    canvas=np.array(image,dtype=np.float32)/255
    depth=np.full((height,width),-np.inf,dtype=np.float32)
    emission=np.zeros((height,width,3),dtype=np.float32)
    for vertices,faces,color,material,alpha in geo:
        projected=project(vertices)
        zs=vertices@camera_dir
        for face in faces:
            points=vertices[face]
            normal=np.cross(points[1]-points[0],points[2]-points[0])
            norm=np.linalg.norm(normal)
            if norm<1e-10: continue
            normal/=norm
            if np.dot(normal,camera_dir)<=0: continue
            tri=projected[face]
            xmin=max(0,int(np.floor(tri[:,0].min()))); xmax=min(width-1,int(np.ceil(tri[:,0].max())))
            ymin=max(0,int(np.floor(tri[:,1].min()))); ymax=min(height-1,int(np.ceil(tri[:,1].max())))
            if xmax<xmin or ymax<ymin: continue
            x0,y0=tri[0]; x1,y1=tri[1]; x2,y2=tri[2]
            den=(y1-y2)*(x0-x2)+(x2-x1)*(y0-y2)
            if abs(den)<1e-9: continue
            xx,yy=np.meshgrid(np.arange(xmin,xmax+1)+.5,np.arange(ymin,ymax+1)+.5)
            a=((y1-y2)*(xx-x2)+(x2-x1)*(yy-y2))/den
            b=((y2-y0)*(xx-x2)+(x0-x2)*(yy-y2))/den
            c=1-a-b
            zz=a*zs[face[0]]+b*zs[face[1]]+c*zs[face[2]]
            view=depth[ymin:ymax+1,xmin:xmax+1]
            mask=(a>=-1e-7)&(b>=-1e-7)&(c>=-1e-7)&(zz>view)
            if not mask.any(): continue
            neon=material=='Neon'
            light=.46+.55*max(0,np.dot(normal,LIGHT))+.18*max(0,np.dot(normal,FILL))
            spec=.22*max(0,np.dot(normal,half))**30 if material=='Metal' else 0
            rgb=np.clip(color*(1.12 if neon else light)+spec,0,1)
            patch=canvas[ymin:ymax+1,xmin:xmax+1]
            if material in ('Granite','Slate','DiamondPlate'):
                # A textura procedural aproxima a aspereza; a aparencia nativa depende do Studio.
                wx=a*points[0,0]+b*points[1,0]+c*points[2,0]
                wy=a*points[0,1]+b*points[1,1]+c*points[2,1]
                wz=a*points[0,2]+b*points[1,2]+c*points[2,2]
                grain=np.mod(np.sin(np.floor(wx*19)*127.1+np.floor(wy*19)*311.7+np.floor(wz*19)*74.7)*43758.5453,1)-.5
                coarse=np.mod(np.sin(np.floor(wx*3.3)*83.1+np.floor(wy*3.3)*191.7+np.floor(wz*3.3)*53.7)*19341.747,1)-.5
                intensity=.95 if material=='Granite' else .27
                rough=np.clip(rgb[None,None,:]*(1+intensity*(grain+coarse*.65))[:,:,None],0,1)
                patch[mask]=patch[mask]*alpha+rough[mask]*(1-alpha)
            else:
                patch[mask]=patch[mask]*alpha+rgb*(1-alpha)
            if alpha==0: view[mask]=zz[mask]
            ep=emission[ymin:ymax+1,xmin:xmax+1]
            ep[mask]=rgb*.48 if neon else 0
    glow=Image.fromarray((np.clip(emission,0,1)*255).astype('uint8'))
    near=np.array(glow.filter(ImageFilter.GaussianBlur(2)))/255
    far=np.array(glow.filter(ImageFilter.GaussianBlur(7)))/255
    canvas=np.clip(canvas+near*.16+far*.12,0,1)
    return Image.fromarray((canvas*255).astype('uint8'))


def font(size,bold=False):
    for p in [Path('C:/Windows/Fonts/segoeuib.ttf' if bold else 'C:/Windows/Fonts/segoeui.ttf'),Path('C:/Windows/Fonts/arial.ttf')]:
        if p.exists(): return ImageFont.truetype(str(p),size)
    return ImageFont.load_default(size=size)


def main():
    models=json.loads((ROOT/'geometria.json').read_text(encoding='utf-8'))
    grupos=[('Inicial','PRIMEIRO GRUPO · FRENTE E COSTAS',list(range(3))*2,3,500,460),
            ('Intermediario','GRUPO INTERMEDIÁRIO · VISTA BAIXA',list(range(3,9)),3,500,460),
            ('Apoios','M1–M9 · ENCAIXES E APOIOS DOS CABEÇOTES',list(range(9)),3,500,460),
            ('Avancado','GRUPO AVANÇADO · VISTA BAIXA',list(range(9,13)),2,720,535),
            ('Silhuetas','M10–M13 · COMPARAÇÃO SEM CORES',list(range(9,13)),2,720,535),
            ('Laterais','M10–M13 · CORPOS E COMPRIMENTOS EXTERNOS',list(range(9,13)),2,720,535),
            ('Encaixes','SAÍDAS · VISTAS DE FRENTE E DE LADO',[0,0,11,11],2,720,500)]
    for nome,titulo,indices,colunas,w,h in grupos:
        folha=Image.new('RGB',(colunas*w,65+((len(indices)+colunas-1)//colunas)*(h+50)),(239,242,246))
        texto=ImageDraw.Draw(folha)
        texto.text((25,20),titulo,font=font(27,True),fill=(30,41,57))
        for j,i in enumerate(indices):
            costas=nome=='Inicial' and j>=3
            camera=(-1.5,.48,-1.2) if costas else (1.25,.48,1.7)
            if nome=='Encaixes':
                camera=(2,.3,.12) if j%2 else (.12,.35,2)
            if nome=='Laterais':
                camera=(2,.42,.14)
            if nome=='Apoios':
                camera=(2,.3,.12)
            x,y=(j%colunas)*w,65+(j//colunas)*(h+50)
            pecas=models[i]['partes']
            if nome=='Silhuetas':
                pecas=copy.deepcopy(pecas)
                for p in pecas:
                    p['color']=[.24,.27,.31]
                    p['material']='SmoothPlastic'
            folha.paste(render(pecas,w,h,camera=camera,reserva=models[i]['blocos']),(x,y))
            vista=(' · lado' if j%2 else ' · frente') if nome=='Encaixes' else (' · costas' if costas else '')
            if nome=='Laterais':
                vista=f" · broca {models[i]['avanco']:g} blocos".replace('.',',')
            texto.text((x+20,y+h+10),f"M{i+1} · "+models[i]['nome']+vista,font=font(23,True),fill=(30,41,57))
        folha.save(PREVIAS/f'PreviaGrupo{nome}.png')
        folha.save(ROOT/f'PreviaGrupo{nome}.png')
        print(f'Grupo {nome} salvo.',flush=True)
    conjunto=[]
    cursor=0
    for i in [0,9,10,11,12]:
        m=models[i]
        centro=cursor+m['blocos'][0]*2
        for p in m['partes']:
            parte=copy.deepcopy(p)
            parte['cf'][0]+=centro
            parte['cf'][2]-=m['blocos'][1]*2
            conjunto.append(parte)
        cursor+=m['blocos'][0]*4+12
    escala=Image.new('RGB',(2400,965),(239,242,246))
    escala.paste(render(conjunto,2400,870,grid=True,camera=(.25,.45,2)),(0,50))
    texto=ImageDraw.Draw(escala)
    texto.text((25,12),'BÁSICA E AVANÇADAS · MESMA ESCALA FÍSICA',font=font(28,True),fill=(30,41,57))
    texto.text((25,920),'Da esquerda para a direita: Básica, Quântica, Singularidade, Estelar e Galáctica. Grade de 4 studs.',font=font(23),fill=(30,41,57))
    escala.save(PREVIAS/'PreviaEscala.png')
    escala.save(ROOT/'PreviaEscala.png')
    names=['Básica','Cobre','Ferro','Industrial','Pressurizada','Cristalina','Ressonante','Plasma','Atômica','Quântica','Singularidade','Estelar','Galáctica']
    board=Image.new('RGB',(1840,1950),(239,242,246)); draw=ImageDraw.Draw(board)
    draw.text((35,25),'MINERADORAS  /  CORPOS, MATERIAIS E SAÍDAS',font=font(31,True),fill=(30,41,57))
    draw.text((36,72),'Corpos compactos · cabeçotes largos · saídas translúcidas · brocas e blindagem',font=font(19),fill=(77,92,112))
    for i,m in enumerate(models):
        preview=render(m['partes'])
        preview.save(WORK/(m['id']+'.png'))
        if i<12:
            col,row=i%4,i//4
            x,y=25+col*455,115+row*445
            board.paste(preview.resize((435,362),Image.Resampling.LANCZOS),(x,y))
            draw.text((x+8,y+366),f'{i+1:02d}  {names[i]}',font=font(23,True),fill=(32,44,61))
            draw.text((x+8,y+400),f"{m['blocos'][0]} × {m['blocos'][1]} blocos  ·  {len(m['partes'])} peças",font=font(18),fill=(82,98,119))
        print(m['id'],len(m['partes']),'partes renderizadas',flush=True)
    hero=render(models[-1]['partes'],1000,700,grid=True)
    board.paste(hero.resize((620,434),Image.Resampling.LANCZOS),(25,1470))
    draw.text((675,1530),'13  Galáctica',font=font(34,True),fill=(32,44,61))
    draw.text((675,1590),f"{models[-1]['blocos'][0]} × {models[-1]['blocos'][1]} blocos · corpo, broca e saída",font=font(23),fill=(74,91,112))
    draw.text((675,1645),'Grade do projeto: 1 bloco = 4 studs',font=font(23),fill=(32,44,61))
    draw.text((675,1695),'Cada quadro tem enquadramento próprio para mostrar detalhes.',font=font(20),fill=(82,98,119))
    draw.text((675,1730),'A galeria no Roblox Studio conserva a escala entre as máquinas.',font=font(20),fill=(82,98,119))
    draw.text((675,1795),'Prévia da geometria real, renderizada fora do Roblox Studio.',font=font(20),fill=(82,98,119))
    board.save(PREVIAS/'PreviaMineradoras.png')
    hero.save(PREVIAS/'PreviaGalactica.png')
    board.save(ROOT/'PreviaMineradoras.png')
    hero.save(ROOT/'PreviaGalactica.png')
    print(f'Prévias salvas em {PREVIAS}.',flush=True)


if __name__=='__main__':
    main()
