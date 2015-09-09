require "yaml"
require "uri"
require "json"
require "unirest"

config = YAML.load_file(ARGV[0])
auth_data = config['auth']
cf_data = config['cf']
cfddns_data = config['cfddns']
full_name = cf_data["host"] + "." + cf_data["domain"]

headers = {"X-Auth-Email" => auth_data["email"],
           "X-Auth-Key" => auth_data["api_key"],
           "Content-Type" => "application/json",
}
urls = {:public_ip => "https://icanhazip.com",
	:cf_dns_zone => "https://api.cloudflare.com/client/v4/zones",
	:cf_dns_records => "https://api.cloudflare.com/client/v4/zones/%s/dns_records/%s",
}

response = Unirest.get urls[:public_ip]
public_ip = response.body.chop

if (cfddns_data["debug"])
  puts "My IP: #{public_ip}"
  puts "User: #{auth_data['email']}"
  puts "Target: #{full_name}"
end


response = Unirest.get(urls[:cf_dns_zone],
  headers: headers,
  :parameters => {:name => cf_data["domain"]})


zones = response.body

zone_id = zones["result"][0]["id"]

url = urls[:cf_dns_records] % [zone_id, nil]

response = Unirest.get(url,
  headers: headers, 
  parameters: {:name => full_name})

records = response.body

if (records["result_info"]["total_count"] == 0)
	if (not cf_data["create_record"])
		abort "I didn't find the record you requested and you have our config set to NOT create records. Aborting."
	else
		parameters = {:type => "A", :name => full_name, :content => public_ip}
		response = Unirest.post(urls[:cf_dns_records] % [zone_id, nil],
					parameters: parameters.to_json,
					headers: headers)
		result = response.body
        	if (result["success"] == true)
			puts "Created #{result['result']['name']} with an IP of #{result['result']['content']} Exiting."
	        else
		       	abort "Failed to update with errors: #{result['errors'][0]['code']}: #{result['errors'][0]['message']}. Aborting."
	        end
	end
else
  records["result"].each do |record|
     if (record["name"] != full_name)
       puts "Not a match"
     elsif (record["type"] != "A")
	     abort "Record found was a #{record['type']} but I only work with A records. Aborting."
     elsif (public_ip == record["content"])
       puts "Already up to date"
       exit
     else
       puts "Outdated record found. Updating #{record['name']} from #{record['content']} to #{public_ip}"
       url = "https://api.cloudflare.com/client/v4/zones/" + zone_id + "/dns_records/" + record["id"]
       new_record = record
       new_record["content"] = public_ip
       response = Unirest.put(url, 
	 parameters: new_record.to_json,
         headers: {"X-Auth-Email" => auth_data["email"], 
	           "X-Auth-Key" => auth_data["api_key"], 
		   "Content-Type" => "application/json",
       })
       result = response.body
       if (result["success"] == true)
	       puts "Completed update. Exiting."
	       exit
       else
	       abort "Failed to update with errors: #{result['errors'][0]['code']}: #{result['errors'][0]['message']}. Aborting."
       end

     end
  end
end
