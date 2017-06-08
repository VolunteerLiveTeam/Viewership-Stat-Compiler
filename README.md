# Viewership-Stat-Compiler
A Ruby-based bot which, given a Reddit live thread ID, collates viewership numbers over a time period and collates into a CSV file.

# Summary of files

* **main.rb** - The main script. This script monitors /r/VolunteerNewsTeam for new post starting with [live], and grabs the ID for this live post. It then continues with gathering viewership numbers of a time period.

* **graph.html** - In progress. This HTML file asks for a CSV filename (with spaces) from the directory in which it 	is contained, and plots it on a line graph. The CSV must be in the format that **main.rb** creates, so you should be fine.

# To-do:
* Integrate a live-graph of the CSV/pass the CSV to the live-graph on **graph.html**.