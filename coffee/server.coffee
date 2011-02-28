# TODO: vim, clear?
# TODO: ^C
# TODO: persisted history and log
# TODO: cd

# import necessary modules

http  = require('http')
url   = require('url')
fs    = require('fs')
path  = require('path')
io    = require('socket.io')
spawn = require('child_process').spawn
exec  = require('child_process').exec


# set ps title

process.title = 'terminal.js'


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


# initialize web server

server = http.createServer (request, response) ->
  mapping = # file mapping to restrict file serving
    '/' : 'index.html'
    '/client.js' : 'client.js'
    '/styles.css' : 'styles.css'

  uri = url.parse(request.url).pathname # get the requested path
  filename = 'lib/' + mapping[uri] # build local path

  if filename # make sure the file is permitted
    path.exists filename, (exists) -> # make sure the file exists
      if not exists # let the user know it doesn't exist
        respond_500(response)
        return

      fs.readFile filename, 'binary', (error, file) -> # read the file and stream it over the http server
        if error? # let the user know if an error occurs
          respond_500(response)
          return

        response.writeHead(200)
        response.write(file, 'binary')
        response.end()

      return
  else # the file isn't permitted
    respond_404(response)
    return

  return


server.listen(8000) # start the http server on 8000


# initialize the html5 websocket server

socket = io.listen(server, { transports : ['websocket'] }) 


 # when a client connects...
 
socket.on 'connection', (client) ->
  client_index = 0 # index within client history
  client_history = [] # client history buffer

  client.on 'message', (data) -> # when the client sends a message to the server...  
    if data.up? and client_history.length > 0
      client_index--
      client_index = client_history.length - 1 if client_index < 0

      client.send(JSON.stringify({ 'history': client_history[client_index] }))

    if data.down? and client_history.length > 0
      client_index++
      client_index %= client_history.length

      client.send(JSON.stringify({ 'history': client_history[client_index] }))
  
    if data.command?
      client_history.push(data.command)
      
      child = exec data.command, (error, stdout, stderr) ->
          client.send(JSON.stringify({ 'output': stdout.toString() })) if stdout?
          client.send(JSON.stringify({ 'output': stderr.toString() })) if stderr?
          client.send(JSON.stringify({ 'output': error.toString() })) if error?
          
      client_index = 0
      
    return
  return
