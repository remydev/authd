
require "option_parser"

require "./user.cr"

user_name     : String? = nil
user_password : String? = nil
user_perms    = Array(String).new

database_url = "postgres:localhost"
database_name = "authd"
database_user = "nico"
database_password = "nico-nico-nii"

OptionParser.parse! do |parser|
	parser.banner = "usage: #{ARGV[0]} [arguments]"

	parser.on "-a url", "--database url", "URL of authd’s database." do |url|
		database_url = url
	end
	parser.on "-U name", "--database-user name", "Name of the database’s user." do |name|
		database_user = name
	end
	parser.on "-P password", "--database-pasword password", "Password of the database’s user." do |password|
		database_password = password
	end
	parser.on "-N name", "--database-name name", "Name of the database." do |name|
		database_name = name
	end

	parser.on "-u name", "--username name", "Name of the user to add." do |name|
		user_name = name
	end
	parser.on "-p password", "--password password", "Password of the user." do |password|
		user_password = password
	end
	parser.on "-x perm", "--permission", "Add a permission token to the user." do |token|
		user_perms << token
	end

	parser.on("-h", "--help", "Show this help") do
		puts parser
		exit 0
	end

	parser.invalid_option do |flag|
		puts "error: #{flag} is not a valid option."
		puts parser

		exit 1
	end
end

module DataBase
	extend Crecto::Repo
end

DataBase.config do |conf|
	conf.adapter = Crecto::Adapters::Postgres
	conf.hostname = database_url
	conf.username = database_user
	conf.password = database_password
	conf.database = database_name
end

if user_name.nil?
	STDERR.puts "No username specified."
	exit 1
end
if user_password.nil?
	STDERR.puts "No user password specified."
	exit 1
end

user = User.new
user.username = user_name
user.password = user_password
user.perms    = user_perms
changeset = DataBase.insert user

if changeset.valid?
	puts "User added successfully."
else
	changeset.errors.each do |e|
		p e
	end
end


