AWS = require 'aws-sdk'
url = require 'url'
AWS.config.region = 'eu-west-1'
SQSConsumer = require 'sqs-consumer'

class Dispatcher

	constructor: (options) ->
		@sns = new AWS.SNS(options?.sns)
		@sqs = new AWS.SQS(options?.sqs)

	createTopic: (topicName, cb) ->
		@sns.createTopic
			Name: topicName
		, cb

	deleteTopic: (topicName, cb) ->
		@sns.deleteTopic
			TopicArn: ''
		, cb

	createQueue: (queueName, cb) ->
		@sqs.createQueue
			QueueName: queueName
		, cb

	deleteQueue: (queueName, cb) ->
		@getQueueUrl queueName, (err, queueUrl) =>
			@sqs.deleteQueue
				QueueUrl: queueUrl
			, cb

	publishToTopic: (topic, message, cb) ->
		@sns.publish
			Message: JSON.stringify(message)
			TopicArn: topic
		, cb

	parseTopicEvent: (event) ->
		JSON.parse(event.Records[0].Sns.Message)

	listenToQueue: (queueName, messageHandler, cb) ->
		@getQueueUrl queueName, (err, queueUrl) =>
			if err?
				console.log err
				cb? err
			else
				listener = SQSConsumer.create
					queueUrl: queueUrl
					handleMessage: @_queueEventHandler(messageHandler)
					sqs: @sqs

				listener.on 'error', (err) ->
					console.log err.message

				listener.start()
				cb? null, listener

	getQueueUrl: (queueName, cb) ->
		@sqs.getQueueUrl {QueueName: queueName}, (err, data) =>
			if err?
				cb err
			else
				parsed = url.parse(data.QueueUrl)
				parsed.host = @sqs.endpoint.host
				cb null, url.format(parsed)


	sendQueueMessage: (queueName, message, cb) ->
		@getQueueUrl queueName, (err, queueUrl) =>
			@sqs.sendMessage
				QueueUrl: queueUrl
				MessageBody: JSON.stringify(message)
			, cb

	_queueEventHandler: (messageHandler) ->
		(event, done) ->
			message = JSON.parse(event.Body)
			if message?.Message?
				message = JSON.parse(message.Message)

			messageHandler message, done

module.exports = Dispatcher
