webpage        = require 'webpage'
uuid           = require 'node-uuid'
system         = require 'system'

class Timer

	constructor: ->
		@resources = []

	start: ->
		@startTime = new Date()

	stop: ->
		@endTime = new Date()

	request: (resource) ->
		@resources[resource.id] =
			request: resource
			startReply: null,
			endReply: null

	replyStart: (resource) ->
		foundResource = @resources[resource.id]
		if foundResource?
			foundResource.startReply = resource

	replyEnd: (resource) ->
		foundResource = @resources[resource.id]
		if foundResource?
			foundResource.endReply = resource

	createHAR: (address, title) ->
		entries = []

		@resources.forEach (resource) ->
			request = resource.request
			startReply = resource.startReply
			endReply = resource.endReply

			if !request or !startReply or !endReply
				return

			if request.url.match(/(^data:image\/.*)/i)
				return

			entries.push
				startedDateTime: request.time.toISOString()
				time: endReply.time - request.time
				request:
					method: request.method
					url: request.url
					httpVersion: "HTTP/1.1"
					cookies: []
					headers: request.headers
					queryString: []
					headersSize: -1
					bodySize: -1
				response:
					status: endReply.status
					statusText: endReply.statusText
					httpVersion: "HTTP/1.1"
					cookies: []
					headers: endReply.headers
					redirectURL: ""
					headersSize: -1
					bodySize: startReply.bodySize
					content:
						size: startReply.bodySize
						mimeType: endReply.contentType
				cache: {}
				timings:
					blocked: 0
					dns: -1
					connect: -1
					send: 0
					wait: startReply.time - request.time
					receive: endReply.time - startReply.time
					ssl: -1
				pageref: address

		result =
			log:
				version: '1.2'
				creator:
					name: 'BikiniGirlsWithMachineGuns'
					version: '0.0.1'
				pages: [
					{
						startedDateTime: @startTime.toISOString()
						id: address
						title: title
						pageTimings:
							onLoad: @endTime - @startTime
					}
				]
				entries: entries

args = system.args

# monkeypatch console.error
console.error = () ->
	system.stderr.write(Array.prototype.join.call(arguments, ' ') + '\n')

try
	input = JSON.parse(args[1])
catch error
	err =
		message: error.message
	console.error JSON.stringify(err)
	phantom.exit()

result =
	url: input.url
	pageErrors: []
	screenshot: {}

timer = new Timer()

page = webpage.create()
if input.viewport?
	page.viewportSize = input.viewport
if input.settings?
	page.settings = input.settings
page.onLoadStarted = ->
	timer.start()
page.onError = (message, trace) ->
	result.pageErrors.push
		message: message
		trace: trace
page.onResourceRequested = (request) ->
	timer.request request
page.onResourceReceived = (response) ->
	if response.stage is 'start'
		timer.replyStart response
	if response.stage is 'end'
		timer.replyEnd response

page.open(input.url, (status) ->
	result.status = status
	if status isnt 'success'
		console.error JSON.stringify(result)
		phantom.exit()
	else
		timer.stop()
		result.title = page.evaluate ->
			document.title
		if input.har
			result.har = timer.createHAR(input.url, result.title)
		if input.screenshots?
			setTimeout ->
				if input.screenshots.success
					if input.screenshots.args?
						extension = input.screenshots.args.format
						result.screenshot = "screenshots/success-#{uuid.v4()}.#{extension}"
						page.render(result.screenshot, input.screenshots.args)
					else
						result.screenshot = "screenshots/success-#{uuid.v4()}.png"
						page.render(result.screenshot)
				if input.screenshots.error and result.pageErrors.length
					if input.screenshots.args?
						extension = input.screenshots.args.format
						result.screenshot = "screenshots/error-#{uuid.v4()}.#{extension}"
						page.render(result.screenshot, input.screenshots.args)
					else
						result.screenshot = "screenshots/error-#{uuid.v4()}.png"
						page.render(result.screenshot)
				console.log JSON.stringify(result)
				phantom.exit()
			, 10
		else
			console.log JSON.stringify(result)
			phantom.exit()

)