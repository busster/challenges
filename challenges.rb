





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

create_relationships_table = <<-SQL
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

#######################

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

def send_friend(db, current_user, other_user)
	action_user_id = current_user
	if current_user < other_user
		user_one_id = current_user
		user_two_id = other_user
	else
		user_one_id = other_user
		user_two_id = current_user
	end
	check_request = db.execute("SELECT * FROM relationships WHERE user_one_id=? AND user_two_id=?",[user_one_id, user_two_id])
	if !check_request[0]
		db.execute("INSERT INTO relationships (user_one_id, user_two_id, status, action_user_id) VALUES (?, ?, ?, ?)",[user_one_id, user_two_id, 0, current_user])
	end
end

def print_friends_list(db, user_id)
	friendslist = db.execute("SELECT * FROM relationships WHERE (user_one_id=? OR user_two_id=?) AND status=?", [user_id, user_id, 0])
	if !friendslist
		puts "Your friends:"
		friendslist[0].each do |friend|
			puts "#{friend}"
		end
	end
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

menu = false
while !menu
	puts "Hello, #{first_name}."
	print_friends_list(db, user_id)
	
	puts "You're active challenges are: "

	print "Type 'c' to enter the challenges menu or 'f' to enter your friendslist or 'done' to exit program: "
	menu_input = gets.chomp
	if menu_input == 'c'
		
	elsif menu_input == 'f'
		line_break
		print_friends_list(db, user_id)
		line_break

		puts "What action would you like to take: "
		print "'add' a friend, 'respond' to a request, 'block' a friend, 'done' to exit: "

		input_toggle = false
		while !input_toggle
			input = gets.chomp
			if input == 'add'
				input_toggle = true
				valid_name = false
				while !valid_name
					line_break
					print "Who would you like to send a friend request to ('done' to exit): "
					friend = gets.chomp
					friend_cred = db.execute("SELECT * FROM users WHERE user_name=?", [friend])
					if friend == 'done'
						valid_name = true
					elsif !friend_cred[0]
						puts "Sorry, that user name does not exist. Try again."
					else
						valid_name = true
						friend_cred = friend_cred[0]
						friend_id = friend_cred[0]
						send_friend(db, user_id, friend_id)
						puts "Friend request sent to #{friend}"
						line_break
						line_break
					end
				end
			elsif input == 'respond'
				input_toggle = true
				friend_requests = db.execute("SELECT * FROM relationships WHERE (user_one_id=? OR user_two_id=?) AND status=?", [user_id, user_id, 0])
				friend_requests.each do |friend|
					friend_id = friend[3]
					request_name = db.execute("SELECT user_name FROM users WHERE id=?", [friend_id])
					request_name.flatten!
					puts "#{request_name[0]} : Pending"
				end
			end			
		end
	elsif menu_input == 'done'
		menu = true	
	else
		puts "Invalid information - choose: challenges - 'c', friendslist - 'f', or exit - 'done'"
		print "What would you like to do: "
	end

end
			
