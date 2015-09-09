require "yaml"
require 'rest-client'
require "uri"
require "json"
require "unirest"

config = YAML.load_file(ARGV[0])
auth_data = config['auth']
cf_data = config['cf']
full_name = cf_data["host"] + "." + cf_data["domain"]

RestClient.log = 'stdout'

headers = { "X-Auth-Email": auth_data["email"], "X-Auth-Key": auth_data["api_key"] }

response = RestClient.get "https://www.icanhazip.com"

public_ip = response.body.chop

puts "My IP: #{public_ip}"
puts "User: #{auth_data['email']}"
puts "Target: #{full_name}"

response = RestClient::Request.execute(method: :get, url: "https://api.cloudflare.com/client/v4/zones", 
  headers: {"X-Auth-Email": auth_data["email"], "X-Auth-Key": auth_data["api_key"], params: {:name => cf_data["domain"]}})

zones = JSON.parse(response.body)

zone_id = zones["result"][0]["id"]

url = "https://api.cloudflare.com/client/v4/zones/" + zone_id + "/dns_records"

response = RestClient::Request.execute(method: :get, url: url,
  headers: {"X-Auth-Email": auth_data["email"], "X-Auth-Key": auth_data["api_key"], params: {:name => full_name}})

records = JSON.parse(response.body)

if (records["result_info"]["total_count"] == 0)
  puts "I couldn't find that record. Should I create it?"
else
  records["result"].each do |record|
     if (record["name"] != full_name)
       puts "Not a match"
     elsif (record["type"] != "A")
       abort "Record found but not an A record. Quitting."
     elsif (public_ip == record["content"])
       puts "Already up to date"
       exit
     else
       puts "I should do an update."
       url = "https://api.cloudflare.com/client/v4/zones/" + zone_id + "/dns_records/" + record["id"]
       # puts "curl -X PUT '#{url}' -H 'X-Auth-Email: #{auth_data['email']}' -H 'X-Auth-Key: #{auth_data['api_key']}' --data '#{{"content" => public_ip}.to_json}'"
       response = Unirest.put(url, 
	 parameters: {"content" => public_ip}.to_json,
         headers: {"X-Auth-Email" => auth_data["email"], 
	           "X-Auth-Key" => auth_data["api_key"], 
		   "Content_Type" => "application/json",
       })
       puts response

     end
  end
end
