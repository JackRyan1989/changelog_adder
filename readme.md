# Add Changelog

This is just a simple script that runs in a git pre-push hook. The idea is that the script will check if you've done a changelog commit, and if not, will provide a simple terminal interface to do so. 

There are some dependencies so make sure to `bundle install` them.

For reasons I can't seem to get this to work when called from a shell script, so it don't work in a git-hook. Which probably warrrants re-writing it as a shell script as a next step. Anyhoo, one thing you can do to make it easier to run is first make this script an executable:

`chmod +x add_changelog.rb`

And then alias it in your .zshrc:

`vim ~/.zshrc` - or whatever editor you use

`alias addclog="/path/to/scrip/add_changelog.rb"` - or whatever you want to call it.