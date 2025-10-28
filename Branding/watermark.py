from PIL import Image, ImageDraw, ImageFont

# --- Configuration ---
width, height = 1920, 400
text = "Studio Patraldo"
font_size = 300

# --- Color Scheme ---
# Transparent background
background_color = (0, 0, 0, 0)

# Semi-transparent white text (adjust opacity: 0-255)
# Higher number = more opaque, lower = more transparent
text_opacity = 120  # Try values between 80-180
text_color = (255, 255, 255, text_opacity)

# Optional subtle outline for better visibility
# Set to None to disable outline, or use a dark color with low opacity
outline_opacity = 60  # Much lower than text for subtle effect
outline_color = (0, 0, 0, outline_opacity)
outline_width = 2  # Thinner outline

# --- Script Logic ---
base = Image.new("RGBA", (width, height), background_color)
draw = ImageDraw.Draw(base)

# Load font
font_path = None
try:
    font = ImageFont.truetype("arialbd.ttf", font_size)
    font_path = "arialbd.ttf (Arial Bold)"
except IOError:
    try:
        font = ImageFont.truetype("arial.ttf", font_size)
        font_path = "arial.ttf (Arial Regular)"
    except IOError:
        try:
            # Try common system fonts on different platforms
            import platform
            if platform.system() == "Darwin":  # macOS
                font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", font_size)
                font_path = "System Arial (macOS)"
            elif platform.system() == "Linux":
                font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
                font_path = "DejaVu Sans Bold (Linux)"
            else:
                font = ImageFont.load_default()
                font_path = "Default Font"
        except:
            font = ImageFont.load_default()
            font_path = "Default Font"

print(f"Using font: {font_path}")

# Calculate text position (centered)
bbox = draw.textbbox((0, 0), text, font=font)
textwidth = bbox[2] - bbox[0]
textheight = bbox[3] - bbox[1]
x = (width - textwidth) / 2
y = (height - textheight) / 2

# Draw subtle outline (optional - comment out if you don't want it)
if outline_color:
    for ox in range(-outline_width, outline_width + 1):
        for oy in range(-outline_width, outline_width + 1):
            if ox == 0 and oy == 0:
                continue
            draw.text((x + ox, y + oy), text, font=font, fill=outline_color)

# Draw the main semi-transparent text
draw.text((x, y), text, font=font, fill=text_color)

# Save the watermark
base.save("watermark_text_only.png")
print(f"Watermark generated: watermark_text_only.png")
print(f"Text opacity: {text_opacity}/255 (adjust 'text_opacity' variable to change)")
print(f"Tip: Try values between 80 (very subtle) and 180 (more visible)")
