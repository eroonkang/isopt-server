require 'sinatra'
require 'data_mapper'
require 'time_difference'
require 'slim'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/timecode.db")

class SecretPassword
  include DataMapper::Resource
  property :id,           Serial
  property :password,     String, :required => true
end

class MinuteRecord
  include DataMapper::Resource
  property :id,           Serial
  property :milliseconds, Integer,   :required => true
  property :submitted_at, DateTime, :required => true
  property :user_id,      String,   :required => true
end

class TimeShift
  include DataMapper::Resource
  property :id,                 Serial
  property :actual_time,        DateTime, :required => true
  property :timecode_start,     DateTime, :required => true
  property :minute_in_seconds,  Float,    :required => true
end

DataMapper.finalize


def get_current_timecode()
	# get most recent timeshift
  st = TimeShift.last
  # calculate time difference between the wallclock time of this timeshift, and now (in real seconds)
  td = TimeDifference.between(st.actual_time, Time.now)
  # transform this value by the current negotiated minute
  return st.timecode_start + (td.in_seconds / st.minute_in_seconds).minutes
end

get '/' do
  
  x = get_current_timecode()
    
  @timecode = x.strftime("%a, %e %b %Y %H:%M:%S")
  @wall_time = Time.now.strftime("%a, %e %b %Y %H:%M:%S")
  @minute_in_seconds = TimeShift.last.minute_in_seconds
  
  slim :display_time

  
end

get '/new' do
  slim :new_time
end

post '/new' do
  
  ms = params['new_time'][:milliseconds]
  user_id = params['new_time'][:user_id]
  password = params['new_time'][:password]
  
  # make sure password matches.
  if SecretPassword.last.password != password
    redirect to('/')
    return
  end
  
  # make sure our milliseconds are in a reasonable range, 30-90 seconds.
  if (ms.to_i > 30000 and ms.to_i < 90000) then
    # delete all other records from this user
    MinuteRecord.all(:user_id => user_id).destroy
    # create a new record for this user
    MinuteRecord.create(:milliseconds => ms.to_i, :submitted_at => Time.now, :user_id => user_id)
    total_milliseconds = 0
    # take an average of all time records
    for r in MinuteRecord.all do
      total_milliseconds += r.milliseconds 
    end
    seconds_in_a_minute = total_milliseconds / 1000.0 / MinuteRecord.all.count
    
    # get current timecode
    current_timecode = get_current_timecode()
    
    # create a new timeshift, starting at the current timecode, with the new negotiated time
    TimeShift.create(:actual_time => Time.now, :timecode_start => current_timecode, :minute_in_seconds => seconds_in_a_minute)
    
  end
  redirect to('/')
end