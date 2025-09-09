class_name GodotVTubeStudio
extends Node

const GVTS = 'GodotVTS'
const VTS_URL = 'ws://127.0.0.1:%s'


signal connected()
signal model_moved()


var socket: WebSocketPeer
var logger:= Logger.scope(GVTS)
var status:= StatusReporter.new()

var ongoing_requests: Dictionary[String, Request] = {}
var ongoing_subscriptions: Dictionary[String, Request] = {}


var persistency:= JSONStorage.new('', 'gvts')
var token: String:
	get():
		return persistency.get_item('token', '')
	set(value):
		persistency.set_item('token', value)


var model:= GodotVTSModel.new()
var window_size: Vector2


func _ready() -> void:
	status.changed.connect(_on_status_changed)


func sign_in(port:= 8001) -> void:
	_connect_to_port(port)
	await connected

	if not token:
		status.report(GVTS, 'token_requested')
		var auth_token: Dictionary = await _send('AuthenticationTokenRequest', {
			'pluginName': GodotVTubeStudioSettings.plugin_name,
			'pluginDeveloper': GodotVTubeStudioSettings.plugin_developer,
			}).response
		token = auth_token.data.get('authenticationToken', '')
		if not token:
			status.report(GVTS, 'error')
			logger.debug('error authing: %s' % auth_token.data.message)
			return

	status.report(GVTS, 'authenticating')
	var auth: Dictionary = await _send('AuthenticationRequest', {
		'pluginName': GodotVTubeStudioSettings.plugin_name,
		'pluginDeveloper': GodotVTubeStudioSettings.plugin_developer,
		'authenticationToken': token,
		}).response
	if not auth.data.get('authenticated'):
		status.report(GVTS, 'error')
		logger.debug('error authing: %s' % auth.data.reason)
		return

	var moved_event_id:= '%s.ModelMovedEvent' % GVTS
	status.report(moved_event_id, 'waiting')
	(await _subscribe('ModelMovedEvent')).event.connect(
		func _on_model_moved(payload: Dictionary):
			status.report(moved_event_id, 'ok')

			model.model_id = payload.data.get('modelID', '')
			model.model_name = payload.data.get('modelName', 'Default Model Name')
			model.position = Vector2(
				payload.data.get('modelPosition', {}).get('positionX', 0),
				payload.data.get('modelPosition', {}).get('positionY', 0))
			model.rotation = payload.data.get('modelPosition', {}).get('rotation', 0)
			model.size = payload.data.get('modelPosition', {}).get('size', 0)
			model_moved.emit()
			pass)

	var vts_stats_event_id:= '%s.stats' % GVTS
	status.report(vts_stats_event_id, 'waiting')
	_send('StatisticsRequest').response.connect(
		func _on_vts_stats(payload: Dictionary):
			status.report(vts_stats_event_id, 'ok')
			window_size = Vector2(
				payload.get('data', {}).get('windowWidth', 1920),
				payload.get('data', {}).get('windowHeight', 1080))
			pass,
		ConnectFlags.CONNECT_ONE_SHOT)

	status.report(GVTS, 'ok')


func _connect_to_port(port:= 8001) -> void:
	var url = VTS_URL % port
	socket = WebSocketPeer.new()
	socket.connect_to_url(url)
	status.report(GVTS, 'connection_requested')


func _send(type: String, data: Dictionary = {}) -> Request:
	var req:= Request.new()
	socket.send_text(req.get_payload(type, data))
	ongoing_requests.set(req.id, req)
	return req


func _subscribe(event: String, config: Dictionary = {}) -> Request:
	var req = _send('EventSubscriptionRequest', {
		'eventName': event,
		'subscribe': true,
		'config': config,
		})
	var payload: Dictionary = await req.response
	if payload.get('data', {}).get('subscribedEvents', []).has(event):
		req.event_name = event
		ongoing_subscriptions.set(event, req)
	return req



func move_model(position: Vector2, rotation_deg: float, size: float, duration:= 0.0, relative:=true) -> Request:
	var deg = wrap(rotation_deg, -360, 360)
	var pos = position.clamp(Vector2(-1, -1), Vector2(1, 1))
	var siz = clamp(size, -100, 100)

	return _send('MoveModelRequest', {
		'timeInSeconds': duration,
		'valuesAreRelativeToModel': relative,
		'positionX': pos.x,
		'positionY': pos.y,
		'rotation': deg,
		'size': siz,
		})


func _process(_delta: float) -> void:
	if not socket: return

	socket.poll()
	var state:= socket.get_ready_state()
	match state:
		WebSocketPeer.STATE_CONNECTING:
			status.report(GVTS, 'connection_connecting')
		WebSocketPeer.STATE_OPEN:
			if status.get_status(GVTS) == 'connection_connecting':
				status.report(GVTS, 'connection_established')

			while socket.get_available_packet_count():
				var data = socket.get_packet()
				var json = JSON.parse_string(data.get_string_from_utf8())
				logger.debug('received data %s' % json.messageType)

				var req = ongoing_requests.get(json.requestID)
				if req:
					req.response.emit(json)
					ongoing_requests.erase(json.requestID)

				var event = ongoing_subscriptions.get(json.messageType)
				if event: event.event.emit(json)
		WebSocketPeer.STATE_CLOSING:
			status.report(GVTS, 'connection_closing')
		WebSocketPeer.STATE_CLOSED:
			status.report(GVTS, 'connection_closed')
			var code = socket.get_close_code()
			var reason = socket.get_close_reason()
			logger.info("WebSocket closed with code: `%d`, reason `%s`. Clean: `%s`" % [code, reason, code != -1])
			socket = null


func _on_status_changed(id: String, state: String) -> void:
	if id == GVTS and state == 'connection_established':
		var api_state: Dictionary = await _send('APIStateRequest').response
		logger.debug('handshake: %s' % api_state.data.active)
		connected.emit()



class Request:
	var id: String
	signal response(response: Dictionary)

	var event_name: String
	signal event(response: Dictionary)

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
