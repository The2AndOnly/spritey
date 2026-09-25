class_name ParseData
extends Node

static func castType(type: int, value: Variant) -> Variant:
	match type:
		0: # integer
			return int(value)
		1: # float
			return float(value)
		2: # string
			if value is float:
				if is_equal_approx(value, floorf(value)):
					return str(int(value))
				else:
					return str(snappedf(float(value), 0.01))
			return str(value)
		3: # positive integer
			return max(0, int(value))
		4: # positive float
			return max(0.0, float(value))
		5: # bool (has no casting since only bool blocks can be inserted)
			return value
	return null

static func stringNumber(value: float) -> String:
	if is_equal_approx(value, floorf(value)):
		return str(int(value))
	else:
		return "%.1f" % value

static func findUniqueName(desired: String, existing: Array[String]) -> String:
	if !existing.has(desired): return desired
	var regex: RegEx = RegEx.new()
	# Splits name into text (with whitespaces) and the number at the end
	regex.compile("^(.*?)(\\d+)?$")
	var result: RegExMatch = regex.search(desired)
	var baseName: String = result.get_string(1)
	var countStart: int = 2
	
	var count: int = countStart
	var possibleName: String = "%s%d" % [baseName, count]
	while existing.has(possibleName):
		count += 1
		possibleName = "%s%d" % [baseName, count]
	return possibleName
