"""Выделяет только большие/средние сосны; геометрия выбранного LOD0 не меняется."""
import copy, json, struct
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=root/'assets/models/pines/source'
source_file=source/'scene.gltf'
if not source_file.exists(): source_file=source/'scene.gltf.source'
doc=json.loads(source_file.read_text())
binary=(source/'scene.bin').read_bytes()

def pack_tree(group_index):
    d=copy.deepcopy(doc)
    group=d['nodes'][group_index]
    group['children']=[i for i in group['children'] if d['nodes'][i].get('name','').endswith('_LOD0')]
    assert len(group['children'])==1
    # Сохраняем преобразования корневых узлов, включая FBX -> glTF оси.
    d['nodes'][2]['children']=[group_index]
    kept=[]
    def visit(i):
        kept.append(i)
        for c in d['nodes'][i].get('children',[]): visit(c)
    visit(0)
    node_map={old:new for new,old in enumerate(kept)}
    meshes=sorted({d['nodes'][i]['mesh'] for i in kept if 'mesh' in d['nodes'][i]})
    mesh_map={old:new for new,old in enumerate(meshes)}
    mats=sorted({p['material'] for i in meshes for p in d['meshes'][i]['primitives']})
    mat_map={old:new for new,old in enumerate(mats)}
    accessors=set()
    for i in meshes:
        for p in d['meshes'][i]['primitives']:
            accessors.update(p['attributes'].values())
            if 'indices' in p: accessors.add(p['indices'])
    accessors=sorted(accessors); access_map={old:new for new,old in enumerate(accessors)}
    views=sorted({d['accessors'][i]['bufferView'] for i in accessors if 'bufferView' in d['accessors'][i]})
    view_map={old:new for new,old in enumerate(views)}
    out=bytearray(); new_views=[]
    def append(data):
        while len(out)%4: out.append(0)
        offset=len(out); out.extend(data)
        return {'buffer':0,'byteOffset':offset,'byteLength':len(data)}
    for i in views:
        v=d['bufferViews'][i]; start=v.get('byteOffset',0)
        new=append(binary[start:start+v['byteLength']])
        for key in ['byteStride','target']:
            if key in v:new[key]=v[key]
        new_views.append(new)
    def texture_indices(obj):
        found=set()
        if isinstance(obj,dict):
            for k,v in obj.items():
                if k.endswith('Texture') and isinstance(v,dict): found.add(v['index'])
                else: found.update(texture_indices(v))
        elif isinstance(obj,list):
            for v in obj:found.update(texture_indices(v))
        return found
    textures=sorted(set().union(*(texture_indices(d['materials'][i]) for i in mats)))
    tex_map={old:new for new,old in enumerate(textures)}
    images=sorted({d['textures'][i]['source'] for i in textures});image_map={old:new for new,old in enumerate(images)}
    new_images=[]
    for i in images:
        im=d['images'][i]; data=(source/im['uri']).read_bytes()
        new_images.append({'name':Path(im['uri']).stem,'uri':'../source/'+im['uri']})
    for i in kept:
        n=d['nodes'][i]
        if 'children' in n:n['children']=[node_map[c] for c in n['children']]
        if 'mesh' in n:n['mesh']=mesh_map[n['mesh']]
    new_meshes=[]
    tris=0
    for i in meshes:
        m=d['meshes'][i]
        for p in m['primitives']:
            tris+=d['accessors'][p['indices']]['count']//3
            p['indices']=access_map[p['indices']]
            p['attributes']={k:access_map[v] for k,v in p['attributes'].items()}
            p['material']=mat_map[p['material']]
        new_meshes.append(m)
    new_access=[]
    for i in accessors:
        a=d['accessors'][i]
        if 'bufferView' in a:a['bufferView']=view_map[a['bufferView']]
        new_access.append(a)
    def remap_textures(obj):
        if isinstance(obj,dict):
            for k,v in obj.items():
                if k.endswith('Texture') and isinstance(v,dict):v['index']=tex_map[v['index']]
                else:remap_textures(v)
        elif isinstance(obj,list):
            for v in obj:remap_textures(v)
    new_mats=[d['materials'][i] for i in mats]
    for m in new_mats:
        remap_textures(m)
        if 'Clusters' in m.get('name',''):
            m['alphaMode']='MASK';m['alphaCutoff']=0.4;m['doubleSided']=True
    new_textures=[d['textures'][i] for i in textures]
    for t in new_textures:t['source']=image_map[t['source']]
    result={'asset':d['asset'],'scene':0,'scenes':[{'nodes':[0]}],
      'nodes':[d['nodes'][i] for i in kept],'meshes':new_meshes,'accessors':new_access,
      'bufferViews':new_views,'materials':new_mats,'textures':new_textures,
      'images':new_images,'samplers':d.get('samplers',[]),'buffers':[{'byteLength':len(out)}]}
    encoded=json.dumps(result,separators=(',',':')).encode()
    while len(encoded)%4:encoded+=b' '
    while len(out)%4:out.append(0)
    glb=struct.pack('<III',0x46546c67,2,28+len(encoded)+len(out))
    glb+=struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(out),0x004e4942)+out
    dest=root/'assets/models/pines/trees'/(group['name']+'.glb')
    dest.write_bytes(glb)
    print(group['name'],tris,'triangles')

for i,n in enumerate(doc['nodes']):
    name=n.get('name','')
    if name.startswith(('Pine_big_','Pine_large_','Pine_medium_')) and name.count('_')==2:
        pack_tree(i)
if source_file.suffix=='.gltf':source_file.rename(source/'scene.gltf.source')
