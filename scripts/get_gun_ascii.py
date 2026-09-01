import PIL.Image, math, sys

PALETTE = {
    'hat_light': (0.55, 0.40, 0.27), 'hat': (0.42, 0.30, 0.20),
    'hat_dark': (0.28, 0.19, 0.12), 'hat_deep': (0.17, 0.11, 0.07),
    'leather_dark': (0.30, 0.16, 0.10), 'gold': (0.92, 0.74, 0.24),
    'skin': (0.85, 0.67, 0.50), 'skin_dark': (0.62, 0.45, 0.32),
    'skin_deep': (0.42, 0.29, 0.21), 'stubble': (0.50, 0.38, 0.31),
    'eye_glow': (1.00, 0.86, 0.42), 'bandana': (0.72, 0.16, 0.16),
    'bandana_dark': (0.50, 0.10, 0.10), 'bandana_light': (0.88, 0.30, 0.24),
    'vest': (0.38, 0.22, 0.15), 'vest_dark': (0.23, 0.13, 0.09),
    'leather': (0.46, 0.26, 0.16), 'belt': (0.26, 0.17, 0.11),
    'gun': (0.35, 0.35, 0.40), 'gun_dark': (0.20, 0.20, 0.24),
    'steel': (0.64, 0.65, 0.72), 'steel_light': (0.86, 0.88, 0.95),
    'rim_cool': (0.56, 0.64, 0.92), 'rim_warm': (1.00, 0.72, 0.34),
    'skin_light': (0.96, 0.80, 0.62), 'brown_light': (0.60, 0.45, 0.30),
    'brown_mid': (0.40, 0.28, 0.18), 'grey_light': (0.75, 0.75, 0.78),
    'grey_mid': (0.55, 0.55, 0.58),
}
CHAR_MAP = {
    'hat_light': 'G', 'hat': 'H', 'hat_dark': 'h', 'hat_deep': 'j',
    'leather_dark': 'k', 'gold': 'Y', 'skin': 'F', 'skin_dark': 'f',
    'skin_deep': 'd', 'stubble': 'u', 'eye_glow': 'E', 'bandana': 'R',
    'bandana_dark': 'r', 'vest': 'V', 'vest_dark': 'v', 'leather': 'C',
    'belt': 'W', 'gun': 'M', 'gun_dark': 'm', 'steel': 'N',
    'steel_light': 'n', 'rim_cool': 'B', 'rim_warm': 'A',
    'skin_light': 'S', 'bandana_light': 's',
    'brown_light': 'P', 'brown_mid': 'p',
    'grey_light': 'L', 'grey_mid': 'l',
}
def cd(c1,c2): return math.sqrt(sum((a-b)**2 for a,b in zip(c1,c2)))
def fc(r,g,b,a=255):
    if a<128: return '.'
    rgb=(r/255.0,g/255.0,b/255.0)
    bk,bd=None,float('inf')
    for k,pc in PALETTE.items():
        d=cd(rgb,pc)
        if d<bd: bd,bk=d,k
    return CHAR_MAP.get(bk,'.')

img=PIL.Image.open(r'C:\Users\Verzion 360\AppData\Local\Temp\claude\e--Creacta-2026-Projects-game\6163de69-d5c9-4a88-8674-c7f6e55c741c\scratchpad\gun.png')
px=img.load(); w,h=img.size
rows=[]
for ty in range(46):
    sy=int(ty*h/46); row=''
    for tx in range(40):
        sx=int(tx*w/40); r,g,b=px[sx,sy][:3]; a=px[sx,sy][3] if img.mode=='RGBA' else 255
        row+=fc(r,g,b,a)
    rows.append(row)
for r in rows: print(f'"{r}",')
