require 'socket'

# Response class is responsible for creating the response string, given a response type (required) and body (optional).
class Response
  def initialize(response_type, response_body)
    # Fail if I do not have a valid response type.
    raise 'Invalid Response Type' if (response_type != :success && response_type != :fail)
    @response_type = response_type
    @response_body = response_body
  end

  #Overriding to_s method so it can take advantage of the default behaviour.
  def to_s
    #Applying to_s to the response body as it can be a nil object.
    #String + nil will fail. String + nil.to_s == String.
    header + @response_body.to_s
  end

  def header
    case @response_type
      when :success
        return success_header
      when :fail
        return failure_header
    end
  end

  def success_header
    success_header = ['HTTP/1.1 200 OK','Content-Type: text/html',"Content-Length: #{@response_body.length}",'Connection: close','','']
    success_header.join("\r\n")
  end

  def failure_header
    not_found_header = ['HTTP/1.1 404 Not Found','Content-Type: text/plain','Content-Type: 0','Connection: close']
    not_found_header.join("\r\n")
  end
end

class Server
  # Initializes and starts the server.
  def initialize
    host = 'localhost'
    port = 2000
    server = TCPServer.open(host, port)
    puts "Server started on #{host}:#{port} ..."
    execution_loop(server)
  end

  # Main Server Exection Loop
  def execution_loop(server)
    loop do
      # Start Listening
      client = server.accept
      request = get_request(client)

      #Skip to Next Loop if Empty
      if request.empty?
        client.close
        next
      end

      #Parse Request and File Existence
      filename = get_filename(request)
      response_body = return_file(filename)

      #Create Response
      if response_body
        response = Response.new(:success, response_body)
      else
        response = Response.new(:fail, nil)
      end

      #Return Response
      puts response
      client.puts(response)
      client.close
    end
  end

  # Method Parses the File Name given an array of response lines.
  def get_filename(response_lines)
    response_lines[0].gsub(/GET \//, '').gsub(/\ HTTP.*/, '')
  end

  # Method parses the request and returns an array of strings (one string per request line)
  def get_request(client)
    lines = []
    #Checking EOF? as line = client.gets.chomp will fail when EOF.
    #Keeping empty? check of line as it will loop until the session closes otherwise.
    while !client.eof? && (line = client.gets.chomp) && !line.empty?
      lines << line
    end
    lines
  end

  # Reads and returns the file specified. Returns nil if filename does not match a file.
  def return_file(filename)
    if File.exists?(filename)
      File.read(filename)
    end
  end
end

Server.new