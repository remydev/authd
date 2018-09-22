
require "kemal"
require "jwt"

require "./user.cr"

class HTTP::Server::Context
	property authd_user : AuthD::User?
end

class AuthD::Middleware < Kemal::Handler
	property key : String = ""

	@configured = false
	@configurator : Proc(Middleware, Nil)

	def initialize(&block : Proc(Middleware, Nil))
		@configurator = block
	end

	def call(context)
		unless @configured
			@configured = true
			@configurator.call self
		end

		context.request.headers["X-Token"]?.try do |x_token|
			payload, header = JWT.decode x_token, @key, "HS256"

			if payload
				context.authd_user = AuthD::User.new.tap do |u|
					u.username = payload["username"].as_s?
					u.realname = payload["realname"].as_s?
					u.avatar = payload["avatar"].as_s?
					u.perms = Array(String).new

					payload["perms"].as_a.tap do |perms|
						perms.each do |perm|
							if perm.class == String
								u.perms! << perm.as_s
							end
						end
					end
				end
			end
		end

		call_next context
	end
end


