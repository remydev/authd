
require "jwt"

require "ipc"

require "./user.cr"
require "./group.cr"

module AuthD
	enum RequestTypes
		GET_TOKEN
	end

	enum ResponseTypes
		OK
		MALFORMED_REQUEST
		INVALID_CREDENTIALS
	end

	class GetTokenRequest
		JSON.mapping({
			# FIXME: Rename to "login" for consistency.
			username: String,
			password: String
		})
	end

	class Client < IPC::Client
		property key : String

		def initialize
			@key = ""

			initialize "auth"
		end

		def get_token?(username : String, password : String)
			send RequestTypes::GET_TOKEN.value.to_u8, {
				:username => username,
				:password => password
			}.to_json

			response = read

			if response.type == ResponseTypes::OK.value.to_u8
				response.payload
			else
				nil
			end
		end

		def decode_token(token)
			user, meta = JWT.decode token, @key, "HS256"

			user = AuthD::User.from_json user.to_json

			{user, meta}
		end
	end
end

