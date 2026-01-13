from PIL import Image, ImageDraw
import os

source_path = r"d:\work\cyrene_music\assets\icons\new_ico.png"
white_bg_png = r"d:\work\cyrene_music\assets\icons\new_ico_white.png"
tray_png = r"d:\work\cyrene_music\assets\icons\tray_icon.png"
tray_ico = r"d:\work\cyrene_music\assets\icons\tray_icon.ico"
extra_ico = r"d:\work\cyrene_music\assets\icons\ico.ico"
extra_png = r"d:\work\cyrene_music\assets\icons\ico.png"
android_padded_png = r"d:\work\cyrene_music\assets\icons\new_ico_padded.png"

def create_rounded_white_icon(input_path, output_path, format="PNG", radius_ratio=0.15):
    with Image.open(input_path) as img:
        img = img.convert("RGBA")
        size = img.size[0]
        background = Image.new("RGBA", img.size, (0, 0, 0, 0))
        mask = Image.new("L", img.size, 0)
        draw = ImageDraw.Draw(mask)
        radius = int(size * radius_ratio)
        draw.rounded_rectangle([0, 0, size, size], radius=radius, fill=255)
        white_layer = Image.new("RGBA", img.size, (255, 255, 255, 255))
        background.paste(white_layer, (0, 0), mask)
        background.paste(img, (0, 0), img)
        
        if format == "ICO":
            icon_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
            background.save(output_path, format="ICO", sizes=icon_sizes)
        else:
            background.save(output_path, "PNG")
    print(f"Created: {output_path}")

def create_padded_android_foreground(input_path, output_path, scale_ratio=0.65):
    """
    为 Android 自适应图标生成带边距的前景图。
    Android 规范建议关键内容控制在中心 66dp (约 61%) 区域。
    """
    with Image.open(input_path) as img:
        img = img.convert("RGBA")
        base_size = img.size[0]
        
        # 新建等大画布
        background = Image.new("RGBA", img.size, (0, 0, 0, 0))
        
        # 缩小原图标
        new_size = int(base_size * scale_ratio)
        shrunk_img = img.resize((new_size, new_size), Image.Resampling.LANCZOS)
        
        # 居中粘贴
        offset = (base_size - new_size) // 2
        background.paste(shrunk_img, (offset, offset), shrunk_img)
        
        background.save(output_path, "PNG")
    print(f"Created (Padded for Android): {output_path}")

# 同步常规资源
targets = [
    (white_bg_png, "PNG"),
    (tray_png, "PNG"),
    (tray_ico, "ICO"),
    (extra_png, "PNG"),
    (extra_ico, "ICO"),
]
for path, fmt in targets:
    create_rounded_white_icon(source_path, path, fmt)

# 生成 Android 专用边距版本
create_padded_android_foreground(source_path, android_padded_png)
