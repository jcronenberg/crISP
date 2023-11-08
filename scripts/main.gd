extends Node2D

func _ready():
	add_child(load("res://scripts/Simulation.gd").new())
