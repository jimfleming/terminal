# wait until the page has loaded

window.onload = ->

  # initialize html elements
  $status = document.getElementById('current-status')
  $commandline = document.getElementById('command-line')
  $history = document.getElementById('history')
  $cwd = document.getElementById('cwd')

  # initialize html5 websockets client
  socket = new io.Socket(location.hostname, { transports : ['websocket'] })
  socket.connect()

  # update status of connection
  socket.on 'connect', ->
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

    # if output was in the message append it to the history
    $history.innerHTML += message.output + '\n' if message.output?

    # if error was in the message append it to the history
    $history.innerHTML += '<span class="error">' + message.error + '</span>\n' if message.error?

    # update the command line with any history
    $commandline.value = message.history if message.history?

    # update the cwd display underneath the input
    $cwd.innerHTML = message.cwd if message.cwd?

    # clear the output if clear response
    $history.innerHTML = '' if message.output is '[H[2J'

    # scroll to the bottom of the history
    $history.scrollTop = $history.scrollHeight

  # send data to server on key events
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

    switch e.keyCode
      when 67
        if e.ctrlKey
          $history.innerHTML += '<span class="command">' + $commandline.value + '^C</span>\n'
          $commandline.value = ''
