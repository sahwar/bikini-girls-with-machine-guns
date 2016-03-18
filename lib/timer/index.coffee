_      = require 'lodash'

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

module.exports = new Timer()