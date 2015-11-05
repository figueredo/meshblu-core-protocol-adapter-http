Subscriber     = require '../models/subscriber'
MeshbluAuthParser = require '../helpers/meshblu-auth-parser'

class SubscriptionsController
  constructor: ({@timeoutSeconds}={}) ->
    @timeoutSeconds ?= 30
    @authParser = new MeshbluAuthParser

  getAll: (request, response) =>
    subscriber = new Subscriber client: request.connection, timeoutSeconds: @timeoutSeconds

    internalRequest =
      auth:     @authParser.parse request
      fromUuid: request.get('x-as')
      toUuid:   request.params.uuid

    subscriber.getSubscriptions internalRequest, (error, subscribeResponse) =>
      return response.status(502).end() if error?
      {code,data} = subscribeResponse
      response.status(code).json data

module.exports = SubscriptionsController