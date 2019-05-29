
require "jwt"

require "ipc"

require "./user.cr"
require "./group.cr"

module AuthD
	enum RequestTypes
		GetToken
		AddUser
		GetUser
		GetUserByCredentials
		ModUser # Edit user attributes.
	end

	enum ResponseTypes
		Ok
		MalformedRequest
		InvalidCredentials
		InvalidUser
		UserNotFound # For UID-based GetUser requests.
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

	class GetUserRequest
		JSON.mapping({
			uid: Int32
		})
	end

	class GetUserByCredentialsRequest
		JSON.mapping({
			login: String,
			password: String
		})
	end

	class ModUserRequest
		JSON.mapping({
			uid: Int32,
			password: String?
		})
	end

	class Client < IPC::Client
		property key : String

		def initialize
			@key = ""

			initialize "auth"
		end

		def get_token?(login : String, password : String)
			send RequestTypes::GetToken, {
				:login => login,
				:password => password
			}.to_json

			response = read

			if response.type == ResponseTypes::Ok.value.to_u8
				response.payload
			else
				nil
			end
		end

		def get_user?(login : String, password : String)
			send RequestTypes::GetUserByCredentials, {
				:login => login,
				:password => password
			}.to_json

			response = read

			if response.type == ResponseTypes::Ok.value.to_u8
				User.from_json response.payload
			else
				nil
			end
		end

		def get_user?(uid : Int32)
			send RequestTypes::GetUser, {:uid => uid}.to_json

			response = read

			if response.type == ResponseTypes::Ok.value.to_u8
				User.from_json response.payload
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
			send RequestTypes::AddUser, {
				:login => login,
				:password => password
			}.to_json

			response = read

			pp! response.type
			case ResponseTypes.new response.type.to_i
			when ResponseTypes::Ok
				AuthD::User.from_json response.payload
			else
				Exception.new response.payload
			end
		end

		def mod_user(uid : Int32, password : String?) : Bool | Exception
			payload = Hash(String, String|Int32).new
			payload["uid"] = uid

			password.try do |password|
				payload["password"] = password
			end

			send RequestTypes::ModUser, payload.to_json

			response = read

			case ResponseTypes.new response.type.to_i
			when ResponseTypes::Ok
				true
			else
				Exception.new response.payload
			end
		end
	end
end

