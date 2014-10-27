require 'socket'                                    # Require socket from Ruby Standard Library (stdlib)

class Response
  def initialize(response_type, response_body)
    raise 'Invalid Response Type' if (response_type != :success && response_type != :fail)
    @response_type = response_type
    @response_body = response_body
  end

  def to_s
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

  def initialize
    host = 'localhost'
    port = 2000
    server = TCPServer.open(host, port)
    puts "Server started on #{host}:#{port} ..."
    response_handler(server)
  end



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

  def get_filename(lines)
    lines[0].gsub(/GET \//, '').gsub(/\ HTTP.*/, '')
  end

  def get_request(client)
    lines = []
    while !client.eof? && (line = client.gets.chomp) && !line.empty?
      lines << line
    end
    lines
  end

  def return_file(filename)
    if File.exists?(filename)
      File.read(filename)
    end
  end
end

Server.new