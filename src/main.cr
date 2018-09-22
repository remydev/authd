require "uuid"

require "kemal"
require "jwt"

require "pg"
require "crecto"

require "./user.cr"

authd_db_name = "authd"
authd_db_hostname = "localhost"
authd_db_user = "user"
authd_db_password = "nico-nico-nii"
authd_jwt_key = "nico-nico-nii"

Kemal.config.extra_options do |parser|
	parser.on "-d name", "--database-name name", "Database name." do |name|
		authd_db_name = name
	end

	parser.on "-u name", "--database-username user", "Database user." do |name|
		authd_db_user = name
	end

	parser.on "-a host", "--hostname host", "Database host name." do |host|
		authd_db_hostname = host
	end

	parser.on "-P file", "--password-file file", "Password file." do |file_name|
		authd_db_password = File.read file_name
	end

	parser.on "-K file", "--key-file file", "JWT key file" do |file_name|
		authd_jwt_key = File.read file_name
	end
end

post "/token" do |env|
	env.response.content_type = "application/json"

	username = env.params.json["username"]?
	password = env.params.json["password"]?

	if ! username.is_a? String
		next halt env, status_code: 400, response: ({error: "Missing username."}.to_json)
	end

	if ! password.is_a? String
		next halt env, status_code: 400, response: ({error: "Missing password."}.to_json)
	end

	user = MyRepo.get_by AuthD::User, username: username, password: password

	if ! user
		next halt env, status_code: 400, response: ({error: "Invalid user or password."}.to_json)
	end

	{
		"status" => "success",
		"token" => JWT.encode user.to_h, authd_jwt_key, "HS256"
	}.to_json
end

module MyRepo
	extend Crecto::Repo
end

Kemal.run 12051 do
	MyRepo.config do |conf|
		conf.adapter = Crecto::Adapters::Postgres
		conf.hostname = authd_db_hostname
		conf.database = authd_db_name
		conf.username = authd_db_user
		conf.password = authd_db_password
	end
end
