# wait until page load

window.onload = ->

  # initialize dom elements
  
  $status = document.getElementById('current-status')
  $commandline = document.getElementById('command-line')
  $history = document.getElementById('history')


  # initialize websockets
  
  socket = new io.Socket(location.hostname, { transports : ['websocket'] })
  socket.connect();


  # update status of connection
  
  socket.on 'connect', ->
    # TODO: load output history and input history
    $status.className = 'connected'

  socket.on 'close', ->
    $status.className = ''


  socket.on 'connect_failed', ->
    $status.className = 'error'


  socket.on 'disconnect', ->
    $status.className = ''
    
    
  # do something with the response
  
  socket.on 'message', (message) ->
    message = JSON.parse(message)
    
    $history.innerHTML += message.output + '\n' if message.output?
    $commandline.value = message.history if message.history?
    
    $history.scrollTop = $history.scrollHeight
    

  # send data to server
  
  # TODO: style history
  # TODO: tips + ex + args
  # TODO: async tasks /w loading
  # TODO: ^A, ^E, Enter ('')
  # TODO: autocomplete
  # TODO: timestamps and pwd
  # TODO: merge IO - for vim, etc...
  # TODO: autoreconnect
  # TODO: formatting???
  $commandline.addEventListener 'keyup', (e) ->
    switch e.keyIdentifier
      when 'Enter'
        socket.send({ 'command': $commandline.value })
        $history.innerHTML += '<span class="command">' + $commandline.value + '</span>\n'
        $commandline.value = ''
        $history.scrollTop = $history.scrollHeight
      when 'Up'
        socket.send({ 'up' })
      when 'Down'
        socket.send({ 'down' })
      when 'Left'
        socket.send({ 'left' })
      when 'Right'
        socket.send({ 'right' })

    switch e.keyCode
      when 67
        socket.send({ 'kill' }) if e.ctrlKey
    
