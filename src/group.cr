
class AuthD::Group
	getter name            : String
	getter password_hash   : String
	getter gid             : Int32
	getter users           = Array(String).new

	def initialize(@name, @password_hash, @gid, @users)
	end
end

