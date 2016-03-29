async      = require 'async'
_          = require 'lodash'
request    = require 'request'
fs         = require 'fs'
path       = require 'path'
uuid       = require 'node-uuid'
Progress   = require 'progress'
Dispatcher = require '../dispatcher'

class Trigger

	constructor: (@options) ->
		@requests = require "#{@options.file}"
		@launchProgress = new Progress('Sending   -- ETA: :etas Elapsed: :elapsed (:percent) :current/:total :bar', { total: parseInt(@options.request_count, 10)})
		@receiveProgress = new Progress('Receiving -- ETA: :etas Elapsed: :elapsed (:percent) :current/:total :bar', { total: parseInt(@options.request_count, 10)})

	fireSNS: (cb) ->
		dispatcher = new Dispatcher()
		dispatcher.listenToQueue 'bikini-girls-with-machine-guns', @shellHandler
		girls = @castGirls @options.request_count
		console.log "Generating #{girls.length} girls..."
		async.mapLimit girls, parseInt(@options.concurrent_limit, 10), (girl, callb) =>
			girl.type = 'bikini-girls-with-machine-guns-request'
			# TODO configure these topics
			girl.errorTopic = '<error_topic>'
			girl.successTopic = '<success_topic>'

			launchDispatcher = new Dispatcher()
			launchDispatcher.publishToTopic @options.request_topic, girl, (err, data) =>
				@launchProgress.tick()
				if err?
					log.error err, "Girls::Error while publishing to topic #{@options.request_topic}"
				callb err, data
		, (err, result) ->
			cb err, _.chain(result).flatten().compact().value()

	fireAPI: (cb) ->
		girls = @castGirls @options.request_count
		concurrentLimit = parseInt(@options.concurrent_limit, 10)
		reqPool =
			maxSockets: concurrentLimit
		console.log "Spinning up #{girls.length} girls..."
		async.mapLimit girls, concurrentLimit, (girl, callb) =>
			request
				pool: reqPool
				url: @options.endpoint
				method: 'POST'
				headers:
					'Content-Type': 'application/json'
					'x-api-key': @options.api_key
				json: girl
			, (error, response, body) =>
				@launchProgress.tick()
				if error?
					callb error
				else
					if response.statusCode is 200
						if @options.dump?
							id = uuid.v4()
							work = []
							work.push (callback) =>
								if body.success?.status?
									@dump "success-#{id}", _.omit(body.success, 'har'), 'json', callback
								else
									callback null
							work.push (callback) =>
								if body.success?.har?
									@dump "success-#{id}", body.success.har, 'har', callback
								else
									callback null
							async.parallel work, callb
						else
							if body?.success?.status?
								console.log 'Load time:', body.success.har?.log?.pages?[0].pageTimings?.onLoad
								callb null, body.success
							else if body?.error?.status?
								callb null, body.error
							else
								callb null
					else
						# console.log 'code', JSON.stringify(response, null, '\t')
						callb null, "ERROR while invoking Lambda HTTP-code: #{response.statusCode} - (#{JSON.stringify(body)})"

		, (err, result) ->
			cb err, _.chain(result).flatten().compact().value()

	shellHandler: (shell, cb) =>
		@receiveProgress.tick()
		if shell.payload?.result?
			@handler shell.payload.result, (err, result) =>
				if @receiveProgress.complete?
					process.exit()
				else
					cb err, result
		else
			cb null

	handler: (shell, cb) =>
		if @options.dump?
			id = uuid.v4()
			work = []
			work.push (callback) =>
				if shell.success?.status?
					@dump "success-#{id}", _.omit(shell.success, 'har'), 'json', callback
				else
					callback null
			work.push (callback) =>
				if shell.success?.har?
					@dump "success-#{id}", shell.success.har, 'har', callback
				else
					callback null
			async.parallel work, cb
		else
			if shell?.success?.status?
				# console.log 'Load time:', shell.success.har?.log?.pages?[0].pageTimings?.onLoad
				cb null, shell.success
			else if shell?.error?.status?
				cb null, shell.error
			else
				cb null

	castGirls: (size) ->
		girls = []
		for i in [1..size]
			girls.push _.sample(@requests)
		girls

	dump: (id, obj, ext, cb) ->
		outputFilename = path.join @options.dump, "#{id}.#{ext}"
		fs.writeFile outputFilename, JSON.stringify(obj, null, 4), (err) ->
			if err?
				cb err
			else
				cb null, "Data saved to #{outputFilename}"

module.exports = Trigger