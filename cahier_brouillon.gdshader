shader_type canvas_item;

// --- PARAMÈTRES MODIFIABLES DANS L'INSPECTEUR ---
group_uniforms Couleurs;
uniform vec4 color_paper : source_color = vec4(0.97, 0.96, 0.92, 1.0);     // Blanc cassé / Crème
uniform vec4 color_lines : source_color = vec4(0.2, 0.4, 0.65, 0.4);      // Bleu écolier (avec transparence)
uniform vec4 color_margin : source_color = vec4(0.85, 0.25, 0.25, 0.6);   // Rouge marge (avec transparence)

group_uniforms Texture_Papier;
uniform float grain_intensity : hint_range(0.0, 0.1) = 0.04;              // Force du grain fin
uniform float fiber_intensity : hint_range(0.0, 0.1) = 0.03;              // Force des vagues/taches de fond
uniform float paper_scale : hint_range(10.0, 500.0) = 300.0;              // Taille de la fibre

group_uniforms Reglage_Lignes;
uniform float line_spacing : hint_range(0.01, 0.2) = 0.06;                // Écart entre les lignes bleues
uniform float line_thickness : hint_range(0.001, 0.01) = 0.002;           // Épaisseur des lignes bleues
uniform float margin_position : hint_range(0.0, 1.0) = 0.15;              // Position de la ligne rouge à gauche
uniform float margin_thickness : hint_range(0.001, 0.01) = 0.003;          // Épaisseur de la ligne rouge

group_uniforms Deplacement;
uniform float camera_x = 0.0;                                             // Lié à la position X de la caméra
uniform float camera_y = 0.0;                                             // Lié à la position Y de la caméra

// --- FONCTIONS DE BRUIT PROCÉDURAL ---

float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

void fragment() {
    vec2 uv = UV;
    
    // Création d'un UV virtuel synchronisé sur les mouvements de la caméra
    // Le multiplicateur 0.0002 crée un effet de parallaxe discret et fluide
    vec2 moving_uv = vec2(uv.x + camera_x, uv.y + camera_y);
    
    // -------------------------------------------------------------
    // 1. GÉNÉRATION DE L'ASPECT PAPIER (LE FOND)
    // -------------------------------------------------------------
    float grain = random(uv * 999.0); // Le grain fin reste calé sur l'écran
    
    // Les imperfections et fibres bougent avec le papier
    float fibers = noise(moving_uv * paper_scale);
    float fibers2 = noise(moving_uv * (paper_scale * 0.4)); 
    float paper_texture = (grain * grain_intensity) + (fibers * fiber_intensity) + (fibers2 * fiber_intensity * 0.5);
    
    vec4 final_color = color_paper - vec4(vec3(paper_texture), 0.0);

    // -------------------------------------------------------------
    // 2. DESSIN DES LIGNES HORIZONTALES (BLEUES)
    // -------------------------------------------------------------
    // Effet tracé main stabilisé grâce au moving_uv
    float hand_drawn_offset_y = (noise(vec2(moving_uv.x * 10.0, 0.0)) - 0.5) * 0.0015;
    
    float pos_y = moving_uv.y + hand_drawn_offset_y;
    float horizontal_pattern = fract(pos_y / line_spacing);
    
    float is_horizontal_line = step(1.0 - (line_thickness / line_spacing), horizontal_pattern);

    // -------------------------------------------------------------
    // 3. DESSIN DE LA MARGE VERTICALE (ROUGE)
    // -------------------------------------------------------------
    // Effet tracé main stabilisé également
    float hand_drawn_offset_x = (noise(vec2(0.0, moving_uv.y * 8.0)) - 0.5) * 0.002;
    
    float pos_x = moving_uv.x + hand_drawn_offset_x;
    float is_margin_line = step(margin_position, pos_x) * step(pos_x, margin_position + margin_thickness);

    // -------------------------------------------------------------
    // 4. MELANGE FINAL
    // -------------------------------------------------------------
    final_color = mix(final_color, color_lines, is_horizontal_line * color_lines.a);
    final_color = mix(final_color, color_margin, is_margin_line * color_margin.a);

    COLOR = final_color;
}