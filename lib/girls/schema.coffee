Joi = require 'joi'

inputSchema = Joi.object().keys(
	url: Joi.string().uri().required()
	viewport: Joi.object().keys(
		width: Joi.number().integer().min(0).required()
		height: Joi.number().integer().min(0).required()
	).optional()
	screenshots: Joi.object().keys(
		args: Joi.object().keys(
			format: Joi.any().valid(['jpeg', 'png']).required()
			quality: Joi.string().optional()
		).optional()
		success: Joi.boolean().optional()
		error: Joi.boolean().optional()
		s3: Joi.object().keys(
			bucket: Joi.string().required()
			directory: Joi.string().required()
		).required()
	).optional()
	settings: Joi.object().optional()
	har: Joi.boolean().required()
)

module.exports.input = inputSchema