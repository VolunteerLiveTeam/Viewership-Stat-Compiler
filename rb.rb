require 'faye/websocket'
require 'em/pure_ruby'
require 'json'
require 'csv'
require 'open-uri'
require 'rss'
require 'nokogiri'
require 'active_support/core_ext/enumerable'
require 'time'

feed = 'https://www.reddit.com/r/livetester5/.rss' # /r/VolunteerLiveTeam RSS feed
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
  begin
    rss = RSS::Parser.parse(feed)
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
  array = []
  rss.items.each do |item|
    title = Nokogiri::HTML(item.title.to_s).xpath('/html/head/title').text
    link = Nokogiri::HTML(item.link.to_s).css('link[href]').map { |link| link['href'] }
    date = Nokogiri::HTML(item.updated.to_s).text
    float = Time.parse(Nokogiri::HTML(date.to_s).text).to_f # Parse the time string as a time object, and convert to float
    if not title.match(/\[live\] (.*)/)
      next
    else
      h = {:title => title, :link => link.join(""), :date => date, :float => float}
      array.push(h)
    end
  end
  return array
end


while true
  array = search_rss(feed) # Array of hashes of each [live] thread.
  found, lastChecked = search(array, lastChecked) # Returns an array of a value and a hash (the live thread)
  unless found # Unless found is truthy, do unless block. Otherwise, do else block.
    puts "No new live threads found, sleeping 2 minutes and retrying."
    sleep 120
    redo
  else
    id = lastChecked[:link].match(/comments\/(.*?)\//)[1] # Grab the hash from the array, reduce to a hash and grab the link element. Then match to get the ID.
    title = lastChecked[:title] # Grab the hash from the array, reduce to a hash and grab title element. NOTE: WE ARE USING LASTCHECKED BECAUSE IT THE SECOND VALUE RETURNED. DON'T WORRY, IT WORKS.
    puts "ID for the new live thread is: #{id}"
    puts "Title of the new live thread is \"#{title}\""
    return id
  end
  return id
end

puts id