





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
# 3 - Blocked         NOT IMPLIMENTED YET
##############

create_friendkey_table = <<-SQL
	CREATE TABLE IF NOT EXISTS friendkey(
	status_id INTEGER,
	status_name VARCHAR (255),
	FOREIGN KEY(status_id) REFERENCES relationships(status)
	)
SQL

create_challenges_table = <<-SQL
	CREATE TABLE IF NOT EXISTS challenges(
	id INTEGER PRIMARY KEY,
	description VARCHAR(255),
	completed BOOLEAN
	)
SQL

create_users_challenges_table = <<-SQL
	CREATE TABLE IF NOT EXISTS users_challenges(
	user_one_id INTEGER,
	user_two_id INTEGER,
	challenges_id INTEGER,
	FOREIGN KEY(user_one_id) REFERENCES users(id),
	FOREIGN KEY(user_two_id) REFERENCES users(id),
	FOREIGN KEY(challenges_id) REFERENCES challenges(id)
	)
SQL


#### CREATE TABLES ####

db.execute(create_users_table)
db.execute(create_relationships_table)
db.execute(create_friendkey_table)
db.execute(create_challenges_table)
db.execute(create_users_challenges_table)

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

###################################################

def send_friend(db, current_user, other_user, other_user_name)
	action_user_id = current_user
	if current_user < other_user
		user_one_id = current_user
		user_two_id = other_user
	else
		user_one_id = other_user
		user_two_id = current_user
	end
	check_request = db.execute("SELECT * FROM relationships WHERE user_one_id=? AND user_two_id=? AND (status=0 OR status=1)",[user_one_id, user_two_id])
	if !check_request[0]
		db.execute("INSERT INTO relationships (user_one_id, user_two_id, status, action_user_id) VALUES (?, ?, ?, ?)",[user_one_id, user_two_id, 0, current_user])
		puts "Friend request sent to #{other_user_name}"
	else
		puts "You are already friends, or have sent a request to #{other_user_name}."			
	end
end

def accept_friend(db, user_id, friend_id)
	if user_id < friend_id
		user_one_id = user_id
		user_two_id = friend_id
	else
		user_one_id = friend_id
		user_two_id = user_id
	end
	db.execute("UPDATE relationships SET status=1, action_user_id=? WHERE user_one_id=? AND user_two_id=?",[user_id, user_one_id, user_two_id])
end

def decline_friend(db, user_id, friend_id)
	if user_id < friend_id
		user_one_id = user_id
		user_two_id = friend_id
	else
		user_one_id = friend_id
		user_two_id = user_id
	end
	db.execute("UPDATE relationships SET status=2, action_user_id=? WHERE user_one_id=? AND user_two_id=?",[user_id, user_one_id, user_two_id])
end

def get_friend_id(db, friend)
	friend_cred = db.execute("SELECT * FROM users WHERE user_name=?", [friend])
	friend_cred = friend_cred[0]
	friend_id = friend_cred[0]
end


def print_friends_list(db, user_id)
	friendslist = db.execute("SELECT * FROM relationships WHERE (user_one_id=? OR user_two_id=?) AND status=?", [user_id, user_id, 1])
	if friendslist
		puts "Your friends:"
		friendslist_index = 0
		friendslist.each do |user|
			index = user.find_index(user_id)
			if index == 0
				friend_id = friendslist[friendslist_index][1]
			else
				friend_id = friendslist[friendslist_index][0]
			end

			friend = db.execute("SELECT user_name FROM users WHERE id=?",[friend_id])
			friend.flatten!
			puts "#{friend[0]}"
			friendslist_index += 1
		end
	end
	line_break
end

def print_pending_requests(db, user_id)
	friend_requests = db.execute("SELECT users.user_name, friendkey.status_name FROM relationships JOIN users, friendkey ON relationships.action_user_id=users.id AND relationships.status=friendkey.status_id WHERE (relationships.user_one_id=? OR relationships.user_two_id=?) AND relationships.status=?", [user_id, user_id, 0])
	puts "You have #{friend_requests.length} friend requests."
end

###################################################

def create_challenge(db, description, challenge_to)
	completed = "false"
	db.execute("INSERT INTO challenges (description, completed) VALUES (?, ?)",[description, completed])
	challenge_pk = db.execute("SELECT last_insert_rowid()")

	participant_id = []
	challenge_to.each do |participant|
		id = get_friend_id(db, participant)
		participant_id << id
	end
	if participant_id.length < 2
		user_one_id = participant_id[0]
		user_two_id = participant_id[0]
		db.execute("INSERT INTO users_challenges (user_one_id, user_two_id, challenges_id) VALUES (?, ?, ?)",[user_one_id, user_two_id, challenge_pk])
	else
		times = participant_id.length - 1
		times.times do |n|
			user_id = participant_id[0]
			friend_id = participant_id[n + 1]

			if user_id < friend_id
				user_one_id = user_id
				user_two_id = friend_id
			else
				user_one_id = friend_id
				user_two_id = user_id
			end
			db.execute("INSERT INTO users_challenges (user_one_id, user_two_id, challenges_id) VALUES (?, ?, ?)",[user_one_id, user_two_id, challenge_pk])
		end
	end

