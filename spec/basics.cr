require "spec"

require "../src/authd.cr"

describe "authd" do
	it "runs basic functions" do
		# Database setup.
		File.write "passwd", ""
		File.write "group",  ""

		ENV["IPC_RUNDIR"]="."

		# authd (dæmon) setup.
		authd_process = Process.new(
			"./bin/authd",
			args: [
				"-u", "passwd",
				"-g", "group"
			]
		)

		# Actual test begins here.
		authd = AuthD::Client.new

		pp! authd.add_user "test", "test"

		# User should be there, we just created it!
		user = authd.get_user?("test", "test").as AuthD::User

		(user.login == "test").should be_true

		user2 = authd.add_user("test2", "test").as AuthD::User

		(user2.uid != user.uid).should be_true

		authd.mod_user user.uid, password: "oh no"
		user_bis = authd.get_user?("test", "oh no").as AuthD::User

		user_bis.to_h.should eq(user.to_h)

		# User should be there, we just created it!
		user2 = authd.get_user?("test2", "test").as AuthD::User

		(user2.uid != user.uid).should be_true

		authd.close

		# authd (dæmon) cleanup.
		authd_process.kill
		authd_process.wait
	end
end

