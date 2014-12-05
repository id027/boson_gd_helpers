# Unused model objects

This provides a list of unused objects in a model. It looks for Attributes, Facts and Date dimensions that are not used in any reports. It allows for generating MAQL DDL for dropping those.

## Prerequisites
You have to have ruby and boson installed.

## Install
If you have boson installing this script should be as easy as running

    boson install https://raw.githubusercontent.com/fluke777/boson_gd_helpers/master/unused/unused.rb

## Reinstall or update
First you have to uninstall an old version

    rm ~/.boson/commands/unused.rb

Then you can follow the procedure in install again

  boson install https://raw.githubusercontent.com/fluke777/boson_gd_helpers/master/unused/unused.rb

## Running
Run command by running

    boson unused PROJECT-ID

This will pick up your credentials from the system if you have them saved through `gooddata auth store`

If you would like to provide specific credentials, you can use

    boson unused PROJECT-ID --login john@gooddata.com --password secret

Also you might want this to work with whitelabeled projects or projects hosted on different domain than the default secure.gooddata.com. You can achieve it by using the `--server` param

    boson unused PROJECT-ID --login john@gooddata.com --password secret --server https://na1.secure.gooddata.com
