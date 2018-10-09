require "uuid"
require "option_parser"

require "ipc"
require "jwt"

require "pg"
require "crecto"

require "./user.cr"

authd_db_name = "authd"
authd_db_hostname = "localhost"
authd_db_user = "user"
authd_db_password = "nico-nico-nii"
authd_jwt_key = "nico-nico-nii"

OptionParser.parse! do |parser|
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
		authd_db_password = File.read(file_name).chomp
	end

	parser.on "-K file", "--key-file file", "JWT key file" do |file_name|
		authd_jwt_key = File.read(file_name).chomp
	end
end

class AuthD::Message
	enum RequestTypes
		TOKEN_REQUEST
	end
	enum ResponseTypes
		ALL_OK
		INVALID_FORMAT
		INVALID_CREDENTIALS
	end

	JSON.mapping({
		username: String,
		password: String,
	})
end

module DataBase
	extend Crecto::Repo
end

DataBase.config do |conf|
	conf.adapter = Crecto::Adapters::Postgres
	conf.hostname = authd_db_hostname
	conf.database = authd_db_name
	conf.username = authd_db_user
	conf.password = authd_db_password
end

# Dummy query to check DB connection is possible.
begin
	DataBase.all AuthD::User, Crecto::Repo::Query.new
rescue e
	puts "Database connection failed: #{e.message}"

	exit 0
end

authd = IPC::Service.new("authd").loop do |event|
	p event.class
	if event.is_a? IPC::Event::Message
		payload = JSON.parse(event.message.payload).as_h?

		if payload.nil?
			event.client.send AuthD::Message::ResponseTypes::INVALID_FORMAT.to_u8, "Input is not a JSON object."
			next
		end

		username = payload["username"]?.try &.as_s?
		password = payload["password"]?.try &.as_s?

		if username.nil?
			event.client.send AuthD::Message::ResponseTypes::INVALID_FORMAT.to_u8, "Missing username."
			next
		end

		if password.nil?
			event.client.send AuthD::Message::ResponseTypes::INVALID_FORMAT.to_u8, "Missing password."
			next
		end

		# FIXME: Huge pitfall here. Somehow doesn’t compile without, but that should be its type already, so…?
		username = username.as String
		password = password.as String

		user = DataBase.get_by AuthD::User, username: username, password: password

		if user.nil?
			event.client.send AuthD::Message::ResponseTypes::INVALID_CREDENTIALS.to_u8, "Invalid credentials.."

			next
		end

		event.client.send AuthD::Message::ResponseTypes::ALL_OK.to_u8, JWT.encode(user.to_h, authd_jwt_key, "HS255")
	end
end

authd.close # Not exactly required because an at_exit{} is added, but…

