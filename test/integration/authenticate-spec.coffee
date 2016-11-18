_                       = require 'lodash'
UUID                    = require 'uuid'
request                 = require 'request'
Server                  = require '../../src/server'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

describe 'Authenticate', ->
  beforeEach (done) ->
    @responseQueueId = UUID.v4()
    @requestQueueName = "request:queue:#{@responseQueueId}"
    @responseQueueName = "response:queue:#{@responseQueueId}"
    @namespace = 'test:meshblu-http'
    @jobLogQueue = 'test:meshblu:job-log'
    @port = 0xd00d
    @sut = new Server {
      @port
      disableLogging: true
      jobTimeoutSeconds: 1
      @namespace
      @jobLogQueue
      jobLogRedisUri: 'redis://localhost:6379'
      jobLogSampleRate: 10
      redisUri: 'redis://localhost'
      cacheRedisUri: 'redis://localhost'
      @requestQueueName
      @responseQueueName
    }

    @sut.run done

  afterEach (done) ->
    @sut.stop => done()

  beforeEach (done) ->
    @redis = new RedisNS @namespace, new Redis 'localhost', dropBufferSupport: true
    @redis.on 'ready', done

  afterEach (done) ->
    @redis.del @requestQueueName, @responseQueueName, done
    return # avoid returning redis

  beforeEach (done) ->
    @queueRedis = new RedisNS @namespace, new Redis 'localhost', dropBufferSupport: true
    @queueRedis.on 'ready', done

  beforeEach ->
    @jobManager = new JobManagerResponder {
      client: @redis
      queueClient: @queueRedis
      queueTimeoutSeconds: 1
      jobTimeoutSeconds: 1
      jobLogSampleRate: 1
      requestQueueName: @requestQueueName
      responseQueueName: @responseQueueName
    }

  describe 'POST /authenticate', ->
    context 'when the request is successful', ->
      beforeEach ->
        @jobManager.do (@request, callback) =>
          response =
            metadata:
              code: 204
              responseId: @request.metadata.responseId

          callback null, response

      beforeEach (done) ->
        options =
          auth:
            username: 'irritable-captian'
            password: 'poop-deck'

        request.post "http://localhost:#{@port}/authenticate", options, (error, @response) =>
          done error

      it 'should have jobType Authenticate', ->
        expect(@request.metadata.jobType).to.equal 'Authenticate'

      it 'should have auth correct', ->
        expect(@request.metadata.auth).to.deep.equal uuid: 'irritable-captian', token: 'poop-deck'

      it 'should return a 204', ->
        expect(@response.statusCode).to.equal 204

  describe 'GET /authenticate/:uuid', ->
    context 'when the request is successful', ->
      beforeEach ->
        @jobManager.do (@request, callback) =>
          response =
            metadata:
              code: 204
              responseId: @request.metadata.responseId

          callback null, response

      beforeEach (done) ->
        options =
          auth:
            username: 'irritable-captian'
            password: 'poop-deck'
          qs:
            token: 'some-token'

        request.get "http://localhost:#{@port}/authenticate/some-uuid", options, (error, @response) =>
          done error

      it 'should have jobType Authenticate', ->
        expect(@request.metadata.jobType).to.equal 'Authenticate'

      it 'should have auth correct', ->
        expect(@request.metadata.auth).to.deep.equal uuid: 'some-uuid', token: 'some-token'

      it 'should return a 200', ->
        expect(@response.statusCode).to.equal 200
