Download statistics reports from Google Play using gsutil and ruby scripts.


Requirements
================

ruby >= 1.9


Before starting
================

Make sure you have gsutil installed and configured in your machine. To do that, follow the steps in https://cloud.google.com/storage/docs/gsutil, or, to be more precise, in https://cloud.google.com/storage/docs/gsutil_install



The project
================


There are two important ruby scripts in this project:

1. import.rb

This script is responsible to fetch and download all csv files from Google Play Store containing the statistics of your apps. Before running it, make sure you know the url prefix of the gs url:

`gs://pubsite_prod_rev_XXXXXXXXXXXXXXXXXXXX/stats/`

To find out your specific number and replace the X's, go to https://play.google.com/apps/publish/ and browse to Reports > Statistcs, find your app by its name and scroll to the bottom of the page, on the 'Direct report URIs' section.

Now you are ready to go Let's suppose the id you go on the step above is 12345678901234567890. You know that because, on the Direct report URIs section of your app, you found these urls:

    gs://pubsite_prod_rev_12345678901234567890/stats/installs
    gs://pubsite_prod_rev_12345678901234567890/stats/ratings
    gs://pubsite_prod_rev_12345678901234567890/stats/crashes


Now, on the terminal, execute:

`ID=12345678901234567890 ruby import.rb`

By default, a folder named "reports" will be created and the data downloaded from Google will be stored in it. It is possible to change the default directory by setting the ENV['DIRECTORY'] on the script call. For example:

`DIRECTORY=./new_folder ID=12345678901234567890 ruby import.rb`

If you want to download only files from a specific month and year, read the section Import Mode below.



2. sql_generator.rb

This script will read all the files in the given directory and generate a set of insert commands to be run on a database. Just like in the import.rb  file, you can override the default folder with the ENV['DIRECTORY'] parameter.

To execute it, go to the terminal and run:

`ruby sql_generator.rb`

You can use a different folder (it must match the one used on import.rb):

`DIRECTORY=./new_folder ruby sql_generator.rb`


Import mode
==================

The default behavior of the importer is to download all files from the server, which might not be so useful if you intend to run the command every month to retrieve only what is new and relevant.

To change that, you can pass the year and the month on the script call, like this:

`ID=12345678901234567890 YEAR=2015 MONTH=7 ruby import.rb`

It is necessary both year and month to use this method. If one of them is not present, the default mode will still run.


Structure
==================

The sql file will, by default, be stored in a directory named "sql". If an error is raised, it will be saved in a log file under the logs directory, which will be created on the run only when needed.