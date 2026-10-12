class_name MessageBox
extends Label

@export var shape: MessageShape
# "show message for seconds" will only hide a message if its delete call matches
var currentCall: int = -999

# "show message for seconds" will hide the message two frames after its done
# waiting one frame prevents flicking when stacking another message block after it
# waiting two frames prevents flickering if putting it in a loop
func hideAfterTwoFrames(deleteCall: int) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if currentCall == deleteCall: visible = false
