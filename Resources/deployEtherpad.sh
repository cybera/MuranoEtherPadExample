#!/bin/bash -v

# Enable updates, if available
if [[ -f /usr/local/bin/enableAutoUpdate ]]; then
  /usr/local/bin/enableAutoUpdate
fi

# Make a directory under /var/lib/mysql
mkdir -p /opt/mysql_data

# Mount a volume, if one was specified
vol="/dev/$(lsblk -o name,type,mountpoint,label,uuid | grep -v root | grep -v ephem | grep -v SWAP | grep -v sda | grep -v vda | grep -v NAME| tail -1 | awk '{print $1}')"
if [[ "${vol}" != "/dev/" ]]; then
  fs=$(blkid -o value -s TYPE $vol)
  if [[ $fs != "ext4" ]]; then
    mkfs -t ext4 $vol
  fi

  mount $vol /opt/mysql_data
  uuid=$(lsblk -o name,type,mountpoint,label,uuid | grep -v root | grep -v ephem | grep -v SWAP | grep -v sda | grep -v vda | grep -v NAME| tail -1 | awk '{print $4}')
  echo "UUID=${uuid} /opt/mysql_data ext4 defaults 0 1 " | tee --append  /etc/fstab
fi

## Install package dependencies
apt-get update

# MySQL
debconf-set-selections <<< 'mysql-server mysql-server/root_password password %PASSWORD%'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password %PASSWORD%'
apt-get -y update
apt-get -y -q install mysql-server
service mysql stop

if [[ -d /opt/mysql_data/mysql ]]; then
  rm -rf /var/lib/mysql
else
  mv /var/lib/mysql /opt/mysql_data/
fi

