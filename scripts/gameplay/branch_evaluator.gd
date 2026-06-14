extends RefCounted
class_name BranchEvaluator


func choose_branch(branch_event: Dictionary, state: Dictionary) -> String:
	var condition := String(branch_event.get("condition", "normal"))
	var value := _condition_value(condition, state)
	if value < 0.0:
		return "normal"

	var expert_threshold := float(branch_event.get("expert_threshold", 0.0))
	var master_threshold := float(branch_event.get("master_threshold", 0.0))
	if _uses_percent_metric(condition) and maxf(expert_threshold, master_threshold) > 1.0:
		value *= 100.0

	if value >= master_threshold:
		return "master"
	if value >= expert_threshold:
		return "expert"
	return "normal"


func _condition_value(condition: String, state: Dictionary) -> float:
	match condition:
		"accuracy":
			return float(state.get("accuracy", 0.0))
		"score":
			return float(state.get("score_rate", 0.0))
		"roll":
			return float(state.get("roll_hits", 0))
		"normal":
			return -1.0
	return -1.0


func _uses_percent_metric(condition: String) -> bool:
	return condition == "accuracy" or condition == "score"
