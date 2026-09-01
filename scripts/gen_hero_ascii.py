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
}

# Create reverse mapping: color -> key
PALETTE_KEYS = {
    'G': 'hat_light', 'H': 'hat', 'h': 'hat_dark', 'j': 'hat_deep',
    'k': 'leather_dark', 'Y': 'gold', 'F': 'skin', 'f': 'skin_dark',
    'd': 'skin_deep', 'u': 'stubble', 'E': 'eye_glow', 'R': 'bandana',
    'r': 'bandana_dark', 'V': 'vest', 'v': 'vest_dark', 'C': 'leather',
    'c': 'leather_dark', 'W': 'belt', 'M': 'gun', 'm': 'gun_dark', 'N': 'steel',
    'n': 'steel_light', 'B': 'rim_cool', 'A': 'rim_warm',
    'S': 'skin_light', 's': 'bandana_light',
}

def color_distance(c1, c2):
    return math.sqrt(sum((a-b)**2 for a,b in zip(c1, c2)))

def find_closest_palette_key(r, g, b, a=255):
    if a < 128:  # Transparent
        return None
    
    rgb = (r/255.0, g/255.0, b/255.0)
    
    best_key = None
    best_dist = float('inf')
    
    for key, pal_color in PALETTE.items():
        dist = color_distance(rgb, pal_color)
        if dist < best_dist:
            best_dist = dist
            best_key = key
    
    # Find the ASCII character for this key
    for char, pal_key in PALETTE_KEYS.items():
        if pal_key == best_key:
            return char
    
    return '?'

def generate_ascii(img_path, target_w, name):
    img = PIL.Image.open(img_path)
    pixels = img.load()
    w, h = img.size
    
    print(f'Analyzing {name}: {w}x{h}')
    
    # Find the bounding box of non-transparent pixels
    min_x, min_y = w, h
    max_x, max_y = 0, 0
    for y in range(h):
        for x in range(w):
            if img.mode == 'RGBA':
                r, g, b, a = pixels[x, y]
            else:
                r, g, b = pixels[x, y]
                a = 255
            if a > 128:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    
    print(f'Bounding box: ({min_x}, {min_y}) to ({max_x}, {max_y})')
    print(f'Content size: {max_x - min_x + 1}x{max_y - min_y + 1}')
    
    # Extract the content and convert to ASCII
    content_w = max_x - min_x + 1
    content_h = max_y - min_y + 1
    
    # Generate ASCII art
    ascii_rows = []
    for y in range(target_w):  # Use target_w as height for now
        src_y = int(y * content_h / target_w) + min_y
        row = ''
        for x in range(target_w):
            src_x = int(x * content_w / target_w) + min_x
            if img.mode == 'RGBA':
                r, g, b, a = pixels[src_x, src_y]
            else:
                r, g, b = pixels[src_x, src_y]
                a = 255
            
            char = find_closest_palette_key(r, g, b, a)
            row += char if char else '.'
        ascii_rows.append(row)
    
    print(f'\nGenerated ASCII art for {name}:')
    for row in ascii_rows:
        print(f'"{row}",')
    print()

# Generate for portrait
generate_ascii(
    r'C:\Users\Verzion 360\AppData\Local\Temp\claude\e--Creacta-2026-Projects-game\6163de69-d5c9-4a88-8674-c7f6e55c741c\scratchpad\portrait.png',
    56,
    'portrait'
)
