
require "pg"
require "crecto"

class AuthD::User < Crecto::Model
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

