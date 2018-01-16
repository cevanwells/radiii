# RADIII

A small FreeRADIUS Perl script that allows patron auth against the III Sierra PatronAPI.

## Installing / Getting started

This module depends on the following Perl modules:

* DateTime
* LWP (The World-Wide Web library for Perl)

And the following software:

* Perl (5) (this is probabaly included in the base install of most distros)
* FreeRADIUS
* FreeRADIUS Perl module

They should be available in the package repository of your distribution and installed very easily by doing something like this:

**Debian/Ubuntu**

```shell
$ sudo apt-get update
$ sudo apt-get install libdatetime-perl libwww-perl freeradius
```

**RHEL/CentOS**

```shell
$ sudo yum install perl-DateTime perl-libwww-perl freeradius freeradius-perl
```

Once installed, FreeRADIUS will need to be configured appropriately. Some basic examples might be given at a future time, otherwise look over the FreeRADIUS documentation.

### Deploying / Publishing

A Docker image is currently underdevelopment and when finished the Dockerfile will be included in this repository

## Features

* Allows a FreeRADIUS server to authenticate and authorize patrons based on their accounts in the Sierra database
* Disallows access if a patron account is expired, manually blocked, or with fines over a configurable threshold

## Configuration

At the moment, there are only 3 Environment variabled that need to be set for configuration of this script. This is only an example, and you should replace the given values with values that represent your environment. 

Additionally, you will need these environment variables to be reset after a boot. This can usually be done by editing ```/etc/profile``` or by adding a file to ```/etc/profile.d/```

```shell
# What is your timezone?
$ export RADIII_TIMEZONE=America/Detroit

# What is the base URL for your III Sierra server?
$ export RADIII_BASEURL=http://sierra-app.example.org:4500

# What is the maximum fine allowed for patrons to use services?
$ export RADIII_MAX_FINE=3.99
```
## Contributing

If you'd like to contribute, please fork the repository and use a feature
branch. Pull requests are warmly welcome.

This isn't a complicated script, so just please try and keep things neat.

## Licensing

The code in this project is licensed under BSD-3 license. For more information, please see the LICENSE file.
