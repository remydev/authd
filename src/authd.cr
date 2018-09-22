
require "kemal"
require "jwt"

class HTTP::Server::Context
	property authd_user : Hash(String, JSON::Any)?
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
				context.authd_user = payload
			end
		end

		call_next context
	end
end


