AWS    = require 'aws-sdk'
fs     = require 'fs'
path   = require 'path'
log    = require '../log'

class S3Store

	constructor: ->
		@initializeS3()

	initializeS3: ->
		AWS.config.update
			region: 'eu-west-1'
		@s3 = new AWS.S3()

	### Upload ###

	upload: (bucket, filepath, s3subDir, mimetype, cb) ->
		fs.readFile filepath, (err, data) =>
			if err?
				log.error err, "S3Store:: could not read file #{filepath} for upload"
				cb err
			else
				filename = path.basename(filepath)
				@_uploadData bucket, "#{s3subDir}/#{filename}", mimetype, data, cb

	_uploadData: (bucket, key, mimetype, data, cb) ->
		@_uploadToBucket bucket, key, mimetype, 'public-read', data, cb

	_uploadToBucket: (bucket, key, mimetype, acl, data, cb) ->
		@s3.putObject
			Bucket: bucket
			Key: key
			Body: data
			ContentType: mimetype
			ACL: acl
		, (err, s3_data) =>
			log.info {key: key, bucket: bucket}, "S3Upload success"
			if err?
				log.error err, "S3Store:: error uploading file with key #{key} to bucket #{bucket}"
			cb err, "#{@s3.endpoint.href}#{bucket}/#{key}"

module.exports = S3Store
