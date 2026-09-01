import PIL.Image
import math

# Palette mapping based on src/core/palette.lua
PALETTE = {
    'hat_light':    (0.55, 0.40, 0.27),
    'hat':          (0.42, 0.30, 0.20),
    'hat_dark':     (0.28, 0.19, 0.12),
    'hat_deep':     (0.17, 0.11, 0.07),
    'leather_dark': (0.30, 0.16, 0.10),
    'gold':         (0.92, 0.74, 0.24),
    'skin':         (0.85, 0.67, 0.50),
    'skin_dark':    (0.62, 0.45, 0.32),
    'skin_deep':    (0.42, 0.29, 0.21),
    'stubble':      (0.50, 0.38, 0.31),
    'eye_glow':     (1.00, 0.86, 0.42),
    'bandana':      (0.72, 0.16, 0.16),
    'bandana_dark': (0.50, 0.10, 0.10),
    'bandana_light':(0.88, 0.30, 0.24),
    'vest':         (0.38, 0.22, 0.15),
    'vest_dark':    (0.23, 0.13, 0.09),
    'leather':      (0.46, 0.26, 0.16),
    'belt':         (0.26, 0.17, 0.11),
    'gun':          (0.35, 0.35, 0.40),
    'gun_dark':     (0.20, 0.20, 0.24),
    'steel':        (0.64, 0.65, 0.72),
    'steel_light':  (0.86, 0.88, 0.95),
    'rim_cool':     (0.56, 0.64, 0.92),
    'rim_warm':     (1.00, 0.72, 0.34),
    'skin_light':   (0.96, 0.80, 0.62),
    'night':        (0.06, 0.07, 0.13),
    # Add more colors to handle the reference images better
    'brown_light':  (0.60, 0.45, 0.30),
    'brown_mid':    (0.40, 0.28, 0.18),
    'brown_dark':   (0.25, 0.16, 0.10),
    'grey_light':   (0.75, 0.75, 0.78),
    'grey_mid':     (0.55, 0.55, 0.58),
    'grey_dark':    (0.35, 0.35, 0.38),
    'red_bright':   (0.85, 0.20, 0.18),
    'yellow_bright':(0.95, 0.80, 0.25),
}

# ASCII character mapping: palette key -> char
# Add new characters for new palette entries
CHAR_MAP = {
    'hat_light': 'G', 'hat': 'H', 'hat_dark': 'h', 'hat_deep': 'j',
    'leather_dark': 'k', 'gold': 'Y', 'skin': 'F', 'skin_dark': 'f',
    'skin_deep': 'd', 'stubble': 'u', 'eye_glow': 'E', 'bandana': 'R',
    'bandana_dark': 'r', 'vest': 'V', 'vest_dark': 'v', 'leather': 'C',
    'leather_dark2': 'c', 'belt': 'W', 'gun': 'M', 'gun_dark': 'm', 'steel': 'N',
    'steel_light': 'n', 'rim_cool': 'B', 'rim_warm': 'A',
    'skin_light': 'S', 'bandana_light': 's',
    'brown_light': 'P', 'brown_mid': 'p', 'brown_dark': 'q',
    'grey_light': 'L', 'grey_mid': 'l', 'grey_dark': 'g',
    'red_bright': 'T', 'yellow_bright': 'X',
    'night': '.',
}

def color_distance(c1, c2):
    return math.sqrt(sum((a-b)**2 for a,b in zip(c1, c2)))

def find_closest_char(r, g, b, a=255):
    if a < 128:  # Transparent
        return '.'
    
    rgb = (r/255.0, g/255.0, b/255.0)
    
    best_key = None
    best_dist = float('inf')
    
    for key, pal_color in PALETTE.items():
        dist = color_distance(rgb, pal_color)
        if dist < best_dist:
            best_dist = dist
            best_key = key
    
    return CHAR_MAP.get(best_key, '.')

def generate_ascii(img_path, target_w, target_h, name):
    img = PIL.Image.open(img_path)
    pixels = img.load()
    w, h = img.size
    
    print(f'Analyzing {name}: {w}x{h} -> {target_w}x{target_h}')
    
    # Find the bounding box of non-transparent pixels
    min_x, min_y = w, h
    max_x, max_y = 0, 0
    has_content = False
    for y in range(h):
        for x in range(w):
            if img.mode == 'RGBA':
                r, g, b, a = pixels[x, y]
            else:
                r, g, b = pixels[x, y]
                a = 255
            if a > 128:
                has_content = True
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    
    if not has_content:
        print('No content found!')
        return []
    
    print(f'Bounding box: ({min_x}, {min_y}) to ({max_x}, {max_y})')
    print(f'Content size: {max_x - min_x + 1}x{max_y - min_y + 1}')
    
    # Extract the content and convert to ASCII
    content_w = max_x - min_x + 1
    content_h = max_y - min_y + 1
    
    # Generate ASCII art with proper scaling
    ascii_rows = []
    for ty in range(target_h):
        src_y = min_y + int(ty * content_h / target_h)
        row = ''
        for tx in range(target_w):
            src_x = min_x + int(tx * content_w / target_w)
            if img.mode == 'RGBA':
                r, g, b, a = pixels[src_x, src_y]
            else:
                r, g, b = pixels[src_x, src_y]
                a = 255
            
            char = find_closest_char(r, g, b, a)
            row += char
        ascii_rows.append(row)
    
    print(f'\nGenerated ASCII art for {name}:')
    for row in ascii_rows:
        print(f'"{row}",')
    print()
    return ascii_rows

# Generate for portrait (body without gun)
print('=' * 60)
print('BODY (portrait.png)')
print('=' * 60)
generate_ascii(
    r'C:\Users\Verzion 360\AppData\Local\Temp\claude\e--Creacta-2026-Projects-game\6163de69-d5c9-4a88-8674-c7f6e55c741c\scratchpad\portrait.png',
    56,  # target width
    64,  # target height
    'portrait'
)

# Generate for gun
print('=' * 60)
print('GUN (gun.png)')
print('=' * 60)
generate_ascii(
    r'C:\Users\Verzion 360\AppData\Local\Temp\claude\e--Creacta-2026-Projects-game\6163de69-d5c9-4a88-8674-c7f6e55c741c\scratchpad\gun.png',
    40,  # target width
    46,  # target height
    'gun'
)

# Generate for idle frames
for i, fname in enumerate(['portrait_idle1.png', 'portrait_idle2.png'], 1):
    print('=' * 60)
    print(f'IDLE FRAME {i} ({fname})')
    print('=' * 60)
    generate_ascii(
        rf'C:\Users\Verzion 360\AppData\Local\Temp\claude\e--Creacta-2026-Projects-game\6163de69-d5c9-4a88-8674-c7f6e55c741c\scratchpad\{fname}',
        56, 64,
        f'idle{i}'
    )

# Generate for draw frames
for i, fname in enumerate(['portrait_draw1.png', 'portrait_draw2.png'], 1):
    print('=' * 60)
    print(f'DRAW FRAME {i} ({fname})')
    print('=' * 60)
    generate_ascii(
        rf'C:\Users\Verzion 360\AppData\Local\Temp\claude\e--Creacta-2026-Projects-game\6163de69-d5c9-4a88-8674-c7f6e55c741c\scratchpad\{fname}',
        56, 64,
        f'draw{i}'
    )
