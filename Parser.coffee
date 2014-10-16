Packet = require './Packet'

module.exports = class Parser

  constructor: (@conditionField = 'opcode') ->
    @packetHead = null # packet header

    @packetCollection = { } # collection of packets
    @packetNameConditions = { }

  registerHead: () ->
    @packetHead = new Packet("_Head");

    return @packetHead

  getHead: () ->
    return @packetHead

  setConditionField: (@conditionField) ->

  getConditionField: () ->
    return @conditionField

  registerPacket: (name, condition = null) ->
    packet = new Packet(name)

    if @getHead()?
      for parse in @getHead().packetParseData
        packet.packetParseData.push parse # give all packets header packet

    @packetCollection[name] = packet

    @registerCondition name, condition if condition?

    return @packetCollection[name] # return packet

  # registers condition for given packet name
  registerCondition: (packetName, condition) ->
    if condition?
      @packetNameConditions[condition] = packetName

  getPacket: (name) ->
    return @packetCollection[name] if @packetCollection[name]?
    return null

  # parse given data by packet name
  parseByName: (data, packetName, callback) =>
    buffer = new Buffer(data)
    packet = @packetCollection[packetName]  

    @_parse @packetCollection[packetName], buffer, callback

  # parse given data by code table
  parse: (data, callback) =>
    buffer = new Buffer(data)

    @_parse @getHead(), data, (name, head) =>
      condition = head[@conditionField] # get switch condition

      packet = @packetCollection[@packetNameConditions[condition]]

      @_parse packet, buffer, callback

  _parse: (packet, buffer, callback) =>
    parsedData = { }
    index = 0

    for parser in packet.packetParseData
      readFunc = parser['read']
      name = parser['name']

      parsed = readFunc(buffer, index)
      index = parsed[1] # set the index to new index
      parsedData[name] = parsed[0]

    callback(packet.name, parsedData)

  serialize: (data, packetName, callback) =>
    packet = @packetCollection[packetName]
    bufferArray = [ ]

    for parser in packet.packetParseData
      writeFunc = parser['write']
      name = parser['name']

      continue if not data[name]? # continue when not set (optional maybe?)

      serialized = writeFunc(data[name])
      bufferArray.push serialized

    callback(Buffer.concat bufferArray)