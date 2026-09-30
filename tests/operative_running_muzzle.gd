extends "res://tools/capture_issue_35.gd"
## Same real level/Input seam as the graphical loop, observed after _process.

func _initialize() -> void:
	artifacts = false
	regression = true
	call_deferred("_run")