ln -s /opt/mysql_data/mysql /var/lib/mysql
echo "/opt/mysql_data/mysql/ r,
/opt/mysql_data/mysql/** rwk," | sudo tee --append /etc/apparmor.d/local/usr.sbin.mysqld
service apparmor restart
service mysql restart

cat << EOT >> /root/.my.cnf
[CLIENT]
user=root
host=localhost
password='%PASSWORD%'
socket=/var/run/mysqld/mysqld.sock
EOT

# SQL Code
SQLCODE="
create database etherpad;
ALTER DATABASE etherpad CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE user 'etherpad'@'localhost' IDENTIFIED BY '%PASSWORD%';
GRANT ALL ON etherpad.* TO 'etherpad'@'localhost';
USE etherpad;
CREATE TABLE store (
  \`key\` varchar(100) COLLATE utf8mb4_bin NOT NULL DEFAULT '',
  value longtext COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (\`key\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;
flush privileges;"

echo "$SQLCODE" | mysql --defaults-extra-file=/root/.my.cnf

apt-get install -y gzip git curl python libssl-dev pkg-config build-essential nodejs-legacy npm supervisor nginx

## Make a user to run etherpad with
adduser --disabled-password --disabled-login --gecos "" etherpad

## Fetch software, configure and install
cd /opt
git clone --branch 1.6.0 https://github.com/ether/etherpad-lite.git etherpad-lite
chown -R etherpad:etherpad etherpad-lite
cd etherpad-lite
bin/installDeps.sh > log.txt 2> error.txt

## Setup supervisord to keep the service running
cat << EOT >> /etc/supervisor/conf.d/etherpad.conf
[program:etherpad]
command=node /opt/etherpad-lite/node_modules/ep_etherpad-lite/node/server.js
directory=/opt/etherpad-lite
user=etherpad
autostart=true
autorestart=true
stderr_logfile=/var/log/etherpad.err.log
stdout_logfile=/var/log/etherpad.out.log
EOT

cat << EOT > /opt/etherpad-lite/settings.json
/*
  This file must be valid JSON. But comments are allowed

  Please edit settings.json, not settings.json.template

  To still commit settings without credentials you can
  store any credential settings in credentials.json
*/
{
  // Name your instance!
  "title": "%NAME%",

  // favicon default name
  // alternatively, set up a fully specified Url to your own favicon
  "favicon": "favicon.ico",

  //IP and port which etherpad should bind at
  "ip": "127.0.0.1",
  "port" : 9001,

  /*
  // Node native SSL support
  // this is disabled by default
  //
  // make sure to have the minimum and correct file access permissions set
  // so that the Etherpad server can access them

  "ssl" : {
            "key"  : "/path-to-your/epl-server.key",
            "cert" : "/path-to-your/epl-server.crt",
            "ca": ["/path-to-your/epl-intermediate-cert1.crt", "/path-to-your/epl-intermediate-cert2.crt"]
          },

  */

  //The Type of the database. You can choose between dirty, postgres, sqlite and mysql
  //You shouldn't use "dirty" for for anything else than testing or development
  //the database specific settings
  /* An Example of MySQL Configuration
   "dbType" : "mysql",
   "dbSettings" : {
                    "user"    : "etherpad",
                    "host"    : "localhost",
                    "password": "%PASSWORD%",
                    "database": "store",
                    "charset" : "utf8mb4"
                  },
  */

  //the default text of a pad
  "defaultPadText" : "Welcome to Etherpad!\n\nThis pad text is synchronized as you type, so that everyone viewing this page sees the same text. This allows you to collaborate seamlessly on documents!\n\nGet involved with Etherpad at http:\/\/etherpad.org\n",

  /* Default Pad behavior, users can override by changing */
  "padOptions": {
    "noColors": false,
    "showControls": true,
    "showChat": true,
    "showLineNumbers": true,
    "useMonospaceFont": false,
    "userName": false,
    "userColor": false,
    "rtl": false,
    "alwaysShowChat": false,
    "chatAndUsers": false,
    "lang": "en-gb"
  },

  /* Should we suppress errors from being visible in the default Pad Text? */
  "suppressErrorsInPadText" : false,

  /* Users must have a session to access pads. This effectively allows only group pads to be accessed. */
  "requireSession" : false,

  /* Users may edit pads but not create new ones. Pad creation is only via the API. This applies both to group pads and regular pads. */
  "editOnly" : false,

  /* Users, who have a valid session, automatically get granted access to password protected pads */
  "sessionNoPassword" : false,

  /* if true, all css & js will be minified before sending to the client. This will improve the loading performance massivly,
     but makes it impossible to debug the javascript/css */
  "minify" : true,

  /* How long may clients use served javascript code (in seconds)? Without versioning this
     may cause problems during deployment. Set to 0 to disable caching */
  "maxAge" : 21600, // 60 * 60 * 6 = 6 hours

  /* This is the absolute path to the Abiword executable. Setting it to null, disables abiword.
     Abiword is needed to advanced import/export features of pads*/
  "abiword" : null,

  /* This is the absolute path to the soffice executable. Setting it to null, disables LibreOffice exporting.
     LibreOffice can be used in lieu of Abiword to export pads */
  "soffice" : null,

  /* This is the path to the Tidy executable. Setting it to null, disables Tidy.
     Tidy is used to improve the quality of exported pads*/
  "tidyHtml" : null,

  /* Allow import of file types other than the supported types: txt, doc, docx, rtf, odt, html & htm */
  "allowUnknownFileEnds" : true,

  /* This setting is used if you require authentication of all users.
     Note: /admin always requires authentication. */
  "requireAuthentication" : false,

  /* Require authorization by a module, or a user with is_admin set, see below. */
  "requireAuthorization" : false,

  /*when you use NginX or another proxy/ load-balancer set this to true*/
  "trustProxy" : false,

  /* Privacy: disable IP logging */
  "disableIPlogging" : false,

  /* Users for basic authentication. is_admin = true gives access to /admin.
     If you do not uncomment this, /admin will not be available! */
  "users": {
    "admin": {
      "password": "%PASSWORD%",
      "is_admin": true
    }
  },

  // restrict socket.io transport methods
  "socketTransportProtocols" : ["xhr-polling", "jsonp-polling", "htmlfile"],

  // Allow Load Testing tools to hit the Etherpad Instance.  Warning this will disable security on the instance.
  "loadTest": false,

  // Disable indentation on new line when previous line ends with some special chars (':', '[', '(', '{')
  /*
  "indentationOnNewLine": false,
  */

  /* The toolbar buttons configuration.
  "toolbar": {
    "left": [
      ["bold", "italic", "underline", "strikethrough"],
      ["orderedlist", "unorderedlist", "indent", "outdent"],
      ["undo", "redo"],
      ["clearauthorship"]
    ],
    "right": [
      ["importexport", "timeslider", "savedrevision"],
      ["settings", "embed"],
      ["showusers"]
    ],
    "timeslider": [
      ["timeslider_export", "timeslider_returnToPad"]
    ]
  },
  */

  /* The log level we are using, can be: DEBUG, INFO, WARN, ERROR */
  "loglevel": "INFO",

  //Logging configuration. See log4js documentation for further information
  // https://github.com/nomiddlename/log4js-node
  // You can add as many appenders as you want here:
  "logconfig" :
    { "appenders": [
        { "type": "console"
        //, "category": "access"// only logs pad access
        }
    /*
      , { "type": "file"
      , "filename": "your-log-file-here.log"
      , "maxLogSize": 1024
      , "backups": 3 // how many log files there're gonna be at max
      //, "category": "test" // only log a specific category
        }*/
    /*
      , { "type": "logLevelFilter"
        , "level": "warn" // filters out all log messages that have a lower level than "error"
        , "appender":
          {  Use whatever appender you want here  }
        }*/
    /*
      , { "type": "logLevelFilter"
        , "level": "error" // filters out all log messages that have a lower level than "error"
        , "appender":
          { "type": "smtp"
          , "subject": "An error occured in your EPL instance!"
          , "recipients": "bar@blurdybloop.com, baz@blurdybloop.com"
          , "sendInterval": 60*5 // in secs -- will buffer log messages; set to 0 to send a mail for every message
          , "transport": "SMTP", "SMTP": { // see https://github.com/andris9/Nodemailer#possible-transport-methods
              "host": "smtp.example.com", "port": 465,
              "secureConnection": true,
              "auth": {
                  "user": "foo@example.com",
                  "pass": "bar_foo"
              }
            }
          }
        }*/
      ]
    }
}
EOT

## Run Etherpad
service supervisor restart


# Setup nginx to only do proxy pass
cat << EOT > /etc/nginx/sites-available/default
server {
  listen [::]:80;
  location / {
    proxy_pass http://127.0.0.1:9001;
    proxy_set_header Host \$host;
    proxy_http_version 1.1;
    proxy_read_timeout 1d;
 }
}
EOT

# Restart nginx and everything should be ready!
service nginx restart
