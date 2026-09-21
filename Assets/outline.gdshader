shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 1.5;

void fragment() {
	vec4 cor = texture(TEXTURE, UV);

	if (cor.a > 0.5) {
		COLOR = cor;
		return;
	}

	vec2 texel = outline_width / vec2(textureSize(TEXTURE, 0));
	float alfa_vizinho = 0.0;
	alfa_vizinho += texture(TEXTURE, UV + vec2(texel.x, 0.0)).a;
	alfa_vizinho += texture(TEXTURE, UV + vec2(-texel.x, 0.0)).a;
	alfa_vizinho += texture(TEXTURE, UV + vec2(0.0, texel.y)).a;
	alfa_vizinho += texture(TEXTURE, UV + vec2(0.0, -texel.y)).a;
	alfa_vizinho += texture(TEXTURE, UV + vec2(texel.x, texel.y)).a;
	alfa_vizinho += texture(TEXTURE, UV + vec2(-texel.x, -texel.y)).a;
	alfa_vizinho += texture(TEXTURE, UV + vec2(texel.x, -texel.y)).a;
	alfa_vizinho += texture(TEXTURE, UV + vec2(-texel.x, texel.y)).a;

	COLOR = vec4(outline_color.rgb, min(alfa_vizinho, 1.0) * outline_color.a);
}
