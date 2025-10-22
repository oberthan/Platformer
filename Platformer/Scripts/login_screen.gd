extends Node2D

@onready var username_input = $UsernameInput
@onready var password_input = $PasswordInput
@onready var login_button = $Login
@onready var register_button = $Register
@onready var output_label = $Output
@onready var http = $HTTPRequest

const SERVER_URL = "http://localhost/test_api/"

func _ready():
	login_button.pressed.connect(_on_login_pressed)
	register_button.pressed.connect(_on_register_pressed)
	http.request_completed.connect(_on_http_request_completed)

func _on_login_pressed():
	var username = username_input.text
	var password = password_input.text
	if username == "" or password == "":
		output_label.text = "Udfyld begge felter"
		return

	var url = SERVER_URL + "login.php"
	var data = {"username": username, "password": password}
	var headers = ["Content-Type: application/x-www-form-urlencoded"]

	http.request(url, headers, HTTPClient.METHOD_POST, http_query_string(data))

	output_label.text = "Logging in"

func _on_register_pressed():
	var username = username_input.text
	var password = password_input.text
	if username == "" or password == "":
		output_label.text = "Udfyld begge felter"
		return

	var url = SERVER_URL + "register.php"
	var data = {"username": username, "password": password}
	var headers = ["Content-Type: application/x-www-form-urlencoded"]

	http.request(url, headers, HTTPClient.METHOD_POST, http_query_string(data))
	output_label.text = "Registerer"

func _on_http_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	var response = JSON.parse_string(response_text)

	if response.success:
		output_label.text = "Login virkede!"
		get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func http_query_string(data):
	var params = []
	for key in data.keys():
		params.append("%s=%s" % [key, str(data[key]).uri_encode()])
	return "&".join(params)
