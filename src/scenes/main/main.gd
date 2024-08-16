extends Node2D

func _ready():
	add_child(NetworkSim.new())
