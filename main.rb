require 'faye/websocket'
require 'em/pure_ruby'
require 'json'
require 'csv'
require 'open-uri'
require 'rss'
require 'nokogiri'
require 'active_support/core_ext/enumerable'
require 'time'
require 'net/http'

feed = "http://www.reddit.com/r/VolunteerLiveTeam/.rss"
lastChecked = Time.now.to_f
now = Time.now.to_f
def search(livethreads, lastChecked)
  puts "Checked for new thread at #{Time.at(lastChecked).utc}"
  now = Time.now.to_f
  livethreads.each do |thread| # For each
    found = false
    float = thread[:float]
    if float > lastChecked
      found = true
      puts "Found a new live thread."
      return [found, thread]
    else
      found = false
      return [found, now]
    end
  end
end

def search_rss(feed)
  tries = 0
  rss = RSS::Parser.parse(feed)
  array = []
  rss.items.each do |item|
    title = Nokogiri::HTML(item.title.to_s).xpath('/html/head/title').text
    postlink = (Nokogiri::HTML(item.link.to_s).css('link[href]').map { |link| link['href'] })
    postlinkjson = "#{postlink.join("")}about.json"
    date = Nokogiri::HTML(item.updated.to_s).text
    float = Time.parse(Nokogiri::HTML(date.to_s).text).to_f # Parse the time string as a time object, and convert to float
    if not title.match(/\[live\] (.*)/)
      next
    else
      h = {:title => title, :jsonlink => postlinkjson, :date => date, :float => float}
      array.push(h)
    end
  end
  return array
end

tries = 0
while true
  begin
    array = search_rss(feed) # Array of hashes of each [live] thread.
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

  found, lastChecked = search(array, lastChecked) # Returns an array of a value and a hash (the live thread)
  unless found # Unless found is truthy, do unless block. Otherwise, do else block.
    puts "No new live threads found, sleeping 2 minutes and retrying."
    sleep 120
    redo
  else
  	threadlink = (JSON.parse(open(lastChecked[:jsonlink]).read))[0]["data"]["children"][0]["data"]["url"]
    id = threadlink.match(/\/live\/(.*)/)[1] # Grab the hash from the array, reduce to a hash and grab the link element. Then match to get the ID.
    title = lastChecked[:title] # Grab the hash from the array, reduce to a hash and grab title element. NOTE: WE ARE USING LASTCHECKED BECAUSE IT THE SECOND VALUE RETURNED. DON'T WORRY, IT WORKS.
    puts "ID for the new live thread is: #{id}"
    puts "Title of the new live thread is \"#{title}\""
  end
  break
end

#id = ARGV[0].to_s # Get user input, set as liveid
abouturl = "http://www.reddit.com/live/#{id}/about.json" # Get url for live thread info
tries = 0

puts abouturl
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

if wsurl == nil # If there is no WebSocket URL
  puts "The live thread is over, exiting."
  abort # Exit
end

puts "Found live thread with ID #{id} - \"#{title}\""

if not File.file?("#{title}.csv") # If our CSV file doesn't exist
  CSV.open("#{title}.csv", "a+") do |csv| # Open a new CSV file with title of live thread as filename
    csv << ['Date','Series1'] # Write label headers
  end
elsif File.file?("#{title}.csv") # Else, if file does exist
end # Continue

def start_connection(url, id, title) # Define a new method for the WebSocket listener with URL, and pass the thread id and title into it
  EM.run {

    ws = Faye::WebSocket::Client.new(url) # Start WebSocket client with WebSocket url
    ws.onopen = lambda do |event| # Triggered when connection is open
      puts "Opened connection"
    end

    ws.onclose = lambda do |close| # Triggered when connection is closed
      p [:close, close.code, close.reason]
      start_connection(url) # Restart the connection
    end

    ws.onerror = lambda do |error| # Triggered when error occurs
      p [:error, error.message]
    end

    ws.onmessage = lambda do |message| # Triggers when response is recieved
      count = nil
      time = Time.now.utc.strftime("%d/%m/%Y at %H:%M:%S")
      csvtime = Time.now.utc.strftime("%H:%M:%S") # For Excel, etc.
      csvdate = Time.now.utc.strftime("%Y-%m-%d") # For Excel, etc.
      postnow = Time.now.utc.iso8601
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
        CSV.open("#{id}.csv", "a+") do |csv| # Open CSV file with title (from live thread ID), write on new line (a+)
          csv << [csvnow, count] # Write viewer count, current time, current date to csv
          puts "Recorded to CSV, filename #{title}.csv"
          break # Break out of CSV loop
        end

        posturl = URI("http://echelon.writhem.com/influx/?test") # Define the URL for our endpoint (not https)
        postreq = Net::HTTP::Post.new(posturl, 'Content-Type' => 'application/json', 'API-Key' => '0629fdb9-2fdd-4f50-bec7-62862d3ea099') # Define our request URL and parameters
        postreq.body = [{"tags":{"slug":id,"name":title},"fields":{"viewers":count},"timestamp":postnow}].to_json # Define the body of our message, convert to a JSON object
        Net::HTTP.start(posturl.hostname, posturl.port) do |http| # Start request with hostname and port
          res = http.request(postreq) # Do request
          puts "#{res.body}" # Output the response
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
end

while true # Set up a loop so when it fails, it can restart. We can probably just do this with activity pings (?)
  start_connection(wsurl, id, title)
end
