{EventEmitter} = require 'events'
async          = require 'async'
joi            = require 'joi'
_              = require 'lodash'

path           = require 'path'
fs             = require 'fs'
childProcess   = require 'child_process'

schema         = require './schema'
log            = require '../log'

class Girls extends EventEmitter

	constructor: (options) ->
		super

	generatePromise: (input) ->
		p = new Promise (resolve, reject) =>
			@generateTask(input) (err, result) ->
				if err?
					reject err
				else
					resolve result

	generateTask: (input) ->
		(cb) =>
			@generate input, (err, results) ->
				if err?
					cb err
				else
					cb null, results

	generate: (input, cb) ->
		work = []
		work.push (callb) =>
			@_validate input, callb
		work.push (callb) =>
			log.info input, 'Girls::request'
			@_generateResult input, callb
		async.waterfall work, (err, result) =>
			if err?
				if cb?
					cb err
				else
					log.info err, 'Girls::error'
					@emit 'error', err
			else
				if cb?
					cb? null, result
				else
					log.info result, 'Girls::success'
					@emit 'finish', result

	_generateResult: (input, cb) ->
		@_callPhantom input, (err, output) ->
			cb? null, output

	_validate: (input, cb) ->
		joi.validate input, schema.input, {abortEarly: false, allowUnknown: true}, (bodyErr, value) =>
			if bodyErr?
				@_handleValidationError bodyErr, (handleErr) ->
					cb handleErr
			else
				cb null

	_handleValidationError: (err, cb) ->
		validations = _.map err.details, 'message'
		badRequest =
			status: 400
			name: 'BAD_REQUEST'
			message: "#{(message for message in validations).join(', ')}"
		cb badRequest

	_getPhantomFileName: (cb) ->
		nodeModulesPath = path.join(__dirname, '../../node_modules/phantomjs')
		fs.exists nodeModulesPath, (exists) ->
			if exists
				cb null, path.join(__dirname, '../../node_modules','phantomjs', 'bin', 'phantomjs')
			else
				cb null, path.join(__dirname, '../../phantomjs')

	_callPhantom: (input, cb) ->
		@_getPhantomFileName((err, phantomJsPath) ->
			childArgs = [
				path.join(__dirname, '../phantomjs/phantom.js')
				JSON.stringify(input)
			]
			output =
				success: ''
				fail: ''
			process.env['LD_WARN'] = true
			libraryPath = path.join(__dirname, '../..')
			log.info libraryPath, 'Girls:: library path'
			process.env['LD_LIBRARY_PATH'] = libraryPath
			log.info input, 'Girls:: launching PhantomJS'
			log.info phantomJsPath, 'Girls:: launching phantomjs location'
			log.info childArgs, 'Girls:: launching args'
			phantomProcess = childProcess.execFile(phantomJsPath, childArgs)
			phantomProcess.stdout.on 'data', (data) ->
				log.info "Girls::Received ok stuff from PhantomJS: #{data}"
				if data?
					# Yay, dirty hack because of https://github.com/ariya/phantomjs/issues/12697
					output.success += data.replace(new RegExp('Unsafe JavaScript attempt to access frame with URL.*','g'), '').trim()

			phantomProcess.stderr.on 'data', (data) ->
				log.info "Girls::Received fail stuff from PhantomJS: #{data}"
				if data?
					output.fail += data.replace(new RegExp('Unsafe JavaScript attempt to access frame with URL.*','g'), '').trim()

			phantomProcess.on 'exit', (code) ->
				if !!output.success
					try
						output.success = JSON.parse(output.success)
					catch e
						log.error output.success
						log.error e, 'Failed parsing result from PhantomJS'
						output.success = {}
				else
					output.success = {}
				if !!output.fail
					try
						output.fail = JSON.parse(output.fail)
					catch e
						log.error output.fail
						log.error e, 'Failed parsing result from PhantomJS'
						output.fail = {}
				else
					output.fail = {}
				cb null, output
		)

module.exports = Girls