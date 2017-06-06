# Viewership-Stat-Compiler
A Ruby-based bot which, given a Reddit live thread ID, collates viewership numbers over a time period and collates into a CSV file.

* **main.rb** - This script asks for input like so: `ruby main.rb <livethreadid>`.

	For example, `ruby main.rb z1z04coqqmyf`.

	You can retrieve this ID from the URL of a live thread, as long as it's active. See the highlighted portion in the screenshot below.
	![Like so!](https://github.com/VolunteerLiveTeam/Viewership-Stat-Compiler/blob/master/Screen%20Shot%202.png)

* **graph.html** - In progress. This HTML file asks for a CSV filename (with spaces) from the directory in which it 	is contained, and plots it on a line graph. The CSV must be in the format that **main.rb** creates, so you should be fine.