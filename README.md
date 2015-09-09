# CFDDNS.rb

This project is a very simplistic wrapper around the Cloudflare API to enable Dynamic DNS resolution.

The provided Bash file has to specify the configuration file in the variable on the second line. Copy .cfddns.yaml wherever you want it to live and then update the Bash script accordingly. The script relies on having a specific Gemset and RVM installed so you may want to roll your own. 

To directly call the ruby script simply pass the configuration file as the first and only argument.

Check out .cfddns.yaml for more information on configuration.

# Disclaimer

No warranty is provided either expressed nor implied. This application is provided as is with no expectation of support should it accidentally somehow delete your zone. I'm not liable under any circumstance for what you do, what the code does, or the zombie flying monkeys that are circling your data center.

# License

This project is licensed under the [WTFPL](http://www.wtfpl.net/txt/copying) so whatever.
