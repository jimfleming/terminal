# import necessary modules

http  = require('http')
url   = require('url')
fs    = require('fs')
sys    = require('sys')
path  = require('path')
io    = require('socket.io')
exec  = require('child_process').exec


# set ps title

process.title = 'terminal.js'

cwd = process.cwd()


# 404 response helper

respond_404 = (response) ->
  response.writeHead(404, { 'Content-Type' : 'text/plain' })
  response.write('404 Not Found\n')
  response.end()
  return


# 500 response helper

respond_500 = (response, error) ->
  response.writeHead(500, { 'Content-Type' : 'text/plain' })
  response.write(error + '\n')
  response.end()
  return


# initialize web server (essentially a file server - doesn't do anything special)

server = http.createServer (request, response) ->

  process.chdir(cwd) if process.cwd() isnt cwd
  
  # file mapping to restrict file serving
  mapping =
    '/'           : 'index.html'
    '/client.js'  : 'client.js'
    '/styles.css' : 'styles.css'
    '/font.css'   : 'font.css'
    '/DroidSansMono.ttf'   : 'DroidSansMono.ttf'

  # get the requested path
  uri = url.parse(request.url).pathname

  # build local path
  filename = 'lib/' + mapping[uri]

  # make sure the file is permitted
  if filename
    # make sure the file exists
    path.exists filename, (exists) ->
      # let the user know it doesn't exist
      if not exists
        respond_500(response)
        return

      # read the file and stream it over the http server
      fs.readFile filename, 'binary', (error, file) ->
        # let the user know if an error occurs
        if error?
          respond_500(response)
          return

        # write the file to the stream
        response.writeHead(200)
        response.write(file, 'binary')
        response.end()

      return
  # the file isn't permitted
  else
    respond_404(response)
    return

  return


# start http server on localhost:8000

server.listen(8000)


# initialize html5 websocket server

socket = io.listen(server, { transports : ['websocket'] })

# client history buffer
command_history = []
# index within client history
command_history_index = 0
# cwd of the child process
command_cwd = cwd

 # when a client connects...

socket.on 'connection', (client) ->

  client.send(JSON.stringify({ 'cwd': command_cwd }))

  # when the client sends a message to the server:
  client.on 'message', (data) ->
    # they pressed `up`
    if data.up? and command_history.length > 0
      command_history_index--
      command_history_index = command_history.length - 1 if command_history_index < 0

      client.send(JSON.stringify({ 'history': command_history[command_history_index] }))

    # they pressed `down`
    if data.down? and command_history.length > 0
      command_history_index++
      command_history_index %= command_history.length

      client.send(JSON.stringify({ 'history': command_history[command_history_index] }))

    # they pressed `enter`
    if data.command?
      pieces = data.command.split(' ')
      
      if pieces[0] is 'exit' or pieces[0] is 'quit'
        process.exit()
        
      if pieces[0] is 'cd'
        try
          process.chdir(command_cwd)
          command_cwd = fs.realpathSync(if pieces.length > 1 then pieces[1] else process.env.HOME)
          client.send(JSON.stringify({ 'cwd': command_cwd }))
        catch error
          client.send(JSON.stringify({ 'error': error.toString(), 'cwd': command_cwd }))
        return
        
      command_history.push(data.command)

      exec data.command, { cwd: command_cwd }, (error, stdout, stderr) ->
          client.send(JSON.stringify({ 'output': stdout.toString(), 'cwd': command_cwd })) if stdout?
          client.send(JSON.stringify({ 'error': stderr.toString(), 'cwd': command_cwd })) if stderr?
          sys.debug(error.toString()) if error
      
      command_history_index = 0

    return
  return
