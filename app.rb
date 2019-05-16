require 'net/http'
require 'net/https'
require 'net/smtp'

class ServerStatus

  attr_reader :mail, :urls, :msg, :status

  def initialize(urls, mail)
    @urls = urls
    @mail = mail
    @status = {}
    urls.each do |v|
    status.store(v, '200')
      end
  end

  def perform
    loop do
      urls.each do |url|
        check(response(url), url)
      end
      sleep 10
    end
  end

  private

  def response(url)
    begin
    uri = URI(url)
    Net::HTTP.get_response(uri)
    rescue
      if status.value?('not available')
        puts 'server still not available, do nothing'
        sleep 10
        retry
      end
      status.store(url, 'not available')
      msg = "Subject: Warning!\n\nserver: #{url}\nstatus: not available"
      mail.perform(msg)
      puts 'server not available, send mail'
      sleep 10
      retry
  end

  def check(res, url)
    if res.code == '200' && status[url] == '200'
      puts '200, do nothing'
    elsif res.code != '200' && status[url] == '200'
      puts 'not 200, send mail'
              msg = "Subject: Warning!\n\nserver: #{url}\nstatus: #{res.code}\nanswer: #{res.message}"
              mail.perform(msg)
    elsif res.code == '200' && status[url] != '200'
      puts 'again 200, send mail'
              msg = "Subject: Don't worry!\n\nserver: #{url}\nstatus: #{res.code}\nanswer: #{res.message}"
              mail.perform(msg)
    elsif res.code != '200' && status[url] != '200'
      puts 'not 200 yet, do nothing'
    end
    status[url] = res.code
  end

end

class Mailer

  attr_reader :receiver_email, :sender_email, :sender_password

  def initialize(receiver_email, sender_email, sender_password)
    @receiver_email = receiver_email
    @sender_email = sender_email
    @sender_password = sender_password
  end


  def perform(msg)
    smtp = Net::SMTP.new 'smtp.gmail.com', 587
    smtp.enable_starttls
    smtp.start('gmail.com', sender_email, sender_password, :login) do
      smtp.send_message(msg, sender_email, receiver_email)
    end
  end

end

mail = Mailer.new('', '', '')
service = ServerStatus.new(%w[https://www.facebook.com/ https://www.youtube.com/], mail)
service.perform