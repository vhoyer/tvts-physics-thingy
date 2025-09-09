class_name GodotVTS
extends Node

const GVTS = 'GodotVTS'
const PLUGIN_NAME = 'TVTS Physiscs Thingy'
const PLUGIN_AUTHOR = 'veshworks'
const VTS_URL = 'ws://127.0.0.1:%s'


signal packet_arrived(id: String, payload: Dictionary)


var token: String
var socket:= WebSocketPeer.new()
var logger:= Logger.scope(GVTS)
var status:= StatusReporter.new()

var ongoing_requests: Dictionary[String, Request] = {}


func _ready() -> void:
	status.changed.connect(_on_status_changed)
	connect_to_port()


func connect_to_port(port:= 8001) -> void:
	var url = VTS_URL % port
	socket.connect_to_url(url)
	set_process(true)
	status.report(GVTS, 'connection_requested')


func send(type: String, data: Dictionary = {}) -> Request:
	var req:= Request.new()
	socket.send_text(req.get_payload(type, data))
	ongoing_requests.set(req.id, req)
	return req


func _process(_delta: float) -> void:
	socket.poll()
	var state:= socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_CONNECTING:
			status.report(GVTS, 'connection_connecting')
		WebSocketPeer.STATE_OPEN:
			status.report(GVTS, 'connection_established')

			while socket.get_available_packet_count():
				var data = socket.get_packet()
				var json = JSON.parse_string(data.get_string_from_utf8())
				logger.debug('received data %s' % json.messageType)

				packet_arrived.emit(json.requestID, json)

				var req = ongoing_requests.get(json.requestID)
				if req: req.response.emit(json)
		WebSocketPeer.STATE_CLOSING:
			status.report(GVTS, 'connection_closing')
		WebSocketPeer.STATE_CLOSED:
			status.report(GVTS, 'connection_closed')
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			logger.info("WebSocket closed with code: `%d`, reason `%s`. Clean: `%s`" % [code, reason, code != -1])
			set_process(false) # Stop processing.


func _on_status_changed(id: String, state: String) -> void:
	if id == GVTS and state == 'connection_established':
		var api_state: Dictionary = await send('APIStateRequest').response
		logger.debug('handshake: %s' % api_state.data.active)

		status.report(GVTS, 'token_requested')
		var auth_token: Dictionary = await send('AuthenticationTokenRequest', {
			'pluginName': PLUGIN_NAME,
			'pluginDeveloper': PLUGIN_AUTHOR,
			}).response
		token = auth_token.data.get('authenticationToken', '')
		if not token:
			status.report(GVTS, 'error')
			logger.debug('error authing: %s' % auth_token.data.message)
			return

		status.report(GVTS, 'authenticating')
		var auth: Dictionary = await send('AuthenticationRequest', {
			'pluginName': PLUGIN_NAME,
			'pluginDeveloper': PLUGIN_AUTHOR,
			'authenticationToken': token,
			}).response
		if not auth.data.get('authenticated'):
			status.report(GVTS, 'error')
			logger.debug('error authing: %s' % auth.data.reason)
			return




class Request:
	var id: String
	signal response(response: Dictionary)
	func _init() -> void:
		id = UUID.v4()
	func get_payload(type: String, data: Dictionary = {}) -> String:
		var request:= {}
		request.apiName = 'VTubeStudioPublicAPI'
		request.apiVersion = '1.0'
		request.requestID = id
		request.messageType = type
		if data: request.data = data
		return JSON.stringify(request)
