require "uuid"
require "option_parser"

require "jwt"

require "pg"
require "crecto"

require "ipc"

require "./authd.cr"

extend AuthD

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

	parser.on "-h", "--help", "Show this help" do
		puts parser

		exit 0
	end
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
	DataBase.all User, Crecto::Repo::Query.new
rescue e
	puts "Database connection failed: #{e.message}"

	exit 1
end

##
# Provides a JWT-based authentication scheme for service-specific users.
IPC::Service.new "auth" do |event|
	client = event.client
	
	case event
	when IPC::Event::Message
		message = event.message
		payload = message.payload

		case RequestTypes.new message.type.to_i
		when RequestTypes::GET_TOKEN
			begin
				request = GetTokenRequest.from_json payload
			rescue e
				client.send ResponseTypes::MALFORMED_REQUEST.value.to_u8, e.message || ""

				next
			end

			user = DataBase.get_by User,
				username: request.username,
				password: request.password

			if user.nil?
				client.send ResponseTypes::INVALID_CREDENTIALS.value.to_u8, ""
				
				next
			end

			client.send ResponseTypes::OK.value.to_u8,
				JWT.encode user.to_h, authd_jwt_key, "HS256"
		end
	end
end

