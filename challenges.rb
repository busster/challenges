





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

db.execute(create_users_table)

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

loop do 
	puts "Login: "
	print "User name: "
	user_name = gets.chomp
	print "Password: "
	password = gets.chomp

	user = db.execute("SELECT * FROM users WHERE user_name=? AND password=?", [user_name, password])
	if !user[0]
		puts "Sorry, the information you entered is incorrect. Try again."
	else
		break
	end

	line_break

end


user_cred = db.execute("SELECT * FROM users")
p user_cred