
class AuthD::User
	getter login           : String
	getter password_hash   : String
	getter uid             : Int32
	getter gid             : Int32
	getter home            : String = "/"
	getter shell           : String = "/bin/nologin"
	getter groups          = Array(String).new
	getter full_name       : String? = nil
	getter location        : String? = nil
	getter office_phone_number : String? = nil
	getter home_phone_number   : String? = nil
	getter other_contact   : String? = nil

	JSON.mapping({
		login: String,
		password_hash: String,
		uid: Int32,
		gid: Int32,
		home: String,
		shell: String,
		groups: Array(String),
		full_name: String?,
		office_phone_number: String?,
		home_phone_number: String?,
		other_contact: String?
	})

	def initialize(@login, @password_hash, @uid, @gid, @home, @shell)
	end

	def to_h
		{
			:login => @login,
			:password_hash => "x", # Not real hash in JWT.
			:uid => @uid,
			:gid => @gid,
			:home => @home,
			:shell => @shell,
			:groups => @groups,
			:full_name => @full_name,
			:office_phone_number => @office_phone_number,
			:home_phone_number => @home_phone_number,
			:other_contact => @other_contact
		}
	end
end

