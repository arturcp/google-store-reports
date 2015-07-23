Download statistics reports from Google Play using gsutil and ruby scripts.

If you need a tool to download data from the Apple Store, check the project at https://github.com/arturbcc/apple-store-reports


Requirements
================

ruby >= 1.9


Before starting
================

Make sure you have gsutil installed and configured in your machine. To do that, follow the steps in https://cloud.google.com/storage/docs/gsutil, or, to be more precise, in https://cloud.google.com/storage/docs/gsutil_install



The project
================


There are four important ruby scripts in this project:

1. importer.rb

This script is responsible to fetch and download all csv files from Google Play Store containing the statistics of your apps. Before running it, make sure you know the url prefix of the gs url:

`gs://pubsite_prod_rev_XXXXXXXXXXXXXXXXXXXX/stats/`

To find out your specific number and replace the X's, go to https://play.google.com/apps/publish/ and browse to Reports > Statistcs, find your app by its name and scroll to the bottom of the page, on the 'Direct report URIs' section.

Now you are ready to go Let's suppose the id you go on the step above is 12345678901234567890. You know that because, on the Direct report URIs section of your app, you found these urls:

    gs://pubsite_prod_rev_12345678901234567890/stats/installs
    gs://pubsite_prod_rev_12345678901234567890/stats/ratings
    gs://pubsite_prod_rev_12345678901234567890/stats/crashes


Now, on the terminal, execute:

`ID=12345678901234567890 ruby importer.rb`

By default, a folder named "reports" will be created and the data downloaded from Google will be stored in it. It is possible to change the default directory by setting the ENV['DIRECTORY'] on the script call. For example:

`DIRECTORY=./new_folder ID=12345678901234567890 ruby importer.rb`

If you want to download only files from a specific month and year, read the section Import Mode below.



2. sql_generator.rb

This script will read all the files in the given directory and generate a set of insert commands to be run on a database. Just like in the importer.rb file, you can override the default folder with the ENV['DIRECTORY'] parameter.

To execute it, go to the terminal and run:

`ruby sql_generator.rb`

You can use a different folder (it must match the one used on importer.rb):

`DIRECTORY=./new_folder ruby sql_generator.rb`


3. mysql_import.rb

After the csv files are converted to sql scripts, you can easily import them to your database by running the mysql_import script:

`ruby mysql_import.rb`

To make it work, you need to configure your database connection. There is a file on the `config` folder called 'config.json.sample'. Rename it to config.json and change the username, password and database information with your database information before you run the script, or a error message will be shown explaining about this json file.


4. start.rb

To make it easier to run all scripts, you can easily run the whole process with one single command, ignoring the previous scripts mentioned above. It is good to understand how each of them work to debug eventual problems that might arise, but once everything is settled you can just go to the terminal and run:

`ID=12345678901234567890 YEAR=2015 MONTH=7 ruby start.rb`

It will call the following commands on the given sequence:

* ID=12345678901234567890 YEAR=2015 MONTH=7 ruby importer.rb
* ruby sql_generator.rb
* ruby mysql_import.rb



Import mode
==================

The default behavior of the importer is to download all files from the server, which might not be so useful if you intend to run the command every month to retrieve only what is new and relevant.

To change that, you can pass the year and the month on the script call, like this:

`ID=12345678901234567890 YEAR=2015 MONTH=7 ruby importer.rb`

It is necessary both year and month to use this method. If one of them is not present, the default mode will still run.


Structure
==================

The sql file will, by default, be stored in a directory named "sql". If an error is raised, it will be saved in a log file under the logs directory, which will be created on the run only when needed.


Database structure
==========================

To create the database, we included a mysql script on the project. It is called database_script.sql and is located on the `db` folder.


Database first load
==========================

To load the initial content into your database, you can use the database_load.rb script. You must inform the vendor, just like you do to import a specific date, and must provide the initial date. The script will download all files from the given date up to four days ago. Then you can run the sql generator script normally.

Just go to the terminal and run:

`ID=12345678901234567890 ruby database_load.rb`