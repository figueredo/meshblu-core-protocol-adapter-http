_ = require 'lodash'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class JobToHttp
  constructor: () ->
    @authParser = new MeshbluAuthParser

  httpToJob: ({jobType, request, toUuid, data}) ->
    data ?= request.body
    userMetadata = @getMetadataFromHeaders request.headers

    auth = @authParser.parse request
    systemMetadata =
      auth: auth
      fromUuid: request.get('x-meshblu-as') ? auth.uuid
      toUuid: toUuid
      jobType: jobType

    job =
      metadata: _.extend userMetadata, systemMetadata
      data: data

    job

  getMetadataFromHeaders: (headers) =>
    _.transform headers, (newMetadata, value, header) =>
      return unless _.startsWith header, 'x-meshblu-'
      key = _.camelCase( _.replace(header, "x-meshblu-", '' ))
      newMetadata[key] = value

  sendJobResponse: ({jobResponse, res}) ->
    return res.sendStatus(500) unless jobResponse?
    _.each jobResponse.metadata, (value, key) => res.set "x-meshblu-#{_.kebabCase(key)}", value

    return res.sendStatus jobResponse.metadata.code unless jobResponse.rawData?

    res.status(jobResponse.metadata.code).send JSON.parse(jobResponse.rawData)

  module.exports = JobToHttp
