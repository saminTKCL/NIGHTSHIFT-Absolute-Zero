extends CanvasLayer

## Screen post-processing effects controller.

@onready var vignette_rect: ColorRect = $VignetteRect
@onready var grain_rect: ColorRect = $GrainRect

var vignette_material: ShaderMaterial
var grain_material: ShaderMaterial

func _ready() -> void:
	_setup_vignette()
	_setup_grain()
	GameManager.vignette_material = vignette_material
	GameManager.grain_material = grain_material

func _setup_vignette() -> void:
	if not vignette_rect:
		vignette_rect = ColorRect.new()
		vignette_rect.name = "VignetteRect"
		add_child(vignette_rect)
	vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette_material = ShaderMaterial.new()
	vignette_material.shader = preload("res://shaders/vignette.gdshader")
	vignette_material.set_shader_parameter("vignette_intensity", 0.4)
	vignette_material.set_shader_parameter("vignette_opacity", 0.6)
	vignette_material.set_shader_parameter("danger_intensity", 0.0)
	vignette_rect.material = vignette_material

func _setup_grain() -> void:
	if not grain_rect:
		grain_rect = ColorRect.new()
		grain_rect.name = "GrainRect"
		add_child(grain_rect)
	grain_rect.anchors_preset = Control.PRESET_FULL_RECT
	grain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grain_material = ShaderMaterial.new()
	grain_material.shader = preload("res://shaders/grain.gdshader")
	grain_material.set_shader_parameter("grain_amount", 0.04)
	grain_rect.material = grain_material

func pulse_danger(duration: float = 0.5) -> void:
	var tween := create_tween()
	tween.tween_property(vignette_material, "shader_parameter/danger_intensity", 0.8, 0.1)
	tween.tween_property(vignette_material, "shader_parameter/danger_intensity", 0.0, duration)

func set_danger_level(level: float) -> void:
	vignette_material.set_shader_parameter("danger_intensity", level)
