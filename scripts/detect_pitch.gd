extends Node2D

const A4 = 440.0  # Reference frequency for A4
const NOTES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const MIN_FREQ = 50.0  # Lowest frequency to detect
const MAX_FREQ = 1000.0  # Highest frequency to detect
const GRAPH_HEIGHT = 400  # Height of the visualization
const NOTE_SPACING = 40  # Distance between notes on the scale

var spectrum
var detected_freq = 0.0

func _ready():
	spectrum = AudioServer.get_bus_effect_instance(0, 0)  # Assuming effect is on bus 0

func _process(_delta):
	detected_freq = get_pitch()

func get_pitch() -> float:
	var step = 5.0  # Frequency step for scanning
	var peak_freq = 0.0
	var peak_magnitude = 0.0
	var prev_hz = MIN_FREQ

	for hz in range(int(MIN_FREQ), int(MAX_FREQ), int(step)):
		var magnitude = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		if magnitude > peak_magnitude:
			peak_magnitude = magnitude
			peak_freq = (prev_hz + hz) / 2
		prev_hz = hz

	return peak_freq

func frequency_to_note(freq: float) -> String:
	if freq <= 0:
		return "N/A"
	var semitones_from_A4 = int(round(12 * log(freq / A4) / log(2)))
	var note_index = (semitones_from_A4 + 9) % 12  # Align A4 properly
	var octave = 4 + ((semitones_from_A4 + 9) / 12)
	return NOTES[note_index] + str(octave)

func frequency_to_y(freq: float) -> float:
	# Normalize frequency position within the height of the graph
	return GRAPH_HEIGHT - ((freq - MIN_FREQ) / (MAX_FREQ - MIN_FREQ) * GRAPH_HEIGHT)

func _draw():
	var circle_x = 200  # Position of the circle
	var bar_x = 100  # Position of the scale

	# Draw vertical scale
	draw_line(Vector2(bar_x, 0), Vector2(bar_x, GRAPH_HEIGHT), Color(1, 1, 1), 2)

	# Draw note markers
	for i in range(0, 12 * 4):  # 4 octaves of notes
		var freq = A4 * pow(2, (i - 9) / 12.0)  # Calculate frequency for this note
		if freq < MIN_FREQ or freq > MAX_FREQ:
			continue
		var y = frequency_to_y(freq)
		draw_line(Vector2(bar_x - 10, y), Vector2(bar_x + 10, y), Color(0.8, 0.8, 0.8), 2)
		draw_string(ThemeDB.fallback_font, Vector2(bar_x - 50, y + 5), frequency_to_note(freq))

	# Draw detected pitch circle
	if detected_freq > 0:
		var y = frequency_to_y(detected_freq)
		draw_circle(Vector2(circle_x, y), 10, Color(1, 0, 0))  # Red circle
		draw_string(ThemeDB.fallback_font, Vector2(circle_x + 20, y + 5), frequency_to_note(detected_freq))
