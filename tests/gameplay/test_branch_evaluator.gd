extends SceneTree

const BranchEvaluatorScript: GDScript = preload("res://scripts/gameplay/branch_evaluator.gd")

var failed_count := 0


func _init() -> void:
	_test_accuracy_thresholds()
	_test_score_rate_thresholds()
	_test_roll_hit_thresholds()
	_test_unknown_condition_defaults_to_normal()

	if failed_count == 0:
		print("PASS: BranchEvaluator")
		quit(0)
	else:
		push_error("FAIL: BranchEvaluator tests failed with %d assertion(s)." % failed_count)
		quit(1)


func _test_accuracy_thresholds() -> void:
	var evaluator: RefCounted = BranchEvaluatorScript.new()
	var branch := {
		"condition": "accuracy",
		"expert_threshold": 50.0,
		"master_threshold": 90.0,
	}
	_assert(evaluator.choose_branch(branch, {"accuracy": 0.4}) == "normal", "Low accuracy should choose normal")
	_assert(evaluator.choose_branch(branch, {"accuracy": 0.75}) == "expert", "Middle accuracy should choose expert")
	_assert(evaluator.choose_branch(branch, {"accuracy": 0.92}) == "master", "High accuracy should choose master")


func _test_score_rate_thresholds() -> void:
	var evaluator: RefCounted = BranchEvaluatorScript.new()
	var branch := {
		"condition": "score",
		"expert_threshold": 60.0,
		"master_threshold": 85.0,
	}
	_assert(evaluator.choose_branch(branch, {"score_rate": 0.59}) == "normal", "Low score rate should choose normal")
	_assert(evaluator.choose_branch(branch, {"score_rate": 0.7}) == "expert", "Middle score rate should choose expert")
	_assert(evaluator.choose_branch(branch, {"score_rate": 0.9}) == "master", "High score rate should choose master")


func _test_roll_hit_thresholds() -> void:
	var evaluator: RefCounted = BranchEvaluatorScript.new()
	var branch := {
		"condition": "roll",
		"expert_threshold": 5.0,
		"master_threshold": 10.0,
	}
	_assert(evaluator.choose_branch(branch, {"roll_hits": 4}) == "normal", "Low roll hits should choose normal")
	_assert(evaluator.choose_branch(branch, {"roll_hits": 7}) == "expert", "Middle roll hits should choose expert")
	_assert(evaluator.choose_branch(branch, {"roll_hits": 12}) == "master", "High roll hits should choose master")


func _test_unknown_condition_defaults_to_normal() -> void:
	var evaluator: RefCounted = BranchEvaluatorScript.new()
	var branch := {
		"condition": "unknown",
		"expert_threshold": 0.0,
		"master_threshold": 0.0,
	}
	_assert(evaluator.choose_branch(branch, {"accuracy": 1.0, "score_rate": 1.0, "roll_hits": 99}) == "normal", "Unknown branch conditions should choose normal")


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failed_count += 1
		push_error("ASSERTION FAILED: " + message)
