RDS (MySQL) has 3 different types of logs: general, slow queries and errors. Each type outputs logs in a different format. That's fine and dandy if you're going to look at them from a shell, but if you want to inject them in [Logstash](https://www.elastic.co/products/logstash), you need them in a structured format. RDS (PostgreSQL) also works, but only has "errors" logs.

In order to structure those different types of logs, a little worker was needed. A castor (French for beaver. The beaver name was already used by a different project!). It eats those logs and poops them out cleanly (that's right, i went there!).

## Supported databases

At the moment, only the RDS MySQL and PostgresSQL databases are supported as far as fetching the logs is concerned. But the parsers should technically work with either RDS (MySQL or PostgresSQL), MySQL and MariaDB.

NOTE: Pull requests encouraged :)

## Setup

+ Clone this repository
+ Inside the repository directory, run: ```bundle install```

## How it works

+ Based on the instance name and the log type, castor will fetch the current log file
+ It will parse those logs based on the type and output them in JSON to STDOUT
+ It will write the last marker in castor.json
+ Next time it runs, castor will check if there's a known last marker, if so, it'll asks for logs past that marker

NOTE: You can use our Chef [cookbook](https://github.com/lightspeedretail/chef-castor) to deploy it also. The cookbook takes care of creating CRON jobs to run it periodically.

## AWS Instance profile

~~~ text
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "rds:Describe*",
        "rds:ListTagsForResource",
        "rds:DownloadDBLogFilePortion",
        "ec2:DescribeAccountAttributes",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "cloudwatch:GetMetricStatistics"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
~~~

## Available CLI options

~~~ text
Usage: castor (options)
    -d DATA_DIRECTORY,               Data directory (default: /tmp/castor)
        --data-directory
        --db-type (mysql|postgres)   Database type: mysql (default) or postgres
    -D, --debug                      Debugging mode (default: false)
    -i, --instance INSTANCE          RDS instance name (required)
    -t, --type LOG_TYPE              Log type to fetch/parse (PostgreSQL only has "error") (required) (included in ['general', 'slowquery', 'error'])
    -p, --profile PROFILE            AWS profile to use in ~/.aws/credentials
    -r, --region REGION              AWS region (default: us-east-1)
    -v, --version                    Print version
~~~

## Examples

~~~ text
$ castor -i server_name -t slow
~~~

~~~ text
$ castor -i server_name -t slow -d /var/lib/castor
~~~

It will output something like this:

~~~ text
{"rds_instance":"server_name","rds_log_type":"slow","database":"test","connection_id":"13000","who":"dba[dba]@[10.148.3.39]","query_time":"0.000418","lock_time":"0.000067","rows_sent":"151","rows_examined":"151","query":"SELECT intcol1,charcol1 FROM t1","timestamp":"1432653735"}
{"rds_instance":"server_name","rds_log_type":"slow","database":"test","connection_id":"12997","who":"dba[dba]@[10.148.3.39]","query_time":"0.000325","lock_time":"0.000052","rows_sent":"151","rows_examined":"151","query":"SELECT intcol1,charcol1 FROM t1","timestamp":"1432653735"}
~~~

Lastly, you could pipe that output into a file, or another tool.

~~~ text
$ castor -i server_name -t slow >> logfile
~~~

## TODO

+ Build a gem and make it available in rubygems.org
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
