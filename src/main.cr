require "uuid"

require "kemal"
require "jwt"

require "pg"
require "crecto"

MASTER_KEY = Random::Secure.base64
authd_db_password_file = "db-password-file"
authd_db_name = "authd"
authd_db_hostname = "localhost"
authd_db_user = "user"

Kemal.config.extra_options do |parser|
	parser.on "-d name", "--database-name name", "database name for authd" do |dbn|
		authd_db_name = dbn
	end

	parser.on "-u name", "--database-username user", "database user for authd" do |u|
		authd_db_user = u
	end

	parser.on "-a hostname", "--hostname host", "hostname for authd" do |h|
		authd_db_hostname = h
	end

	parser.on "-P password-file", "--passfile file", "password file for authd" do |f|
		authd_db_password_file = f
	end
end

class User < Crecto::Model
	schema "users" do # table name
		field :username, String
		field :realname, String
		field :avatar, String
		field :password, String
		field :perms, Array(String)
	end

	validate_required [:username, :password, :perms]

	def to_h
		{
			:username => @username,
			:realname => @realname,
			:perms => @perms,
			:avatar => @avatar
		}
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

	user = MyRepo.get_by(User, username: username, password: password)

	if ! user
		next halt env, status_code: 400, response: ({error: "Invalid user or password."}.to_json)
	end

	{
		"status" => "success",
		"token" => JWT.encode(user.to_h, MASTER_KEY, "HS256")
	}.to_json
end

module MyRepo
	extend Crecto::Repo
end

Kemal.run do
	MyRepo.config do |conf|
		conf.adapter = Crecto::Adapters::Postgres
		conf.hostname = authd_db_hostname
		conf.database = authd_db_name
		conf.username = authd_db_user
		conf.password = File.read authd_db_password_file
	end
end
