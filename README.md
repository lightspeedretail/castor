RDS (MySQL) has 3 different types of logs: general, slow queries and errors. Each type outputs logs in a different format. That's fine and dandy if you're going to look at them from a shell, but when you want to inject them in a structured format to allow [Logstash](https://www.elastic.co/products/logstash) to search them easily, it just plain sucks.

In order to structure those different types of logs, a little worker was needed. A castor (French for beaver. The beaver name was already used by a different project!). It eats those logs and poops them out cleanly (that's right, i went there!).

## Requirements

+ A properly configured [AWS CLI toolkit](https://aws.amazon.com/cli/).
+ Ruby (tested on v2.0.0 and v2.2.2). Only core librarires are used, to it might work on v1.8.7 and v1.9.3.

## Supported databases

At the moment, only the RDS MySQL database is supported as far as fetching the logs is concerned. But the parser should technically work with either RDS (MySQL), MySQL and MariaDB.

## Setup

+ Clone this repository
+ Inside the repository directory, run: ```bundle install```

## How it works

+ Based on the instance name and the log type, castor will fetch the current log file
+ It will parse those logs based on the type and output them in JSON
+ It will write the last marker in castor.json
+ Next time it runs, castor will check if there's a known last marker, if so, it'll asks for logs past that marker

## Available CLI options

~~~ text
Usage: castor [options]

Required options:
    -n INSTANCE_NAME                 Instance name
    -t LOG_TYPE                      Log type (error, general, slowquery)

Other options:
    -d DATA_DIR                      Data directory
    -h, --help                       Help message
~~~

## Examples

~~~ text
$ castor -n server_name -t slow
~~~

~~~ text
$ castor -n server_name -t slow -d /var/lib/castor
~~~

It will output something like this:

~~~ text
{"rds_instance":"server_name","rds_log_type":"slow","database":"test","connection_id":"13000","who":"dba[dba]@[10.148.3.39]","query_time":"0.000418","lock_time":"0.000067","rows_sent":"151","rows_examined":"151","query":"SELECT intcol1,charcol1 FROM t1","timestamp":"1432653735"}
{"rds_instance":"server_name","rds_log_type":"slow","database":"test","connection_id":"12997","who":"dba[dba]@[10.148.3.39]","query_time":"0.000325","lock_time":"0.000052","rows_sent":"151","rows_examined":"151","query":"SELECT intcol1,charcol1 FROM t1","timestamp":"1432653735"}
~~~

Lastly, you could pipe that output into a file, or another tool.

~~~ text
$ castor -n server_name -t slow >> logfile
~~~

## TODO

+ Writing tests
+ Implement different types of inputs. Like using STDIN or reading a file.

## Contributing

+ Fork this repository
+ Make a feature branch
+ Make your changes
+ Sacrifice a chicken to the coding Gods
+ Make a pull request

## Author

+ Jean-Francois Theroux \<jean-francois.theroux@lightspeedretail.com\>