end

###################################################

def line_break
	puts "-" * 50
end

############################################################################## DRIVER CODE
############################################################################################
############################################################################################

puts "Welcome to Challenges! The best way to keep track of bets, personal improvement goals, and healthy competition."
print "Are you a new user? Enter ('n' or hit enter to continue): "
user_status = gets.chomp

############################################################################## CREATE ACCOUNT
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


############################################################################## LOGIN
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
	line_break

end

user = user[0]
user_id, user_name, password, first_name, last_name = user


############################################################################## MAIN MENU
menu = false
while !menu
	puts "Hello, #{first_name}."

	line_break
	print_friends_list(db, user_id)
	
	puts "You're active challenges are: "

	print "Type 'c' to enter the challenges menu or 'f' to enter your friendslist or 'done' to exit program: "
	menu_input = gets.chomp
############################################################################## CHALLENGES MENU	
	if menu_input == 'c'
		line_break
		puts "What action would you like to take: "
		print "'create' a challenge, 'mark' a challenge complete, 'done' to exit: "
		input_toggle = false
		while !input_toggle
			input = gets.chomp
			line_break

############################################################################## CHALLENGES CREATE
			if input == 'create'
				participants = []
				participants << user_name
				puts "Enter the challenge description ('done' to exit): "
				done = false
				description = gets.chomp
				while !done
					if description == 'done'
						done = true
					else
						puts "Enter each user name involved in the challenge (hit enter after each name, enter 'done' to stop, or if you are the only user involved): "
						name = gets.chomp
						if name == 'done'
							done = true
						else
							participants << name
						end
					end
				end
				create_challenge(db, description, participants)
				input_toggle = true

			end
		end

############################################################################## FRIENDS MENU		
	elsif menu_input == 'f'
		line_break
		print_pending_requests(db, user_id)
		line_break

		puts "What action would you like to take: "
		print "'add' a friend, 'respond' to a request, 'done' to exit: "

		input_toggle = false
		while !input_toggle
			input = gets.chomp
			line_break

############################################################################## FRIENDS ADD
			if input == 'add'
				input_toggle = true
				valid_name = false
				while !valid_name
					line_break
					print "Enter the user name of the friend you would like to send a friend request to ('done' to exit): "
					friend = gets.chomp
					friend_cred = db.execute("SELECT * FROM users WHERE user_name=?", [friend])
					if friend == 'done'
						valid_name = true
					elsif !friend_cred[0]
						puts "Sorry, that user name does not exist. Try again."
					else
						valid_name = true
						friend_id = get_friend_id(db, friend)
						send_friend(db, user_id, friend_id, friend)
						line_break
						line_break
					end
				end

############################################################################## FRIENDS RESPOND
			elsif input == 'respond'
				input_toggle = true
				puts "Your friend requests: "
				friend_requests = db.execute("SELECT users.user_name, friendkey.status_name FROM relationships JOIN users, friendkey ON relationships.action_user_id=users.id AND relationships.status=friendkey.status_id WHERE (relationships.user_one_id=? OR relationships.user_two_id=?) AND relationships.status=?", [user_id, user_id, 0])
				friend_requests.each do |friend|
					puts "#{friend[0]} : #{friend[1]}"
				end
				valid_name = false
				while !valid_name
					print "Enter a user name to respond to or 'done' to exit: "
					friend = gets.chomp
					friend_requests.flatten!
					if friend_requests.include? friend
						puts "Enter 'accept' or 'decline' to accept or decline the request or 'done' to exit."
						action_request = gets.chomp

############################################################################## FRIENDS ACCEPT
						if action_request == 'accept'
							friend_id = get_friend_id(db, friend)
							accept_friend(db, user_id, friend_id)
							puts "You are now friends with #{friend}!"
							valid_name = true

############################################################################## FRIENDS DECLINE
						elsif action_request == 'decline'
							friend_id = get_friend_id(db, friend)
							decline_friend(db, user_id, friend_id)
							puts "You have declined #{friend}'s request."
							valid_name = true
						elsif action_request == 'done'
							valid_name = true
						else
							puts "Invalid option, Please try again."
								
						end
					elsif friend == 'done'
						valid_name = true
					else
						puts "Sorry that is not a valid user name."
					end
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
			
