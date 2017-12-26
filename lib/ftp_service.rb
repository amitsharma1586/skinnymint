require 'net/sftp'
# FTP class handle SFTP connection
class FtpService
  attr_reader :host, :username, :password

  def initialize(host, username, password)
    @host = host
    @username = username
    @password = password
  end

  def connect
    Net::SFTP.start(host, username, password: password) do |sftp|
      if block_given?
        yield sftp
      else
        sftp
      end
    end
  end

  def download_dir(path = 'outbound')
    files = []
    connect do |conn|
      conn.dir.foreach(path) do |file|
        if file.name.ends_with? 'xml'
          conn.download! path + '/' + file.name, 'tmp/' + file.name
          files << 'tmp/' + file.name
        end
      end
    end
    files
  end

  def move(from, to)
    connect do |conn|
      conn.rename from, to
    end
  end

  def upload(path)
    connect do |conn|
      conn.upload!(path, '/orders/' + path)
    end
  end
end
