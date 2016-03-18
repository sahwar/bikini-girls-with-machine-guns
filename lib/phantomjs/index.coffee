webpage        = require 'webpage'
uuid           = require 'node-uuid'
moment         = require 'moment'
system         = require 'system'
timer          = require '../timer'

args = system.args

input = JSON.parse(args[1])

# monkeypatch console.error
console.error = () ->
	system.stderr.write(Array.prototype.join.call(arguments, ' ') + '\n')

result =
	url: input.url
	pageErrors: []
	screenshot: {}

page = webpage.create()
if input.viewport?
	page.viewportSize = input.viewport
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
					result.screenshot.success = "screenshots/success-#{uuid.v4()}.png"
					if input.screenshots.args?
						page.render(result.screenshot.success, input.screenshots.args)
					else
						page.render(result.screenshot.success)
				if input.screenshots.error and result.pageErrors.length
					result.screenshot.error = "screenshots/error-#{uuid.v4()}.png"
					if input.screenshots.args?
						page.render(result.screenshot.error, input.screenshots.args)
					else
						page.render(result.screenshot.error)
				console.log JSON.stringify(result)
				phantom.exit()
			, 300
		else
			console.log JSON.stringify(result)
			phantom.exit()

)