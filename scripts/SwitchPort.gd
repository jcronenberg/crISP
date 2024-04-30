extends Port

class_name SwitchPort

func get_real_parent():
	return get_node("../..")
