# Viewership-Stat-Compiler
A Ruby-based bot which, given a Reddit live thread ID, collates viewership numbers over a time period and collates into a CSV file.

# Installation and usage
## Installation

To clone, simply:
```
git clone https://github.com/VolunteerLiveTeam/Viewership-Stat-Compiler.git
```
Then, to install dependencies needed, simply install Bundler.
```
gem install bundler
```
Then, in the repo folder, install the dependencies with:
```
bundler install
```

You'll need an API key from @pironic on the VolunteerLiveTeam Slack. Put it in a config.yaml file like so:
```
endpoint_key: <key>
```
With key obviously being your key, with no quotes.
## Usage

To use, simply do:
```
bundler exec ruby main.rb
```
The script should start monitoring for new live threads on /r/VolunteerNewsTeam.

# Summary of files

* **main.rb** - The main script. This script monitors /r/VolunteerNewsTeam for new post starting with [live], and grabs the ID for this live post. It then continues with gathering viewership numbers of a time period.

* **graph.html** - In progress. This HTML file asks for a CSV filename (with spaces) from the directory in which it 	is contained, and plots it on a line graph. The CSV must be in the format that **main.rb** creates, so you should be fine.

# To-do:
* Integrate a live-graph of the CSV/pass the CSV to the live-graph on **graph.html**.
