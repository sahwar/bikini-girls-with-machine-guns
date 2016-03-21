async       = require 'async'
_           = require 'lodash'
fs          = require 'fs'
path        = require 'path'
request     = require 'request'
uuid        = require 'node-uuid'
Progress    = require 'progress'

class Trigger

	constructor: (@options) ->
		@requests = require "#{@options.file}"
		@progress = new Progress('ETA: :etas (:percent) :current/:total :bar', { total: parseInt(@options.request_count, 10)})

	fire: (cb) ->
		girls = @castGirls @options.request_count
		async.mapLimit girls, @options.concurrent_limit, (girl, callb) =>
			request
				url: @options.endpoint
				method: 'POST'
				headers:
					'Content-Type': 'application/json'
					'x-api-key': @options.api_key
				json: girl
			, (error, response, body) =>
				@progress.tick()
				if error?
					callb error
				else
					if @options.dump?
						id = uuid.v4()
						work = []
						work.push (callback) =>
							if body.success?.status?
								@dump "success-#{id}", _.omit(body.success, 'har'), 'json', callback
							else
								callback null
						work.push (callback) =>
							if body?.success?.har?
								@dump "success-#{id}", body.success.har, 'har', callback
							else
								callback null
						async.parallel work, callb
					else
						if body?.success?.status?
							callb null, body.success
						if body?.error?.status?
							callb "ERROR while fetching: #{girl.payload.url}"

		, (err, result) ->
			cb err, _.chain(result).flatten().compact().value()

	castGirls: (size) ->
		girls = []
		for i in [0...size]
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