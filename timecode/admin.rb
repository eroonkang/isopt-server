require './timecode.rb'

if ARGV.length == 0 or (ARGV[0] != "set_new_password" and ARGV[0] != "reset_database")
  puts "Usage: "
  puts "admin.rb set_new_password new_password"
  puts "- Sets write-access password to new_password"
  puts
  puts "admin.rb reset_database"
  puts "- Creates new database."
  puts "- Deletes all Minute records, and all Time Change events."
  puts "- Also creates a backup of existing database, just in case."
  exit(0)
end
    
if ARGV[0] == "set_new_password"
  if ARGV[1].length < 8
    puts "Please set a password longer than 8 characters."
    exit(0)
  end
  if ARGV[2]
    puts "Password may not have spaces"
    exit(0)
  end
  puts "Please enter the phrase: 'change the password' (without quotes)"
  puts "to change the password to #{ARGV[1]}"
  change = STDIN.gets.chomp
  if (change != "change the password")
    puts "Not Changing the Password."
    exit(0)
  end
  SecretPassword.all.destroy
  SecretPassword.create(:password => ARGV[1])
  puts "New password set to: ", ARGV[1]
  
end

if ARGV[0] == "reset_database" 
  puts "Please enter the phrase: 'reset database' (without quotes)"
  puts "to backup existing database and create a new one."
  change = STDIN.gets.chomp
  if (change != "reset database")
    puts "Not resetting database"
    exit(0)
  end
  `cp timecode.db timecode_#{Time.now.strftime("%Y-%m-%d--%H-%M-%S")}.db`
  DataMapper.auto_migrate!
  MinuteRecord.all.destroy
  TimeShift.all.destroy
  SecretPassword.create(:password => "password")
  TimeShift.create(:actual_time => Time.now, :timecode_start => Time.now, :minute_in_seconds => 60.0)
  puts "","Deleted all records, database is clean."
  puts "New password is 'password' (without quotes)"
end
  
