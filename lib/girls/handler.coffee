_          = require 'lodash'
AWS        = require 'aws-sdk'
Dispatcher = require '../dispatcher'

Generator  = require './'

AWS.config.region = 'eu-west-1'

class Handler

	handle: (event, context) ->
		eventSource = _.result event, 'Records[0].EventSource'
		if eventSource is 'aws:sns'
			@handleSNSEvent event, context
		else
			@handleAPIEvent event, context

	handleAPIEvent: (event, context) ->
		input =
			payload: event.payload
		generator = new Generator()
		generator.generate input
		generator.on 'finish', @handleAPISuccess({}, context)
		generator.on 'error', @handleAPIError({}, context)

	handleAPIError: (message, context) ->
		(error) ->
			context.fail(error)

	handleAPISuccess: (message, context) ->
		(result) ->
			context.succeed(result)

	handleSNSEvent: (event, context) ->
		snsMessage = JSON.parse(event.Records[0].Sns.Message)

		generator = new Generator()
		generator.generate snsMessage.payload
		generator.on 'finish', @handleSNSSuccess(snsMessage, context)
		generator.on 'error', @handleSNSFail(snsMessage, context)

	handleSNSFail: (snsMessage, context) ->
		(error) ->
			errorMessage =
				type: 'bikini-girls-with-machine-guns-error'
				payload:
					data: snsMessage.payload
					error: error

			dispatcher = new Dispatcher()
			dispatcher.publishToTopic snsMessage.errorTopic, errorMessage, (err, data) ->
				if err?
					console.log(err.stack)
				context.fail(error)

	handleSNSSuccess: (snsMessage, context) ->
		(result) ->
			successMessage =
				type: 'bikini-girls-with-machine-guns-success'
				payload:
					data: snsMessage.payload
					result: result

			dispatcher = new Dispatcher()
			dispatcher.publishToTopic snsMessage.successTopic, successMessage, (err, data) ->
				if err?
					console.log(err.stack)
				context.succeed(result)

module.exports = (event, context) ->
	handler = new Handler()
	handler.handle(event, context)