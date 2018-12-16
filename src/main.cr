require "uuid"
require "option_parser"

require "jwt"

require "pg"
require "crecto"

require "ipc"

require "./authd.cr"
require "./passwd.cr"

extend AuthD

authd_passwd_file = "passwd"
authd_group_file = "group"
authd_jwt_key = "nico-nico-nii"

OptionParser.parse! do |parser|
	parser.on "-u file", "--passwd-file file", "passwd file." do |name|
		authd_passwd_file = name
	end

	parser.on "-g file", "--group-file file", "group file." do |name|
		authd_group_file = name
	end

	parser.on "-K file", "--key-file file", "JWT key file" do |file_name|
		authd_jwt_key = File.read(file_name).chomp
	end

	parser.on "-h", "--help", "Show this help" do
		puts parser

		exit 0
	end
end

passwd = Passwd.new authd_passwd_file, authd_group_file

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

			user = passwd.get_user request.username, request.password

			if user.nil?
				client.send ResponseTypes::INVALID_CREDENTIALS.value.to_u8, ""
				
				next
			end

			client.send ResponseTypes::OK.value.to_u8,
				JWT.encode user.to_h, authd_jwt_key, "HS256"
		end
	end
end

