class_name GodotVTubeStudio
extends Node

const GVTS = 'GodotVTS'
const VTS_URL = 'ws://127.0.0.1:%s'


signal connected()
signal disconnected()
signal model_moved()


signal _socket_state_changed(state: int)

var _socket: WebSocketPeer
var _socket_ready_state: int:
	set(value):
		if _socket_ready_state == value: return
		_socket_ready_state = value
		_socket_state_changed.emit(value)

var _udp: UDPServer

signal _vts_state_reported(active: bool)

var _vts_current_instance_id: String
var _vts_current_port: int

var _ongoing_requests: Dictionary[String, Request] = {}
var _ongoing_subscriptions: Dictionary[String, Request] = {}


var _persistency:= JSONStorage.new('', 'gvts')
var _token: String:
	get():
		return _persistency.get_item('token', '')
	set(value):
		_persistency.set_item('token', value)


var _logger:= Logger.scope(GVTS)


var status:= StatusReporter.new()

var model:= GodotVTSModel.new()
var window_size: Vector2


func _ready() -> void:
	_socket_state_changed.connect(_on_socket_state_changed)
	_vts_state_reported.connect(_on_vts_state_reported)


func _report(state: String, subscope: String = '') -> void:
	var scope = GVTS
	if subscope: scope = '%s.%s' % [GVTS, subscope]
	status.report(scope, state)
	_logger.debug('status updated: %s' % state)


func sign_in() -> void:
	_report('waiting loaded vts')
	_udp = UDPServer.new()
	_udp.listen(47779)

	var is_active: bool = await _vts_state_reported
	if not is_active:
		_report('enable plugin server api')
		_logger.warn('Error connecting with vts, Plugin API needs to be enabled')
		var counter:= 0
		while counter < 150:
			_logger.debug('waiting for plugin API...')
			is_active = await _vts_state_reported
			if is_active: break
			counter += 1
		if not is_active:
			_report('error')
			_logger.error('timeout trying to connect to vts, restart app after enabling plugins on vts')
			return
		_logger.debug('plugin API activated')

	_connect_to_port(_vts_current_port)
	await connected

	if not _token:
		_report('token_requested')
		var auth_token: Dictionary = await _send('AuthenticationTokenRequest', {
			'pluginName': GodotVTubeStudioSettings.plugin_name,
			'pluginDeveloper': GodotVTubeStudioSettings.plugin_developer,
			}).response
		_token = auth_token.data.get('authenticationToken', '')
		if not _token:
			_report('error')
			_logger.error('error authing: %s' % auth_token.data.message)
			return

	_report('authenticating')
	var auth: Dictionary = await _send('AuthenticationRequest', {
		'pluginName': GodotVTubeStudioSettings.plugin_name,
		'pluginDeveloper': GodotVTubeStudioSettings.plugin_developer,
		'authenticationToken': _token,
		}).response
	if not auth.data.get('authenticated'):
		_report('error')
		_logger.debug('error authing: %s' % auth.data.reason)
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

	_report('ok')


func is_ready() -> bool:
	return status.get_status(GVTS) == 'ok'


func _connect_to_port(port:= 8001) -> void:
	var url = VTS_URL % port
	_logger.debug('connecting to "%s"' % url)

	_socket = WebSocketPeer.new()
	_socket.connect_to_url(url)
	_report('websocket_requested')


func _send(type: String, data: Dictionary = {}) -> Request:
	var req:= Request.new()
	_socket.send_text(req.get_payload(type, data))
	_ongoing_requests.set(req.id, req)
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
		_ongoing_subscriptions.set(event, req)
	return req



func move_model(new_transform: GodotVTSModel, relative:=true, duration:= 0.0) -> Request:
	return _send('MoveModelRequest', {
		'timeInSeconds': duration,
		'valuesAreRelativeToModel': relative,
		'positionX': new_transform.position.x,
		'positionY': new_transform.position.y,
		'rotation': new_transform.rotation,
		'size': new_transform.size,
		})


func _process(_delta: float) -> void:
	_poll_udp()
	_poll_socket()


func _poll_udp() -> void:
	if not _udp: return

	_udp.poll()
	if not _udp.is_connection_available(): return

	var peer: PacketPeerUDP = _udp.take_connection()
	# Process the newly connected peer
	if peer.get_available_packet_count() <= 0: return

	var data = peer.get_packet()
	var json = JSON.parse_string(data.get_string_from_utf8())

	if !(json.get('data', {}) is Dictionary):
		_logger.info('unexpected format of vts packet, ignoring packet')
		return

	var is_vts_plugin_active: bool = json.data.get('active', false)
	var instance_id: String = json.data.get('instanceID', '')
	var port: int = json.data.get('port', 8001)

	if _vts_current_instance_id:
		if _vts_current_instance_id != instance_id:
			_logger.info('received notification from an unexpected instance of vtube studio, ignoring')
			return
		if not is_vts_plugin_active:
			_vts_state_reported.emit(false)
	else:
		if is_vts_plugin_active:
			_vts_current_instance_id = instance_id
			_vts_current_port = port
			_logger.debug('vts instance id and port updated')
		_vts_state_reported.emit(is_vts_plugin_active)


func _on_vts_state_reported(active: bool) -> void:
	if active: return

	# never was connected to begin with
	if not _vts_current_instance_id: return

	_logger.info("vtube studio's plugin api became inactive")

	_vts_current_instance_id = ''
	_vts_current_port = 8001


func _poll_socket() -> void:
	if not _socket: return

	_socket.poll()
	var state:= _socket.get_ready_state()
	_socket_ready_state = state
	match state:
		WebSocketPeer.STATE_OPEN:
			while _socket.get_available_packet_count():
				var data = _socket.get_packet()
				var json = JSON.parse_string(data.get_string_from_utf8())
				_logger.debug('received data %s' % json.messageType)

				var req = _ongoing_requests.get(json.requestID)
				if req:
					req.response.emit(json)
					_ongoing_requests.erase(json.requestID)

				var event = _ongoing_subscriptions.get(json.messageType)
				if event: event.event.emit(json)
		WebSocketPeer.STATE_CLOSED:
			var code = _socket.get_close_code()
			var reason = _socket.get_close_reason()
			_logger.info("WebSocket closed with code: `%d`, reason `%s`. Clean: `%s`" % [code, reason, code != -1])
			_socket = null
			if _vts_current_instance_id and code == 1001:
				_logger.debug("vts closed")
				_vts_state_reported.emit(false)
			disconnected.emit()


func _on_socket_state_changed(state: int) -> void:
	match state:
		WebSocketPeer.STATE_CONNECTING:
			_report('websocket_connecting')
		WebSocketPeer.STATE_OPEN:
			_report('websocket_established')
			var api_state: Dictionary = await _send('APIStateRequest').response
			_logger.debug('handshake: %s' % api_state.data.active)
			connected.emit()
		WebSocketPeer.STATE_CLOSING:
			_report('websocket_closing')
		WebSocketPeer.STATE_CLOSED:
			_report('websocket_closed')


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
