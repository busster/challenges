





require 'sqlite3'

db = SQLite3::Database.new('challenges.db')



create_users_table = <<-SQL
	CREATE TABLE IF NOT EXISTS users(
	id INTEGER PRIMARY KEY,
	user_name Varchar(255),
	password Varchar(255),
	first_name Varchar(255),
	last_name Varchar(255)
	)
SQL

create_friends_table = <<-SQL
	CREATE TABLE IF NOT EXISTS relationships(
	user_one_id INTEGER,
	user_two_id INTEGER,
	status INTEGER,
	action_user_id INTEGER,
	FOREIGN KEY(user_one_id) REFERENCES users(id),
	FOREIGN KEY(user_two_id) REFERENCES users(id),
	FOREIGN KEY(action_user_id) REFERENCES users(id)
	)
SQL
####status####
# 0 - Pending
# 1 - Accepted
# 2 - Declined
# 3 - Blocked
##############


#### CREATE TABLES ####

db.execute(create_users_table)
db.execute(create_relationships_table)

#### CREATE TABLES ####

def create_user(db, user_name, password, first_name, last_name)
	db.execute("INSERT INTO users (user_name, password, first_name, last_name) VALUES (?, ?, ?, ?)",[user_name, password, first_name, last_name])
end

def check_user_name_available(db, user_name)
	available = true
	existing_user_names = db.execute("SELECT user_name FROM users")
	existing_user_names.each do |eun|
		if eun[0] == user_name
			available = false
		end
	end
	return available
end

def line_break
	puts "-" * 50
end


puts "Welcome to Challenges! The best way to keep track of bets, personal improvement goals, and healthy competition."
print "Are you a new user? Enter ('n' or hit enter to continue): "
user_status = gets.chomp
if user_status == 'n'
	puts "Create and account:"

	line_break

	available = false
	while !available
		print "Enter a user name: "
		user_name = gets.chomp
		available = check_user_name_available(db, user_name)
		if !available
			puts "Sorry, that name has been taken."
		end
	end

	print "Enter a password: "
	password = gets.chomp

	print "What is your First Name: "
	first_name = gets.chomp
	print "What is your Last Name: "
	last_name = gets.chomp

	create_user(db, user_name, password, first_name, last_name)
else
end

line_break
line_break

valid = false
while !valid
	puts "Login: "
	print "User name: "
	user_name = gets.chomp
	print "Password: "
	password = gets.chomp

	user = db.execute("SELECT * FROM users WHERE user_name=? AND password=?", [user_name, password])
	if !user[0]
		puts "Sorry, the information you entered is incorrect. Try again."
	else
		valid = true
	end

	line_break

end

user = user[0]
user_id, user_name, password, first_name, last_name = user

puts "Hello, #{first_name}."
puts "You're active challenges are: "

user_cred = db.execute("SELECT * FROM users")
p user_cred