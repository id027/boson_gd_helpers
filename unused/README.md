# Unused model objects

This provides a list of unused objects in a model. It looks for Attributes, Facts and Date dimensions that are not used in any reports. It allows for generating MAQL DDL for dropping those.

## Prerequisites
You have to have ruby and boson installed.

## Install
If you have boson installing this script should be as easy as running

    boson install https://raw.githubusercontent.com/fluke777/boson_gd_helpers/master/unused/unused.rb

## Running
Run command by running

    boson unused PROJECT-ID

