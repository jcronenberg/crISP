extends Node2D

var is_port_connected := false
## kind of an ugly hack to not register the click if it was connected to another port
var just_connected := false
