require 'faye/websocket'
require 'em/pure_ruby'
require 'json'
require 'csv'
require 'open-uri'

liveid = ARGV[0].to_s # Get user input, set as liveid
abouturl = "http://www.reddit.com/live/#{liveid}/about.json" # Get url for live thread info
tries = 0

begin
  aboutjson = open(abouturl).read # Open live thread info JSON
rescue OpenURI::HTTPError => error
  tries += 1
  if tries < 3
    puts "#{error.message} - You'll most likely need to see here for the request rules: https://github.com/reddit/reddit/wiki/API/"
    puts "Sleeping ten seconds and retrying, attempt #{tries}/3"
    sleep(10)
    retry
  else
    puts "Exiting after 3 attemps"
    abort
  end
rescue Exception => e
  puts "Throw error's class was #{e.class}, message was #{e.message}"
  raise e
end

aboutparsed = JSON.parse(aboutjson) # Parse lt info JSON

wsurl = aboutparsed["data"]["websocket_url"] # Extract websocket_url from live thread info
title = aboutparsed["data"]["title"] # Extract title of live thread

puts "Found live thread with ID #{liveid} - \"#{title}\""

if not File.file?("#{title}.csv") # If our CSV file doesn't exist
  CSV.open("#{title}.csv", "a+") do |csv| # Open a new CSV file with title of live thread as filename
    csv << ['Date','Series1'] # Write label headers
  end
elsif File.file?("#{title}.csv") # Else, if file does exist
end # Continue


EM.run {
  ws = Faye::WebSocket::Client.new(wsurl) # Start WebSocket client with WebSocket url
  ws.onopen = lambda do |event| # Triggered when connection is open
    puts "Opened connection"
  end

  ws.onclose = lambda do |close| # Triggered when connection is closed
    p [:close, close.code, close.reason]
    EM.stop
  end

  ws.onerror = lambda do |error| # Triggered when error occurs
    p [:error, error.message]
  end

  ws.onmessage = lambda do |message| # Triggers when response is recieved
    count = nil
    time = Time.now.utc.strftime("%d/%m/%Y at %H:%M:%S")
    csvtime = Time.now.utc.strftime("%H:%M:%S") # For Excel, etc.
    csvdate = Time.now.utc.strftime("%Y-%m-%d") # For Excel, etc.
    csvnow = Time.now.utc.strftime("%Y/%m/%d %k:%M:%S") # Correct CSV format for HTML CSV plotting (dygraphs)
    incoming = JSON.parse(message.data) #hash of message (parsed JSON)
    puts incoming
    type = incoming["type"] # Look at incoming message's type
    if type == "activity" # If message type is activity
      puts "Recieved an activity message."
      array = JSON.parse(message.data) # Parse message data as JSON
      puts "Array: #{array}"
      count = array["payload"]["count"] # Extract current viewer count from message data
      puts "Number of viewers on #{time}: #{count}"
      CSV.open("#{title}.csv", "a+") do |csv| # Open CSV file with title (from live thread info), write on new line
        csv << [csvnow, count] # Write viewer count, current time, current date to csv
        puts "Recorded to CSV, filename #{title}.csv"
        break # Break out of CSV loop
      end
    elsif type == "complete" # If message type is complete, inform and abort
      puts "#{time} - Thread is over, bye!"
      abort
    elsif type == "update" # If message type is update, inform and print message data
      puts "Recieved an update"
      p [:update, message.data]
    end

  end
}
