# lastChecked refers to:
# the last time it was checked (if the loop finds no new threads)
# OR
# the correct thread hash (if loop finds a new thread)

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
require 'yaml'
require './modules.rb'

config = YAML.load_file('config.yaml') # Load our config YAML, for secret API key
key = config["endpoint_key"] # Set key to be the key in config YAML
feed = "http://www.reddit.com/r/VolunteerLiveTeam/.rss"
lastChecked = Time.now.to_f
now = Time.now.to_f

if ARGV.length > 0 # If arguments given

  id = ARGV[0].to_s # ID equals user arg to string
  wsurl, title = get_url(id)
  start_connection(wsurl, id, title, key)

elsif ARGV.length == 0 # If no arguments given

  while true # Set up a loop so when it fails, it can restart. We can probably just do this with activity pings (?)
    livethreads = search_rss(feed) # Get the list of threads (array of hashes)
    found, lastChecked = search(livethreads, lastChecked) # See above. Get our found value (yes, no) and the last time we checked OR the correct thread hash
    unless found # Unless found is truthy, do unless block. Otherwise, do else block.
      puts "No new live threads found, sleeping 2 minutes and retrying."
      sleep 120
      redo
    else
      threadlink = (JSON.parse(open(lastChecked[:jsonlink]).read))[0]["data"]["children"][0]["data"]["url"]
      id = threadlink.match(/\/live\/(.*)\//)[1] # Grab the hash from the array, reduce to a hash and grab the link element. Then match to get the ID.
      title = lastChecked[:title] # Grab the hash from the array, reduce to a hash and grab title element.
      puts "ID for the new live thread is: #{id}"
      puts "Title of the new live thread is \"#{title}\""
    end
    wsurl, title = get_url(id)
    start_connection(wsurl, id, title, key)
  end

end
