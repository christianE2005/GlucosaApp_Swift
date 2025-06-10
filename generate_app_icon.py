#!/usr/bin/env python3

from PIL import Image, ImageDraw
import os
import math

print("Iniciando creación del icono...")

# Tamaños necesarios para iOS
size = 1024

# Colores del tema médico/salud
bg_color = (64, 150, 255)  # Azul médico
accent_color = (255, 255, 255)  # Blanco
secondary_color = (45, 125, 230)  # Azul más oscuro

icon_dir = "/Users/alumno/Documents/data_insights/ControlGlucosa/ControlGlucosa/Assets.xcassets/AppIcon.appiconset"

print(f"Creando imagen de {size}x{size}...")

# Crear imagen
img = Image.new('RGB', (size, size), bg_color)
draw = ImageDraw.Draw(img)

# Parámetros del diseño
center = size // 2
radius = size // 2 - 40

print("Dibujando círculo de fondo...")
# Dibujar círculo de fondo más oscuro
draw.ellipse([40, 40, size-40, size-40], fill=secondary_color)

print("Dibujando cruz médica...")
# Dibujar cruz médica estilizada
cross_thickness = size // 10
cross_length = size // 3

# Brazo horizontal de la cruz
draw.rectangle([
    center - cross_length//2,
    center - cross_thickness//2,
    center + cross_length//2,
    center + cross_thickness//2
], fill=accent_color)

# Brazo vertical de la cruz
draw.rectangle([
    center - cross_thickness//2,
    center - cross_length//2,
    center + cross_thickness//2,
    center + cross_length//2
], fill=accent_color)

print("Añadiendo elementos decorativos...")
# Añadir círculos pequeños que representen gotas/medición
dot_size = size // 40
for angle in [30, 60, 120, 150, 210, 240, 300, 330]:
    x = center + int((radius * 0.8) * math.cos(math.radians(angle)))
    y = center + int((radius * 0.8) * math.sin(math.radians(angle)))
    draw.ellipse([
        x - dot_size, y - dot_size,
        x + dot_size, y + dot_size
    ], fill=accent_color)

# Guardar imagen
filename = "AppIcon-1024.png"
filepath = os.path.join(icon_dir, filename)
print(f"Guardando en: {filepath}")
img.save(filepath, 'PNG')
print(f"✅ Creado: {filename}")

print("¡Icono de la aplicación creado exitosamente!")
