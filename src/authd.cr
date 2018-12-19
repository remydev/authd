
require "jwt"

require "ipc"

require "./user.cr"
require "./group.cr"

module AuthD
	enum RequestTypes
		GET_TOKEN
		ADD_USER
	end

	enum ResponseTypes
		OK
		MALFORMED_REQUEST
		INVALID_CREDENTIALS
		INVALID_USER
	end

	class GetTokenRequest
		JSON.mapping({
			# FIXME: Rename to "login" for consistency.
			login: String,
			password: String
		})
	end

	class AddUserRequest
		JSON.mapping({
			login: String,
			password: String,
			uid: Int32?,
			gid: Int32?,
			home: String?,
			shell: String?
		})
	end

	class Client < IPC::Client
		property key : String

		def initialize
			@key = ""

			initialize "auth"
		end

		def get_token?(login : String, password : String)
			send RequestTypes::GET_TOKEN.value.to_u8, {
				:login => login,
				:password => password
			}.to_json

			response = read

			if response.type == ResponseTypes::OK.value.to_u8
				response.payload
			else
				nil
			end
		end

		def send(type : RequestTypes, payload)
			send type.value.to_u8, payload
		end

		def decode_token(token)
			user, meta = JWT.decode token, @key, "HS256"

			user = AuthD::User.from_json user.to_json

			{user, meta}
		end

		# FIXME: Extra options may be useful to implement here.
		def add_user(login : String, password : String) : AuthD::User | Exception
			send RequestTypes::ADD_USER, {
				:login => login,
				:password => password
			}.to_json

			response = read

			pp! response.type
			case ResponseTypes.new response.type.to_i
			when ResponseTypes::OK
				AuthD::User.from_json response.payload
			else
				Exception.new response.payload
			end
		end
	end
end

